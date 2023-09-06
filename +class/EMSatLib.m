classdef EMSatLib < handle

    % Author.: Eric Magalhães Delgado & Vinicius Puga
    % Date...: September 05, 2023
    % Version: 1.01

    % !! PENDENTE !!
    % Pendente implementação do controle da ACU GD-123T (Banda Ka)

    properties
        %-----------------------------------------------------------------%
        SwitchCommand
        Switch

        Antenna
        TargetList
        
        LNBCommand        
        LNB
        
        GeneratedDate
    end


    methods
        %-----------------------------------------------------------------%
        function obj = EMSatLib(RootFolder)
            % Antenna switch (Matrix) commands
            switchCommand = table('Size', [32, 3],                                 ...
                                  'VariableTypes', {'double', 'string', 'string'}, ...
                                  'VariableNames', {'Port', 'set', 'get'});
            sTerminator = {'[', '\', ']', '^', '_', '`', 'a', 'b', 'c'};
            for ii = 1:height(switchCommand)
                nPort = num2str(ii);
                if numel(nPort) == 1; nPort = "0" + nPort;
                end
                nTerminator = mod(ii-1, 9);

                switchCommand(ii,:) = {ii, sprintf("{*zs,012,0%s}%.0f", nPort, nTerminator), sprintf("{zBs?012,0%s}%s", nPort, sTerminator{nTerminator+1})};
            end

            % LNB commands
            lnbCommand = {'<0001/LBCHN=1', '>0001/LBCHN=1'; ...
                          '<0001/LBCHN=2', '>0001/LBCHN=2'; ...
                          '<0001/LBCHN=3', '>0001/LBCHN=3'; ...
                          '<0001/LBCHN=4', '>0001/LBCHN=4'};
            lnbCommand = table((1:4)', lnbCommand(:,1), lnbCommand(:,2), 'VariableNames', {'Port', 'set', 'get'});
            
            % Antenna/LNB list
            tempStruct = jsondecode(fileread(fullfile(RootFolder, 'Settings', 'EMSatLib.json')));

            tempStruct.LNB        = struct2table(tempStruct.LNB);
            tempStruct.LNB.Name   = string(tempStruct.LNB.Name);
            tempStruct.LNB.Offset = uint64(tempStruct.LNB.Offset);

            % Object
            obj.SwitchCommand = switchCommand;
            obj.LNBCommand    = lnbCommand;

            obj.Switch        = tempStruct.Switch;
            obj.Antenna       = tempStruct.Antenna;
            obj.LNB           = tempStruct.LNB;
            obj.TargetList    = tempStruct.TargetList;
            obj.GeneratedDate = tempStruct.GeneratedDate;
        end


        %-----------------------------------------------------------------%
        function msgError = AntennaPositionSET(obj, targetPos)
            msgError = '';

            idx1 = find(strcmp({obj.Antenna.Name}, targetPos.Name), 1);
            IP   = obj.Antenna(idx1).ACU.IP;
            Port = obj.Antenna(idx1).ACU.Port;

            try
                hACU = SocketCreation(obj, IP, Port);

                switch obj.Antenna(idx1).ACU.Model
                    %-----------------------------------------------------%
                    case 'GD-7200'
                        switch targetPos.TrackingMode
                            case 'Target'
                                % Syntax: "TT 01 T"
        
                                idx2 = find(strcmp({obj.TargetList(idx1).Target.Name}, targetPos.Target), 1);
                                TargetID = obj.TargetList(idx1).Target(idx2).ID;
        
                                writeline(hACU, sprintf('TT %s T', TargetID));
        
                            case 'LookAngles'
                                % Syntax: "IA AAA.AAA EEE.EEE +-PPP.PPP"
                                % Range:
                                % - Azimuth:         0.00 to 360.00
                                % - Elevation:    -180.00 to 180.00
                                % - Polarization: -180.00 to 180.00
        
                                writeline(hACU, sprintf('IA %.3f %.3f %.3f', wrapTo360(targetPos.Azimuth), wrapTo180(targetPos.Elevation), wrapTo180(targetPos.Polarization)))
                        end

                    %-----------------------------------------------------%
                    case 'GD-123T'
                        % !! PENDENTE !!!
                        error('Pendente implementação do controle da ACU GD-123T.')
                end
                pause(class.Constants.antACUPause)

            catch  ME
                msgError = ME.message;
            end

            if exist('hACU', 'var'); clear hACU
            end
        end


        %-----------------------------------------------------------------%
        function [pos, msgError] = TargetPositionGET(obj, antennaName, targetName)
            pos = [];
            msgError = '';

            idx1 = find(strcmp({obj.Antenna.Name}, antennaName), 1);
            IP   = obj.Antenna(idx1).ACU.IP;
            Port = obj.Antenna(idx1).ACU.Port;

            try
                hACU = SocketCreation(obj, IP, Port);

                switch obj.Antenna(idx1).ACU.Model
                    %-----------------------------------------------------%
                    case 'GD-7200'
                        idx2 = find(strcmp({obj.TargetList(idx1).Target.Name}, targetName), 1);
                        TargetID = obj.TargetList(idx1).Target(idx2).ID;
        
                        writeline(hACU, sprintf('TT %s', TargetID));
                        pause(class.Constants.antACUPause)
        
                        pos = regexp(read(hACU, hACU.NumBytesAvailable, 'char'), '(?<Azimuth>\d{6}) (?<Elevation>\d{6}) (?<Polarization>\d{6})', 'names');
                        if ~isempty(pos)
                            pos = pos(end);
                            
                            pos.Azimuth      = str2double(pos.Azimuth)   / 1000;
                            pos.Elevation    = str2double(pos.Elevation) / 1000;
                            pos.Polarization = wrapTo360(str2double(pos.Polarization) / 1000);
                        end

                    %-----------------------------------------------------%
                    case 'GD-123T'
                        % !! PENDENTE !!!
                        error('Pendente implementação do controle da ACU GD-123T.')
                end

            catch  ME
                msgError = ME.message;
            end

            if exist('hACU', 'var'); clear hACU
            end
        end



        %-----------------------------------------------------------------%
        function [pos, msgError] = AntennaPositionGET(obj, antennaName)
            pos = [];
            msgError = '';

            idx1 = find(strcmp({obj.Antenna.Name}, antennaName), 1);
            IP   = obj.Antenna(idx1).ACU.IP;
            Port = obj.Antenna(idx1).ACU.Port;

            try
                hACU = SocketCreation(obj, IP, Port);

                switch obj.Antenna(idx1).ACU.Model
                    %-----------------------------------------------------%
                    case 'GD-7200'
                        writeline(hACU, '/ CONFIGS ENCODERS CURRENT')
                        pause(class.Constants.antACUPause)
        
                        pos = regexp(read(hACU, hACU.NumBytesAvailable, 'char'), '(?<Azimuth>\d{1,3}.\d{1,3}) (?<Elevation>\d{1,3}.\d{1,3}) (?<Polarization>[-]?\d{1,3}.\d{1,3})', 'names');
                        if ~isempty(pos)
                            pos = pos(end);
                            
                            pos.Azimuth      = str2double(pos.Azimuth);
                            pos.Elevation    = str2double(pos.Elevation);
                            pos.Polarization = wrapTo360(str2double(pos.Polarization));
                        end

                    %-----------------------------------------------------%
                    case 'GD-123T'
                        % !! PENDENTE !!!
                        error('Pendente implementação do controle da ACU GD-123T.')
                end

            catch  ME
                msgError = ME.message;
            end

            if exist('hACU', 'var'); clear hACU
            end
        end


        %-----------------------------------------------------------------%
        function msgError = MatrixSwitch(obj, SwitchPort, LNBChannel, LNDIndex)
            % As of July 4, 2023, the L-Band Matrix is not switching to the
            % ports 19, 28 and 29.
            msgError = '';
            
            % SWITCH
            try
                hSwitch = tcpclient(obj.Switch.IP, obj.Switch.Port);

                for ii = 1:class.Constants.switchTimes
                    writeline(hSwitch, obj.SwitchCommand.set(SwitchPort));

                    pause(class.Constants.switchPause)
                    if strcmp(obj.SwitchCommand.get(SwitchPort), read(hSwitch, hSwitch.NumBytesAvailable, 'char'))
                        break
                    else
                        if ii == class.Constants.switchTimes
                            error('A matrix não aceitou a programação.')
                        end
                    end
                end
            catch ME
                msgError = ME.message;
                return
            end

            % LNB
            if LNBChannel ~= -1
                IP   = obj.Antenna(LNDIndex(1)).LNB(LNDIndex(2)).IP;
                Port = obj.Antenna(LNDIndex(1)).LNB(LNDIndex(2)).Port;

                try
                    hLNB = tcpclient(IP, Port);
                    configureTerminator(hLNB, "CR/LF")
    
                    for ii = 1:class.Constants.switchTimes
                        if contains(writeread(hLNB, obj.LNBCommand.set{LNBChannel}), obj.LNBCommand.get{LNBChannel})
                            break
                        else
                            if ii == class.Constants.switchTimes
                                error('O LNB não aceitou a programação.')
                            end
                        end
                    end
                catch ME
                    msgError = ME.message;
                end
            end
        end


        %-----------------------------------------------------------------%
        function TargetListUpdate(obj, RootFolder)
            PAUSE = 1;

            % Switch
            switchStruct = struct('IP', '192.168.0.116', 'Port', 4000);

            % Antenna config
            LNBTemplate  = struct('Name', {}, 'IP', {}, 'Port', {});

            antStruct(1) = struct('Name', 'MCL-1', 'ACU', struct('Model', 'GD-7200', 'IP', '10.21.205.45',    'Port', 4002), 'LNB', LNBTemplate, 'LOG', '');
            antStruct(2) = struct('Name', 'MCL-2', 'ACU', struct('Model', 'GD-7200', 'IP', '10.21.205.45',    'Port', 4003), 'LNB', LNBTemplate, 'LOG', '');
            antStruct(3) = struct('Name', 'MCL-3', 'ACU', struct('Model', '',        'IP', '',                'Port',   -1), 'LNB', LNBTemplate, 'LOG', '');
            antStruct(4) = struct('Name', 'MCC-1', 'ACU', struct('Model', 'GD-7200', 'IP', '10.21.205.45',    'Port', 4006), 'LNB', LNBTemplate, 'LOG', '');
            antStruct(5) = struct('Name', 'MKU-1', 'ACU', struct('Model', 'GD-7200', 'IP', '10.21.205.45',    'Port', 4004), 'LNB', LNBTemplate, 'LOG', '');
            antStruct(6) = struct('Name', 'MKU-2', 'ACU', struct('Model', 'GD-7200', 'IP', '10.21.205.45',    'Port', 4005), 'LNB', LNBTemplate, 'LOG', '');
            antStruct(7) = struct('Name', 'MKA-1', 'ACU', struct('Model', 'GD-123T', 'IP', '192.168.241.102', 'Port', 4660), 'LNB', LNBTemplate, 'LOG', '');

            antStruct(7).LNB(1) = struct('Name', {{'MKA-1 LO_R', 'MKA-1 MID_R', 'MKA-1 MID_HI_R', 'MKA-1 HI_R'}}, 'IP', '192.168.241.102', 'Port', 4662, 'DeviceAddress', '0001');
            antStruct(7).LNB(2) = struct('Name', {{'MKA-1 LO_L', 'MKA-1 MID_L', 'MKA-1 MID_HI_L', 'MKA-1 HI_L'}}, 'IP', '192.168.241.102', 'Port', 4663, 'DeviceAddress', '0001');

            % Target list
            tgtStruct(1) = struct('Name', 'MCL-1', 'Target', []);
            tgtStruct(2) = struct('Name', 'MCL-2', 'Target', []);
            tgtStruct(3) = struct('Name', 'MCL-3', 'Target', []);
            tgtStruct(4) = struct('Name', 'MCC-1', 'Target', []);
            tgtStruct(5) = struct('Name', 'MKU-1', 'Target', []);
            tgtStruct(6) = struct('Name', 'MKU-2', 'Target', []);
            tgtStruct(7) = struct('Name', 'MKA-1', 'Target', []);

            for ii = 1:numel(antStruct)
                IP   = antStruct(ii).ACU.IP;
                Port = antStruct(ii).ACU.Port;

                if isempty(IP)
                    continue
                end

                try
                    hACU = SocketCreation(obj, IP, Port);

                    switch antStruct(ii).ACU.Model
                        %-------------------------------------------------%
                        case 'GD-7200'
                            writeline(hACU, '/ CONFIGS SITE ANTENNA')
                            pause(PAUSE)
        
                            if ~contains(read(hACU, hACU.NumBytesAvailable, 'char'), antStruct(ii).Name)
                                error('Não se trata da antena correta...')
                            end
        
                            writeline(hACU, '/ TRACKING TRACK LS')
                            pause(PAUSE)
                            
                            tgtList = regexp(read(hACU, hACU.NumBytesAvailable, 'char'), '\d{1,2} X T(?<ID>\d{2}) "(?<Name>.*)"', 'names', 'dotexceptnewline');

                        %-------------------------------------------------%
                        case 'GD-123T'
                            % PENDENTE !!!

                            tgtList = [];
                    end

                    if ~isempty(tgtList)
                        tgtList(deblank({tgtList.Name}) == "") = [];
                        
                        tgtStruct(ii).Target = struct('ID', {}, 'Name', {}, 'Azimuth', {}, 'Elevation', {}, 'Polarization', {});
                        for jj = 1:numel(tgtList)
                            writeline(hACU, sprintf('TT %s', tgtList(jj).ID))
                            pause(PAUSE)

                            tgtInfo = regexp(read(hACU, hACU.NumBytesAvailable, 'char'), '\d{2} \d{2} \d{4} (?<Azimuth>\d{6}) (?<Elevation>\d{6}) (?<Polarization>\d{6})', 'names');
                            if ~isempty(tgtInfo)
                                tgtInfo = tgtInfo(end);
                                
                                tgtInfo.Azimuth      = str2double(tgtInfo.Azimuth)   / 1000;
                                tgtInfo.Elevation    = str2double(tgtInfo.Elevation) / 1000;
                                tgtInfo.Polarization = wrapTo360(str2double(tgtInfo.Polarization) / 1000);
                                
                                tgtStruct(ii).Target(end+1) = struct('ID',           tgtList(jj).ID,    ...
                                                                     'Name',         tgtList(jj).Name,  ...
                                                                     'Azimuth',      tgtInfo.Azimuth,   ...
                                                                     'Elevation',    tgtInfo.Elevation, ...
                                                                     'Polarization', tgtInfo.Polarization);
                            end
                        end
                    end
                    clear hACU

                catch ME
                    antStruct(ii).LOG{end+1} = ME.message;

                    if exist('hACU', 'var'); clear hACU
                    end
                end                
            end

            % LNB
            lnbTable         = table('Size', [24, 5] ,                                                           ...
                                     'VariableNames', {'Name', 'Offset', 'Inverted', 'SwitchPort', 'LNBChannel'}, ...
                                     'VariableTypes', {'string', 'uint64', 'double', 'double', 'double'});
            lnbTable(1:24,:) = {'MCL-1 V',         5150000050, 1,  1, -1; ...
                                'MCL-1 H',         5150000050, 1,  2, -1; ...
                                'MCL-2 V',         5150000050, 1,  3, -1; ...
                                'MCL-2 H',         5150000050, 1,  4, -1; ...
                                'MCC-1 L',         5150000050, 1,  5, -1; ...
                                'MCC-1 R',         5150000050, 1,  6, -1; ...
                                'MCL-3 V',         5760000050, 1,  7, -1; ...
                                'MCL-3 H',         5760000050, 1,  8, -1; ...
                                'MKU-1 LO_V',      9750000000, 0,  9, -1; ...
                                'MKU-1 HI_V',     10750000000, 0, 10, -1; ...
                                'MKU-1 LO_H',      9750000000, 0, 11, -1; ...
                                'MKU-1 HI_H',     10750000000, 0, 12, -1; ...
                                'MKU-2 LO_V',      9750000000, 0, 13, -1; ...
                                'MKU-2 HI_V',     10750000000, 0, 14, -1; ...
                                'MKU-2 LO_H',      9750000000, 0, 15, -1; ...
                                'MKU-2 HI_H',     10750000000, 0, 16, -1; ...
                                'MKA-1 LO_R',     16200000000, 0, 23,  1; ...
                                'MKA-1 MID_R',    17200000000, 0, 23,  2; ...
                                'MKA-1 MID_HI_R', 18200000000, 0, 23,  3; ...
                                'MKA-1 HI_R',     19200000000, 0, 23,  4; ...
                                'MKA-1 LO_L',     16200000000, 0, 24,  1; ...
                                'MKA-1 MID_L',    17200000000, 0, 24,  2; ...
                                'MKA-1 MID_HI_L', 18200000000, 0, 24,  3; ...
                                'MKA-1 HI_L',     19200000000, 0, 24,  4};

            % JSON file
            writematrix(jsonencode(struct('Switch', switchStruct, 'Antenna', antStruct, 'LNB', lnbTable, 'TargetList', tgtStruct, 'GeneratedDate', datestr(now, 'dd/mm/yyyy HH:MM:SS')), 'PrettyPrint', true), fullfile(RootFolder, 'Settings', 'EMSatLib.json'), "FileType", "text", "QuoteStrings", "none")
        end


        %-----------------------------------------------------------------%
        function [propTable, propSummary] = TargetProperties(obj)

            % Em 21/07/2023 executei essa função, identificando os seguintes
            % limites:
            % (a) Azimuth:     0.118 a 356.300 graus (limites em auxApp.winAddTask: 0 a 360 graus)
            % (b) Elevation:  15.397 a  63.306 graus (limites em auxApp.winAddTask: 0 a  90 graus)
            % (c) Polarização: 0.200 a 355.700 graus (limites em auxApp.winAddTask: 0 a 360 graus)

            propTable = table('Size', [0,5], ...
                                    'VariableTypes', {'cell', 'cell', 'double', 'double', 'double'}, ...
                                    'VariableNames', {'antenna', 'target', 'azimuth', 'elevation', 'polarization'});
            
            for ii = 1:numel(obj.TargetList)
                for jj = 1:numel(obj.TargetList(ii).Target)
                    propTable(end+1,:) = {obj.TargetList(ii).Name,                 ...
                                          obj.TargetList(ii).Target(jj).Name,      ...
                                          obj.TargetList(ii).Target(jj).Azimuth,   ...
                                          obj.TargetList(ii).Target(jj).Elevation, ...
                                          obj.TargetList(ii).Target(jj).Polarization};
                end
            end
            propSummary = summary(propTable);
        end
    end


    methods (Access = protected)
        %-----------------------------------------------------------------%
        function hACU = SocketCreation(obj, IP, Port)
            hACU = tcpclient(IP, Port);
            configureTerminator(hACU, "CR/LF")

            pause(class.Constants.antACUPause)
            if hACU.NumBytesAvailable
                clear hACU
                error('A ACU deve estar sendo controlada pelo Compass, o que impede o apontamento da antena e giro do LNB de forma automática.')
            end
        end
    end
end
        