function output = connect_Receiver(instrHandles, instrSelected)

    arguments
        instrHandles  table
        instrSelected struct
    end

    Type = instrSelected.Type;
    Tag  = instrSelected.Tag;
    [IP, Port, Localhost_publicIP, Localhost_localIP] = MissingParameters(instrSelected);
        
    try
        idx = find(contains(instrHandles.Socket, IP), 1);
        if ~isempty(idx)            
            instrNew = instrHandles.Handle{idx};

        else
            idx = height(instrHandles)+1;
            switch Type
                case {'TCPIP Socket', 'TCP/UDP IP Socket'}                    
                    instrNew = tcpclient(IP, Port);
                    
                case 'TCPIP Visa'
                    instrNew = visadev("TCPIP::" + IP + "::INSTR");
            end
        end
        
        flush(instrNew)

        writeline(instrNew, '*IDN?');
        fcn.waitfor(instrNew)
        IDN = replace(deblank(read(instrNew, instrNew.NumBytesAvailable, 'char')), '"', '');

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
        if (idx > height(instrHandles)) & exist('instrNew', 'var')
            clear instrNew
        end

        output = struct('type', 'error', 'msg', getReport(ME));
    end
end


%-------------------------------------------------------------------------%
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