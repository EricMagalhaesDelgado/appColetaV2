classdef EB500Lib < handle

    % Author.: Eric Magalhães Delgado & Michel Cerqueira Kulhavy
    % Date...: September 15, 2023
    % Version: 1.02

    properties
        SelectivityMap
        Firmware
        udpPort
        nDatagrams
    end


    methods
        %-----------------------------------------------------------------%
        function obj = EB500Lib(RootFolder)
            % Selectivity x Resolution Mapping
            SelectivityMap = table('Size', [12, 3],                                 ...
                                   'VariableTypes', {'double', 'double', 'double'}, ...
                                   'VariableNames', {'Normal', 'Narrow', 'Sharp'},  ...
                                   'RowNames', {'2.500 kHz', '5.000 kHz', '10.000 kHz', '12.500 kHz', '20.000 kHz', '25.000 kHz', '50.000 kHz', '100.000 kHz', '200.000 kHz', '500.000 kHz', '1000.000 kHz', '2000.000 kHz'});

            SelectivityMap(1:12,:) = {   6000    3000    1500; ...
                                        12000    6000    3000; ...
                                        24000   12000    6000; ...
                                        30000   15000    7500; ...
                                        48000   24000   12000; ...
                                        60000   30000   15000; ...
                                       120000   60000   30000; ...
                                       240000  120000   60000; ...
                                       480000  240000  120000; ...
                                      1200000  600000  300000; ...
                                      2400000 1200000  600000; ...
                                      4800000 2400000 1200000};

            obj.SelectivityMap = SelectivityMap;

            % Firmware version, udpPort & nDatagrams
            tempStruct = jsondecode(fileread(fullfile(RootFolder, 'Settings', 'EB500Lib.json')));

            obj.Firmware   = tempStruct.Firmware;
            obj.udpPort    = tempStruct.udpPort;
            obj.nDatagrams = tempStruct.nDatagrams;
        end
    end


    methods(Static = true)
        %-----------------------------------------------------------------%
        function specObj = DatagramRead_PreTask(EB500Obj, specObj, hReceiver, hStreaming)
            Timeout  = class.Constants.Timeout;
            udpPort  = hStreaming.LocalPort;
            taskType = specObj.Task.Type;

            for ii = 1:numel(specObj.Band)
                specDatagram = [];
                
                writeline(hReceiver, specObj.Band(ii).SpecificSCPI.configSET);

                flush(hStreaming)
                class.EB500Lib.DatagramRead_OnOff(taskType, 'Open', udpPort, hReceiver)

                udpTic = tic;
                t = toc(udpTic);
                while t < Timeout
                    specDatagram = [specDatagram, read(hStreaming, hStreaming.NumDatagramsAvailable)];

                    if numel(specDatagram) > EB500Obj.nDatagrams                        
                        break
                    end
                    t = toc(udpTic);
                end
                class.EB500Lib.DatagramRead_OnOff(taskType, 'Close', udpPort, hReceiver)

                if isempty(specDatagram)
                    error(['ERROR - Não identificada a estimativa do número de datagramas que representam um único traço do fluxo %d.\n' ...
                           'Possíveis causas:\n'                                                                     ...
                           '(a) Perda de conectividade com o EB500.\n'                                               ...
                           '(b) <i>Firewall</i> bloqueando fluxo UDP gerado pelo EB500.\n'                           ...
                           '(c) Não redirecionamento de porta do roteador (no caso de não ser uma conexão direta ao EB500).'], ii)
                end

                % Delete datagrams sent by an unexpected source
                idx0 = ([specDatagram.SenderAddress] ~= hReceiver.Address);
                if any(idx0)
                    specDatagram(idx0) = [];
                end

                if contains(taskType, 'Drive-test (Level+Azimuth)')
                    kData = 3;
                else
                    kData = 1;
                end

                nDatagrams  = 0;
                nTerminator = 0;
                for jj = 1:numel(specDatagram)
                    specDatagram(jj).Data = uint8(specDatagram(jj).Data);

                    MagicNumber = typecast(specDatagram(jj).Data( 4:-1: 1), 'uint32');
                    DataSize    = typecast(specDatagram(jj).Data(16:-1:13), 'uint32');

                    FreqStart   = double(typecast(specDatagram(jj).Data(32:-1:29), 'uint32')) + double(typecast(specDatagram(jj).Data(44:-1:41), 'uint32')) * 2^32;
                    FreqStop    = double(typecast(specDatagram(jj).Data(36:-1:33), 'uint32')) + double(typecast(specDatagram(jj).Data(48:-1:45), 'uint32')) * 2^32;
                    DataPoints  = (FreqStop - FreqStart)/double(typecast(specDatagram(jj).Data(40:-1:37), 'uint32')) + 1;

                    if (MagicNumber == 963072)                                     && ...
                            (DataSize   == numel(specDatagram(jj).Data))           && ...
                            (FreqStart  == specObj.Task.Script.Band(ii).FreqStart) && ...
                            (FreqStop   == specObj.Task.Script.Band(ii).FreqStop)  && ...
                            (DataPoints == kData * specObj.Band(ii).DataPoints)
                        nDatagrams = nDatagrams + 1;
                        if typecast(specDatagram(jj).Data(end:-1:end-1), 'uint16') == 2000
                            nTerminator = nTerminator + 1;
                        end
                    end
                end
                
                if nTerminator
                    specObj.Band(ii).Datagrams = round(nDatagrams/nTerminator);
                else
                    error(['ERROR - Não identificada a estimativa do número de datagramas que representam um único traço do fluxo %d.\n' ...
                           'Possíveis causas:\n'                                                                     ...
                           '(a) Perda de conectividade com o EB500.\n'                                               ...
                           '(b) <i>Firewall</i> bloqueando fluxo UDP gerado pelo EB500.\n'                           ...
                           '(c) Não redirecionamento de porta do roteador (no caso de não ser uma conexão direta ao EB500).'], ii)
                end
            end
        end


        %-----------------------------------------------------------------%
        function [newArray, Flag_success] = DatagramRead_Task(taskInfo, hReceiver, hStreaming)            
            Timeout = class.Constants.Timeout;
            udpPort = hStreaming.LocalPort;

            if contains(taskInfo.Type, 'Drive-test (Level+Azimuth)')
                kData = 3;
            else
                kData = 1;
            end

            newArray     = zeros(1, taskInfo.DataPoints, kData, 'single');
            Flag_success = false;
            specDatagram = [];

            flush(hStreaming)
            class.EB500Lib.DatagramRead_OnOff(taskInfo.Type, 'Open', udpPort, hReceiver)
            
            udpTic = tic;
            t = toc(udpTic);
            while t < Timeout
                specDatagram = [specDatagram, read(hStreaming, 2*taskInfo.nDatagrams-1)];

                if ~isempty(specDatagram)
                    % Delete datagrams sent by an unexpected source
                    idx0 = ([specDatagram.SenderAddress] ~= hReceiver.Address);
                    if any(idx0)
                        specDatagram(idx0) = [];
                    end
        
                    % Sort datagrams
                    DatagramsID = zeros(numel(specDatagram), 1);        
                    for ii = 1:numel(specDatagram)
                        specDatagram(ii).Data = uint8(specDatagram(ii).Data);
        
                        DatagramID_low  = double(typecast(specDatagram(ii).Data(10:-1: 9), 'uint16'));
                        DatagramID_high = double(typecast(specDatagram(ii).Data(12:-1:11), 'uint16')).*2^16;
                        DatagramsID(ii) = DatagramID_low + DatagramID_high;
                    end
        
                    if ~issorted(DatagramsID)
                        [DatagramsID, idxSort] = sort(DatagramsID);
                        specDatagram = specDatagram(idxSort);
                    end
        
                    % Array
                    udpFlag  = 0;
                    Points   = 0;
        
                    for jj = 1:numel(specDatagram)
                        if udpFlag && (DatagramsID(jj) ~= DatagramsID(jj-1)+1)
                            udpFlag  = 0;
                            Points   = 0;
                            continue
                        end
        
                        MagicNumber = typecast(specDatagram(jj).Data( 4:-1: 1), 'uint32');
                        DataSize    = typecast(specDatagram(jj).Data(16:-1:13), 'uint32');

                        if contains(taskInfo.Type, 'Drive-test (Level+Azimuth)')
                            FreqCenter = double(typecast(specDatagram(ii).Data(32:-1:29), 'uint32')) + double(typecast(specDatagram(ii).Data(36:-1:33), 'uint32')) * 2^32;
                            FreqSpan   = double(typecast(specDatagram(ii).Data(40:-1:37), 'uint32'));
                                                            
                            FreqStart  = FreqCenter - FreqSpan/2;
                            FreqStop   = FreqCenter + FreqSpan/2;
                            DataPoints = typecast(specDatagram(ii).Data(22:-1:21), 'uint16');

                        else
                            FreqStart  = double(typecast(specDatagram(jj).Data(32:-1:29), 'uint32')) + double(typecast(specDatagram(jj).Data(44:-1:41), 'uint32')) * 2^32;
                            FreqStop   = double(typecast(specDatagram(jj).Data(36:-1:33), 'uint32')) + double(typecast(specDatagram(jj).Data(48:-1:45), 'uint32')) * 2^32;
                            DataPoints = (FreqStop - FreqStart)/double(typecast(specDatagram(jj).Data(40:-1:37), 'uint32')) + 1;
                        end
        
                        if (MagicNumber == 963072)                           && ...
                                (DataSize   == numel(specDatagram(jj).Data)) && ...
                                (FreqStart  == taskInfo.FreqStart)           && ...
                                (FreqStop   == taskInfo.FreqStop)            && ...
                                (DataPoints == taskInfo.DataPoints)
                            idx1   = Points + 1;
                            Points = Points + typecast(specDatagram(jj).Data(22:-1:21), 'uint16');
                            idx2   = Points;
        
                            if typecast(specDatagram(jj).Data(end:-1:end-1), 'uint16') == 2000
                                if Points == DataPoints+1
                                    newArray(idx1:idx2-1) = single(flip(typecast(specDatagram(jj).Data((end-2):-1:81), 'int16')))./10;
                                    Flag_success = true;
                                    break
                                else
                                    udpFlag = 0;
                                    Points  = 0;
                                end
                            else
                                udpFlag = 1;
                                newArray(idx1:idx2) = single(flip(typecast(specDatagram(jj).Data(end:-1:81), 'int16')))./10;                                    
                            end
                        end
                    end
        
                    if Flag_success
                        break
                    end
                end
                t = toc(udpTic);
            end

            class.EB500Lib.DatagramRead_OnOff(taskInfo.Type, 'Close', udpPort, hReceiver)
        end


        %-----------------------------------------------------------------%
        function [newArray, Flag_success] = DatagramRead_AzimuthTask(taskInfo, hReceiver, hStreaming)            
            Timeout = class.Constants.Timeout;
            udpPort = hStreaming.LocalPort;

            newArray     = zeros(1, taskInfo.DataPoints, 3, 'single');
            Flag_success = false;
            specDatagram = [];

            flush(hStreaming)
            class.EB500Lib.DatagramRead_OnOff(taskInfo.Type, 'Open', udpPort, hReceiver)
            
            udpTic = tic;
            t = toc(udpTic);
            while t < Timeout
                specDatagram = [specDatagram, read(hStreaming)];

                if ~isempty(specDatagram)
                    % Delete datagrams sent by an unexpected source
                    idx0 = ([specDatagram.SenderAddress] ~= hReceiver.Address);
                    if any(idx0)
                        specDatagram(idx0) = [];
                    end
        
                    % Array        
                    for ii = 1:numel(specDatagram)
                        specDatagram(ii).Data = uint8(specDatagram(ii).Data);
        
                        MagicNumber = typecast(specDatagram(ii).Data( 4:-1: 1), 'uint32');
                        DataSize    = typecast(specDatagram(ii).Data(16:-1:13), 'uint32');

                        DataPoints  = typecast(specDatagram(ii).Data(22:-1:21), 'uint16');
                        FreqCenter  = double(typecast(specDatagram(ii).Data(32:-1:29), 'uint32')) + double(typecast(specDatagram(ii).Data(36:-1:33), 'uint32')) * 2^32;
                        FreqSpan    = double(typecast(specDatagram(ii).Data(40:-1:37), 'uint32'));

                        if (MagicNumber == 963072)                           && ...
                                (DataSize   == numel(specDatagram(ii).Data)) && ...
                                (FreqCenter == taskInfo.FreqCenter)          && ...
                                (FreqSpan   == taskInfo.FreqSpan)            && ...
                                (DataPoints == taskInfo.DataPoints)

                            % Limites "Level"
                            idx11 = 143;
                            idx12 = idx11 + DataPoints*2 - 1;
                        
                            % Limites "Azimuth"
                            idx21 = idx12 + 1;
                            idx22 = idx21 + DataPoints*2 - 1;
                        
                            % Limites "AzimuthQuality"
                            idx31 = idx22 + 1;
                            idx32 = idx31 + DataPoints*2 - 1;
                        
                            newArray(1,:,1) = single(flip(typecast(specDatagram(ii).Data(idx12:-1:idx11), 'int16'))) ./ 10;
                            newArray(1,:,2) = single(flip(typecast(specDatagram(ii).Data(idx22:-1:idx21), 'int16'))) ./ 10;
                            newArray(1,:,3) = single(flip(typecast(specDatagram(ii).Data(idx32:-1:idx31), 'int16'))) ./ 10;

                            Flag_success = true;
                            break
                        end
                    end
        
                    if Flag_success
                        break
                    end
                end
                t = toc(udpTic);
            end

            class.EB500Lib.DatagramRead_OnOff(taskInfo.Type, 'Close', udpPort, hReceiver)
        end


        %-----------------------------------------------------------------%
        function DatagramRead_OnOff(taskType, operationType, udpPort, hReceiver)
            if contains(taskType, 'Drive-test (Level+Azimuth)')
                switch operationType
                    case 'Open'
                        writeline(hReceiver, sprintf('TRACE:UDP:TAG:ON "%s", %.0f, DFPan',                                     hReceiver.UserData.ClientIP, udpPort))
                        writeline(hReceiver, sprintf('TRACE:UDP:FLAG:ON "%s", %.0f, "DFLevel", "AZImuth", "DFQuality", "OPT"', hReceiver.UserData.ClientIP, udpPort))
    
                    case 'Close'
                        writeline(hReceiver, sprintf('TRACE:UDP:TAG:OFF "%s", %.0f, DFPan',                                     hReceiver.UserData.ClientIP, udpPort))
                        writeline(hReceiver, sprintf('TRACE:UDP:FLAG:OFF "%s", %.0f, "DFLevel", "AZImuth", "DFQuality", "OPT"', hReceiver.UserData.ClientIP, udpPort))                            
                        writeline(hReceiver, sprintf('TRACE:UDP:DEL "%s", %.0f',                                                hReceiver.UserData.ClientIP, udpPort))
                end

            else
                switch operationType
                    case 'Open'
                        writeline(hReceiver, sprintf('TRACE:UDP:TAG:ON "%s", %.0f, PSCAN',                                      hReceiver.UserData.ClientIP, udpPort))
                        writeline(hReceiver, sprintf('TRACE:UDP:FLAG:ON "%s", %.0f, "VOLTage:AC", "OPT"',                       hReceiver.UserData.ClientIP, udpPort))
    
                    case 'Close'
                        writeline(hReceiver, sprintf('TRACE:UDP:TAG:OFF "%s", %.0f, PSCAN',                                     hReceiver.UserData.ClientIP, udpPort))
                        writeline(hReceiver, sprintf('TRACE:UDP:FLAG:OFF "%s", %.0f, "VOLTage:AC", "OPT"',                      hReceiver.UserData.ClientIP, udpPort))
                        writeline(hReceiver, sprintf('TRACE:UDP:DEL "%s", %.0f',                                                hReceiver.UserData.ClientIP, udpPort))
                end
            end
        end
    end
end