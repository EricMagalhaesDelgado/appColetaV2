function output = connect_Receiver(instrHandles, instrSelected)

    arguments
        instrHandles  table
        instrSelected struct
    end

    Type = instrSelected.Type;
    Tag  = instrSelected.Tag;
    IP   = instrSelected.IP;
    
    idx = find(contains(instrHandles.Socket, IP), 1);
    try
        if ~isempty(idx)            
            instrNew = instrHandles.Handle{idx};

        else
            idx = height(instrHandles)+1;
            switch Type
                case {'TCPIP Socket', 'TCP/UDP IP Socket'}
                    Port = instrSelected.Port;
                    instrNew = tcpclient(IP, Port);
                    
                case 'TCPIP Visa'
                    instrNew = visadev("TCPIP::" + IP + "::INSTR");
            end
        end
        
        IDN = replace(deblank(writeread(instrNew, '*IDN?')), '"', '');

        if ~isempty(IDN)
            if contains(IDN, Tag, "IgnoreCase", true) 
                if idx > height(instrHandles)
                    Socket = IP;
                    if ~isempty(Port)
                        Socket = sprintf('%s:%.0f', Socket, Port);
                    end

                    instrHandles(idx,:) = {'Receiver', IDN, Socket, {instrNew}, 0};
                else
                    if ~contains(instrHandles.IDN(idx), Tag, "IgnoreCase", true)
                        error('O instrumento mapeado (%s) difere do identificado (%s).', instrHandles.IDN(idx), IDN)
                    end
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