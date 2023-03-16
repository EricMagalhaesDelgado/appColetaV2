%% EMSATLIB.M Resources for integration between EMSAT and Sentinela
% Author: Vinicius Puga <vinicius.puga@anatel.gov.br>
% Date: 2022-11-08
% Revision: 010
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
       UserOptions
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
                    % Create properties for the object
                    obj.Antenna = imported_config.Antenna;
                    obj.Matrix = imported_config.Matrix;
                    obj.SpectrumAnalyzer = imported_config.SpectrumAnalyzer;
                    %obj.UserOptions = imported_config.UserOptions;
                    % Assign methods to functions
                    availableantennas = fieldnames(obj.Antenna);
                    for k=1:numel(availableantennas)
                        %fprintf('Selecionado %i',k);
                        %fprintf(availableantennas{k});
                        %obj.Antenna.availableantennas{k}.SetTarget =
                        %@self.move_antenna
                        %eval(['obj.Antenna. ',availableantennas{k},'.SetTarget = @obj.move_antenna;'])
                        settarget = eval(['@(preset)obj.move_antenna(obj.Antenna.',availableantennas{k},',preset)'])
                        eval(['obj.Antenna. ',availableantennas{k},'.SetTarget = settarget;'])
                    end
                catch
                    fprintf('Failed to open $s.Check if file exists\n',config_file);
                end
            else
                imported_config = jsondecode(fileread(obj.create_new_cfg_file()));
                % Create properties for the object
                obj.Antenna = imported_config.Antenna;
                obj.Matrix = imported_config.Matrix;
                obj.SpectrumAnalyzer = imported_config.SpectrumAnalyzer;
                obj.UserOptions = imported_config.UserOptions;
                % Assign methods to functions
                availableantennas = fieldnames(obj.Antenna);
                for k=1:numel(availableantennas)
                    %fprintf('Selecionado %i',k);
                    %fprintf(availableantennas{k});
                    settarget = eval(['@(preset)obj.move_antenna(obj.Antenna.',availableantennas{k},',preset)'])
                    %eval(['obj.Antenna. ',availableantennas{k},'.SetTarget = @obj.move_antenna;'])
                    eval(['obj.Antenna. ',availableantennas{k},'.SetTarget = settarget;'])
                    end
            end
        end
        %%   2) create_new_cfg_file():
        %       Creates a new configuration file from scratch based
        %       on default configuration parameters
        %       
        %       Returns: CONFIG_JSON (the config file name)
        function filepath = create_new_cfg_file(obj)
            %
            % This function will generate a json file from the template below
            %
            filepath = 'emsat_config.json';
            %
            MCL1_H = struct('Pol', 'H', 'Offset', 5150000050, 'Inverted', 1);
            MCL1_V = struct('Pol', 'V', 'Offset', 5150000050, 'Inverted', 1);
            LNB_MCL1 = struct('MCL1_H', MCL1_H, 'MCL1_V', MCL1_V);
            ACU_MCL1=struct('Name','MCL-1','IP','10.21.205.45','Port',4002,'Timeout',150,'Model','GD-7200');
            LIMITS_MCL1 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MCL1 = struct('Limits', LIMITS_MCL1, 'LNB', LNB_MCL1,'ACU',ACU_MCL1);
            %
            MCL2_H = struct('Pol', 'H', 'Offset', 5150000050, 'Inverted', 1);
            MCL2_V = struct('Pol', 'V', 'Offset', 5150000050, 'Inverted', 1);
            LNB_MCL2 = struct('MCL2_H', MCL2_H, 'MCL2_V', MCL2_V);
            ACU_MCL2=struct('Name','MCL-2','IP','10.21.205.45','Port',4003,'Timeout',150,'Model','GD-7200');
            LIMITS_MCL2 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MCL2 = struct('Limits', LIMITS_MCL2, 'LNB',LNB_MCL2,'ACU',ACU_MCL2);
            %
            MCL3_H = struct('Pol', 'H', 'Offset', 5760000050, 'Inverted', 1);
            MCL3_V = struct('Pol', 'V', 'Offset', 5760000050, 'Inverted', 1);
            LNB_MCL3 = struct('MCL3_H', MCL3_H, 'MCL3_V', MCL3_V);
            ACU_MCL3=struct('Name','MCL-3','IP','','Port',-1,'Timeout',0); %This antenna doesn't have an ACU.
            LIMITS_MCL3 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MCL3 = struct('Limits', LIMITS_MCL3, 'LNB',LNB_MCL3,'ACU',ACU_MCL3);
            %
            MCC1_L = struct('Pol', 'L', 'Offset', 5150000050, 'Inverted', 1);
            MCC1_R = struct('Pol', 'R', 'Offset', 5150000050, 'Inverted', 1);
            LNB_MCC1 = struct('MCC1_L', MCC1_L, 'MCC1_R', MCC1_R);
            ACU_MCC1=struct('Name','MCC-1','IP','10.21.205.45','Port',4006,'Timeout',150,'Model','GD-7200');
            LIMITS_MCC1 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MCC1 = struct('Limits', LIMITS_MCC1, 'LNB',LNB_MCC1,'ACU',ACU_MCC1);
            %
            MKU1_LO_H = struct('Pol', 'H', 'Offset', 9750000000, 'Inverted', 0);
            MKU1_HI_H = struct('Pol', 'H', 'Offset', 10750000000, 'Inverted', 0);
            MKU1_LO_V = struct('Pol', 'V', 'Offset', 9750000000, 'Inverted', 0);
            MKU1_HI_V = struct('Pol', 'V', 'Offset', 10750000000, 'Inverted', 0);
            LNB_MKU1 = struct('MKU1_LO_H', MKU1_LO_H, 'MKU1_HI_H', MKU1_HI_H, 'MKU1_LO_V', MKU1_LO_V, 'MKU1_HI_V', MKU1_HI_V);
            ACU_MKU1=struct('Name','MKU-1','IP','10.21.205.45','Port',4004,'Timeout',150,'Model','GD-7200');
            LIMITS_MKU1 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MKU1 = struct('Limits', LIMITS_MKU1, 'LNB',LNB_MKU1,'ACU',ACU_MKU1);
            %
            MKU2_LO_H = struct('Pol', 'H', 'Offset', 9750000000, 'Inverted', 0);
            MKU2_HI_H = struct('Pol', 'H', 'Offset', 10750000000, 'Inverted', 0);
            MKU2_LO_V = struct('Pol', 'V', 'Offset', 9750000000, 'Inverted', 0);
            MKU2_HI_V = struct('Pol', 'V', 'Offset', 10750000000, 'Inverted', 0);
            LNB_MKU2 = struct('MKU2_LO_H', MKU2_LO_H, 'MKU2_HI_H', MKU2_HI_H, 'MKU2_LO_V', MKU2_LO_V, 'MKU2_HI_V', MKU2_HI_V);
            ACU_MKU2=struct('Name','MKU-2','IP','10.21.205.45','Port',4005,'Timeout',150,'Model','GD-7200');
            LIMITS_MKU2 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MKU2 = struct('Limits', LIMITS_MKU2, 'LNB',LNB_MKU2, 'ACU',ACU_MKU2);
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
            ACU_MKA1=struct('Name','MCL-1','IP','','Port',-1,'Timeout',0,'Model','GD-123T');
            LIMITS_MKA1 = struct('Azimuth', struct('Min', 0 ,'Max', 0), 'Elevation', struct('Min', 0,'Max', 0), 'LNB_Skew', struct('Min', 0,'Max', 0));
            MKA1 = struct('Limits', LIMITS_MKA1, 'LNB',LNB_MKA1,'ACU',ACU_MKA1);
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
            Matrix = struct('IP','192.168.0.116','Port',4000,'Timeout',150,'Switch',Matrix_Switch);
            %
            SpectrumAnalyzer = struct('IP','10.21.204.212','Port',4000);
            % UserOptions
            UserOptions = struct('CheckExternalPolling',1, ...
                'CheckACUReachable', 1, ...
                'UserOption3',0);
            
            % Generate JSON text from the assembled structure
            emsat_json_txt = jsonencode(struct('Antenna', Antenna,'Matrix',Matrix,'SpectrumAnalyzer',SpectrumAnalyzer,'UserOptions',UserOptions),'PrettyPrint', true);
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
            if isempty(LBandMatrix);
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
        %%   4) move_antenna_(struct([ANTENNA],[PRESET_CODE]) or struct([AZIMUTH],[ELEVATION],[LNB_SKEW])):
        %        Commands the specified antena to move to a preset or to a selected
        %        azimuth, elevation and LNB skew.
        %       
        %        The config_ini file specifies the command required to move the
        %        antenna.
        %        Tracking is currently not supported.
        %        Returns: 0 (sucess), 1 (failure)        
        function status = move_antenna(obj,CurrentAntenna,preset)
            %
            % Define the error types
            %
            errIDs = struct('ACUUnreachable',['Couldn''t connect to the ACU of antenna ',CurrentAntenna.ACU.Name,' on ',CurrentAntenna.ACU.IP,':',num2str(CurrentAntenna.ACU.Port),'.Check if the ACU is reachable or set UserConfig.CheckACUReachable to 0.'], ...
                'ACUBusy',['The ACU of antenna ',CurrentAntenna.ACU.Name,' on ',CurrentAntenna.ACU.IP,':',num2str(CurrentAntenna.ACU.Port),' is beign polled by another application. Disable polling for this ACU on Kratos Compass or set UserOptions.CheckExternalPolling to 0.'], ...
                'ACUWrongPort',['The ACU name of ',CurrentAntenna.ACU.Name,' antenna doesn''t match the information retrieved on IP ',CurrentAntenna.ACU.IP,':',num2str(CurrentAntenna.ACU.Port),'. Check if json file was specified with the wrong port.'], ...
                'ACUPort5Level',['The Port 5 of ',CurrentAntenna.ACU.Name,' ACU must be in Supervisor user level. Set the correct userlevel through Compass or manually.'], ...
                'ACUFault',['The ACU of antenna ',CurrentAntenna.ACU.Name,' reported a faulty status. Clear the ACU errors before continuing.']);
            %
            %1) Attempting to connect to ACU
            %
            try
                objACU=tcpclient(CurrentAntenna.ACU.IP,CurrentAntenna.ACU.Port);
                configureTerminator(objACU,"CR/LF");
                fprintf('Attempting to connect to %s : %i ...\n',CurrentAntenna.ACU.IP,CurrentAntenna.ACU.Port);
            catch
                fprintf('Connection failed');
                status = MException(['EMSATLib:','ACUUnreachable'],errIDs.ACUUnreachable);
                throw(status);
                return
            end
            %
            %2) Check if any other application (i.e.Kratos Compass) is polling the ACU
            %
            fprintf('Connection successful\n')
            fprintf('Checking if any other application is polling %s...\n',CurrentAntenna.ACU.Name)
            retries = 1; %How many times to retry to read a line
            for i=1:retries
                try
                    response = readline(objACU);
                catch
                    fprintf('Failed during readline attempt');
                    flush(objACU);
                    clear objACU;
                    status = MException(['EMSATLib:','ACUUnreachable'],errIDs.ACUUnreachable);
                    throw(status);
                    return
                end
                if ~isempty(response)
                    status = MException(['EMSATLib:','ACUBusy'],errIDs.ACUBusy);
                    throw(status);
                    flush(objACU);
                    clear objACU;
                    return
                end
                flush(objACU)
            end
            fprintf('After %i read attempts, no external polling was identified.\n',retries);
            %
            %3) Checks if the user specified the correct port in json file
            %
            try
                response = writeread(objACU,'/ CONFIGS SITE ANTENNA'); %This requests the ACU antenna name
                if contains(response,CurrentAntenna.ACU.Name)
                    fprint('The ACU identified itself as expected: %s\n',replace(replace(response,'"',''),' ',''));
                else
                    fprintf('The ACU on %s:%i identified itself as %s, which differs from the expected antenna %s. Aborting operation.\n',CurrentAntenna.ACU.IP,CurrentAntenna.ACU.Port,replace(replace(response,'"',''),' ',''),CurrentAntenna.ACU.Name);
                    flush(objACU)
                    clear objACU
                    status = MException(['EMSATLib:','ACUWrongPort'],errIDs.ACUWrongPort)
                    throw(status)
                    return
                end
            catch
                fprintf('Failed during writeread attempt')
                flush(objACU)
                clear objACU
                status = MException(['EMSATLib:','ACUUnreachable'],errIDs.ACUUnreachable)
                throw(status)
                return
            end
            %
            %4) Checks if Port 5 is in supervisor level
            %
            try
                response = writeread(objACU,'WHO'); %This requests the userlevel for Port 5
                if contains(response,'Port 5 at supervisor')
                    fprint('The ACU is controllable: %s',replace(replace(response,'"',''),' ',''));
                else
                    fprintf('The ACU Port 5 is not at the supervisor user level. Currently: %s. Aborting operation.\n',replace(response,'"',''));
                    flush(objACU)
                    clear objACU
                    status = MException(['EMSATLib:','ACUPort5Level'],errIDs.ACUPort5Level)
                    throw(status)
                    return
                end
            catch
                fprintf('Failed during writeread attempt\n')
                flush(objACU)
                clear objACU
                status = MException(['EMSATLib:','ACUUnreachable'],errIDs.ACUUnreachable)
                throw(status)
                return
            end
            %
            %5) Checks the presence of a faulty status
            %
            ReferenceACUStatus = '00000000 00000000 00000000 00000000'
            try
                response = writeread(objACU,'F 0'); %
                if contains(response,ReferenceACUStatus)
                    fprint('No faults identified in %s antenna ACU.\n',CurrentAntenna.ACU.Name);
                else
                    fprintf('The ACU of antenna %s has reported a faulty status. Aborting...\n Fault status: %s\n',CurrentAntenna.ACU.Name,replace(response,'"',''));
                    flush(objACU)
                    clear objACU
                    status = MException(['EMSATLib:','ACUFault'],errIDs.ACUFault)
                    throw(status)
                    return
                end
            catch
                fprintf('Failed during writeread attempt\n')
                flush(objACU)
                clear objACU
                status = MException(['EMSATLib:','ACUUnreachable'],errIDs.ACUUnreachable)
                throw(status)
                return
            end
            %
            %TT T07 T ->Move para o preset 07
            %Q -> Coloca em Idle
            %S -> Suspende a movimentação
            %R -> Resume
            %/ CONFIGS ENCODERS CURRENT ->Mostra o azimute, elevação e giro
            %do LNB da antena atual
            %/ TRACKING TRACK LS ->Lista o nome dos presets
            %Antena,Satelite(Designador Internacional-8digitos)
            fprintf('Congratulations, youve made this far! Try a command.\n')
            clear objACU

        end
        %%  4.1) move_antenna_preset()
    end
end
        