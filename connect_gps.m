function gpsInstrument = connect_gps(instrSelected)

    arguments
        instrSelected struct
    end

    Type = instrSelected.Type;
    Port = instrSelected.Port;

    if isfield(instrSelected, 'Timeout'); Timeout = instrSelected.Timeout;
    else;                                 Timeout = 10;
    end

    switch Type
        case 'Serial'
            BaudRate = instrSelected.BaudRate;
            gpsInstrument = serialport(Port, BaudRate, "Timeout", Timeout);

        case 'TCPIP Socket'
            IP = instrSelected.IP;
            gpsInstrument = tcpclient(IP, str2double(Port), 'Timeout', Timeout);
    end

    gpsInstrument.UserData = Task_gpsReader(gpsInstrument, Timeout);
    
end