classdef scpiLib

    % !! EVOLUÇÃO !!
    % A consulta para saber se já há objeto "tcpclient" criado para o 
    % instrumento selecionado está restrita ao IP. E se tiver vários
    % instrumentos no mesmo IP, mas com portas distintas?!

    % !! EVOLUÇÃO !!
    % Inserir conexão VISA - normal (sem indicar a porta) e SOCKET.

    properties
        Config
        List
        Table = table('Size', [0, 7],                                                                      ...
                      'VariableTypes', {'string', 'string', 'string', 'cell', 'double', 'double', 'cell'}, ...
                      'VariableNames', {'Type', 'IDN', 'Socket', 'Handle', 'nTask', 'Status', 'LOG'})
    end


    methods
        %-----------------------------------------------------------------%
        function obj = scpiLib(RootFolder)
            % Config
            obj.Config = struct2table(jsondecode(fileread(fullfile(RootFolder, 'Settings', 'scpiLib_Config.json'))));

            % List
            tempList = jsondecode(fileread(fullfile(RootFolder, 'Settings', 'scpiLib_List.json')));
            for ii = 1:numel(tempList)
                tempList(ii).Parameters = jsonencode(tempList(ii).Parameters);
            end

            obj.List = struct2table(tempList, 'AsArray', true);
            obj.List.idx = (1:numel(tempList))';
            obj.List = movevars(obj.List, 'idx', 'Before', 1);
        end


        %-----------------------------------------------------------------%
        function [obj, idx] = Connect(obj, instrSelected)        
            % Características do instrumento em que se deseja controlar:
            Type = instrSelected.Type;
            Tag  = instrSelected.Tag;
            [IP, Port, Localhost_publicIP, Localhost_localIP] = MissingParameters(instrSelected);

            % Consulta se há objeto "tcpclient" criado para o instrumento:
            IDN = '';

            idx = find(contains(obj.Table.Socket, IP), 1);
            if ~isempty(idx)
                hReceiver = obj.Table.Handle{idx};

                % Três tentativas para reestabelecer a comunicações, caso
                % esteja com falha.
                for kk = 1:3
                    try
                        if ~struct(struct(hReceiver).TCPCustomClient).Transport.Connected
                            struct(struct(hReceiver).TCPCustomClient).Transport.connect
                        end

                        IDN = ConnectionStatusTest(hReceiver);
                        break

                    catch ME
                        switch ME.identifier
                            case 'network:tcpclient:connectFailed'
                                obj.Table.Status(idx) = 'Disconnected';
                                return

                            case {'MATLAB:class:InvalidHandle', 'testmeaslib:CustomDisplay:PropertyError'}
                                delete(obj.Table.Handle{idx})
                                obj.Table(idx,:) = [];
                                idx = [];
                                break

                            otherwise
                                ME.identifier
                        end
                    end
                    pause(.100)
                end

                if isempty(IDN)
                    idx = [];
                end
            end

            if isempty(idx)
                idx = height(obj.Table)+1;
                switch Type
                    case {'TCPIP Socket', 'TCP/UDP IP Socket'}                    
                        hReceiver = tcpclient(IP, Port);                            
                    case 'TCPIP Visa'
                        hReceiver = visadev("TCPIP::" + IP + "::INSTR");
                        % TCPIP0::127.0.0.1::34835::SOCKET
                end
            end

                

        try
                if ~isempty(IDN)
                    if contains(IDN, Tag, "IgnoreCase", true) 
                        if idx > height(instrHandles)
                            ClientIP = '';
                            if     ~isempty(Localhost_publicIP); ClientIP      = Localhost_publicIP;
                            elseif ~isempty(Localhost_localIP);  ClientIP      = Localhost_localIP;
                            elseif ~strcmp(IP, '127.0.0.1');     [~, ClientIP] = connect_IPsFind(IP);
                            end
        
                            instrNew.UserData = struct('IDN',      IDN,      ...
                                                       'ClientIP', ClientIP, ...
                                                       'nTasks',   0,        ...
                                                       'SyncMode', '');
        
                            Socket = IP;
                            if ~isempty(Port)
                                Socket = sprintf('%s:%.0f', Socket, Port);
                            end
                            instrHandles(idx,:) = {'Receiver', IDN, Socket, {instrNew}, 0};
        
                        elseif ~contains(instrHandles.IDN(idx), Tag, "IgnoreCase", true)
                            error('O instrumento mapeado (%s) difere do identificado (%s).', instrHandles.IDN(idx), IDN)
                        end
                        output = struct('type', 'handles', 'instrHandles', instrHandles, 'idx', idx);
        
                    else
                        error('O instrumento identificado (%s) difere do configurado (%s).', IDN, Tag)
                    end
        
                else
                    error('Não recebida resposta à requisição "*IDN?".')
                end
        
            catch ME
                idx = [];

                if (idx > height(instrHandles)) & exist('instrNew', 'var')
                    clear instrNew
                end
            end
        end


        %-----------------------------------------------------------------%
        function obj = ReconnectAttempt(obj, instrSelected)

        % ## tcpclient ##
        % O objeto "tcpclient" possui uma propriedade privada da classe - "TCPCustomClient" -, o qual armazena o objeto "TCPCustomClient".
        % É essa propriedade que possibilita acesso ao objeto "TCPClient".
        %
        % ## TCPClient ##
        % O objeto "TCPClient" possui as propriedades "Connect" (true|false) e "ConnectionStatus" ('Connected'|'Disconnected') que registram o 
        % estado da conexão, o qual só é alterado quando realizada alguma operação de escrita (write, writeline etc) ou leitura no objeto "tcpclient".
        %
        % O MATLAB retorna os seguintes erros em operações de escrita e leitura de um objeto "tcpclient" desconectado:
        % 'MATLAB:networklib:tcpclient:connectTerminated'  (write)
        % 'transportclients:string:writeFailed'            (writeline|writeread)
        % 'transportclients:string:invalidConnectionState' (read|readline)
        %
        % E esse objeto "TCPClient" possui os métodos "connect" e "disconnect", os quais tentam alterar ativamente o estado da conexão.
        %
        % O controle da conexão do appColeta com o objeto "tcpclient" pode ser feito com a exclusão do objeto (delete/clear) e posterior
        % recriação, ou po meio da alteração do seu estado (método "connect" do objeto "TCPClient").
        %
        % Notei, contudo, que o objeto "TCPCustomClient" às vezes é deletado, desvinculando o objeto "tcpclient" do "TCPClient". Quando isso
        % acontece, o MATLAB retorna os seguintes erros:
        % 'MATLAB:networklib:tcpclient:writeFailed'        (write)
        % 'MATLAB:class:InvalidHandle'                     (writeline|writeread|read|readline)
        % 'testmeaslib:CustomDisplay:PropertyError'        (acesso à propriedade)
        %
        % Nesse caso, o objeto "tcpclient" deve ser recriado. Não é adequado armazenar um handle pro objeto "TCPClient" porque, mesmo
        % existente, ele pode não mais estar relacionado ao objeto "tcpclient".
        %
        % Na maioria das vezes, contudo, isso não ocorre, e aí basta chamar o método "connect" do objeto "TCPClient". Se a conexão não for
        % reestabelecida, o MATLAB retorna o erro:
        % 'network:tcpclient:connectFailed'



        end


        %-----------------------------------------------------------------%
        function obj = StatusUpdate(obj)
            for ii = 1:height(Handle)
                hReceiver = obj.Table.Handle{ii};

                if hReceiver.Status
                    try
                        obj.Table.Handle{ii}.NumBytesAvailable;
                    catch ME
                        ME.identifier
                    end
                end
            end
        end
    end


    methods (Access = protected)
        %-----------------------------------------------------------------%
        function [IP, Port, Localhost_publicIP, Localhost_localIP] = MissingParameters(instrSelected)
            % IP
            if isfield(instrSelected.Parameters, 'IP');   IP = instrSelected.Parameters.IP;
            else;                                         IP = '';
            end
        
            % Port
            if isfield(instrSelected.Parameters, 'Port'); Port = instrSelected.Parameters.Port;
            else;                                         Port = [];
            end
            
            if ~isnumeric(Port);                          Port = str2double(Port);
            end
        
            % Localhost_publicIP
            if isfield(instrSelected.Parameters, 'Localhost_publicIP'); Localhost_publicIP = instrSelected.Parameters.Localhost_publicIP;
            else;                                                       Localhost_publicIP = '';
            end
        
            % Localhost_localIP
            if isfield(instrSelected.Parameters, 'Localhost_localIP');  Localhost_localIP = instrSelected.Parameters.Localhost_localIP;
            else;                                                       Localhost_localIP = '';
            end
        end


        %-----------------------------------------------------------------%
        function IDN = ConnectionStatusTest(hReceiver)
            flush(hReceiver)
            IDN = writeread(hReceiver, '*IDN?');
            if isempty(IDN)
                error('scpiLib:EmptyIDN', 'Empty identification')
            end
        end
    end
end