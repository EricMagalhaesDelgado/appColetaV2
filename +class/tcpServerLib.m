classdef tcpServerLib < handle

    properties
        App
        Server
        Time
        LOG
    end


    methods
        %-----------------------------------------------------------------%
        function obj = tcpServerLib(app)
            obj.App = app;

            try
                obj.Server = tcpserver(app.General.tcpServer.IP, app.General.tcpServer.Port);
            catch
                obj.Server = tcpserver(app.General.tcpServer.Port);
            end
            configureTerminator(obj.Server, "CR/LF")
            configureCallback(obj.Server, "terminator", @(~,~)obj.receivedMessage)

            obj.Time = datetime('now', 'Format', 'dd/MM/yyyy HH:mm:ss');
            obj.LOG  = table('Size', [0, 8],                                                                                    ...
                             'VariableTypes', {'string', 'string', 'double', 'string', 'string', 'string', 'double', 'string'}, ...
                             'VariableNames', {'Timestamp', 'ClientAddress', 'ClientPort', 'Message', 'ClientName', 'Request', 'NumBytesWritten', 'Status'});
        end


        %-----------------------------------------------------------------%
        function receivedMessage(obj)
            app = obj.App;

        % O servidor se comunica com apenas um único cliente, negando tentativas 
        % de conexão de outros clientes enquanto estiver ativa a comunicação com 
        % o cliente (socket criado).

        % O cliente deve enviar uma mensagem textual encapsulada pelas tags <JSON> 
        % e </JSON>. A mensagem deve respeitar a sintaxe JSON e possuir as 
        % seguintes chaves: "Key", "ClientName" e "Request".

        % O trigger no servidor não é o número de bytes recebidos, mas a chegada 
        % do terminador "CR/LF", que o cliente deve embutir na sua requisição.
    
        % Caso o cliente seja criado no MATLAB, a comunicação pode se dar da 
        % seguinte forma:
        % - writeline(tcpClient, ['<JSON>' jsonencode(msg) '</JSON>'])
        % - write(tcpClient, sprintf('<JSON>%s</JSON>\r\n', jsonencode(msg)))

            while obj.Server.NumBytesAvailable
                rawMsg  = readline(obj.Server);
                rawCell = extractBetween(rawMsg, '<JSON>', '</JSON>');
                
                if ~isempty(rawCell)
                    for ii = 1:numel(rawCell)
                        try
                            decodedMsg = jsondecode(rawCell{ii});
    
                            % Verifica se a mensagem apresenta apenas as chaves
                            % "Key", "ClientName" e "Request".
                            if ~all(ismember(fields(decodedMsg), {'Key', 'ClientName', 'Request'}))
                                error('tcpServerLib:WrongListOfFields', 'Wrong list of fields')
                            end
                            
                            % Verifica tipos de dados...
                            mustBeTextScalar(decodedMsg.Key)
                            mustBeTextScalar(decodedMsg.ClientName)
                            mustBeTextScalar(decodedMsg.Request)
    
                            % Verifica se o cliente passou o valor correto de "Key".
                            % (configurado no arquivo "GeneralSettings.json")
                            if ~strcmp(decodedMsg.Key, app.General.tcpServer.Key)
                                error('tcpServerLib:IncorrectKey', 'Incorrect key')
                            end
    
                            % Verifica se o nome do cliente está na lista de possíveis 
                            % nomes que o servidor se comunica.
                            % (configurado no arquivo "GeneralSettings.json")
                            if ~isempty(app.General.tcpServer.ClientList) && ~ismember(decodedMsg.ClientName, app.General.tcpServer.ClientList)
                                error('tcpServerLib:UnauthorizedClient', 'Unauthorized client')
                            end
            
                            % Requisições...
                            switch decodedMsg.Request
                                case 'StationInfo'; msg = StationInfo(obj);
                                case 'TaskList';    msg = TaskList(obj);
                                otherwise;          error('tcpServerLib:UnexpectedRequest', 'Unexpected Request')
                            end
    
                            sendMessageToClient(obj, struct('Request', rawCell{ii}, 'Answer', msg))
                            logTableFill(obj, rawMsg, decodedMsg, 'success')
                            
                        catch ME
                            sendMessageToClient(obj, struct('Request', rawCell{ii}, 'Answer', ME.identifier))
                            logTableFill(obj, rawMsg, rawCell{ii}, ME.message)
                        end
                    end
    
                else
                    sendMessageToClient(obj, struct('Request', rawMsg, 'Answer', 'Invalid request'))
                    logTableFill(obj, rawMsg, '', 'tcpServerLib:EmptyRequest')
                end
            end
        end
    end


    methods (Access = protected)
        %-----------------------------------------------------------------%
        function sendMessageToClient(obj, structMsg)
            writeline(obj.Server, ['<JSON>' jsonencode(structMsg) '</JSON>'])
        end


        %-----------------------------------------------------------------%
        function logTableFill(obj, rawMsg, decodedMsg, statusMsg)
            if isfield(decodedMsg, 'ClientName'); ClientName = decodedMsg.ClientName;
            else;                                 ClientName = '-';
            end

            if isfield(decodedMsg, 'ClientName'); Request    = decodedMsg.Request;
            else;                                 Request    = '-';
            end

            obj.LOG(end+1,:) = {datestr(now),               ...
                                obj.Server.ClientAddress,   ...
                                obj.Server.ClientPort,      ...
                                rawMsg,                     ...
                                ClientName,                 ...
                                Request,                    ...
                                obj.Server.NumBytesWritten, ...
                                statusMsg};
        end


        %-----------------------------------------------------------------%
        function stationInfo = StationInfo(obj)
            app = obj.App;
            stationInfo = struct('stationInfo', app.General.stationInfo, ...
                                 'position',    struct('IDN', {}, 'gpsType', {}, 'Latitude', {}, 'Longitude', {}));

            for ii = 1:numel(app.specObj)
                stationInfo.position(ii) = struct('IDN',       app.specObj(ii).IDN,                  ...
                                                  'gpsType',   app.specObj(ii).Task.Script.GPS.Type, ...
                                                  'gpsStatus', app.specObj(ii).lastGPS.Status,       ...
                                                  'Latitude',  app.specObj(ii).lastGPS.Latitude,     ...
                                                  'Longitude', app.specObj(ii).lastGPS.Longitude);
            end
        end


        %-----------------------------------------------------------------%
        function taskList = TaskList(obj)            
            app = obj.App;
            taskList = struct();
            
            for ii = 1:numel(app.specObj)
                taskList(ii).ID           = app.specObj(ii).ID;
                taskList(ii).IDN          = app.specObj(ii).IDN;
                taskList(ii).TaskName     = app.specObj(ii).Task.Script.Name;
                taskList(ii).Observation  = struct('Type',      app.specObj(ii).Task.Script.Observation.Type, ...
                                                   'BeginTime', app.specObj(ii).Observation.BeginTime,  ...
                                                   'EndTime',   app.specObj(ii).Observation.EndTime);
                
                for jj = 1:numel(app.specObj(ii).Band)
                    Mask = app.specObj(ii).Band(jj).Mask;
                    if ~isempty(Mask)
                        Mask = rmfield(Mask, {'Array', 'BrokenArray'});
                    end

                    taskList(ii).Band(jj) = struct('FreqStart',          app.specObj(ii).Task.Script.Band(jj).FreqStart,                ...
                                                   'FreqStop',           app.specObj(ii).Task.Script.Band(jj).FreqStop,                 ...
                                                   'ObservationSamples', app.specObj(ii).Task.Script.Band(jj).instrObservationSamples,  ...
                                                   'nSweeps',            app.specObj(ii).Band(jj).nSweeps,                              ...
                                                   'Mask',               Mask);
                end
                taskList(ii).Status       = app.specObj(ii).Status;
            end
        end
    end
end