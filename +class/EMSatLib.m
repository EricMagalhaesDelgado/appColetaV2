classdef EMSatLib < handle

    % Author.: Eric Magalhães Delgado & Vinicius Puga
    % Date...: September 07, 2023
    % Version: 1.01

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
                        switch targetPos.TrackingMode
                            case 'Target'
                                % Syntax: "POS 1,0" | "POS 2,0" | ... | "POS 50,0"
        
                                idx2 = find(strcmp({obj.TargetList(idx1).Target.Name}, targetPos.Target), 1);
                                TargetID = obj.TargetList(idx1).Target(idx2).ID;
        
                                writeline(hACU, sprintf('POS %s,0', TargetID));
        
                            case 'LookAngles'
                                % Syntax: "TRACK 0,AAA.AAA,EEE.EEE,0.000"
                                % Range:
                                % - Azimuth:         0.00 to 360.00
                                % - Elevation:    -180.00 to 180.00
        
                                writeline(hACU, sprintf('TRACK 0,%.3f,%.3f,0.000', wrapTo360(targetPos.Azimuth), wrapTo180(targetPos.Elevation)))
                        end
                end

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

                idx2 = find(strcmp({obj.TargetList(idx1).Target.Name}, targetName), 1);
                TargetID = obj.TargetList(idx1).Target(idx2).ID;

                regExp = RegularExpression(obj, 'TargetPosition', obj.Antenna(idx1).ACU.Model);

                switch obj.Antenna(idx1).ACU.Model
                    case 'GD-7200'
                        pos = WriteRead(obj, hACU, sprintf('TT %s', TargetID));
                        div = 1000;

                    case 'GD-123T'
                        pos = writeread(hACU, sprintf('SAT? %s', TargetID));
                        div = 1;
                end

                pos = regexp(pos, regExp, 'names');
                if ~isempty(pos)
                    pos = PositionParser(obj, pos, div);
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
                    case 'GD-7200'
                        pos = WriteRead(obj, hACU, '/ CONFIGS ENCODERS CURRENT');

                    case 'GD-123T'
                        pos = writeread(hACU, 'STAT');
                end

                pos = regexp(pos, RegularExpression(obj, 'AntennaPosition', obj.Antenna(idx1).ACU.Model), 'names');
                if ~isempty(pos)
                    pos = PositionParser(obj, pos, 1);
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
                    % Essencial a substituição do WRITEREAD pelo conjunto
                    % WRITELINE + PAUSE + READ.

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
        function TargetListUpdate(obj, FullFileName)

            % Antenna config
            antStruct    = obj.Antenna;

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

                tgtStruct(ii).Target = struct('ID', {}, 'Name', {}, 'Azimuth', {}, 'Elevation', {}, 'Polarization', {});

                try
                    hACU = SocketCreation(obj, IP, Port);

                    regExp = RegularExpression(obj, 'TargetPosition', antStruct(ii).ACU.Model);

                    switch antStruct(ii).ACU.Model
                        case 'GD-7200'
                            % O WRITEREAD funciona aqui, mas é perigoso porque 
                            % a resposta da ACU possui um caractere "<" após 
                            % a quebra de linha. Consequentemente, esse caractere
                            % fica no buffer, podendo causar uma leitura equivocada 
                            % à frente, numa outra comunicação. Recomendável
                            % usar o WRITELINE seguido e um READ. O PAUSE é 
                            % essencial!

                            antennaName = WriteRead(obj, hACU, '/ CONFIGS SITE ANTENNA');
                            if ~contains(antennaName, antStruct(ii).Name)
                                error('Não se trata da antena correta...')
                            end

                            % O WRITEREAD não funciona aqui porque a resposta 
                            % da ACU possui diversas quebras de linha. Dessa forma, 
                            % o WRITEREAD, por ser uma concatenação dos métodos 
                            % WRITELINE e READLINE, não funciona...
                            % Deve-se usar um WRITELINE seguido de um PAUSE 
                            % e um READ (e não READLINE!). O PAUSE é essencial 
                            % pois a ACU demora alguns milisegundos para apresentar 
                            % a sua resposta completamente (cerca de 800 bytes).

                            tgtList = WriteRead(obj, hACU, '/ TRACKING TRACK LS');
                            tgtList = regexp(tgtList, '\d{1,2} X T(?<ID>\d{2}) "(?<Name>.*)"', 'names', 'dotexceptnewline');
                            if ~isempty(tgtList)
                                tgtList(deblank({tgtList.Name}) == "") = [];
                                
                                for jj = 1:numel(tgtList)
                                    % Novamente...
                                    % O WRITEREAD funciona aqui, mas é perigoso porque 
                                    % a resposta da ACU possui um caractere "<" após 
                                    % a quebra de linha. O PAUSE aqui também é essencial.

                                    tgtInfo = WriteRead(obj, hACU, sprintf('TT %s', tgtList(jj).ID));
                                    tgtInfo = regexp(tgtInfo, regExp, 'names');
                                    if ~isempty(tgtInfo)
                                        tgtInfo.ID   = tgtList(jj).ID;
                                        tgtInfo.Name = tgtList(jj).Name;

                                        tgtStruct(ii).Target(end+1) = PositionParser(obj, tgtInfo, 1000);
                                    end
                                end
                            end

                        case 'GD-123T'
                            for jj = 1:50
                                % Diferente do outro modelo de ACU (GD-7200), 
                                % a GD-123T apresenta respostas sem caracteres
                                % adicionais à quebra de linha. É possível,
                                % portanto, uso do WRITEREAD.

                                tgtName = replace(writeread(hACU, sprintf('SATDB? %d', jj)), '"', '');
                                if ismember(tgtName, {'', 'N BADD'})
                                    continue
                                end

                                tgtInfo = regexp(writeread(hACU, sprintf('SAT? %d', jj)), regExp, 'names');
                                if ~isempty(tgtInfo)
                                    tgtInfo.ID   = num2str(jj);
                                    tgtInfo.Name = tgtName;

                                    tgtStruct(ii).Target(end+1) = PositionParser(obj, tgtInfo, 1);
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

            % JSON file
            writematrix(jsonencode(struct('Switch',        obj.Switch, ...
                                          'Antenna',       antStruct,  ...
                                          'LNB',           obj.LNB,    ...
                                          'TargetList',    tgtStruct,  ...
                                          'GeneratedDate', datestr(now, 'dd/mm/yyyy HH:MM:SS')), 'PrettyPrint', true), FullFileName, "FileType", "text", "QuoteStrings", "none")
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


        %-----------------------------------------------------------------%
        function receivedMessage = WriteRead(obj, hACU, requiredInfo)
            writeline(hACU, requiredInfo);
            pause(class.Constants.antACUPause)

            receivedMessage = read(hACU, hACU.NumBytesAvailable, 'char');
        end


        %-----------------------------------------------------------------%
        function regExp = RegularExpression(obj, srcFcn, ACUModel)

            switch srcFcn
                case 'TargetPosition'
                    switch ACUModel
                        case 'GD-7200'; regExp = '(?<Azimuth>\d{6}) (?<Elevation>\d{6}) (?<Polarization>\d{6})';
                        case 'GD-123T'; regExp = '(?<Azimuth>\d{1,3}[.]\d{1,3}),(?<Elevation>\d{1,3}[.]\d{1,3}),[-]?\d{1,3}[.]\d{1,3}';
                    end

                case 'AntennaPosition'
                    switch ACUModel
                        case 'GD-7200'; regExp = '(?<Azimuth>\d{1,3}[.]\d{1,3}) (?<Elevation>\d{1,3}[.]\d{1,3}) (?<Polarization>[-]?\d{1,3}[.]\d{1,3})';
                        case 'GD-123T'; regExp = '(?<Azimuth>\d{1,3}[.]\d+),(?<Elevation>\d{1,3}[.]\d+),\d+[.]\d+,\d+[.]?\d*,[-]?\d+.\d+';
                    end
            end
        end


        %-----------------------------------------------------------------%
        function tgtPos = PositionParser(obj, tgtPos, Divisor)

            % O tgtPos é uma estrutura gerada pela avaliação da expressão
            % regular, já possuindo os campos "Azimuth", "Elevation" e
            % "Polarization" (restrito à ACU GD-7200).

            tgtPos = tgtPos(end);

            tgtPos.Azimuth   = str2double(tgtPos.Azimuth)/Divisor;
            tgtPos.Elevation = str2double(tgtPos.Elevation)/Divisor;

            if isfield(tgtPos, 'Polarization')
                tgtPos.Polarization = wrapTo360(str2double(tgtPos.Polarization)/Divisor);
            else
                tgtPos.Polarization = 0;
            end
        end
    end
end
        