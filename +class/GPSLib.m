classdef GPSLib

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
            [IP, Port, BaudRate, Timeout] = obj.MissingParameters(instrSelected);

            switch Type
                case 'Serial';       Socket = Port;
                case 'TCPIP Socket'; Socket = sprintf("%s:%s", IP, Port);
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
                        warning('off', 'transportlib:legacy:PropertyNotSupported')

                        switch Type
                            case 'Serial';       hTransport = struct(hGPS).Transport;
                            case 'TCPIP Socket'; hTransport = struct(struct(hGPS).TCPCustomClient).Transport;
                        end

                        if ~hTransport.Connected
                            hTransport.connect
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
                    hGPS.Timeout = Timeout;

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
                for ii = numel(tempList):-1:1
                    switch tempList(ii).Type
                        case 'Serial';       essentialFields = {'Port', 'BaudRate'};
                        case 'TCPIP Socket'; essentialFields = {'IP', 'Port'};
                        otherwise;           essentialFields = {};
                    end

                    if ~all(ismember(essentialFields, fields(tempList(ii).Parameters)))
                        tempList(ii) = [];
                    else
                        tempList(ii).Parameters = jsonencode(tempList(ii).Parameters);
                    end                    
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
        function [IP, Port, BaudRate, Timeout] = MissingParameters(obj, instrSelected)
            % IP
            if isfield(instrSelected.Parameters, 'IP');       IP = instrSelected.Parameters.IP;
            else;                                             IP = '';
            end

            if strcmpi(IP, 'localhost');                      IP = '127.0.0.1';
            end
        
            % Port
            if isfield(instrSelected.Parameters, 'Port');     Port = instrSelected.Parameters.Port;
            else;                                             Port = [];
            end

            % BaudRate
            if isfield(instrSelected.Parameters, 'BaudRate'); BaudRate = instrSelected.Parameters.BaudRate;
            else;                                             BaudRate = 9600;
            end

            % Timeout
            if isfield(instrSelected.Parameters, 'Timeout');  Timeout = instrSelected.Parameters.Timeout;
            else;                                             Timeout = class.Constants.Timeout;
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