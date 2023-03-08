%% EMSATLIB.M Resources for integration between EMSAT and Sentinela
% Author: Vinicius Puga <vinicius.puga@anatel.gov.br>
% Date: 2022-11-08
% Revision: 001
%
%   This library provides resources for the integration of EMSAT's
%   activities and hardware to Sentinela project applications, like 
%   appSat, appColeta and appAnalise.

classdef EMSATLib
    %% Properties of the EMSAT object
    properties
       Antenna
       Matrix
       SpectrumAnalyzer
    end
    methods
        %%   1) Constructor of EMSAT([CONFIG_FILE]):
        %       Constructor of the EMSAT object. Accepts a configuration
        %       file path [CONFIG_FILE].
        %       If [CONFIG_FILE] is not specified, create_new_cfg_file()
        %       method will be called to create a new one.
        %       
        %       Returns: obj = [OBJECT]
        function obj = EMSATLib(config_file)
            if nargin >0
                try
                    imported_config = jsondecode(fileread(config_file));
                catch
                    fprintf('Failed to open $s.Check if file exists\n',config_file);
                end
                obj.Antenna = imported_config.Antenna;
                obj.Matrix = imported_config.Matrix;
                obj.SpectrumAnalyzer = imported_config.SpectrumAnalyzer;
            else
                imported_config = jsondecode(fileread(obj.create_new_cfg_file()));
                obj.Antenna = imported_config.Antenna;
                obj.Matrix = imported_config.Matrix;
                obj.SpectrumAnalyzer = imported_config.SpectrumAnalyzer;
            end
        end
        %%   2) create_new_cfg_file():
        %       Creates a new configuration file from scratch based
        %       on default configuration parameters
        %       
        %       Returns: CONFIG_JSON (the config file name)
        function filepath =  (obj)
            %
            % This function will generate a json file from the template below
            %
            filepath = 'emsat_config.json';
            %
            MCL1_H = struct('Pol', 'H', 'Offset', 5150000050, 'Inverted', 1);
            MCL1_V = struct('Pol', 'V', 'Offset', 5150000050, 'Inverted', 1);
            LNB_MCL1 = struct('MCL1_H', MCL1_H, 'MCL1_V', MCL1_V);
            LIMITS_MCL1 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MCL1 = struct('Limits', LIMITS_MCL1, 'LNB', LNB_MCL1 );
            %
            MCL2_H = struct('Pol', 'H', 'Offset', 5150000050, 'Inverted', 1);
            MCL2_V = struct('Pol', 'V', 'Offset', 5150000050, 'Inverted', 1);
            LNB_MCL2 = struct('MCL2_H', MCL2_H, 'MCL2_V', MCL2_V);
            LIMITS_MCL2 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MCL2 = struct('Limits', LIMITS_MCL2, 'LNB',LNB_MCL2 );
            %
            MCL3_H = struct('Pol', 'H', 'Offset', 5760000050, 'Inverted', 1);
            MCL3_V = struct('Pol', 'V', 'Offset', 5760000050, 'Inverted', 1);
            LNB_MCL3 = struct('MCL3_H', MCL3_H, 'MCL3_V', MCL3_V);
            LIMITS_MCL3 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MCL3 = struct('Limits', LIMITS_MCL3, 'LNB',LNB_MCL3);
            %
            MCC1_L = struct('Pol', 'L', 'Offset', 5150000050, 'Inverted', 1);
            MCC1_R = struct('Pol', 'R', 'Offset', 5150000050, 'Inverted', 1);
            LNB_MCC1 = struct('MCC1_L', MCC1_L, 'MCC1_R', MCC1_R);
            LIMITS_MCC1 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MCC1 = struct('Limits', LIMITS_MCC1, 'LNB',LNB_MCC1);
            %
            MKU1_LO_H = struct('Pol', 'H', 'Offset', 9750000000, 'Inverted', 0);
            MKU1_HI_H = struct('Pol', 'H', 'Offset', 10750000000, 'Inverted', 0);
            MKU1_LO_V = struct('Pol', 'V', 'Offset', 9750000000, 'Inverted', 0);
            MKU1_HI_V = struct('Pol', 'V', 'Offset', 10750000000, 'Inverted', 0);
            LNB_MKU1 = struct('MKU1_LO_H', MKU1_LO_H, 'MKU1_HI_H', MKU1_HI_H, 'MKU1_LO_V', MKU1_LO_V, 'MKU1_HI_V', MKU1_HI_V);
            LIMITS_MKU1 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MKU1 = struct('Limits', LIMITS_MKU1, 'LNB',LNB_MKU1);
            %
            MKU2_LO_H = struct('Pol', 'H', 'Offset', 9750000000, 'Inverted', 0);
            MKU2_HI_H = struct('Pol', 'H', 'Offset', 10750000000, 'Inverted', 0);
            MKU2_LO_V = struct('Pol', 'V', 'Offset', 9750000000, 'Inverted', 0);
            MKU2_HI_V = struct('Pol', 'V', 'Offset', 10750000000, 'Inverted', 0);
            LNB_MKU2 = struct('MKU2_LO_H', MKU2_LO_H, 'MKU2_HI_H', MKU2_HI_H, 'MKU2_LO_V', MKU2_LO_V, 'MKU2_HI_V', MKU2_HI_V);
            LIMITS_MKU2 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MKU2 = struct('Limits', LIMITS_MKU2, 'LNB',LNB_MKU2);
            %
            MKA1_LO_L = struct('Pol', 'L', 'Offset', 16200000000, 'Inverted', 0);
            MKA1_MID_L = struct('Pol', 'L', 'Offset', 17200000000, 'Inverted', 0);
            MKA1_MID_HI_L = struct('Pol', 'L', 'Offset', 18200000000, 'Inverted', 0);
            MKA1_HI_L = struct('Pol', 'L', 'Offset', 19200000000, 'Inverted', 0);
            MKA1_LO_R = struct('Pol', 'R', 'Offset', 16200000000, 'Inverted', 0);
            MKA1_MID_R = struct('Pol', 'R', 'Offset', 17200000000, 'Inverted', 0);
            MKA1_MID_HI_R = struct('Pol', 'R', 'Offset', 18200000000, 'Inverted', 0);
            MKA1_HI_R = struct('Pol', 'R', 'Offset', 19200000000, 'Inverted', 0);
            LNB_MKA1 = struct('MKA1_LO_L', MKA1_LO_L, 'MKA1_MID_L', MKA1_MID_L, 'MKA1_MID_HI_L', MKA1_MID_HI_L, 'MKA1_HI_L', MKA1_HI_L, 'MKA1_LO_R', MKA1_LO_R, 'MKA1_MID_R', MKA1_MID_R, 'MKA1_MID_HI_R', MKA1_MID_HI_R, 'MKA1_HI_R', MKA1_HI_R);
            LIMITS_MKA1 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MKA1 = struct('Limits', LIMITS_MKA1, 'LNB',LNB_MKA1);
            %
            Antenna = struct('MCL1', MCL1, 'MCL2', MCL2, 'MCL3', MCL3, 'MCC1', MCC1, 'MKU1', MKU1,'MKU2', MKU2,'MKA1', MKA1);
            %
            Matrix_Switch = struct('MCL1_V', struct('set','{*zs,012,001}0','get','{zBs?012,001}['), ...
                'MCL1_H', struct('set','{*zs,012,002}1','get','{zBs?012,002}\'), ...
                'MCL2_V', struct('set','{*zs,012,003}2','get','{zBs?012,003}]'), ...
                'MCL2_H', struct('set','{*zs,012,004}3','get','{zBs?012,004}^'), ...
                'MCL3_V', struct('set','{*zs,012,007}6','get','{zBs?012,007}a'), ...
                'MCL3_H', struct('set','{*zs,012,008}7','get','{zBs?012,008}b'), ...
                'MCC1_L', struct('set','{*zs,012,005}4','get','{zBs?012,005}_'), ...
                'MCC1_R', struct('set','{*zs,012,006}5','get','{zBs?012,006}`'), ...
                'MKU1_LO_V', struct('set','{*zs,012,009}8','get','{zBs?012,009}c'), ...
                'MKU1_HI_V', struct('set','{*zs,012,010}0','get','{zBs?012,010}['), ...
                'MKU1_LO_H', struct('set','{*zs,012,011}1','get','{zBs?012,011}\'), ...
                'MKU1_HI_H', struct('set','{*zs,012,012}2','get','{zBs?012,012}]'), ...
                'MKU2_LO_V', struct('set','{*zs,012,013}3','get','{zBs?012,013}^'), ...
                'MKU2_HI_V', struct('set','{*zs,012,014}4','get','{zBs?012,014}_'), ...
                'MKU2_LO_H', struct('set','{*zs,012,015}5','get','{zBs?012,015}`'), ...
                'MKU2_HI_H', struct('set','{*zs,012,016}6','get','{zBs?012,016}a'));
            Matrix = struct('IP','192.168.0.116','Port',4000,'Timeout_ms',150,'Switch',Matrix_Switch);
            SpectrumAnalyzer = struct('IP','10.21.204.212','Port',4000);
            % Generate JSON text from the assembled structure
            emsat_json_txt = jsonencode(struct('Antenna', Antenna,'Matrix',Matrix,'SpectrumAnalyzer',SpectrumAnalyzer),'PrettyPrint', true);
            % Write the JSON file
            fid = fopen(filepath,'w');
            fprintf(fid, '%s', emsat_json_txt);
            fclose(fid);
            
        end
        %%   3) switch_signal_input(ANTENNA_LNB,CONFIG_JSON):
        %       Commands EMSAT's L-Band Matrix to switch the interconnection between
        %       the selected LNB/Antenna pair to the spectrum analyzer.
        %       
        %        The CONFIG_JSON file specifies the command required to switch between 
        %        each LNB/Antenna pair.
        %        Returns: 0 (sucess) or 1 (failure)
        function status = switch_signal_input(obj,ANTENNA_LNB)
            % Setup L-band Matrix connection
            LBandMatrix = instrfind('Type', 'tcpip', 'RemoteHost', obj.Matrix.IP, 'RemotePort', obj.Matrix.Port, 'Tag', '','Timeout', 0.15);
            % Create the tcpip object if it does not exist
            % otherwise use the object that was found.
            if isempty(LBandMatrix)
                LBandMatrix = tcpip(obj.Matrix.IP, obj.Matrix.Port);
            else
                fclose(LBandMatrix);
                LBandMatrix = LBandMatrix(1);
            end
            % Connect to instrument object, obj1.
            fopen(LBandMatrix);
            % Communicating with instrument object, obj1.
            fprintf('Attempting to switch the L-Band Matrix input to %s \n',ANTENNA_LNB);
            fprintf('Query: %14s \n',getfield(obj.Matrix.Switch,ANTENNA_LNB).set);
            response = query(LBandMatrix, getfield(obj.Matrix.Switch,ANTENNA_LNB).set, '%s' ,'%s');
            fprintf('Got %14s from L-Band Matrix\n',response);
            % Disconnect from LBandMatrix
            fclose(LBandMatrix);
            % Return the status (success or failure)
            if (response == getfield(obj.Matrix.Switch,ANTENNA_LNB).get)
                fprintf('Command sucessful\n --\n');
                status = 0;
            else
                fprintf('Command failed\n --\n');
                status = 1;
            end
        end
        %%   4) move_antenna(struct([ANTENNA],[PRESET_CODE]) or struct([AZIMUTH],[ELEVATION],[LNB_SKEW])):
        %        Commands the specified antena to move to a preset or to a selected
        %        azimuth, elevation and LNB skew.
        %       
        %        The config_ini file specifies the command required to move the
        %        antenna.
        %        Tracking is currently not supported.
        %        Returns: 0 (sucess), 1 (failure)
        function status = move_antenna(input_data)
            % ToDo: implement antenna movement algorithm
            status = 0;
        end
    end
end
        