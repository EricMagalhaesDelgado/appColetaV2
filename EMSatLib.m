% EMSatLib.m
% Author(s): Eric Magalhães Delgado & Vinicius Puga
% Date: April 10th, 2023

classdef EMSatLib

    properties
       Switch
       Antenna
       LNB
    end

    methods
        function obj = EMSatLib()
            global appGeneral

            % Antenna switch (Matrix)
            Switch = table('Size', [32, 3], ...
                           'VariableTypes', {'double', 'string', 'string'}, ...
                           'VariableNames', {'Port', 'set', 'get'});
            sTerminator = {'[', '\', ']', '^', '_', '`', 'a', 'b', 'c'};
            for ii = 1:height(Switch)
                nPort = num2str(ii);
                if numel(nPort) == 1; nPort = "0" + nPort;
                end
                nTerminator = mod(ii-1, 9);

                Switch(ii,:) = {ii, sprintf("{*zs,012,0%s}%.0f", nPort, nTerminator), sprintf("{zBs?012,0%s}%s", nPort, sTerminator{nTerminator+1})};
            end
            
            % Antenna/LNB list
            tempStruct = jsondecode(fileread(fullfile(appGeneral.RootFolder, 'Settings', 'EMSatLib.json')));

            tempStruct.LNB        = struct2table(tempStruct.LNB);
            tempStruct.LNB.Name   = string(tempStruct.LNB.Name);
            tempStruct.LNB.Offset = uint64(tempStruct.LNB.Offset);

            % Object
            obj.Switch  = Switch;
            obj.Antenna = tempStruct.Antenna;
            obj.LNB     = tempStruct.LNB;
        end
    end

    methods(Static = true)
        function ConfigFile_Update()
            global appGeneral

            % Antenna
            Antenna(1) = struct('Name', 'MCL-1', 'ACU', 'GD-7200', 'IP', '10.21.205.45', 'Port', 4002, 'Target', []);
            Antenna(2) = struct('Name', 'MCL-2', 'ACU', 'GD-7200', 'IP', '10.21.205.45', 'Port', 4003, 'Target', []);
            Antenna(3) = struct('Name', 'MCL-3', 'ACU', '',        'IP', '',             'Port', -1,   'Target', []);
            Antenna(4) = struct('Name', 'MCC-1', 'ACU', 'GD-7200', 'IP', '10.21.205.45', 'Port', 4006, 'Target', []);
            Antenna(5) = struct('Name', 'MKU-1', 'ACU', 'GD-7200', 'IP', '10.21.205.45', 'Port', 4004, 'Target', []);
            Antenna(6) = struct('Name', 'MKU-2', 'ACU', 'GD-7200', 'IP', '10.21.205.45', 'Port', 4005, 'Target', []);
            Antenna(7) = struct('Name', 'MKA-1', 'ACU', 'GD-123T', 'IP', '',             'Port', -1,   'Target', []);

            for ii = 1:numel(Antenna)
                IP   = Antenna(ii).IP;
                Port = Antenna(ii).Port;

                try
                    hACU = tcpclient(IP, Port);
                    configureTerminator(hACU, "CR/LF")

                    writeline(hMCL1, '/ CONFIGS SITE ANTENNA')
                    pause(PAUSE)
                    antName = read(hMCL1, hMCL1.NumBytesAvailable, 'char');
                    if ~contains(antName, Antenna(ii).Name)
                        error('Não se trata da antena correta...')
                    end

                    writeline(hMCL1, '/ TRACKING TRACK LS')
                    pause(PAUSE)
                    tgtList = regexp(read(hMCL1, hMCL1.NumBytesAvailable, 'char'), '\d{1,2} X T(?<ID>\d{2}) (?<Name>".*")\n', 'names');

                    for jj = 1:numel(tgtList)
                        writeline(hMCL1, sprintf('TT %s', tgtList(jj).ID))
                        pause(PAUSE)
                        Antenna(ii).Target(jj) = regexp(read(hMCL1, hMCL1.NumBytesAvailable, 'char'), '\d{2} \d{2} \d{4} (?<Azimuth>\d{6}) (?<Elevation>\d{6}) (?<Polarization>\d{6})', 'names');
                    end

                    clear hACU
                catch
                    if exist('hACU', 'var'); clear hACU
                    end
                end                
            end

            % LNB
            LNB = table('Size', [24, 4] ,                                        ...
                            'VariableNames', {'Name', 'Offset', 'Inverted', 'Port'}, ...
                            'VariableTypes', {'string', 'uint64', 'double', 'double'});

            LNB(1:24,:) = {'MCL-1 V',         5150000050, 1,  1; ...
                           'MCL-1 H',         5150000050, 1,  2; ...
                           'MCL-2 V',         5150000050, 1,  3; ...
                           'MCL-2 H',         5150000050, 1,  4; ...
                           'MCC-1 L',         5150000050, 1,  5; ...
                           'MCC-1 R',         5150000050, 1,  6; ...
                           'MCL-3 V',         5760000050, 1,  7; ...
                           'MCL-3 H',         5760000050, 1,  8; ...
                           'MKU-1 LO_V',      9750000000, 0,  9; ...
                           'MKU-1 HI_V',     10750000000, 0, 10; ...
                           'MKU-1 LO_H',      9750000000, 0, 11; ...
                           'MKU-1 HI_H',     10750000000, 0, 12; ...
                           'MKU-2 LO_V',      9750000000, 0, 13; ...
                           'MKU-2 HI_V',     10750000000, 0, 14; ...
                           'MKU-2 LO_H',      9750000000, 0, 15; ...
                           'MKU-2 HI_H',     10750000000, 0, 16; ...
                           'MKA-1 LO_R',     16200000000, 0, 23; ...
                           'MKA-1 MID_R',    17200000000, 0, 23; ...
                           'MKA-1 MID_HI_R', 18200000000, 0, 23; ...
                           'MKA-1 HI_R',     19200000000, 0, 23; ...
                           'MKA-1 LO_L',     16200000000, 0, 24; ...
                           'MKA-1 MID_L',    17200000000, 0, 24; ...
                           'MKA-1 MID_HI_L', 18200000000, 0, 24; ...
                           'MKA-1 HI_L',     19200000000, 0, 24};

            % JSON file
            writecell({jsonencode(struct('Antenna', Antenna, 'LNB', LNB), 'PrettyPrint', true)}, fullfile(appGeneral.RootFolder, 'Settings', 'EMSatLib.json'), "FileType", "text", "QuoteStrings", false)
        end
    end
end
        