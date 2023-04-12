function output = connect_Receiver(instrHandles, instrSelected)

    arguments
        instrHandles  table
        instrSelected struct
    end

    Type               = instrSelected.Type;
    Tag                = instrSelected.Tag;
    IP                 = instrSelected.Parameters.IP;
    Port               = instrSelected.Parameters.Port;    
    Localhost_publicIP = instrSelected.Parameters.Localhost_publicIP;
    Localhost_localIP  = instrSelected.Parameters.Localhost_localIP;
        
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
%         IDN = replace(deblank(writeread(instrNew, '*IDN?')), '"', '');
%         drawnow nocallbacks

        writeline(instrNew, '*IDN?'); 
        pause(.1); 
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