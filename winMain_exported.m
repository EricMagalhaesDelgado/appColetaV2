classdef winMain_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        GridLayout           matlab.ui.container.GridLayout
        Tree                 matlab.ui.container.Tree
        FaixasdefrequnciarelacionadastarefaselecionadaLabel  matlab.ui.control.Label
        GridLayout3          matlab.ui.container.GridLayout
        Image6               matlab.ui.control.Image
        task_NameEdit_2      matlab.ui.control.Button
        task_NameEdit        matlab.ui.control.Button
        task_scpiListEdit_2  matlab.ui.control.Button
        Image5               matlab.ui.control.Image
        Image2               matlab.ui.control.Image
        Image                matlab.ui.control.Image
        Image3               matlab.ui.control.Image
        Image4               matlab.ui.control.Image
        task_scpiListEdit    matlab.ui.control.Button
        Panel                matlab.ui.container.Panel
        table_Grid           matlab.ui.container.GridLayout
        Column5_4            matlab.ui.control.Label
        Column5_3            matlab.ui.control.Label
        Column5_2            matlab.ui.control.Label
        Column5              matlab.ui.control.Label
        Export_Grid          matlab.ui.container.GridLayout
        table_Separator      matlab.ui.control.Image
        table_Play           matlab.ui.control.Image
        table_Stop           matlab.ui.control.Image
        table_Edit           matlab.ui.control.Image
        table_New            matlab.ui.control.Image
        table_Del            matlab.ui.control.Image
        Column10             matlab.ui.control.Label
        Column8              matlab.ui.control.Label
        Column7              matlab.ui.control.Label
        Column3              matlab.ui.control.Label
        Column2              matlab.ui.control.Label
        Column1              matlab.ui.control.Label
        UITable              matlab.ui.control.Table
    end

    
    properties (Access = public)
        
        General
        RootFolder

        axes1
        axes2

        specObj      = specClass
        timeObj
        udpPortArray = {}
        
        taskList
        scpiList
        instrInfo

        Flag_running
        Flag_editing

        auxWin1 = []
        auxWin2 = []
        auxWin3 = []

        d

    end

    
    methods (Access = private)

        function startup_Layout(app)

            mainMonitor = get(0, 'MonitorPositions');

            [~, ind]    = max(mainMonitor(:,3));
            mainMonitor = mainMonitor(ind,:);
            
            app.UIFigure.Position(1:2) = [mainMonitor(1)+round((mainMonitor(3)-app.UIFigure.Position(3))/2), ...
                                          mainMonitor(2)+round((mainMonitor(4)-app.UIFigure.Position(4)-30)/2)];

        end


        function startup_AxesCreation(app)

            t = tiledlayout(app.Panel, 3, 1, "Padding", "tight", "TileSpacing", "compact");

            % app.UIAxes1
            app.axes1 = uiaxes(t);
            app.axes1.Layout.Tile = 1;
            set(app.axes1, Color = [0.94, .94, .94], ...
                           FontSize = 8)

            % app.UIAxes2
            app.axes2 = uiaxes(t);
            app.axes2.Layout.Tile = 2;
            app.axes2.Layout.TileSpan  = [2,1];
            set(app.axes2, Color = [0.94, .94, .94], ...
                           FontSize = 8)

        end


        function startup_ConfigFiles(app)

            % app.General
            tempObj = jsondecode(fileread(fullfile(app.RootFolder, 'Settings', 'GeneralSettings.json')));
            tempObj.layout.lightColor = tempObj.layout.lightColor';
            tempObj.layout.cyanColor  = tempObj.layout.cyanColor';

            app.General = tempObj;


            % app.taskList
            taskTemp = jsondecode(fileread('taskList.json'));
            for ii = 1:numel(taskTemp)
                app.taskList{ii} = taskTemp(ii);
    
                if (app.taskList{ii}.Observation.Type == "Duration") & isempty(app.taskList{ii}.Observation.Duration)
                    app.taskList{ii}.Observation.Duration = inf;
                end
    
                if ~any([app.taskList{ii}.Band.Enable])
                    app.taskList{ii}.Band(1).Enable = 1;
                end
            end


            % app.scpiList
            tempList = jsondecode(fileread('scpiList.json'));
            for ii = 1:numel(tempList)
                tempList(ii).Parameters = jsonencode(tempList(ii).Parameters);
            end

            app.scpiList     = struct2table(tempList, 'AsArray', true);
            app.scpiList.idx = (1:numel(tempList))';
            app.scpiList     = movevars(app.scpiList, 'idx', 'Before', 1);


            % app.instrInfo            
            app.instrInfo = struct2table(jsondecode(fileread(fullfile(app.RootFolder, 'Settings', 'instrInfo.json'))));

        end


        function MessageBox(app, type, msg)

            appName = 'appColeta';

            msg = sprintf('<font style="font-size:12;">%s</font>', msg);
            switch type
                case 'error';   uialert(app.UIFigure, msg, appName, 'Interpreter', 'html');
                case 'warning'; uialert(app.UIFigure, msg, appName, 'Interpreter', 'html', 'Icon', 'warning');
                case 'info';    uialert(app.UIFigure, msg, appName, 'Interpreter', 'html', 'Icon', 'LT_info.png')
                case 'startup'; app.UIFigure.Visible = 1; uialert(app.UIFigure, msg, appName, 'Interpreter', 'html', 'CloseFcn', @(~,~)closeFcn(app));
            end

        end


        function Fcn_TableBuilding(app)

            tempTable = table('Size', [0, 10], ...
                              'VariableTypes', {'double', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'}, ...
                              'VariableNames', {'ID', 'Name', 'Created', 'BeginTime', 'EndTime', 'Status', 'Receiver', 'udpPort', 'GPS', 'AntennaSwitch'});

            
            for ii = 1:numel(app.specObj)
                Receiver = sprintf('%s (%s)', app.specObj(ii).Receiver.Name, app.specObj(ii).Receiver.Parameters.IP);
                if ~isempty(app.specObj(ii).Receiver.Parameters.Port)
                    Receiver = replace(Receiver, sprintf('(%s)',    app.specObj(ii).Receiver.Parameters.IP), ...
                                                 sprintf('(%s:%s)', app.specObj(ii).Receiver.Parameters.IP, app.specObj(ii).Receiver.Parameters.Port));
                end

                udpPort = "-1";
                if ~isempty(app.specObj(ii).udpPort.Source)
                    udpPort = app.specObj(ii).udpPort.Parameters.Port;
                end

                GPS = "-1";
                if ~isempty(app.specObj(ii).GPS.Name)
                    udpPort = app.specObj(ii).GPS.Name;
                end

                AntennaSwitch = "-1";
                if ~isempty(app.specObj(ii).AntennaSwitch.Name)
                    AntennaSwitch = app.specObj(ii).AntennaSwitch.Name;
                end

                tempTable(end+1,:) = {app.specObj(ii).ID,                             ...
                                      app.specObj(ii).Task.Name,                      ...
                                      app.specObj(ii).Observation.Created,            ...
                                      datestr(app.specObj(ii).Observation.BeginTime, 'dd/mm/yyyy HH:MM:SS'), ...
                                      datestr(app.specObj(ii).Observation.EndTime, 'dd/mm/yyyy HH:MM:SS'),   ...
                                      app.specObj(ii).Status,                         ...
                                      Receiver, udpPort, GPS, AntennaSwitch};
            end

            app.UITable.Data      = tempTable;
            app.UITable.Selection = height(app.UITable.Data);

            UITableSelectionChanged(app)

        end


        function Fcn_TreeBuilding(app)
            
            delete(app.Tree.Children);
            
            idx = app.UITable.Selection;
            for ii = 1:numel(app.specObj(idx).Task.Band)
                AntennaName = '';
                if ~isempty(app.specObj(idx).AntennaSwitch.Name)
                    AntennaName = app.specObj(idx).Task.Band.Antenna.Name;
                end

                if ~isempty(AntennaName)
                    AntennaName = sprintf('(%s)', AntennaName);
                end

                uitreenode(app.Tree, 'Text', sprintf('ThreadID %d: %.3f - %.3f MHz %s',                ...
                                                     app.specObj(idx).Task.Band(ii).ThreadID,          ...
                                                     app.specObj(idx).Task.Band(ii).FreqStart .* 1e-6, ...
                                                     app.specObj(idx).Task.Band(ii).FreqStop  .* 1e-6, ...
                                                     AntennaName),                                     ...
                                     'NodeData', ii);
            end
            
            app.Tree.SelectedNodes = app.Tree.Children(1);
            TreeSelectionChanged(app)
            
        end


        function task_ParametersEditables(app, idx1, idx2)

            for ii = 1:numel(app.taskList{idx2}.Band)
                task_ParametersEditables_SaveValues(app, idx1, idx2, ii)
            end

        end


        function task_ParametersEditables_SaveValues(app, idx1, idx2, idx3)

            instrSettings = task_ParametersEditables_GetValues(app, idx1, idx2, idx3);

            app.taskList{idx2}.Band(idx3).instrStepWidth_Items   = instrSettings.StepWidth_Items;
            app.taskList{idx2}.Band(idx3).instrStepWidth         = instrSettings.StepWidth;

            app.taskList{idx2}.Band(idx3).instrDataPoints_Limits = instrSettings.DataPoints_Limits;
            app.taskList{idx2}.Band(idx3).instrDataPoints        = instrSettings.DataPoints;

            app.taskList{idx2}.Band(idx3).instrResolution_Items  = instrSettings.Resolution_Items;
            app.taskList{idx2}.Band(idx3).instrResolution        = instrSettings.Resolution;
            
            app.taskList{idx2}.Band(idx3).instrSelectivity       = instrSettings.Selectivity;
            app.taskList{idx2}.Band(idx3).instrSensitivityMode   = instrSettings.SensitivityMode;
            
            app.taskList{idx2}.Band(idx3).instrPreamp            = instrSettings.Preamp;
            app.taskList{idx2}.Band(idx3).instrAttMode           = instrSettings.AttMode;
            app.taskList{idx2}.Band(idx3).instrAttFactor_Items   = instrSettings.AttFactor_Items;
            app.taskList{idx2}.Band(idx3).instrAttFactor         = instrSettings.AttFactor;

            app.taskList{idx2}.Band(idx3).instrDetector_Items    = instrSettings.Detector_Items;
            indDetector = find(strcmp(app.taskList{idx2}.Band(idx3).instrDetector_Items, app.taskList{idx2}.Band(idx3).Detector), 1);
            if isempty(indDetector)
                indDetector = 1;
            end
            app.taskList{idx2}.Band(idx3).instrDetector        = instrSettings.Detector_Items{indDetector};
            app.taskList{idx2}.Band(idx3).instrLevelUnit       = instrSettings.LevelUnit;
            app.taskList{idx2}.Band(idx3).instrIntegrationTime = instrSettings.IntegrationTime;

            app.taskList{idx2}.Band(idx3).EditedFlag = 0;

        end


        function instrSettings = task_ParametersEditables_GetValues(app, idx1, idx2, idx3)

            instrSettings = struct('StepWidth_Items',   [], 'StepWidth',       [], ...
                                   'DataPoints_Limits', [], 'DataPoints',      [], ...
                                   'Resolution_Items',  [], 'Resolution',      [], ...
                                   'Selectivity_Items', [], 'Selectivity',     [], ...
                                   'SensitivityMode',   [], 'Preamp',          [], ...
                                   'AttMode',           [], 'AttFactor_Items', [], ...
                                   'AttFactor',         [], 'LevelUnit',       [], ...
                                   'Detector_Items',    [], 'IntegrationTime', []);

            span = app.taskList{idx2}.Band(idx3).FreqStop - app.taskList{idx2}.Band(idx3).FreqStart;
            
            instrSettings.AttMode         = 'Auto';
            instrSettings.AttFactor_Items = strsplit(app.instrInfo.Attenuation_Values{idx1}, ',');
            instrSettings.AttFactor       = instrSettings.AttFactor_Items{1};
            instrSettings.Detector_Items  = strsplit(app.instrInfo.Detector_Items{idx1}, ',');

            switch app.instrInfo.connectFlag{idx1}
                case 1
                    instrSettings.Resolution_Items = strsplit(app.instrInfo.Resolution_Values{idx1}, ',');

                    rbwValues = [];
                    for ii = 1:numel(instrSettings.Resolution_Items)
                        rbwValues = [rbwValues, str2double(extractBefore(instrSettings.Resolution_Items{ii}, ' kHz')).*1000];
                    end

                    instrSettings.DataPoints_Limits = app.instrInfo.DataPoints_Limits{idx1};

                    DataPoints = round(span/app.taskList{idx2}.Band(idx3).StepWidth + 1);
                    if     DataPoints < instrSettings.DataPoints_Limits(1); instrSettings.DataPoints = instrSettings.DataPoints_Limits(1);
                    elseif DataPoints > instrSettings.DataPoints_Limits(2); instrSettings.DataPoints = fix(instrSettings.DataPoints_Limits(2));
                    else;                                                   instrSettings.DataPoints = DataPoints;
                    end
                    instrSettings.StepWidth = span/(instrSettings.DataPoints - 1);

                    rbwIndex  = find(abs(rbwValues - app.taskList{idx2}.Band(idx3).Resolution) == min(abs(rbwValues - app.taskList{idx2}.Band(idx3).Resolution)));
                    instrSettings.Resolution = instrSettings.Resolution_Items{rbwIndex};

                    instrSettings.Selectivity     = '';

                    instrSettings.SensitivityMode = '0';
                    instrSettings.Preamp          = 'On';

                    instrSettings.LevelUnit       = app.taskList{idx2}.Band(idx3).LevelUnit;

                    switch app.taskList{idx2}.Band(idx3).RFMode
                        case 'High Sensitivity'
                            instrSettings.AttMode         = 'Manual';
                            instrSettings.SensitivityMode = '1';
                        case 'Low Distortion'
                            instrSettings.Preamp          = 'Off';
                    end

                case 2                                                                                              % EB500
                    instrSettings.StepWidth_Items   = strsplit(app.instrInfo.StepWidth_Values{idx1}, ',');
                    instrSettings.Selectivity_Items = {'Normal', 'Narrow', 'Sharp'};

                    stepValues = [];
                    for ii = 1:length(instrSettings.StepWidth_Items)
                        stepValues = [stepValues, str2double(extractBefore(instrSettings.StepWidth_Items{ii}, ' kHz')).*1000];
                    end

                    stepIndex  = find(abs(stepValues - app.taskList{idx2}.Band(idx3).StepWidth) == min(abs(stepValues - app.taskList{idx2}.Band(idx3).StepWidth)));
                    instrSettings.StepWidth  = instrSettings.StepWidth_Items{stepIndex};

                    instrSettings.DataPoints = span/(str2double(extractBefore(instrSettings.StepWidth, ' kHz'))*1000) + 1;

                    rbwValues = [];
                    rbwItems  = {};
                    for ii = 1:3
                        rbwValues = [rbwValues, app.EB500Map{instrSettings.StepWidth, ii}];
                        rbwItems  = [rbwItems,  sprintf('%.3f kHz', rbwValues(ii)/1000)];
                    end
                    instrSettings.Resolution_Items = rbwItems;

                    rbwIndex = find(abs(rbwValues - app.taskList{idx2}.Band(idx3).Resolution) == min(abs(rbwValues - app.taskList{idx2}.Band(idx3).Resolution)));
                    instrSettings.Resolution  = instrSettings.Resolution_Items{rbwIndex};
                    instrSettings.Selectivity = app.task_Selectivity.Items{rbwIndex};

                    instrSettings.SensitivityMode = 'NORM';
                    instrSettings.Preamp          = 'Off';
                    instrSettings.LevelUnit       = 'dBμV';

                    switch app.taskList{idx2}.Band(idx3).RFMode
                        case 'High Sensitivity'
                            instrSettings.AttMode = 'Manual';
                        case 'Low Distortion'
                            instrSettings.SensitivityMode = 'LOWD';
                    end

                    switch app.taskList{idx2}.Band(idx3).TraceMode
                        case 'ClearWrite'
                            instrSettings.IntegrationTime = 0;
                        otherwise
                            instrSettings.IntegrationTime = 10 * app.taskList{idx2}.Band(idx3).IntegrationFactor;
                    end
            end

        end


        function task_TableToolbarCallbacks(app, event)

            switch event.Source
                case app.table_Play
                    % Pendente

                case app.table_Stop
                    % Pendente

                case app.table_New

                    % General indexes:
                    idx1 = 1;                                                            % app.taskList
                    idx2 = 7;                                                            % app.scpiList
                    idx3 = find(strcmp(app.instrInfo.Name, app.scpiList.Name{idx2}), 1); % app.instrInfo
        
                    % OBJECT:
                    [app.specObj, idx] = app.specObj.Fcn_AddTask;

                    app.specObj(idx).Task   = app.taskList{idx1};
                    app.specObj(idx).Status = 'Em andamento...';
                    
                    [BeginTime, EndTime] = task_ObservationTime(app, idx1);
                    app.specObj(idx).Observation.BeginTime = BeginTime;
                    app.specObj(idx).Observation.EndTime   = EndTime;

                    app.timeObj = timeClass(app.specObj);

                    app.specObj(idx).LOG(end+1) = struct('time', datestr(now, 'dd/mm/yyyy HH:MM:SS'), ...
                                                         'msg',  'TESTE 1');
                    pause(2)
                    app.specObj(idx).LOG(end+1) = struct('time', datestr(now, 'dd/mm/yyyy HH:MM:SS'), ...
                                                         'msg',  'TESTE 2 DEPOIS DE 2 SEGUNDOS');
                    app.specObj(idx).LOG(end+1) = struct('time', datestr(now, 'dd/mm/yyyy HH:MM:SS'), ...
                                                         'msg',  jsonencode(app.timeObj));

                    % RECEIVER
                    app.specObj(idx).Receiver.Name       = app.scpiList.Name{idx2};
                    app.specObj(idx).Receiver.Type       = app.scpiList.Type{idx2};
                    app.specObj(idx).Receiver.Parameters = jsondecode(app.scpiList.Parameters{idx2});

                    Fcn_TableBuilding(app)

%                     Parameters = jsondecode(app.scpiList.Parameters{idx2});
%                     if ~isfield(Parameters, 'IP');   Parameters.IP = '';   end
%                     if ~isfield(Parameters, 'Port'); Parameters.Port = ''; end
%         
%                     instrSelected  = struct('Name',        app.scpiList.Name{idx2},        ...
%                                             'Type',        app.scpiList.Type{idx2},        ...
%                                             'IP',          Parameters.IP,               ...
%                                             'Port',        str2double(Parameters.Port), ...
%                                             'ConnectType', 'Task',                      ...
%                                             'ResetCmd',    'Off',                       ...
%                                             'SyncType',    'Continuous Sweep');
%         
%                     if isfield(Parameters, 'Localhost_Enable')
%                         instrSelected.Localhost_localIP  = Parameters.Localhost_localIP;
%                         instrSelected.Localhost_publicIP = Parameters.Localhost_publicIP;
%                     end
%         
%                     task_ParametersEditables(app, idx3, idx1)
%                     try
%                         instrreset % apenas para a situação em que tem um objeto que aponta pro mesmo IP.
%                         app.specObj(idx).Receiver.Handle = connect_scpi(instrSelected, app.instrInfo, app.taskList{idx1}.Band);
%             
%                         % IDN Check
%                         if ~isempty(app.specObj(idx).Receiver.Handle.UserData.IDN)
%                             if ~contains(app.specObj(idx).Receiver.Handle.UserData.IDN, app.instrInfo.Tag{idx3})
%                                 error('Esperava-se instrumento da família <b>%s</b>, mas identificado <b>%s</b>.', app.instrInfo.Tag{idx3}, app.specObj(idx).Receiver.Handle.UserData.IDN);
%                             end
%                         else
%                             error('Não recebida resposta ao comando "*IDN?".');
%                         end
%             
%                         if app.instrInfo.connectFlag{idx3} == 2
%                             [app.udpPortArray, udpIndex] = connect_udpSockets(app.udpPortArray, struct('Port', app.General.EB500_udpPort, 'Timeout', 5));
%                             if ~isempty(udpIndex)
%                                 app.specObj(idx).udpPort.Handle = app.udpPortArray{udpIndex};
%                                 flush(app.specObj(idx).udpPort.Handle)
%                             end
%                         end
%         
%                     catch ME
%                         msg = ME.message;
%                         MessageBox(app, 'error', msg)        
%                     end

                case app.table_Open
                    % Pendente

                case app.table_Del
                    % Pendente
            end

        end


        function [BeginTime, EndTime] = task_ObservationTime(app, idx)

            switch app.taskList{idx}.Observation.Type
                case 'Duration'
                    BeginTime = datetime("now", "Format", "dd/MM/yyyy HH:mm:ss");
                    EndTime   = BeginTime + seconds(app.taskList{idx}.Observation.Duration);

                case 'Time'
                    BeginTime = datetime(app.taskList{idx}.Observation.BeginTime, "InputFormat", "dd/MM/yyyy HH:mm:ss", "Format", "dd/MM/yyyy HH:mm:ss");
                    EndTime   = datetime(app.taskList{idx}.Observation.EndTime,   "InputFormat", "dd/MM/yyyy HH:mm:ss", "Format", "dd/MM/yyyy HH:mm:ss");

                case 'Samples'
                    BeginTime = datetime("now", "Format", "dd/MM/yyyy HH:mm:ss");
                    EndTime   = [];
            end

        end

    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            app.UIFigure.Visible = 0;            
            appName = 'appColeta_Task';
                        
            % PATH SEARCH
            Flag = 1;
            if isdeployed
                [~, result]    = system('path');
                app.RootFolder = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));

                if ~isfile(fullfile(app.RootFolder, sprintf('%s.exe', appName)))
                    Flag = 0;
                    MessageBox(app, 'startup', 'Não identificado local de instalação do <i>app</i>.')
                end
                
            else
                prjPath = matlab.project.rootProject;
                appPath = fullfile(char(com.mathworks.appmanagement.MlappinstallUtil.getAppInstallationFolder), appName);
                
                if ~isempty(prjPath) & strcmp(prjPath.Name, appName)
                    app.RootFolder = char(prjPath.RootFolder);
                elseif isfolder(appPath)
                    app.RootFolder = appPath;                    
                else
                    Flag = 0;
                    MessageBox(app, 'startup', 'Não identificado local de instalação do <i>app</i>.')
                end
            end

            % INITIALIZATION            
            if Flag
                try
                    % <LOG>
                    diary(fullfile(app.RootFolder, 'Debug', '_log.txt'))
                    
                    diary on
                    fprintf(sprintf('<LogEntry>\n<BeginTime>%s</BeginTime>\n', datestr(now,'dd/mm/yyyy HH:MM:SS')))
                    % </LOG>

                    warning('off', 'MATLAB:ui:javaframe:PropertyToBeRemoved')
                    warning('off', 'MATLAB:subscripting:noSubscriptsSpecified')
                    warning('off', 'MATLAB:structOnObject')

                    startup_Layout(app)
                    startup_AxesCreation(app)
                    startup_ConfigFiles(app)

                catch ME
                    fprintf('%s\n', jsonencode(ME))
                    MessageBox(app, 'startup', getReport(ME))
                end

                app.UIFigure.Visible = 1;
                drawnow nocallbacks
            end
            
        end

        % Close request function: UIFigure
        function closeFcn(app, event)
            
            delete(app.auxWin1)
            delete(app.auxWin2)
            delete(app.auxWin3)

            delete(app)
            
        end

        % Callback function: UITable
        function UITableSelectionChanged(app, event)

            Fcn_TreeBuilding(app)
            
        end

        % Selection changed function: Tree
        function TreeSelectionChanged(app, event)

            idx1 = app.UITable.Selection;
            idx2 = app.Tree.SelectedNodes.NodeData;

            FreqStart  = app.specObj(idx1).Task.Band(idx2).FreqStart;
            FreqStop   = app.specObj(idx1).Task.Band(idx2).FreqStop;
