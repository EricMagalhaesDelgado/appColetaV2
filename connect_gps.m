function output = connect_gps(instrHandles, instrSelected)

    arguments
        instrHandles  table
        instrSelected struct
    end

    Type = instrSelected.Type;
    IP   = instrSelected.IP;
    Port = instrSelected.Port;
    Baud = instrSelected.BaudRate;

    try
        switch Type
            case 'Serial';       Socket = Port;
            case 'TCPIP Socket'; Socket = sprintf("%s:%s", IP, Port);
        end

        idx = find(instrHandles.Socket == Socket, 1);

        if ~isempty(idx)            
            instrNew = instrHandles.Handle{idx};
            
        else
            idx = height(instrHandles)+1;

            switch Type
                case 'Serial';       instrNew = serialport(Port, Baud);
                case 'TCPIP Socket'; instrNew = tcpclient(IP, str2double(Port));
            end
        end
        instrHandles(idx,:) = {'gps', '', Socket, {instrNew}, 0};

        output = struct('type', 'handles', 'instrHandles', instrHandles, 'idx', idx);

    catch ME
        if (idx > height(instrHandles)) & exist('instrNew', 'var')
            clear instrNew
        end

        output = struct('type', 'error', 'msg', getReport(ME));
    end
    
end