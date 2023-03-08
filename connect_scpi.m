function scpiNode = connect_scpi(instrSelected, instrInfo, Band)

    arguments
        instrSelected struct
        instrInfo     table
        Band          struct = []
    end

    Type = instrSelected.Type;
    IP   = instrSelected.IP;
    Port = instrSelected.Port;

    if isfield(instrSelected, 'Timeout');     Timeout = instrSelected.Timeout;
    else;                                     Timeout = 10;
    end

    if isfield(instrSelected, 'ConnectType'); ConnectType = instrSelected.ConnectType;
    else;                                     ConnectType = 'ConnectivityTest';
    end

    if isfield(instrSelected, 'ResetCmd');    ResetCmd = instrSelected.ResetCmd;
    else;                                     ResetCmd = 'Off';
    end

    if isfield(instrSelected, 'SyncType');    SyncType = instrSelected.SyncType;
    else;                                     SyncType = 'Single Sweep';
    end

    switch Type
        case {'TCPIP Socket', 'TCP/UDP IP Socket'}
            scpiNode = tcpip(IP, Port);
        case 'TCPIP Visa'
            scpiNode = visa("ni", "TCPIP::" + string(IP) + "::INSTR");
    end

    set(scpiNode, 'Timeout', Timeout, 'InputBufferSize', 10*1e+6, 'ByteOrder', 'littleEndian');
    fopen(scpiNode);

    scpiNode.UserData = struct('IDN', replace(deblank(query(scpiNode, '*IDN?')), '"', ''));
    
    if ConnectType == "Task"
        Localhost_localIP  = '';
        Localhost_publicIP = '';

        if isfield(instrSelected, 'Localhost_localIP');  Localhost_localIP  = instrSelected.Localhost_localIP;
        end

        if isfield(instrSelected, 'Localhost_publicIP'); Localhost_publicIP = instrSelected.Localhost_publicIP;
        end
        
        idx = find(strcmp(instrInfo.Name, instrSelected.Name), 1);
        if ResetCmd == "On"
            fprintf(scpiNode, instrInfo.scpiReset{idx});
            pause(instrInfo.ResetPause{idx})
        end
        
        fprintf(scpiNode, instrInfo.StartUp{idx});
        
        switch SyncType
            case 'Single Sweep'
                fprintf(scpiNode, 'INITiate:CONTinuous OFF');
            
            case 'Continuous Sweep'
                fprintf(scpiNode, 'INITiate:CONTinuous ON');
        end
    
        if     ~isempty(Localhost_publicIP); scpiNode.UserData.ClientIP      = Localhost_publicIP;
        elseif ~isempty(Localhost_localIP);  scpiNode.UserData.ClientIP      = Localhost_localIP;
        elseif ~strcmp(IP, '127.0.0.1');     [~, scpiNode.UserData.ClientIP] = connect_IPsFind(IP);
        end

        scpiNode.UserData.SpecInfo = table2struct(Task_MetaDataRead(scpiNode, instrInfo(idx,:), Band));
    end

end