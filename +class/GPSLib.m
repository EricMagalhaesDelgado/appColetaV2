classdef GPSLib

    % !! PENDENTE !!
    % Confirmar que o objeto de transporte de uma conexão serial é aquilo
    % que catei na classe serialport (atualmente nas linhas 50 e 51).

    % !! PENDENTE !!
    % Confirmar comportamento do socket numa porta serial de comunicação...
    % desconexão de cabo, o que ocorre? Criar notas dentro da função
    % "ReconnectAttempt"

    properties
        Config
        List
        Table = table('Size', [0, 6],                                                              ...
                      'VariableTypes', {'string', 'string', 'string', 'string', 'cell', 'string'}, ...
                      'VariableNames', {'Family', 'Type', 'IDN', 'Socket', 'Handle', 'Status'})
    end


    methods
        %-----------------------------------------------------------------%
        function obj = GPSLib(RootFolder)
            obj.Config = struct2table(jsondecode(fileread(fullfile(RootFolder, 'Settings', 'GPSLib.json'))));
            obj.List   = obj.FileRead(RootFolder);
        end


        %-----------------------------------------------------------------%
        function [obj, idx, msgError] = Connect(obj, instrSelected)
            % Características do instrumento em que se deseja controlar:
            Type = instrSelected.Type;
            Port = instrSelected.Parameters.Port;
            [IP, BaudRate] = obj.MissingParameters(instrSelected);

            switch Type
                case 'Serial';       Socket = Port;                       className = 'Serialport';
                case 'TCPIP Socket'; Socket = sprintf("%s:%s", IP, Port); className = 'TCPCustomClient';
            end

            % Consulta se já há objeto criado para o instrumento:
            msgError = '';
            idx = find(strcmp(obj.Table.Socket, Socket), 1);

            if ~isempty(idx)
                hGPS = obj.Table.Handle{idx};

                % Três tentativas para reestabelecer a comunicação, caso
                % esteja com falha.
                for kk = 1:3
                    try
                        warning('off', 'MATLAB:structOnObject')
                        if ~struct(struct(hGPS).(className)).Transport.Connected
                            struct(struct(hGPS).(className)).Transport.connect
                        end

                        if obj.ConnectionStatus(hGPS)
                            break
                        end

                    catch ME
                        switch ME.identifier
                            case 'network:tcpclient:connectFailed'
                                msgError = ME.message;
                                obj.Table.Status(idx) = 'Disconnected';
                                return
                            case {'MATLAB:class:InvalidHandle', 'testmeaslib:CustomDisplay:PropertyError'}
                                delete(obj.Table.Handle{idx})
                                obj.Table(idx,:) = [];
                                idx = [];
                                break
                        end
                    end
                    pause(.100)
                end
            end

            try
                if isempty(idx)
                    idx = height(obj.Table)+1;
                    switch Type
                        case 'Serial';       hGPS = serialport(Port, BaudRate);
                        case 'TCPIP Socket'; hGPS = tcpclient(IP, str2double(Port));
                    end

                    if ~ConnectionStatus(obj, hGPS)
                        error('GPSLib:NoData', 'No data received from GPS')
                    end
                end

                hGPS.UserData = struct('instrSelected', instrSelected);
                obj.Table{idx,:}   = {"GPS", Type, "", Socket, hGPS, "Connected"};
      
            catch ME
                msgError = ME.message;
                if (idx > height(obj.Table)) & exist('hGPS', 'var')
                    clear hGPS
                end
                idx = [];
            end
        end


        %-----------------------------------------------------------------%
        function obj = ReconnectAttempt(obj, instrSelected)
            obj = Connect(obj, instrSelected);
        end
    end


    methods (Access = protected)
        %-----------------------------------------------------------------%
        function List = FileRead(obj, RootFolder)
            
            try
                tempList = jsondecode(fileread(fullfile(RootFolder, 'Settings', 'instrumentList.json')));
                for ii = 1:numel(tempList)
                    tempList(ii).Parameters = jsonencode(tempList(ii).Parameters);
                end
    
                List = struct2table(tempList, 'AsArray', true);
                List(~strcmp(List.Family, 'GPS'),:) = [];

            catch
                List = table('Size', [0, 7],                                                              ...
                             'VariableTypes', {'cell', 'cell', 'cell', 'cell', 'cell', 'double', 'cell'}, ...
                             'VariableNames', {'Family', 'Name', 'Type', 'Parameters', 'Description', 'Enable', 'LOG'});            
            end
        end


        %-----------------------------------------------------------------%
        function [IP, BaudRate] = MissingParameters(obj, instrSelected)
            % IP
            if isfield(instrSelected.Parameters, 'IP');        IP = instrSelected.Parameters.IP;
            else;                                              IP = '';
            end

            if strcmpi(IP, 'localhost');                       IP = '127.0.0.1';
            end
        
            % BaudRate
            if ~isfield(instrSelected.Parameters, 'BaudRate'); BaudRate = [];
            end
        end


        %-----------------------------------------------------------------%
        function Status = ConnectionStatus(obj, hGPS)
            
            Status = false;
            flush(hGPS)

            statusTic = tic;
            t = toc(statusTic);
            while t < class.Constants.gpsTimeout
                if hGPS.NumBytesAvailable
                    Status = true;
                    break
                end
                t = toc(statusTic);
            end
        end
    end
end