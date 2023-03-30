% RFlookBinLib.m
% Author: Eric Magalhães Delgado
% Date: 2023/03/30

classdef RFlookBinLib

	methods(Static = true)

        function [fileCount, CurrentFile] = OpenFile(specObj, ii)
            global appGeneral

            baseName   = specObj.Band(ii).File.Basename;
            fileCount  = specObj.Band(ii).File.Filecount+1;
            fileID     = [];
            fileMemMap = [];
            AlocatedSamples = 0;

            switch specObj.Band(ii).File.Fileversion
                case 'RFlookBin v.1/1'
                    fileName = fullfile(appGeneral.userPath, sprintf('~%s_%.0f.bin', baseName, fileCount));
                    fileID   = fopen(fileName, 'w');

                    AlocatedSamples    = RFlookBinLib.v1_WriteHeader(fileID, specObj, ii);
                    [Offset1, Offset2] = RFlookBinLib.v1_WriteBody(fileID, specObj, ii, AlocatedSamples);
                    fclose(fileID);

                    fileMemMap = RFlookBinLib.v1_MemoryMap(fileName, specObj, ii, AlocatedSamples, Offset1, Offset2);
        
                case 'RFlookBin v.2/1'
                    fileName = fullfile(appGeneral.userPath, sprintf('%s_%.0f.bin', baseName, fileCount));
                    fileID   = fopen(fileName, 'w');
                    
                    RFlookBinLib.v2_WriteHeader(fileID, specObj, ii)
            end

            CurrentFile = struct('FullPath',        fileName,        ...
                                 'AlocatedSamples', AlocatedSamples, ...
                                 'Handle',          fileID,          ...
                                 'MemMap',          fileMemMap);
        end


        function EditFile(specObj, ii, rawArray, attFactor, gpsData)
            switch specObj.Band(ii).File.Fileversion
                case 'RFlookBin v.1/1'
                    RFlookBinLib.v1_MemoryEdit(specObj, ii, rawArray, attFactor, gpsData)

                case 'RFlookBin v.2/1'
                    RFlookBinLib.v2_WriteBody(specObj,  ii, rawArray, attFactor, gpsData)
            end        
        end


        function CloseFile(specObj, ii)
            switch specObj.Band(ii).File.Fileversion
                case 'RFlookBin v.1/1'
                    RFlookBinLib.v1_PostProcessing(specObj, ii);

                case 'RFlookBin v.2/1'
                    fileID = specObj.Band(ii).File.CurrentFile.Handle;
                    fclose(fileID);
            end        
        end

    end


    methods (Static = true, Access = private)

        % ## RFlookBin v.1/1 ##
        function AlocatedSamples = v1_WriteHeader(fileID, specObj, ii)
            global appGeneral

            Task            = specObj.taskObj.General.Task;
            MetaData        = Task.Band(ii);
            BitsPerSample   = Task.BitsPerSample;
            DataPoints      = MetaData.instrDataPoints;
            AlocatedSamples = ceil(appGeneral.Filesize ./ (BitsPerSample * DataPoints));
        
            fwrite(fileID, 'RFlookBin v.1/1', 'char*1');
            fwrite(fileID, BitsPerSample);
            fwrite(fileID, AlocatedSamples, 'uint32');
            fwrite(fileID, 0, 'uint32');
        
            % RECEIVER
            Resolution   = str2double(extractBefore(MetaData.instrResolution, ' kHz')) * 1000;
            Trace_ID     = RFlookBinLib.str2id('TraceMode',      MetaData.TraceMode);
            Detector_ID  = RFlookBinLib.str2id('Detector',       MetaData.instrDetector);
            LevelUnit_ID = RFlookBinLib.str2id('LevelUnit',      MetaData.instrLevelUnit);
            Preamp_ID    = RFlookBinLib.str2id('Preamp',         MetaData.instrPreamp);
            AttMode_ID   = RFlookBinLib.str2id('Attenuation',    MetaData.instrAttMode);
        
            fwrite(fileID, MetaData.FreqStart, 'single');
            fwrite(fileID, MetaData.FreqStop,  'single');
            fwrite(fileID, Resolution,         'single');
            fwrite(fileID, DataPoints, 'uint16');                           % Sweep Points (0-65535 pontos)
            fwrite(fileID, Trace_ID,     'int8');
            fwrite(fileID, Detector_ID,  'int8');
            fwrite(fileID, LevelUnit_ID, 'int8');
            fwrite(fileID, Preamp_ID,    'int8');
            fwrite(fileID, AttMode_ID,   'int8');
        
            if AttMode_ID; attFactor = -1;
            else;          attFactor = str2double(extractBefore(MetaData.instrAttFactor, ' dB'));
            end
            fwrite(fileID, attFactor, 'int8');
        
            fwrite(fileID, -1, 'single');                                   % SampleTimeValue
            fwrite(fileID, zeros(1, 2));                                    % Alignment
        
            % GPS
            switch Task.GPS.Type
                case 'Manual'
                    gpsInfo = struct('Type',       0,                ...
                                     'Status',    -1,                ...
                                     'Latitude',  Task.GPS.Latitude, ...
                                     'Longitude', Task.GPS.Longitude);
        
                otherwise
                    switch Task.GPS.Type
                        case 'Built-in'; gpsType = 1;
                        case 'External'; gpsType = 2;
                    end
        
                    gpsInfo = struct('Type',      gpsType, ...
                                     'Status',     0,      ...
                                     'Latitude',  -1,      ...
                                     'Longitude', -1);
            end
        
            fwrite(fileID, gpsInfo.Type);
            fwrite(fileID, gpsInfo.Status,    'int8');
            fwrite(fileID, gpsInfo.Latitude,  'single');
            fwrite(fileID, gpsInfo.Longitude, 'single');
            fwrite(fileID, -ones(1,6),        'int8');
            fwrite(fileID, -1,                'int16');        
        end


        function [Offset1, Offset2] = v1_WriteBody(fileID, specObj, ii, AlocatedSamples)        
            Task            = specObj.taskObj.General.Task;
            MetaData        = Task.Band(ii);
            BitsPerSample   = Task.BitsPerSample;
            DataPoints      = Task.Band(ii).instrDataPoints;
            Node            = specObj.hReceiver.UserData.IDN;
            
            Offset1 = ftell(fileID) + 12;
            Offset2 = Offset1 + 20*AlocatedSamples;
            Offset3 = Offset2 + BitsPerSample * DataPoints * AlocatedSamples;
        
            fwrite(fileID, Offset1, 'uint32');
            fwrite(fileID, Offset2, 'uint32');
            fwrite(fileID, Offset3, 'uint32');
        
            fwrite(fileID, zeros(1, (20 + BitsPerSample * DataPoints) * AlocatedSamples, 'uint8'));
            fwrite(fileID, jsonencode(struct('TaskName',          replace(Task.Name, {'"', ',', newline}, ''),            ...
                                             'ThreadID',          MetaData.ThreadID,                                      ...
                                             'Description',       replace(MetaData.Description, {'"', ',', newline}, ''), ...
                                             'Node',              Node,                                                   ...
                                             'Antenna',           specObj.Band(ii).Antenna,                               ...
                                             'IntegrationFactor', MetaData.IntegrationFactor,                             ...
                                             'RevisitTime',       MetaData.RevisitTime)), 'char*1');        
        end
        
        
        function fileMemMap = v1_MemoryMap(fileName, specObj, ii, AlocatedSamples, Offset1, Offset2)        
            Task            = specObj.taskObj.General.Task;
            DataPoints      = Task.Band(ii).instrDataPoints;
        
            switch Task.BitsPerSample
                case  8; dataFormat = 'uint8';
                case 16; dataFormat = 'int16';
                case 32; dataFormat = 'single';
            end
        
            % WritedSamples
            fileMemMap{1} = memmapfile(fileName, 'Writable', true,                   ...
                                                 'Offset',   20,                     ...
                                                 'Format',   {'uint32', 1, 'Value'}, ...
                                                 'Repeat',   1);
            % GPS/TimeStamp Block
            fileMemMap{2} = memmapfile(fileName, 'Writable', true,                                 ...
                                                 'Offset',   Offset1,                              ...
                                                 'Format', {'int8',   [1  6], 'localTimeStamp';    ...
                                                            'int16',  [1  1], 'localTimeStamp_ms'; ...
                                                            'int16',  [1  1], 'RefLevel';          ...
                                                            'int8',   [1  1], 'attFactor';         ...
                                                            'uint8',  [1  1], 'gpsStatus';         ...
                                                            'single', [1  1], 'Latitude';          ...
                                                            'single', [1  1], 'Longitude'},        ...
                                                 'Repeat',   AlocatedSamples);
            % Spectral Block
            fileMemMap{3} = memmapfile(fileName, 'Writable', true,                                                 ...
                                                 'Offset',   Offset2,                                              ...
                                                 'Format',   {dataFormat, [DataPoints, AlocatedSamples], 'Array'}, ...
                                                 'Repeat',   1);        
        end


        function v1_MemoryEdit(specObj, ii, rawArray, attFactor, gpsData)
            TimeStamp = datetime('now');
            RefLevel  = max(rawArray);        
            
            switch specObj.taskObj.General.Task.BitsPerSample
                case  8
                    Offset = -2*RefLevel+255;
                    processedArray = uint8(2.*rawArray + Offset);                
                case 16
                    processedArray = int16(100.*rawArray);
                case 32
                    processedArray = single(rawArray);
            end

            idx = specObj.Band(ii).File.CurrentFile.MemMap{1}.Data.Value + 1;

            specObj.Band(ii).File.CurrentFile.MemMap{1}.Data.Value = idx;

            specObj.Band(ii).File.CurrentFile.MemMap{2}.Data(idx).localTimeStamp    = int8([year(TimeStamp)-2000, month(TimeStamp), day(TimeStamp), hour(TimeStamp), minute(TimeStamp), fix(second(TimeStamp))]);
            specObj.Band(ii).File.CurrentFile.MemMap{2}.Data(idx).localTimeStamp_ms = int16((second(TimeStamp) - fix(second(TimeStamp))).*1000);

            specObj.Band(ii).File.CurrentFile.MemMap{2}.Data(idx).RefLevel  = int16(RefLevel);
            specObj.Band(ii).File.CurrentFile.MemMap{2}.Data(idx).attFactor = int8(attFactor);

            specObj.Band(ii).File.CurrentFile.MemMap{2}.Data(idx).gpsStatus = uint8(gpsData.Status);
            specObj.Band(ii).File.CurrentFile.MemMap{2}.Data(idx).Latitude  = single(gpsData.Latitude);
            specObj.Band(ii).File.CurrentFile.MemMap{2}.Data(idx).Longitude = single(gpsData.Longitude);

            specObj.Band(ii).File.CurrentFile.MemMap{3}.Data.Array(:,idx)   = processedArray;        
        end


        function v1_PostProcessing(specObj, ii)
            fileFullPath = specObj.Band(ii).File.CurrentFile.FullPath;

            [filePath, name, ext] = fileparts(fileFullPath);
            fileName = [name, ext];

            AlocatedSamples = specObj.Band(ii).File.CurrentFile.AlocatedSamples;
            WritedSamples   = specObj.Band(ii).File.CurrentFile.MemMap{1}.Data.Value;

            if AlocatedSamples == WritedSamples
                system(sprintf('rename "%s" "%s"', fileFullPath, replace(fileName, '~', '')));

            else
                fileID_temp = fopen(fileFullPath, 'r');
                tempData    = fread(fileID_temp, [1, inf], 'uint8=>uint8');
                fclose(fileID_temp);

                BitsPerPoint  = double(tempData(16));
                WritedSamples = double(typecast(tempData(21:24), 'uint32'));
                DataPoints    = double(typecast(tempData(37:38), 'uint16'));

                Offset2_old   = double(typecast(tempData(73:76), 'uint32'));
                Offset3_old   = double(typecast(tempData(77:80), 'uint32'));

                Offset2 = 80 + 20*WritedSamples;
                Offset3 = Offset2 + (BitsPerPoint/8) * DataPoints * WritedSamples;

                tempData(17:20) = typecast(uint32(WritedSamples), 'uint8');
                tempData(73:76) = typecast(uint32(Offset2), 'uint8');
                tempData(77:80) = typecast(uint32(Offset3), 'uint8');

                trimIdx1 = Offset2_old + (BitsPerPoint/8) * DataPoints * WritedSamples + 1;
                trimIdx2 = Offset2 + 1;
                
                tempData(trimIdx1:Offset3_old) = [];
                tempData(trimIdx2:Offset2_old) = [];

                fileID_new = fopen(fullfile(filePath, replace(fileName, '~', '')), 'w');
                fwrite(fileID_new, tempData);
                fclose(fileID_new);

                system(sprintf('del /f "%s"', fileFullPath));
            end
        end


        % ## RFlookBin v.2/1 ##        
        function v2_WriteHeader(fileID, specObj, ii)
            Task          = specObj.taskObj.General.Task;
            MetaData      = Task.Band(ii);
            BitsPerSample = Task.BitsPerSample;
            Node          = specObj.hReceiver.UserData.IDN;

            AttMode_ID    = RFlookBinLib.str2id('Attenuation', MetaData.instrAttMode);
            gpsMode_ID    = RFlookBinLib.str2id('GPS',         Task.GPS.Type);
        
            fwrite(fileID, 'RFlookBin v.2/1', 'char*1');
            fwrite(fileID, BitsPerSample);
            fwrite(fileID, AttMode_ID);
            fwrite(fileID, gpsMode_ID);
        
            MetaStruct = struct('Receiver',         Node,                        ...
                                'AntennaInfo',      specObj.Band(ii).Antenna,    ...
                                'gpsType',          Task.GPS.Type,               ...
                                'Task',             Task.Name,                   ...
                                'ID',               MetaData.ThreadID,           ...
                                'Description',      MetaData.Description,        ...
                                'FreqStart',        MetaData.FreqStart,          ...
                                'FreqStop',         MetaData.FreqStop,           ...
                                'DataPoints',       MetaData.instrDataPoints,    ...
                                'Resolution',       MetaData.instrResolution,    ...
                                'Preamp',           MetaData.instrPreamp,        ...
                                'AttMode',          MetaData.instrAttMode,       ...
                                'AttFactor',        MetaData.instrAttFactor,     ...
                                'Unit',             MetaData.instrLevelUnit,     ...
                                'TraceMode',        MetaData.TraceMode,          ...
                                'TraceIntegration', MetaData.IntegrationFactor,  ...
                                'Detector',         MetaData.instrDetector,      ...
                                'RevisitTime',      MetaData.RevisitTime);
        
            if AttMode_ID
                MetaStruct = rmfield(MetaStruct, 'AttFactor');
            end
        
            if gpsMode_ID
                MetaStruct.gpsRevisitTime = Task.GPS.RevisitTime;
            else
                MetaStruct.Latitude  = Task.GPS.Latitude;
                MetaStruct.Longitude = Task.GPS.Longitude;
            end

            MetaStruct = jsonencode(MetaStruct);
        
            fwrite(fileID, numel(MetaStruct), 'uint32');
            fwrite(fileID, MetaStruct, 'char*1');
        end


        function v2_WriteBody(specObj, ii, rawArray, attFactor, gpsData)
            TimeStamp = datetime('now');

            fileID = specObj.Band(ii).File.CurrentFile.Handle;
            
            fwrite(fileID, 'StArT', 'char*1');
            fwrite(fileID, [year(TimeStamp)-2000, month(TimeStamp), day(TimeStamp), hour(TimeStamp), minute(TimeStamp), fix(second(TimeStamp))]);
            fwrite(fileID, (second(TimeStamp) - fix(second(TimeStamp))).*1000, 'uint16');

            if ~isempty(gpsData)
                fwrite(fileID, gpsData.Status);
                fwrite(fileID, [gpsData.Latitude, gpsData.Longitude], 'single');
            end
            
            if attFactor ~= -1
                fwrite(fileID, attFactor, 'int8');
            end
            
            switch specObj.taskObj.General.Task.BitsPerSample
                case  8
                    RefLevel = max(rawArray);
                    fwrite(fileID, RefLevel, 'int16');

                    Offset = -2*RefLevel+255;
                    processedArray = uint8(2.*rawArray + Offset);                
                case 16
                    processedArray = int16(100.*rawArray);
                case 32
                    processedArray = single(rawArray);
            end
        
            fwrite(fileID, CompressLib.compress(processedArray));            
            fwrite(fileID, 'StOp', 'char*1');        
        end


        % ## Auxiliar function ##
        function ID = str2id(Type, Value)        
            switch Type
                case 'TraceMode'
                    switch Value
                        case 'ClearWrite'; ID = 1;
                        case 'Average';    ID = 2;
                        case 'MaxHold';    ID = 3;
                        case 'MinHold';    ID = 4;
                    end
        
                case 'Detector'
                    switch Value
                        case 'Sample';        ID = 1;
                        case 'Average/RMS';   ID = 2;
                        case 'Positive Peak'; ID = 3;
                        case 'Negative Peak'; ID = 4;
                    end
        
                case 'LevelUnit'
                    switch Value
                        case 'dBm';            ID = 1;
                        case {'dBµV', 'dBμV'}; ID = 2;
                    end
        
                case 'Preamp'
                    switch Value
                        case 'Off'; ID = 0;
                        case 'On';  ID = 1;
                    end
        
                case 'Attenuation'
                    switch Value
                        case 'Manual'; ID = 0;
                        case 'Auto';   ID = 1;
                    end

                case 'GPS'
                    switch Value
                        case 'Manual';   ID = 0;
                        case 'Built-in'; ID = 1;
                        case 'External'; ID = 2;
                    end
            end        
        end

    end

end