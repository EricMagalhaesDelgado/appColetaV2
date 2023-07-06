classdef RFlookBinLib

    % Author.: Eric Magalhães Delgado
    % Date...: March 30, 2023
    % Version: 1.00

    % !! BUG !!
    % Na v. 1, o arquivo binário é criado por meio da função memmepfile. Ao 
    % finalizar a escrita do arquivo, não consigo desmapeá-lo. Ao que parce, o
    % arquivo está visível em alguma outra área de trabalho, o que impede
    % o desmapeamento.
    % Até que se resolva o problema, o appColetaV2 gerará apenas arquivos do 
    % novo formato (v.2).
    % Testar o seguinte: ao invés de passar specObj como argumento de
    % entrada, passar app, alterando diretamente app.specObj.

	methods(Static = true)
        %-----------------------------------------------------------------%
        function [fileCount, CurrentFile] = OpenFile(specObj, idx)
            global appGeneral

            baseName   = specObj.Band(idx).File.Basename;
            fileCount  = specObj.Band(idx).File.Filecount+1;
            fileID     = [];
            fileMemMap = [];
            AlocatedSamples = 0;

            switch specObj.Band(idx).File.Fileversion
                case 'RFlookBin v.1/1'
                    fileName = fullfile(appGeneral.userPath, sprintf('~%s_%.0f.bin', baseName, fileCount));
                    fileID   = fopen(fileName, 'w');

                    AlocatedSamples    = class.RFlookBinLib.v1_WriteHeader(fileID, specObj, idx);
                    [Offset1, Offset2] = class.RFlookBinLib.v1_WriteBody(fileID, specObj, idx, AlocatedSamples);

                    fclose(fileID);
                    fileID = [];

                    fileMemMap = class.RFlookBinLib.v1_MemoryMap(fileName, specObj, idx, AlocatedSamples, Offset1, Offset2);
        
                case 'RFlookBin v.2/1'
                    fileName = fullfile(appGeneral.userPath, sprintf('%s_%.0f.bin', baseName, fileCount));
                    fileID   = fopen(fileName, 'w');
                    
                    class.RFlookBinLib.v2_WriteHeader(fileID, specObj, idx)
            end

            CurrentFile = struct('FullPath',        fileName,        ...
                                 'AlocatedSamples', AlocatedSamples, ...
                                 'Handle',          fileID,          ...
                                 'MemMap',          {fileMemMap});
        end


        %-----------------------------------------------------------------%
        function specObj = CloseFile(specObj, idx)
            switch specObj.Band(idx).File.Fileversion
                case 'RFlookBin v.1/1'
                    AlocatedSamples = specObj.Band(idx).File.CurrentFile.AlocatedSamples;
                    WritedSamples   = specObj.Band(idx).File.CurrentFile.MemMap{1}.Data.Value;

                    if AlocatedSamples == WritedSamples
                        class.RFlookBinLib.v1_PostProcessing(specObj, idx, 'FullFile');
                    else
                        class.RFlookBinLib.v1_PostProcessing(specObj, idx, 'ObservationTime');
                    end
        
                case 'RFlookBin v.2/1'
                    fileID = specObj.Band(idx).File.CurrentFile.Handle;
                    fclose(fileID);
            end

            specObj.Band(idx).File.CurrentFile = [];
        end


        %-----------------------------------------------------------------%
        function specObj = CheckFile(specObj, idx)
            global appGeneral

            switch specObj.Band(idx).File.Fileversion
                case 'RFlookBin v.1/1'
                    AlocatedSamples = specObj.Band(idx).File.CurrentFile.AlocatedSamples;
                    WritedSamples   = specObj.Band(idx).File.CurrentFile.MemMap{1}.Data.Value;
        
                    if AlocatedSamples == WritedSamples
                        class.RFlookBinLib.v1_PostProcessing(specObj, idx, 'FullFile');

                        [specObj.Band(idx).File.Filecount, ...
                            specObj.Band(idx).File.CurrentFile] = class.RFlookBinLib.OpenFile(specObj, idx);
                    end
        
                case 'RFlookBin v.2/1'
                    fileID = specObj.Band(idx).File.CurrentFile.Handle;

                    if ftell(fileID) > appGeneral.File.Size
                        fclose(fileID);

                        [specObj.Band(idx).File.Filecount, ...
                            specObj.Band(idx).File.CurrentFile] = class.RFlookBinLib.OpenFile(specObj, idx);
                    end
            end
        end


        %-----------------------------------------------------------------%
        function EditFile(specObj, idx, rawArray, attFactor)
            gpsData = specObj.lastGPS;
            switch specObj.Band(idx).File.Fileversion
                case 'RFlookBin v.1/1'
                    class.RFlookBinLib.v1_MemoryEdit(specObj, idx, rawArray, attFactor, gpsData)

                case 'RFlookBin v.2/1'
                    class.RFlookBinLib.v2_WriteBody(specObj,  idx, rawArray, attFactor, gpsData)
            end        
        end

    end


    methods (Static = true, Access = private)
        %-----------------------------------------------------------------%
        % ## RFlookBin v.1/1 ##
        %-----------------------------------------------------------------%
        function AlocatedSamples = v1_WriteHeader(fileID, specObj, idx)
            global appGeneral

            Task            = specObj.taskObj.General.Task;
            MetaData        = Task.Band(idx);
            BitsPerSample   = Task.BitsPerSample;
            DataPoints      = MetaData.instrDataPoints;

            if strcmp(specObj.taskObj.General.Task.Observation.Type, 'Samples')
                AlocatedSamples = min([specObj.taskObj.General.Task.Band(idx).instrObservationSamples, ceil(appGeneral.File.Size ./ (BitsPerSample * DataPoints))]);
            else
                AlocatedSamples = ceil(appGeneral.File.Size ./ (BitsPerSample * DataPoints));
            end
        
            fwrite(fileID, 'RFlookBin v.1/1', 'char*1');
            fwrite(fileID, BitsPerSample);
            fwrite(fileID, AlocatedSamples, 'uint32');
            fwrite(fileID, 0, 'uint32');
        
            % RECEIVER
            Resolution   = str2double(extractBefore(MetaData.instrResolution, ' kHz')) * 1000;
            Trace_ID     = class.RFlookBinLib.str2id('TraceMode',      MetaData.TraceMode);
            Detector_ID  = class.RFlookBinLib.str2id('Detector',       MetaData.instrDetector);
            LevelUnit_ID = class.RFlookBinLib.str2id('LevelUnit',      MetaData.instrLevelUnit);
            Preamp_ID    = class.RFlookBinLib.str2id('Preamp',         MetaData.instrPreamp);
            AttMode_ID   = class.RFlookBinLib.str2id('Attenuation',    MetaData.instrAttMode);
        
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


        %-----------------------------------------------------------------%
        function [Offset1, Offset2] = v1_WriteBody(fileID, specObj, idx, AlocatedSamples)        
            Task            = specObj.taskObj.General.Task;
            MetaData        = Task.Band(idx);
            BitsPerSample   = Task.BitsPerSample;
            DataPoints      = Task.Band(idx).instrDataPoints;
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
                                             'Antenna',           specObj.Band(idx).Antenna,                               ...
                                             'IntegrationFactor', MetaData.IntegrationFactor,                             ...
                                             'RevisitTime',       MetaData.RevisitTime)), 'char*1');        
        end
        
        
        %-----------------------------------------------------------------%
        function fileMemMap = v1_MemoryMap(fileName, specObj, idx, AlocatedSamples, Offset1, Offset2)        
            Task            = specObj.taskObj.General.Task;
            DataPoints      = Task.Band(idx).instrDataPoints;
        
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


        %-----------------------------------------------------------------%
        function v1_MemoryEdit(specObj, idx1, rawArray, attFactor, gpsData)
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

            idx2 = specObj.Band(idx1).File.CurrentFile.MemMap{1}.Data.Value + 1;

            specObj.Band(idx1).File.CurrentFile.MemMap{1}.Data.Value = idx2;

            specObj.Band(idx1).File.CurrentFile.MemMap{2}.Data(idx2).localTimeStamp    = int8([year(TimeStamp)-2000, month(TimeStamp), day(TimeStamp), hour(TimeStamp), minute(TimeStamp), fix(second(TimeStamp))]);
            specObj.Band(idx1).File.CurrentFile.MemMap{2}.Data(idx2).localTimeStamp_ms = int16((second(TimeStamp) - fix(second(TimeStamp))).*1000);

            specObj.Band(idx1).File.CurrentFile.MemMap{2}.Data(idx2).RefLevel  = int16(RefLevel);
            specObj.Band(idx1).File.CurrentFile.MemMap{2}.Data(idx2).attFactor = int8(attFactor);

            specObj.Band(idx1).File.CurrentFile.MemMap{2}.Data(idx2).gpsStatus = uint8(gpsData.Status);
            specObj.Band(idx1).File.CurrentFile.MemMap{2}.Data(idx2).Latitude  = single(gpsData.Latitude);
            specObj.Band(idx1).File.CurrentFile.MemMap{2}.Data(idx2).Longitude = single(gpsData.Longitude);

            specObj.Band(idx1).File.CurrentFile.MemMap{3}.Data.Array(:,idx2)   = processedArray;        
        end


        %-----------------------------------------------------------------%
        function v1_PostProcessing(specObj, idx, Type)
            fileFullPath = specObj.Band(idx).File.CurrentFile.FullPath;

            [filePath, name, ext] = fileparts(fileFullPath);
            fileName = [name, ext];

            switch Type
                case 'FullFile'
                    system(sprintf('rename "%s" "%s"', fileFullPath, replace(fileName, '~', '')));

                case 'ObservationTime'
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


        %-----------------------------------------------------------------%
        % ## RFlookBin v.2/1 ##      
        %-----------------------------------------------------------------%
        function v2_WriteHeader(fileID, specObj, idx)
            Task          = specObj.taskObj.General.Task;
            MetaData      = Task.Band(idx);
            BitsPerSample = Task.BitsPerSample;
            Node          = specObj.hReceiver.UserData.IDN;

            AttMode_ID    = class.RFlookBinLib.str2id('Attenuation', MetaData.instrAttMode);
            gpsMode_ID    = class.RFlookBinLib.str2id('GPS',         Task.GPS.Type);
        
            fwrite(fileID, 'RFlookBin v.2/1', 'char*1');
            fwrite(fileID, BitsPerSample);
            fwrite(fileID, AttMode_ID);
            fwrite(fileID, gpsMode_ID);
        
            MetaStruct = struct('Receiver',         Node,                        ...
                                'AntennaInfo',      specObj.Band(idx).Antenna,   ...
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


        %-----------------------------------------------------------------%
        function v2_WriteBody(specObj, idx, rawArray, attFactor, gpsData)
            TimeStamp = datetime('now');

            fileID = specObj.Band(idx).File.CurrentFile.Handle;
            
            fwrite(fileID, 'StArT', 'char*1');
            fwrite(fileID, [year(TimeStamp)-2000, month(TimeStamp), day(TimeStamp), hour(TimeStamp), minute(TimeStamp), fix(second(TimeStamp))]);
            fwrite(fileID, (second(TimeStamp) - fix(second(TimeStamp))).*1000, 'uint16');

            if ismember(specObj.taskObj.General.Task.GPS.Type, {'Built-in', 'External'})
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
        
            fwrite(fileID, class.CompressLib.compress(processedArray));            
            fwrite(fileID, 'StOp', 'char*1');        
        end


        %-----------------------------------------------------------------%
        % ## Auxiliar function ##
        %-----------------------------------------------------------------%
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