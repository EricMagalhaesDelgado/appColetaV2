classdef specClass

    properties

        ID          {mustBeNumeric}
        Task        = []
        Observation = struct('Created',    '', ...                          % DATESTRING: '24/02/2023 14:00:00'
                             'BeginTime',  [], ...                          % DATETIME
                             'EndTime',    [])                              % DATETIME
        hReceiver                                                           % Handle to Receiver
        hGPS                                                                % Handle to GPS
        hSwitch                                                             % Handle to Antenna Switch (handles to ACUs will be deleted after task startup)
        SCPI        = struct('ResetMode',       '', ...
                             'SyncMode',        '', ...
                             'scpiSet_Reset',   '', ...
                             'scpiSet_Startup', '', ...
                             'scpiSet_Att',     '', ...
                             'scpiGet_Att',     '', ...
                             'scpiGet_Data',    '')
        Band        = struct('scpiSet_Config', '', ...
                             'Datagrams',      [], ...
                             'DataPoints',     [], ...
                             'SyncModeRef',    [], ...
                             'Mask',           [], ...
                             'Matrix',         [], ...
                             'File', struct('Filename',        '', ...
                                            'Filecount',       [], ...
                                            'AlocatedSamples', [], ...
                                            'WritedSamples',   [], ...
                                            'Handle',          []))
        Status      = ''                                                    % 'Na fila...' | 'Em andamento...' | 'Concluída' | 'Cancelada' | 'Erro'
        LOG         = {}

    end


    methods

        function [specObj, idx] = Fcn_AddTask(specObj, taskObj)

            if isempty([specObj.ID]); idx = 1;
            else;                     idx = numel(specObj)+1;
            end

            specObj(idx).ID          = idx;
            specObj(idx).Task        = taskObj.General.Task;
            specObj(idx).Observation = struct('Created',   datestr(now, 'dd/mm/yyyy HH:MM:SS'),                                                                                         ...
                                              'BeginTime', datetime(taskObj.General.Task.Observation.BeginTime, 'InputFormat', 'dd/MM/yyyy HH:mm:ss', 'Format', 'dd/MM/yyyy HH:mm:ss'), ...
                                              'EndTime',   datetime(taskObj.General.Task.Observation.EndTime,   'InputFormat', 'dd/MM/yyyy HH:mm:ss', 'Format', 'dd/MM/yyyy HH:mm:ss'));

            specObj(idx).hReceiver   = taskObj.Receiver.Handle;
            specObj(idx).hGPS        = taskObj.GPS.Handle;
            specObj(idx).hSwitch     = taskObj.Antenna.Switch.Handle;
            
            errorMsg = '';
            try
                [specObj(idx).SCPI, specObj(idx).Band] = connect_Receiver_WriteReadTest(taskObj);
            catch ME
                errorMsg = ME.message;
            end
            
            if isempty(errorMsg); specObj(idx).Status = 'Em andamento...';
            else;                 specObj(idx).Status = 'Erro';
            end

            specObj(idx).LOG{end+1}  = sprintf('%s - "Tarefa criada. Estado atual: %s"', specObj(idx).Observation.Created, specObj(idx).Status);
            if ~isempty(errorMsg)
                specObj(idx).LOG{end+1} = sprintf('%s - "Registro de erro: %s"', datestr(now, 'dd/mm/yyyy HH:MM:SS'), errorMsg);
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