%             DataPoints = app.specObj(idx1).Band(idx2).DataPoints;

%             xArray  = linspace(FreqStart, FreqStop, DataPoints);
%             yMatrix = app.specObj(idx1).Band(idx2).Matrix;

%             plot(app.axes1, xArray, randn(DataPoints, 1))
            
        end

        % Image clicked function: table_Edit, table_New
        function TableToolbarCallbacks(app, event)
            
            if isempty(app.auxWin1)
                app.d = uiprogressdlg(app.UIFigure, 'Indeterminate', 'on', 'Interpreter', 'html');
                app.d.Message = '<font style="font-size:12;">Em andamento...</font>';

                switch event.Source
                    case app.table_Edit; tempVar = struct('type', 'edit', 'idx', app.UITable.Selection);
                    otherwise;           tempVar = struct('type', 'new');                    
                end

                app.auxWin1 = winTask(app, tempVar);
                drawnow nocallbacks

%                 delete(d)
            else
                figure(app.auxWin1.UIFigure)
            end



%             app.Flag_editing = 1;
%             task_TableToolbarCallbacks(app, event)
% 
%             if ~app.Flag_running
%                 app.Flag_running = 1;
%             end

        end

        % Button pushed function: task_NameEdit
        function task_NameEditButtonPushed(app, event)
            
            if isempty(app.auxWin2)
                d = uiprogressdlg(app.UIFigure, 'Indeterminate', 'on', 'Interpreter', 'html');
                d.Message = '<font style="font-size:12;">Em andamento...</font>';

                app.auxWin2 = winTaskEdit(app);
                drawnow nocallbacks

                delete(d)                
            else
                figure(app.auxWin2.UIFigure)
            end

        end

        % Button pushed function: task_scpiListEdit
        function task_scpiListEditButtonPushed(app, event)
            
            if isempty(app.auxWin3)
                d = uiprogressdlg(app.UIFigure, 'Indeterminate', 'on', 'Interpreter', 'html');
                d.Message = '<font style="font-size:12;">Em andamento...</font>';

                app.auxWin3 = winScpiEdit(app);
                drawnow nocallbacks

                delete(d)
            else
                figure(app.auxWin3.UIFigure)
            end

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 1244 660];
            app.UIFigure.Name = 'appColeta: Tarefas';
            app.UIFigure.Icon = 'LR_icon.png';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeFcn, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {256, '1x'};
            app.GridLayout.RowHeight = {256, 25, '1x', 22};
            app.GridLayout.ColumnSpacing = 5;
            app.GridLayout.RowSpacing = 5;
            app.GridLayout.BackgroundColor = [1 1 1];

            % Create table_Grid
            app.table_Grid = uigridlayout(app.GridLayout);
            app.table_Grid.ColumnWidth = {40, 120, 120, 120, 120, 120, 210, 120, 120, '1x'};
            app.table_Grid.RowHeight = {27, '1x', 20};
            app.table_Grid.ColumnSpacing = 0;
            app.table_Grid.RowSpacing = 0;
            app.table_Grid.Padding = [0 0 0 0];
            app.table_Grid.Layout.Row = 1;
            app.table_Grid.Layout.Column = [1 2];
            app.table_Grid.BackgroundColor = [1 1 1];

            % Create UITable
            app.UITable = uitable(app.table_Grid);
            app.UITable.ColumnName = {''; ''; ''; ''; ''; ''; ''; ''; ''; ''};
            app.UITable.ColumnWidth = {40, 120, 120, 120, 120, 120, 210, 120, 120, '1x'};
            app.UITable.RowName = {};
            app.UITable.SelectionType = 'row';
            app.UITable.SelectionChangedFcn = createCallbackFcn(app, @UITableSelectionChanged, true);
            app.UITable.Multiselect = 'off';
            app.UITable.ForegroundColor = [0.149 0.149 0.149];
            app.UITable.Layout.Row = [1 2];
            app.UITable.Layout.Column = [1 10];
            app.UITable.FontSize = 10;

            % Create Column1
            app.Column1 = uilabel(app.table_Grid);
            app.Column1.FontSize = 10;
            app.Column1.FontWeight = 'bold';
            app.Column1.FontColor = [0.149 0.149 0.149];
            app.Column1.Layout.Row = 1;
            app.Column1.Layout.Column = 1;
            app.Column1.Text = {'  ID'; '  '};

            % Create Column2
            app.Column2 = uilabel(app.table_Grid);
            app.Column2.FontSize = 10;
            app.Column2.FontWeight = 'bold';
            app.Column2.FontColor = [0.149 0.149 0.149];
            app.Column2.Layout.Row = 1;
            app.Column2.Layout.Column = 2;
            app.Column2.Text = {'  Tarefa'; '  '};

            % Create Column3
            app.Column3 = uilabel(app.table_Grid);
            app.Column3.FontSize = 10;
            app.Column3.FontWeight = 'bold';
            app.Column3.FontColor = [0.149 0.149 0.149];
            app.Column3.Layout.Row = 1;
            app.Column3.Layout.Column = 3;
            app.Column3.Text = {'   Inclusão'; '  '};

            % Create Column7
            app.Column7 = uilabel(app.table_Grid);
            app.Column7.FontSize = 10;
            app.Column7.FontWeight = 'bold';
            app.Column7.FontColor = [0.149 0.149 0.149];
            app.Column7.Layout.Row = 1;
            app.Column7.Layout.Column = 4;
            app.Column7.Text = {'  Início'; '  Observação'};

            % Create Column8
            app.Column8 = uilabel(app.table_Grid);
            app.Column8.FontSize = 10;
            app.Column8.FontWeight = 'bold';
            app.Column8.FontColor = [0.149 0.149 0.149];
            app.Column8.Layout.Row = 1;
            app.Column8.Layout.Column = 5;
            app.Column8.Text = {'  Fim'; '  Observação'};

            % Create Column10
            app.Column10 = uilabel(app.table_Grid);
            app.Column10.FontSize = 10;
            app.Column10.FontWeight = 'bold';
            app.Column10.FontColor = [0.149 0.149 0.149];
            app.Column10.Layout.Row = 1;
            app.Column10.Layout.Column = 6;
            app.Column10.Text = {'  Estado'; '  '};

            % Create Export_Grid
            app.Export_Grid = uigridlayout(app.table_Grid);
            app.Export_Grid.ColumnWidth = {16, 16, 5, 16, 16, 16};
            app.Export_Grid.RowHeight = {'1x'};
            app.Export_Grid.ColumnSpacing = 2;
            app.Export_Grid.RowSpacing = 5;
            app.Export_Grid.Padding = [0 0 0 2];
            app.Export_Grid.Layout.Row = 3;
            app.Export_Grid.Layout.Column = [1 7];
            app.Export_Grid.BackgroundColor = [1 1 1];

            % Create table_Del
            app.table_Del = uiimage(app.Export_Grid);
            app.table_Del.Enable = 'off';
            app.table_Del.Tooltip = {'Excluir tarefa'};
            app.table_Del.Layout.Row = 1;
            app.table_Del.Layout.Column = 6;
            app.table_Del.ImageSource = 'LT_redX.png';

            % Create table_New
            app.table_New = uiimage(app.Export_Grid);
            app.table_New.ImageClickedFcn = createCallbackFcn(app, @TableToolbarCallbacks, true);
            app.table_New.Tooltip = {'Nova tarefa'};
            app.table_New.Layout.Row = 1;
            app.table_New.Layout.Column = 4;
            app.table_New.ImageSource = 'LT_AddFiles.png';

            % Create table_Edit
            app.table_Edit = uiimage(app.Export_Grid);
            app.table_Edit.ImageClickedFcn = createCallbackFcn(app, @TableToolbarCallbacks, true);
            app.table_Edit.Enable = 'off';
            app.table_Edit.Tooltip = {'Editar tarefa'};
            app.table_Edit.Layout.Row = 1;
            app.table_Edit.Layout.Column = 5;
            app.table_Edit.ImageSource = 'LT_edit.png';

            % Create table_Stop
            app.table_Stop = uiimage(app.Export_Grid);
            app.table_Stop.Enable = 'off';
            app.table_Stop.Tooltip = {'Parar tarefa'};
            app.table_Stop.Layout.Row = 1;
            app.table_Stop.Layout.Column = 2;
            app.table_Stop.ImageSource = 'LT_stop.png';

            % Create table_Play
            app.table_Play = uiimage(app.Export_Grid);
            app.table_Play.Enable = 'off';
            app.table_Play.Tooltip = {'Executar tarefa'};
            app.table_Play.Layout.Row = 1;
            app.table_Play.Layout.Column = 1;
            app.table_Play.ImageSource = 'LT_play.png';

            % Create table_Separator
            app.table_Separator = uiimage(app.Export_Grid);
            app.table_Separator.Layout.Row = 1;
            app.table_Separator.Layout.Column = 3;
            app.table_Separator.ImageSource = 'LT_LineV.png';

            % Create Column5
            app.Column5 = uilabel(app.table_Grid);
            app.Column5.FontSize = 10;
            app.Column5.FontWeight = 'bold';
            app.Column5.FontColor = [0.149 0.149 0.149];
            app.Column5.Layout.Row = 1;
            app.Column5.Layout.Column = 7;
            app.Column5.Text = {'  Receptor'; '  '};

            % Create Column5_2
            app.Column5_2 = uilabel(app.table_Grid);
            app.Column5_2.FontSize = 10;
            app.Column5_2.FontWeight = 'bold';
            app.Column5_2.FontColor = [0.149 0.149 0.149];
            app.Column5_2.Layout.Row = 1;
            app.Column5_2.Layout.Column = 8;
            app.Column5_2.Text = {'  Streaming'; '  (Porta)'};

            % Create Column5_3
            app.Column5_3 = uilabel(app.table_Grid);
            app.Column5_3.FontSize = 10;
            app.Column5_3.FontWeight = 'bold';
            app.Column5_3.FontColor = [0.149 0.149 0.149];
            app.Column5_3.Layout.Row = 1;
            app.Column5_3.Layout.Column = 9;
            app.Column5_3.Text = {'  GPS'; '  '};

            % Create Column5_4
            app.Column5_4 = uilabel(app.table_Grid);
            app.Column5_4.FontSize = 10;
            app.Column5_4.FontWeight = 'bold';
            app.Column5_4.FontColor = [0.149 0.149 0.149];
            app.Column5_4.Layout.Row = 1;
            app.Column5_4.Layout.Column = 10;
            app.Column5_4.Text = {'  Comutador'; '  Antenas'};

            % Create Panel
            app.Panel = uipanel(app.GridLayout);
            app.Panel.AutoResizeChildren = 'off';
            app.Panel.BorderType = 'none';
            app.Panel.BackgroundColor = [1 1 1];
            app.Panel.Layout.Row = 3;
            app.Panel.Layout.Column = 2;

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.GridLayout);
            app.GridLayout3.ColumnWidth = {22, 5, 22, 22, '1x', 22, 22, 22, 22, 5, 22};
            app.GridLayout3.RowHeight = {'1x'};
            app.GridLayout3.ColumnSpacing = 5;
            app.GridLayout3.RowSpacing = 5;
            app.GridLayout3.Padding = [0 0 0 0];
            app.GridLayout3.Layout.Row = 4;
            app.GridLayout3.Layout.Column = [1 2];
            app.GridLayout3.BackgroundColor = [1 1 1];

            % Create task_scpiListEdit
            app.task_scpiListEdit = uibutton(app.GridLayout3, 'push');
            app.task_scpiListEdit.ButtonPushedFcn = createCallbackFcn(app, @task_scpiListEditButtonPushed, true);
            app.task_scpiListEdit.Tag = 'task_Editable';
            app.task_scpiListEdit.Icon = 'LT_connect.png';
            app.task_scpiListEdit.BackgroundColor = [0.9608 0.9608 0.9608];
            app.task_scpiListEdit.Tooltip = {'Editar lista de instrumentos '; '(Analisador de espectro, receptor e GPS)'};
            app.task_scpiListEdit.Layout.Row = 1;
            app.task_scpiListEdit.Layout.Column = 4;
            app.task_scpiListEdit.Text = '';

            % Create Image4
            app.Image4 = uiimage(app.GridLayout3);
            app.Image4.Layout.Row = 1;
            app.Image4.Layout.Column = 9;
            app.Image4.ImageSource = 'tb_maxHold.gif';

            % Create Image3
            app.Image3 = uiimage(app.GridLayout3);
            app.Image3.Layout.Row = 1;
            app.Image3.Layout.Column = 8;
            app.Image3.ImageSource = 'tb_meanHold.gif';

            % Create Image
            app.Image = uiimage(app.GridLayout3);
            app.Image.Layout.Row = 1;
            app.Image.Layout.Column = 6;
            app.Image.ImageSource = 'LR_Persistance.png';

            % Create Image2
            app.Image2 = uiimage(app.GridLayout3);
            app.Image2.Layout.Row = 1;
            app.Image2.Layout.Column = 7;
            app.Image2.ImageSource = 'tb_minHold.gif';

            % Create Image5
            app.Image5 = uiimage(app.GridLayout3);
            app.Image5.Layout.Row = 1;
            app.Image5.Layout.Column = 10;
            app.Image5.ImageSource = 'LT_LineV.png';

            % Create task_scpiListEdit_2
            app.task_scpiListEdit_2 = uibutton(app.GridLayout3, 'push');
            app.task_scpiListEdit_2.Tag = 'task_Editable';
            app.task_scpiListEdit_2.Icon = 'tb_waterfall.gif';
            app.task_scpiListEdit_2.BackgroundColor = [0.9608 0.9608 0.9608];
            app.task_scpiListEdit_2.Tooltip = {'Editar lista de instrumentos '; '(Analisador de espectro, receptor e GPS)'};
            app.task_scpiListEdit_2.Layout.Row = 1;
            app.task_scpiListEdit_2.Layout.Column = 11;
            app.task_scpiListEdit_2.Text = '';

            % Create task_NameEdit
            app.task_NameEdit = uibutton(app.GridLayout3, 'push');
            app.task_NameEdit.ButtonPushedFcn = createCallbackFcn(app, @task_NameEditButtonPushed, true);
            app.task_NameEdit.Tag = 'task_Editable';
            app.task_NameEdit.Icon = 'LT_edit.png';
            app.task_NameEdit.BackgroundColor = [0.9608 0.9608 0.9608];
            app.task_NameEdit.Tooltip = {'Parametrização'; 'Tarefa SCPI'};
            app.task_NameEdit.Layout.Row = 1;
            app.task_NameEdit.Layout.Column = 3;
            app.task_NameEdit.Text = '';

            % Create task_NameEdit_2
            app.task_NameEdit_2 = uibutton(app.GridLayout3, 'push');
            app.task_NameEdit_2.Tag = 'task_Editable';
            app.task_NameEdit_2.Icon = 'LT_edit.png';
            app.task_NameEdit_2.BackgroundColor = [0.9608 0.9608 0.9608];
            app.task_NameEdit_2.Tooltip = {'Parametrização'; 'Tarefa SCPI'};
            app.task_NameEdit_2.Layout.Row = 1;
            app.task_NameEdit_2.Layout.Column = 1;
            app.task_NameEdit_2.Text = '';

            % Create Image6
            app.Image6 = uiimage(app.GridLayout3);
            app.Image6.Layout.Row = 1;
            app.Image6.Layout.Column = 2;
            app.Image6.ImageSource = 'LT_LineV.png';

            % Create FaixasdefrequnciarelacionadastarefaselecionadaLabel
            app.FaixasdefrequnciarelacionadastarefaselecionadaLabel = uilabel(app.GridLayout);
            app.FaixasdefrequnciarelacionadastarefaselecionadaLabel.VerticalAlignment = 'bottom';
            app.FaixasdefrequnciarelacionadastarefaselecionadaLabel.WordWrap = 'on';
            app.FaixasdefrequnciarelacionadastarefaselecionadaLabel.FontSize = 10;
            app.FaixasdefrequnciarelacionadastarefaselecionadaLabel.FontWeight = 'bold';
            app.FaixasdefrequnciarelacionadastarefaselecionadaLabel.Layout.Row = 2;
            app.FaixasdefrequnciarelacionadastarefaselecionadaLabel.Layout.Column = 1;
            app.FaixasdefrequnciarelacionadastarefaselecionadaLabel.Text = 'Faixa(s) de frequência relacionada(s) à tarefa selecionada:';

            % Create Tree
            app.Tree = uitree(app.GridLayout);
            app.Tree.SelectionChangedFcn = createCallbackFcn(app, @TreeSelectionChanged, true);
            app.Tree.FontSize = 10;
            app.Tree.Layout.Row = 3;
            app.Tree.Layout.Column = 1;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = winMain_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end