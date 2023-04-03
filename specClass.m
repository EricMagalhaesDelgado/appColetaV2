classdef specClass

    properties

        ID          {mustBeNumeric}
        taskObj     = []
        Observation = struct('Created',    '', ...                          % Datestring data type - Format: '24/02/2023 14:00:00'
                             'BeginTime',  [], ...                          % Datetime data type
                             'EndTime',    [])                              % Datetime data type
        hReceiver                                                           % Handle to Receiver
        hUDP
        hGPS                                                                % Handle to GPS
        hSwitch                                                             % Handle to Antenna Switch (handles to ACUs will be deleted after task startup)
        SCPI        = struct('scpiSet_Reset',   '', ...
                             'scpiSet_Startup', '', ...
                             'scpiSet_Sync',    '', ...
                             'scpiGet_Att',     '', ...
                             'scpiGet_Data',    '')
        lastGPS     = struct('Status',     0, ...
                             'Latitude',  -1, ...
                             'Longitude', -1)
        Band        = struct('scpiSet_Config',  '', ...
                             'scpiSet_Att',     '', ...
                             'scpiSet_Answer',  '', ...
                             'Datagrams',       [], ...
                             'DataPoints',      [], ...
                             'SyncModeRef',     -1, ...
                             'Waterfall', struct('idx',      0,   ...
                                                 'Matrix',   []), ...
                             'Mask', struct('Array',         [],  ...
                                            'Count',         [],  ...
                                            'MainPeaks',     []), ...
                             'File', struct('Fileversion',   [],  ...
                                            'Basename',      '',  ...
                                            'Filecount',     [],  ...
                                            'WritedSamples', [],  ...
                                            'CurrentFile',   struct('FullPath',        '',   ...
                                                                    'AlocatedSamples', [],   ...
                                                                    'Handle',          [],   ...
                                                                    'MemMap',          [])), ...
                             'Antenna', '')
        Status      = ''                                                    % 'Na fila...' | 'Em andamento...' | 'Concluída' | 'Cancelada' | 'Erro'
        LOG         = struct('type', '', ...
                             'time', '', ...
                             'msg',  '')

    end


    methods

        function [specObj, idx] = Fcn_AddTask(specObj, taskObj)

            global appGeneral
            appGeneral = struct('userPath',       'C:\P&D\appColeta_Task\Temp', ...
                                'WaterfallDepth', 512,                          ...
                                'Fileversion',    'RFlookBin v.2/1',            ...
                                'Filesize',       100e+6);

            if isempty([specObj.ID]); idx = 1;
            else;                     idx = numel(specObj)+1;
            end

            specObj(idx).ID          = idx;
            specObj(idx).taskObj     = taskObj;
            specObj(idx).Observation = struct('Created',   datestr(now, 'dd/mm/yyyy HH:MM:SS'),                                                                                         ...
                                              'BeginTime', datetime(taskObj.General.Task.Observation.BeginTime, 'InputFormat', 'dd/MM/yyyy HH:mm:ss', 'Format', 'dd/MM/yyyy HH:mm:ss'), ...
                                              'EndTime',   datetime(taskObj.General.Task.Observation.EndTime,   'InputFormat', 'dd/MM/yyyy HH:mm:ss', 'Format', 'dd/MM/yyyy HH:mm:ss'));

            specObj(idx).hReceiver   = taskObj.Receiver.Handle;
            specObj(idx).hGPS        = taskObj.GPS.Handle;
            specObj(idx).hSwitch     = taskObj.Antenna.Switch.Handle;

            specObj(idx).lastGPS     = struct('Status',     0, ...
                                              'Latitude',  -1, ...
                                              'Longitude', -1);
            
            warnMsg  = {};
            errorMsg = '';
            try
                [specObj(idx).SCPI, specObj(idx).Band, warnMsg] = connect_Receiver_WriteReadTest(taskObj);
            catch ME
                errorMsg = ME.message;
            end

            % LOG
            specObj(idx).LOG = struct('type', '', ...
                                      'time', '', ...
                                      'msg',  '');
            
            % STATUS
            if isempty(errorMsg); specObj(idx).Status = 'Na fila...';
            else;                 specObj(idx).Status = 'Erro';
            end
            specObj(idx).LOG(end+1) = struct('type', 'StartUp', 'time', specObj(idx).Observation.Created, 'msg', sprintf('<b>INICIALIZAÇÃO (1 de 3)</b>\nEstado atual: %s', specObj(idx).Observation.Created, specObj(idx).Status));
            
            if ~isempty(warnMsg)
                specObj(idx).LOG{end+1} = sprintf('<b>%s - ALERTA</b>\n%s"', datestr(now, 'dd/mm/yyyy HH:MM:SS'), warnMsg);
            end

            if isempty(errorMsg)
                baseName = sprintf('appColeta_%s', datestr(now, 'yymmdd_THHMMSS'));

                if strcmp(taskObj.General.Type, 'Rompimento de Máscara Espectral')
                    maskInfo = mask_FileRead(taskObj.General.Maskfile);
                end 

                logMsg = sprintf(['scpiSet_Reset: "%s"\n'                                   ...
                                  'scpiSet_Startup: "%s"\n'                                 ...
                                  'scpiSet_Sync: "%s"'], specObj(idx).SCPI.scpiSet_Reset,   ...
                                                         specObj(idx).SCPI.scpiSet_Startup, ...
                                                         specObj(idx).SCPI.scpiSet_Sync);

                specObj(idx).LOG{end+1} = sprintf('<b>%s - INICIALIZAÇÃO (2 de 3)</b>\n%s', datestr(now, 'dd/mm/yyyy HH:MM:SS'), logMsg);

                for ii = 1:numel(specObj(idx).Band)
                    ThreadID = taskObj.General.Task.Band(ii).ThreadID;

                    % MASK
                    specObj(idx).Band(ii).Mask = [];
                    if strcmp(taskObj.General.Type, 'Rompimento de Máscara Espectral') & taskObj.General.Task.Band(ii).Trigger
                        specObj(idx).Band(ii).Mask = struct('Array', mask_ArrayConstructor(maskInfo, taskObj.General.Task.Band(ii)), ...
                                                            'Count', 0, 'MainPeak', []);

                        specObj(idx).LOG{end+1} = sprintf('<b>%s - INICIALIZAÇÃO (Máscara espectral)</b>\nID %.0f\n%s"', datestr(now, 'dd/mm/yyyy HH:MM:SS'), ThreadID, jsonencode(maskInfo.Table));
                    end


                    % FILE
                    specObj(idx).Band(ii).File = struct('Fileversion', appGeneral.Fileversion,                    ...
                                                        'Basename', sprintf('%s_ID%.0f', baseName, ThreadID), ...
                                                        'Filecount', 0, 'WritedSamples', 0, 'CurrentFile', []);

                    [specObj(idx).Band(ii).File.Filecount, ...
                        specObj(idx).Band(ii).File.CurrentFile] = RFlookBinLib.OpenFile(specObj(idx), ii);

                    logMsg = sprintf(['ID: %.0f\n'             ...
                                      'scpiSet_Config: "%s"\n' ...
                                      'scpiSet_Att: "%s"\n'    ...
                                      'scpiSet_Answer: "%s"\n' ...
                                      'Filename (base): %s\n'  ...
                                      'AlocatedSamples: %.0f'], ThreadID,                             ...
                                                                specObj(idx).Band(ii).scpiSet_Config, ...
                                                                specObj(idx).Band(ii).scpiSet_Att,    ...
                                                                specObj(idx).Band(ii).scpiSet_Answer, ...
                                                                specObj(idx).Band(ii).File.Basename,  ...
                                                                specObj(idx).Band(ii).File.CurrentFile.AlocatedSamples);

                    specObj(idx).LOG{end+1} = sprintf('<b>%s - INICIALIZAÇÃO (3 de 3)</b>\n%s', datestr(now, 'dd/mm/yyyy HH:MM:SS'), logMsg);


                    % WATERFALL MATRIX
                    WaterfallDepth  = appGeneral.WaterfallDepth;   
                    AlocatedSamples = specObj(idx).Band(ii).File.CurrentFile.AlocatedSamples;
                    DataPoints      = taskObj.General.Task.Band(ii).instrDataPoints;

                    switch taskObj.General.Task.Band(ii).instrLevelUnit
                        case 'dBm';            refLevel = -120;
                        case {'dBµV', 'dBμV'}; refLevel = -13;
                    end
                    
                    if taskObj.General.Task.Observation.Type == "Samples"
                        WaterfallDepth  = min([WaterfallDepth,  taskObj.General.Task.Band(ii).instrObservationSamples]);
                        AlocatedSamples = min([AlocatedSamples, taskObj.General.Task.Band(ii).instrObservationSamples]);
                    end
                    specObj(idx).Band(ii).Matrix = refLevel .* ones(WaterfallDepth, DataPoints, 'single');
                end

            else
                specObj(idx).LOG{end+1} = sprintf('<b>%s - ERRO</b>\n%s', datestr(now, 'dd/mm/yyyy HH:MM:SS'), errorMsg); 
            end

        end


        function specObj = Fcn_DelTask(specObj, idx)

            if (idx <= numel(specObj)) & (numel([specObj.ID]) > 1)
                specObj(idx) = [];

                for ii = 1:numel(specObj)
                    specObj(ii).ID = ii;
                end
            end

        end

    end
end