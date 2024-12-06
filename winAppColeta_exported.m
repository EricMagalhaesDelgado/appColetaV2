classdef winAppColeta_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure              matlab.ui.Figure
        GridLayout            matlab.ui.container.GridLayout
        popupContainerGrid    matlab.ui.container.GridLayout
        SplashScreen          matlab.ui.control.Image
        popupContainer        matlab.ui.container.Panel
        menu_Grid             matlab.ui.container.GridLayout
        dockModule_Undock     matlab.ui.control.Image
        dockModule_Close      matlab.ui.control.Image
        AppInfo               matlab.ui.control.Image
        FigurePosition        matlab.ui.control.Image
        jsBackDoor            matlab.ui.control.HTML
        menu_Button6          matlab.ui.control.StateButton
        menu_Button5          matlab.ui.control.StateButton
        menu_Separator2       matlab.ui.control.Image
        menu_Button4          matlab.ui.control.StateButton
        menu_Button3          matlab.ui.control.StateButton
        menu_Button2          matlab.ui.control.StateButton
        menu_Separator1       matlab.ui.control.Image
        menu_Button1          matlab.ui.control.StateButton
        TabGroup              matlab.ui.container.TabGroup
        Tab1_Task             matlab.ui.container.Tab
        task_Grid             matlab.ui.container.GridLayout
        task_toolGrid         matlab.ui.container.GridLayout
        task_TopPanel         matlab.ui.control.Image
        task_LeftPanel        matlab.ui.control.Image
        task_RightPanel       matlab.ui.control.Image
        task_ButtonLOG        matlab.ui.control.Button
        task_Separator2       matlab.ui.control.Image
        task_ButtonDel        matlab.ui.control.Button
        task_ButtonPlay       matlab.ui.control.Button
        task_RevisitTime      matlab.ui.control.Label
        task_Status           matlab.ui.control.Label
        task_docGrid          matlab.ui.container.GridLayout
        TaskInfo_Panel        matlab.ui.container.GridLayout
        lastGPS_Panel         matlab.ui.container.Panel
        lastGPS_Grid1         matlab.ui.container.GridLayout
        errorCount_img_2      matlab.ui.control.Image
        errorCount_txt_2      matlab.ui.control.Label
        lastGPS_Grid2         matlab.ui.container.GridLayout
        lastGPS_color         matlab.ui.control.Lamp
        lastGPS_text          matlab.ui.control.Label
        lastGPS_label         matlab.ui.control.Label
        lastMask_Panel        matlab.ui.container.Panel
        lastMask_Grid         matlab.ui.container.GridLayout
        lastMask_text         matlab.ui.control.Label
        lastMask_label        matlab.ui.control.Label
        Sweeps_Panel          matlab.ui.container.Panel
        Sweeps_Grid           matlab.ui.container.GridLayout
        errorCount_img        matlab.ui.control.Image
        errorCount_txt        matlab.ui.control.Label
        Sweeps                matlab.ui.control.Label
        Sweeps_Label          matlab.ui.control.Label
        Sweeps_REC            matlab.ui.control.Image
        PlotTool_Grid         matlab.ui.container.GridLayout
        Button_MaskPlot       matlab.ui.control.StateButton
        Button_Layout         matlab.ui.control.Button
        Button_peakExcursion  matlab.ui.control.StateButton
        Button_MaxHold        matlab.ui.control.StateButton
        Button_Average        matlab.ui.control.StateButton
        Button_MinHold        matlab.ui.control.StateButton
        Plot_Panel            matlab.ui.container.Panel
        MetaData_Panel        matlab.ui.container.Panel
        MetaData_Grid         matlab.ui.container.GridLayout
        MetaData              matlab.ui.control.HTML
        Tree                  matlab.ui.container.Tree
        Tree_Label            matlab.ui.control.Label
        Table                 matlab.ui.control.Table
        Tab3_InstrumentList   matlab.ui.container.Tab
        Tab2_TaskList         matlab.ui.container.Tab
        TASKADDTab            matlab.ui.container.Tab
        Tab4_Server           matlab.ui.container.Tab
        Tab5_Config           matlab.ui.container.Tab
    end

    
    properties (Access = public)
        %-----------------------------------------------------------------%
        % PROPRIEDADES COMUNS A TODOS OS APPS
        %-----------------------------------------------------------------%
        General
        General_I
        rootFolder

        % Essa propriedade registra o tipo de execução da aplicação, podendo
        % ser: 'built-in', 'desktopApp' ou 'webApp'.
        executionMode

        % A função do timer é executada uma única vez após a renderização
        % da figura, lendo arquivos de configuração, iniciando modo de operação
        % paralelo etc. A ideia é deixar o MATLAB focar apenas na criação dos 
        % componentes essenciais da GUI (especificados em "createComponents"), 
        % mostrando a GUI para o usuário o mais rápido possível.
        timerObj_startup

        % O MATLAB não renderiza alguns dos componentes de abas (do TabGroup) 
        % não visíveis. E a customização de componentes, usando a lib ccTools, 
        % somente é possível após a sua renderização. Controla-se a aplicação 
        % da customizaçao por meio dessa propriedade jsBackDoorFlag.
        tabGroupController
        jsBackDoorFlag = true(2, 1);

        % Janela de progresso já criada no DOM. Dessa forma, controla-se 
        % apenas a sua visibilidade - e tornando desnecessário criá-la a
        % cada chamada (usando uiprogressdlg, por exemplo).
        progressDialog

        % Objeto que possibilita integração com o FISCALIZA, consumindo lib
        % escrita em Python (fiscaliza).
        fiscalizaObj

        %-----------------------------------------------------------------%
        % PROPRIEDADES ESPECÍFICAS
        %-----------------------------------------------------------------%
        specObj
        revisitObj
        timerObj_task
        taskList

        Flag_running = 0
        Flag_editing = 0
        plotLayout   = 1

        %-----------------------------------------------------------------%
        % PLOT
        %-----------------------------------------------------------------%
        axes1
        axes2
        
        line_ClrWrite
        line_MinHold
        line_Average
        line_MaxHold
        peakExcursion
        surface_WFall

        %-----------------------------------------------------------------%
        % COMMUNICATION
        %-----------------------------------------------------------------%
        tcpServer
        
        receiverObj
        gpsObj
        udpPortArray = {}

        EB500Obj
        EMSatObj
        ERMxObj
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % JSBACKDOOR
        %-----------------------------------------------------------------%
        function jsBackDoor_Initialization(app)
            app.jsBackDoor.HTMLSource           = ccTools.fcn.jsBackDoorHTMLSource;
            app.jsBackDoor.HTMLEventReceivedFcn = @(~, evt)jsBackDoor_Listener(app, evt);
        end

        %-----------------------------------------------------------------%
        function jsBackDoor_Listener(app, event)
            switch event.HTMLEventName
                case 'BackgroundColorTurnedInvisible'
                    switch event.HTMLEventData
                        case 'SplashScreen'
                            if isvalid(app.SplashScreen)
                                delete(app.SplashScreen)
                                app.popupContainerGrid.Visible = 0;
                            end
                        otherwise
                            % ...
                    end
            end
            drawnow
        end

        %-----------------------------------------------------------------%
        function jsBackDoor_Customizations(app, tabIndex)
            switch tabIndex
                case 0 % STARTUP
                    % Cria um ProgressDialog...
                    app.progressDialog = ccTools.ProgressDialog(app.jsBackDoor);
        
                    % Customizações dos componentes...
                    sendEventToHTMLSource(app.jsBackDoor, 'htmlClassCustomization', struct('className',        'body',                           ...
                                                                                           'classAttributes', ['--tabButton-border-color: #fff;' ...
                                                                                                               '--tabContainer-border-color: #fff;']));
        
                    sendEventToHTMLSource(app.jsBackDoor, 'htmlClassCustomization', struct('className',        '.mw-theme-light',                                                   ...
                                                                                           'classAttributes', ['--mw-backgroundColor-dataWidget-selected: rgb(180 222 255 / 45%); ' ...
                                                                                                               '--mw-backgroundColor-selected: rgb(180 222 255 / 45%); '            ...
                                                                                                               '--mw-backgroundColor-selectedFocus: rgb(180 222 255 / 45%);'        ...
                                                                                                               '--mw-backgroundColor-tab: #fff;']));
        
                    sendEventToHTMLSource(app.jsBackDoor, 'htmlClassCustomization', struct('className',        '.mw-default-header-cell', ...
                                                                                           'classAttributes',  'font-size: 10px; white-space: pre-wrap; margin-bottom: 5px;'));
                    
                    ccTools.compCustomizationV2(app.jsBackDoor, app.popupContainerGrid, 'backgroundColor', 'rgba(255,255,255,0.65)')
                    sendEventToHTMLSource(app.jsBackDoor, "panelDialog", struct('componentDataTag', struct(app.popupContainer).Controller.ViewModel.Id)) 

                case 1 % TASK:VIEW
                    % ...

                otherwise
                    % ...
            end
        end
    end

    
    methods (Access = private)
        %-----------------------------------------------------------------%
        % INICIALIZAÇÃO DO APP
        %-----------------------------------------------------------------%
        function startup_timerCreation(app)
            app.timerObj_startup = timer("ExecutionMode", "fixedSpacing", ...
                                         "StartDelay",    1.5,            ...
                                         "Period",        .1,             ...
                                         "TimerFcn",      @(~,~)app.startup_timerFcn);
            start(app.timerObj_startup)
        end

        %-----------------------------------------------------------------%
        function startup_timerFcn(app)
            if ccTools.fcn.UIFigureRenderStatus(app.UIFigure)
                stop(app.timerObj_startup)
                drawnow

                app.executionMode = appUtil.ExecutionMode(app.UIFigure);
                appUtil.winMinSize(app.UIFigure, class.Constants.windowMinSize)

                appName           = class.Constants.appName;
                MFilePath         = fileparts(mfilename('fullpath'));
                app.rootFolder    = appUtil.RootFolder(appName, MFilePath);

                % Customiza as aspectos estéticos de alguns dos componentes da GUI 
                % (diretamente em JS).
                jsBackDoor_Customizations(app, 0)

                % Trecho migrado de "startupFcn" para "startup_timerFcn",
                % evitando que seja executado antes da renderização do app.
                startup_ConfigFileRead(app)
                startup_AppProperties(app)
                startup_GUIComponents(app)

                RegularTask_timerCreation(app)
                if app.General.startupInfo
                    startup_specObjRead(app)
                end

                % Torna visível o container do auxApp.popupContainer, forçando
                % a exclusão do SplashScreen.
                sendEventToHTMLSource(app.jsBackDoor, 'turningBackgroundColorInvisible', struct('componentName', 'SplashScreen', 'componentDataTag', struct(app.SplashScreen).Controller.ViewModel.Id));
                drawnow

                % Força a exclusão do SplashScreen.
                app.TabGroup.Visible = 1;
                if isvalid(app.SplashScreen)
                    pause(1)
                    delete(app.SplashScreen)
                    app.popupContainerGrid.Visible = 0;
                end
            end
        end

        %-----------------------------------------------------------------%
        function startup_ConfigFileRead(app)
            % "GeneralSettings.json"
            [app.General_I, msgWarning] = appUtil.generalSettingsLoad(class.Constants.appName, app.rootFolder);
            if ~isempty(msgWarning)
                appUtil.modalWindow(app.UIFigure, 'error', msgWarning);
            end            

            % Para criação de arquivos temporários, cria-se uma pasta da 
            % sessão.
            tempDir = tempname;
            mkdir(tempDir)
            app.General_I.fileFolder.tempPath = tempDir;

            % Resgata a pasta de trabalho do usuário (configurável).
            userPaths = appUtil.UserPaths(app.General_I.fileFolder.userPath);
            app.General_I.fileFolder.userPath = userPaths{end};

            switch app.executionMode
                case 'desktopStandaloneApp'
                    app.General_I.operationMode.Debug = false;
                case 'MATLABEnvironment'
                    app.General_I.operationMode.Debug = true;
                    app.General_I.operationMode.Dock  = true;               % APENAS PARA TESTE! REMOVER DEPOIS.
            end
            
            app.General = app.General_I;            
            app.General.AppVersion = fcn.envVersion(app.rootFolder);
            app.General.stationInfo.Computer = getenv('COMPUTERNAME');            
        end

        %-----------------------------------------------------------------%
        function startup_AppProperties(app)
            % app.taskList
            [app.taskList, msgError] =  class.taskList.file2raw(fullfile(app.rootFolder, 'Settings', 'taskList.json'), 'winAppColetaV2');
            if ~isempty(msgError)
                appUtil.modalWindow(app.UIFigure, 'error', msgError);
            end

            % Others...
            app.specObj     = class.specClass.empty;
            app.receiverObj = class.ReceiverLib(app.rootFolder);
            app.gpsObj      = class.GPSLib(app.rootFolder);            
            app.EB500Obj    = class.EB500Lib(app.rootFolder);
            app.EMSatObj    = class.EMSatLib(app.rootFolder);
            app.ERMxObj     = class.ERMxLib(app.rootFolder);            

            if app.General.tcpServer.Status
                try
                    app.tcpServer = class.tcpServerLib(app);
                catch
                    app.tcpServer = [];
                end
            end
        end

        %-----------------------------------------------------------------%
        function startup_GUIComponents(app)
            % Cria o objeto que conecta o TabGroup com o GraphicMenu.
            app.tabGroupController = tabGroupGraphicMenu(app.menu_Grid, app.TabGroup, app.progressDialog, @app.jsBackDoor_Customizations, '');

            addComponent(app.tabGroupController, "Built-in", "",                     app.menu_Button1, "AlwaysOn", struct('On', 'Playback_32Yellow.png', 'Off', 'Playback_32White.png'), matlab.graphics.GraphicsPlaceholder, 1)
            addComponent(app.tabGroupController, "External", "auxApp.winInstrument", app.menu_Button2, "AlwaysOn", struct('On', 'Connect_36Yellow.png',  'Off', 'Connect_36White.png'),  app.menu_Button1,                    2)
            addComponent(app.tabGroupController, "External", "auxApp.winTaskList",   app.menu_Button3, "AlwaysOn", struct('On', 'Task_36Yellow.png',     'Off', 'Task_36White.png'),     app.menu_Button1,                    3)
            addComponent(app.tabGroupController, "External", "auxApp.winAddTask",    app.menu_Button4, "AlwaysOn", struct('On', 'AddFile_36Yellow.png',  'Off', 'AddFile_36White.png'),  app.menu_Button1,                    4)
            addComponent(app.tabGroupController, "External", "auxApp.winServer",     app.menu_Button5, "AlwaysOn", struct('On', 'Server_36Yellow.png',   'Off', 'Server_36White.png'),   app.menu_Button1,                    5)
            addComponent(app.tabGroupController, "External", "auxApp.winSettings",   app.menu_Button6, "AlwaysOn", struct('On', 'Settings_36Yellow.png', 'Off', 'Settings_36White.png'), app.menu_Button1,                    6)

            startup_Axes(app)
        end

        %-----------------------------------------------------------------%
        function startup_Axes(app)
            t = tiledlayout(app.Plot_Panel, 3, 1, "Padding", "tight", "TileSpacing", "tight");

            % app.axes1
            app.axes1 = uiaxes(t);
            app.axes1.Layout.Tile = 1;
            set(app.axes1, Color=[0 0 0], FontName='Helvetica', FontSize=9, FontSmoothing='on',     ...
                                          XGrid='on', XMinorGrid='on', YGrid='on', YMinorGrid='on', ...
                                          GridAlpha=.25, GridColor=[.94,.94,.94], MinorGridAlpha=.2, MinorGridColor=[.94,.94,.94], XTickLabel={}, ...
                                          Interactions=[])
            ylabel(app.axes1, 'Nível (dB)')

            % app.axes2
            app.axes2 = uiaxes(t);
            app.axes2.Layout.Tile = 2;
            app.axes2.Layout.TileSpan = [2,1];
            set(app.axes2, Color=[.98,.98,.98], FontName='Helvetica', FontSize=9, FontSmoothing='on', ...
                                                Interactions=[])
            xlabel(app.axes2, 'Frequência (MHz)')
            ylabel(app.axes2, 'Amostras')

            % Others aspects...
            hold(app.axes1, 'on')
            hold(app.axes2, 'on')

            Interactions = class.Constants.Interactions;
            plotFcn.axesInteractions(app.axes1, Interactions)
            plotFcn.axesInteractions(app.axes2, Interactions)

            linkaxes([app.axes1, app.axes2], 'x')
            task_ButtonPushed_plotLayout(app)

            try
                eval(sprintf('opengl %s', app.General.openGL))
            catch
            end
        end

        %-----------------------------------------------------------------%
        function startup_specObjRead(app)

            if isfile(fullfile(app.rootFolder, 'Settings', 'startupInfo.mat'))
                app.progressDialog.Visible = 'visible';

                load(fullfile(app.rootFolder, 'Settings', 'startupInfo.mat'), 'SpecObj');

                % É possível que o MATLAB não consiga instancionar o objeto
                % "class.specClass", lendo-o como "uint32", o que inviabiliza 
                % o aproveitamento da informação salva...

                % Warning: Variable 'SpecObj' originally saved as a class.specClass cannot be instantiated as an object and will be read in as a uint32.

                if exist('SpecObj', 'var') && isa(SpecObj, 'class.specClass') && ~isempty(SpecObj)
                    for ii = 1:numel(SpecObj)
                        SpecObj(ii) = startup_specObjRead_Receiver(app, SpecObj(ii));
                        SpecObj(ii) = startup_specObjRead_Streaming(app, SpecObj(ii));
                        SpecObj(ii) = startup_specObjRead_GPS(app, SpecObj(ii));

                        if ismember(SpecObj(ii).Status, {'Na fila', 'Em andamento'})
                            SpecObj(ii).Status = 'Erro';
                        end
                    end

                    app.specObj = SpecObj;                    

                    Layout_tableBuilding(app, 1)
                    task_TreeSelectionChanged(app)

                    % Ida ao modo de "Execução das tarefas da monitoração"
                    % de forma programática:
                    app.menu_Button1.Value = 1;
                    menu_mainButtonPushed(app, struct('Source', app.menu_Button1, 'PreviousValue', 0))
                end

                app.progressDialog.Visible = 'hidden';
            end
        end


        %-----------------------------------------------------------------%
        function [SpecObj, msgError] = startup_specObjRead_Receiver(app, SpecObj)

            % Função funcionalmente idêntica à fcn.ConnectivityTest_Receiver.
            % A "duplicação" garante que seja usado a informação constante
            % no objeto SpecObj, ao invés da informação constante no arquivo 
            % "instrumentList.json", que pode ter sido editado.

            idx1 = find(strcmp(app.receiverObj.Config.Name, SpecObj.Task.Receiver.Selection.Name{1}), 1);
            instrSelected = struct('Type',       SpecObj.Task.Receiver.Selection.Type{1}, ...
                                   'Tag',        app.receiverObj.Config.Tag{idx1},        ...
                                   'Parameters', jsondecode(SpecObj.Task.Receiver.Selection.Parameters{1}));
            
            [idx2, msgError] = app.receiverObj.Connect(instrSelected);            
            
            if isempty(msgError)
                SpecObj.Task.Receiver.Handle = app.receiverObj.Table.Handle{idx2};
                SpecObj.hReceiver            = SpecObj.Task.Receiver.Handle;
            end
        end


        %-----------------------------------------------------------------%
        function SpecObj = startup_specObjRead_Streaming(app, SpecObj)

            receiverName = SpecObj.Task.Receiver.Selection.Name{1};
            taskType     = SpecObj.Task.Type;

            idx1 = SelectedReceiverIndex(app, receiverName, taskType);
            if ismember(app.receiverObj.Config.connectFlag(idx1), [2, 3])
                [app.udpPortArray, idx2] = fcn.udpSockets(app.udpPortArray, app.EB500Obj.udpPort);
                if ~isempty(idx2)
                    SpecObj.Task.Streaming.Handle = app.udpPortArray{idx2};
                    SpecObj.hStreaming            = SpecObj.Task.Streaming.Handle;
                end
            end
        end


        %-----------------------------------------------------------------%
        function [SpecObj, msgError] = startup_specObjRead_GPS(app, SpecObj)

            % Função funcionalmente idêntica à fcn.ConnectivityTest_GPS.
            % A "duplicação" garante que seja usado a informação constante
            % no objeto SpecObj, ao invés da informação constante no arquivo 
            % "instrumentList.json", que pode ter sido editado.

            msgError = '';

            if ~isempty(SpecObj.Task.GPS.Selection)
                instrSelected = struct('Type',       SpecObj.Task.GPS.Selection.Type{1}, ...
                                       'Parameters', jsondecode(SpecObj.Task.GPS.Selection.Parameters{1}));

                [idx2, msgError] = app.gpsObj.Connect(instrSelected);
                if isempty(msgError)
                    SpecObj.Task.GPS.Handle = app.gpsObj.Table.Handle{idx2};
                    SpecObj.GPS             = SpecObj.Task.GPS.Handle;
                end
            end
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % CHAVEANDO ENTRE MÓDULOS
        %-----------------------------------------------------------------%
        function inputArguments = menu_auxAppInputArguments(app, auxAppName)
            arguments
                app
                auxAppName char {mustBeMember(auxAppName, {'TASK:VIEW', 'INSTRUMENT', 'TASK:EDIT', 'TASK:ADD', 'SERVER', 'CONFIG'})}
            end

            switch auxAppName
                case 'TASK:ADD'
                    [~, idxApp] = ismember(auxAppName, app.tabGroupController.Components.Tag);
                    appHandle   = app.tabGroupController.Components.appHandle{idxApp};
                    if ~isempty(appHandle) && isvalid(appHandle)
                        inputArguments = {app, appHandle.infoEdition};
                    else
                        inputArguments = {app, struct('type', 'new')};
                    end
                otherwise
                    inputArguments = {app};
            end
        end

        %-----------------------------------------------------------------%
        function menu_LayoutPopupApp(app, auxAppName, varargin)
            arguments
                app
                auxAppName char {mustBeMember(auxAppName, {'AddTask', 'Tracking'})}
            end

            arguments (Repeating)
                varargin 
            end

            % Inicialmente ajusta as dimensões do container.
            switch auxAppName
                case 'AddTask';  screenWidth = 1045; screenHeight = 540;
                case 'Tracking'; screenWidth =  622; screenHeight = 302;
            end

            app.popupContainerGrid.ColumnWidth{2} = screenWidth;
            app.popupContainerGrid.RowHeight{3}   = screenHeight-180;

            % Executa o app auxiliar, mas antes tenta configurar transparência
            % do BackgroundColor do Grid (caso não tenha sido aplicada anteriormente).
            ccTools.compCustomizationV2(app.jsBackDoor, app.popupContainerGrid, 'backgroundColor', 'rgba(255,255,255,0.65')
            inputArguments = [{app}, varargin];
            eval(sprintf('auxApp.dock%s_exported(app.popupContainer, inputArguments{:})', auxAppName))
            app.popupContainerGrid.Visible = 1;
        end

        %-----------------------------------------------------------------%
        function idx = SelectedReceiverIndex(app, receiverName, taskType)
            idx = find(strcmp(app.receiverObj.Config.Name, receiverName));
            if numel(idx) > 1
                connectFlagList = app.receiverObj.Config.connectFlag(idx);
                if contains(taskType, 'Drive-test (Level+Azimuth)')
                    idx = idx(connectFlagList == 3);
                else
                    idx = idx(connectFlagList ~= 3);
                end
                idx = idx(1);
            end
        end


        %-----------------------------------------------------------------%
        % TIMER 
        %-----------------------------------------------------------------%
        function RegularTask_timerCreation(app)
            app.timerObj_task = timer("ExecutionMode", "fixedRate", ...
                                      "Period",        10,          ...
                                      "TimerFcn",      @(~,~)app.RegularTask_timerFcn);
            start(app.timerObj_task)
        end


        %-----------------------------------------------------------------%
        function RegularTask_timerFcn(app)
            if ~app.Flag_running
                Flag = false;
                for ii = 1:numel(app.specObj)
                    if RegularTask_StatusTaskCheck(app, ii, '')
                        Flag = true;
                        break
                    end
                end

                if Flag
                    RegularTask_MainLoop(app)
                end
            end

            if numel(app.specObj) ~= height(app.Table.Data)
                Layout_tableBuilding(app, app.Table.Selection)
                task_TreeSelectionChanged(app)
            end
        end


        %-----------------------------------------------------------------%
        % REGULAR TASK
        %-----------------------------------------------------------------%
        function RegularTask_specObjSave(app)

            % Ao salvar "app.specObj" em um arquivo .MAT, reabrindo-o
            % posteriormente, os objetos de comunicação (tcpclient, por
            % exemplo) não retém o valor da propriedade "UserData".
            %
            % Por essa razão, esses objetos não serão salvos, devendo ser
            % recriados na inicialização do app.

            SpecObj = copy(app.specObj);
            
            for ii = 1:numel(SpecObj)
                SpecObj(ii).hReceiver  = [];
                SpecObj(ii).hStreaming = [];
                SpecObj(ii).hGPS       = [];

                SpecObj(ii).Task.Receiver.Handle  = [];
                SpecObj(ii).Task.Streaming.Handle = [];
                SpecObj(ii).Task.GPS.Handle       = [];
            end

            save(fullfile(app.rootFolder, 'Settings', 'startupInfo.mat'), 'SpecObj')
        end


        %-----------------------------------------------------------------%
        function Flag = RegularTask_StatusTaskCheck(app, idx, evtName)
            % Função responsável por trocar o estado das tarefas, de "Na
            % fila" para "Em andamento", "Em andamento" para "Cancelada",
            % "Em andamento" para "Erro" e por aí vai...
            %
            % Lembrando que o estado de uma nova tarefa é "Na fila", exceto
            % quando ocorre algum erro no processo de criação (decorrente 
            % de uma configuração de um parâmetro não aceito pelo receptor,
            % por exemplo). Nesse caso, o estado será "Erro".
            %
            % Caso não exista alguma tarefa em execução, o app.Flag_running
            % será igual a 0, e o app.timerObj estará ativo, o que o fará
            % avaliar a cada minuto o estado de todas as tarefas, nesta 
            % função, de forma que:
            % (a) Seja iniciada uma tarefa no estado "Na fila";
            % (b) Seja realizada uma nova tentativa de iniciar uma tarefa 
            %     no estado "Erro" (o que ocorrerá a cada 15 minutos).
            
            Timestamp = datetime('now');

            Flag = false;
            initialStatus = app.specObj(idx).Status;
            
            switch app.specObj(idx).Status
                case 'Em andamento'
                    if app.specObj(idx).Observation.EndTime < Timestamp || ismember(evtName, {'DeleteButtonPushed', 'ErrorTrigger'})
                        Flag = true;

                        if app.specObj(idx).Observation.EndTime < Timestamp
                            app.specObj(idx).Status = 'Concluída';
                        else
                            switch evtName
                                case 'DeleteButtonPushed'
                                    app.specObj(idx).Status = 'Cancelada';
                                case 'ErrorTrigger'
                                    app.specObj(idx).Status = 'Erro';
                            end
                        end
                        
                        app.specObj(idx).hReceiver.UserData.nTasks = app.specObj(idx).hReceiver.UserData.nTasks-1;
                        app.specObj(idx).LOG(end+1) = struct('type', 'task', 'time', char(Timestamp), 'msg', sprintf('Alterado o estado da tarefa: Em andamento → %s.', app.specObj(idx).Status));

                        for ii = 1:numel(app.specObj(idx).Band)
                            app.specObj(idx) = class.RFlookBinLib.CloseFile(app.specObj(idx), ii);
                            app.specObj(idx).Band(ii).Status = false;
                        end

                    else
                        if strcmp(app.specObj(idx).Task.Script.Observation.Type, 'Samples')
                            tempFlag = [];                            
                            for ii = 1:numel(app.specObj(idx).Band)
                                if app.specObj(idx).Band(ii).Status
                                    if app.specObj(idx).Band(ii).nSweeps == app.specObj(idx).Task.Script.Band(ii).instrObservationSamples
                                        app.specObj(idx) = class.RFlookBinLib.CloseFile(app.specObj(idx), ii);
                                        app.specObj(idx).Band(ii).Status = false;
                                        tempFlag(end+1) = true;

                                    else
                                        tempFlag(end+1) = false;
                                    end
                                end
                            end

                            if all(tempFlag)
                                Flag = true;

                                app.specObj(idx).Status = 'Concluída';
                                app.specObj(idx).hReceiver.UserData.nTasks = app.specObj(idx).hReceiver.UserData.nTasks-1;
                                app.specObj(idx).Observation.EndTime = Timestamp;
                                app.specObj(idx).LOG(end+1) = struct('type', 'task', 'time', char(Timestamp), 'msg', sprintf('Alterado o estado da tarefa: Em andamento → %s.', app.specObj(idx).Status));

                            elseif any(tempFlag)
                                Flag = true;
                            end
                        end
                    end

                case {'Na fila', 'Erro'}
                    if strcmp(app.specObj(idx).Status, 'Erro') 
                        if isnat(app.specObj(idx).Observation.StartUp)
                            app.specObj(idx).Observation.StartUp = Timestamp;
                        end

                        StartUp = app.specObj(idx).Observation.StartUp;
                        if isequal([year(Timestamp), month(Timestamp), day(Timestamp), hour(Timestamp), minute(Timestamp)], ...
                                [year(StartUp), month(StartUp), day(StartUp), hour(StartUp), minute(StartUp)])
                            return
                        end
                    end

                    if app.specObj(idx).Observation.BeginTime < Timestamp
                        switch app.specObj(idx).Task.Script.Observation.Type
                            case {'Duration', 'Time'}
                                if isnat(app.specObj(idx).Observation.EndTime) || (app.specObj(idx).Observation.EndTime > Timestamp)
                                    Flag = true;
                                end

                            case 'Samples'
                                Flag = true;
                        end
                    end

                    if Flag
                        try
                            if strcmp(app.timerObj_task.Running, 'on')
                                stop(app.timerObj_task)
                            end
                            RegularTask_StartUp(app, idx);

                            app.specObj(idx).Status = 'Em andamento';
                            app.specObj(idx).hReceiver.UserData.nTasks   = app.specObj(idx).hReceiver.UserData.nTasks+1;
                            app.specObj(idx).hReceiver.UserData.SyncMode = app.specObj(idx).Task.Receiver.Sync;
                            app.specObj(idx).LOG(end+1) = struct('type', 'task', 'time', char(Timestamp), 'msg', 'Iniciada a execução da tarefa.');

                        catch ME
                            if strcmp(app.timerObj_task.Running, 'off') && ~app.Flag_running
                                start(app.timerObj_task)
                            end
                            app.specObj(idx).Status = 'Erro';
                            app.specObj(idx).LOG(end+1) = struct('type', 'error', 'time', char(Timestamp), 'msg', getReport(ME));

                            Flag = false;
                        end
                    end
            end

            if Flag
                Layout_tableBuilding(app, app.Table.Selection)
                task_TreeSelectionChanged(app)
            end

            if ~strcmp(initialStatus, app.specObj(idx).Status)
                RegularTask_specObjSave(app)
            end
        end


        %-----------------------------------------------------------------%
        function RegularTask_RestartStatus(app, idx, nSweepsFlag)

            for ii = 1:numel(app.specObj(idx).Band)
                app.specObj(idx).Band(ii).SyncModeRef   = -1;
                app.specObj(idx).Band(ii).LastTimeStamp = [];
                app.specObj(idx).Band(ii).Status        = true;

                if nSweepsFlag
                    app.specObj(idx).Band(ii).nSweeps   = 0;
                end
            end
        end


        %-----------------------------------------------------------------%
        % Notas sobre a interface TCPCLIENT:
        % (a) Não existe uma função que retorna os objetos TCPCLIENT 
        %     (como instrfind p/ os objetos TCPIP). 
        % (b) Algumas chamadas a um objeto não mais válido (decorrente 
        %     de uma perda de conectividade, por exemplo) apresentam a 
        %     mensagem de erro na janela de comandos do Matlab, mesmo 
        %     "protegidos" num bloco try/catch. A execução não para, 
        %     mas imprimir a mensagem na janela de comandos é um 
        %     comportamento não esperado.
        % (c) A propriedade que indica que o objeto não mais está conectado 
        %     ao instrumento é privada, sendo acessível usando struct.
        % (d) A propriedade "UserData" se perde quando da reinicialização
        %     do app, sendo necessária criá-la novamente.
        %-----------------------------------------------------------------%


        %-----------------------------------------------------------------%
        function RegularTask_StartUp(app, idx)
            Task = app.specObj(idx).Task;
            
            % RECEIVER
            msgError = app.receiverObj.ReconnectAttempt(app.specObj(idx).hReceiver.UserData.instrSelected, ...
                                                        app.specObj(idx).Task.Receiver.Config.connectFlag, ...
                                                        app.specObj(idx).Task.Receiver.Config.StartUp{1},  ...
                                                        app.specObj(idx).Band(1).SpecificSCPI);
            if ~isempty(msgError)
                error(msgError)
            end
            hReceiver = app.specObj(idx).hReceiver;

            % STREAMING
            if isempty(app.specObj(idx).hStreaming)
                if ismember(Task.Receiver.Config.connectFlag, [2, 3])
                    app.specObj(idx) = startup_specObjRead_Streaming(app, app.specObj(idx));
                end
            else
                if contains(app.specObj(idx).IDN, 'EB500')                 && ...
                        ~contains(Task.Type, 'Drive-test (Level+Azimuth)') &&...
                        isempty(app.specObj(idx).Band(1).Datagrams)

                    hStreaming = app.specObj(idx).hStreaming;
                    app.specObj(idx) = class.EB500Lib.DatagramRead_PSCAN_PreTask(app.EB500Obj, app.specObj(idx), hReceiver, hStreaming);
                end
            end

            % GPS
            if isempty(app.specObj(idx).hGPS)
                if ~isempty(Task.GPS.Selection)
                    [app.specObj(idx), msgError] = startup_specObjRead_GPS(app, app.specObj(idx));
                    if ~isempty(msgError)
                        error(msgError)
                    end
                end
            end

            % ANTENNA TRACKING (EMSat)
            if strcmp(Task.Antenna.Switch.Name, 'EMSat')
                fcn.antennaTracking(app, Task.Antenna.MetaData, app.progressDialog);
            end

            % MASK, FILE & WATERFALL MATRIX
            baseName = sprintf('appColeta_%s', datestr(now, 'yymmdd_THHMMSS'));
            for ii = 1:numel(app.specObj(idx).Band)
                ID = Task.Script.Band(ii).ID;

                % ANTENNA SWITCH & ACU
                % Esse trecho do código consiste na tentativa de obter a posição 
                % da antena, inserindo-a no arquivo binário e apresentando no 
                % painel de metadados. 
                % 
                % Erros retornáveis:
                % - Caso não tenha sido desabilitado o Polling/Bus da ACU 
                % no Compass.
                % - Caso a ACU não esteja acessível ('MCL-3' e 'MCC-1' ainda
                % não possuem); e 'MKA-1' ainda não é controlável por falta
                % de conectividade de rede (o app não "enxerga" a ACU).
                %
                % Os erros não travam a execução do código pois a antena
                % pode ter sido apontada manualmente ou automaticamente - este
                % último poderia ter sido conduzido no momento de criação da 
                % tarefa (e posteriormente reabilitado o controle da ACU pelo 
                % Compass.
                if strcmp(Task.Antenna.Switch.Name, 'EMSat')
                    antennaName = extractBefore(Task.Script.Band(ii).instrAntenna, ' ');
                    [antennaPos, errorMsg] = app.EMSatObj.AntennaPositionGET(antennaName);
                    app.specObj(idx).Band(ii).Antenna.Position = jsonencode(antennaPos);

                    if ~isempty(errorMsg)
                        app.specObj(idx).LOG(end+1) = struct('type', 'startup', 'time', datestr(now), 'msg', sprintf('ID: %.0f\n%s ACU - %s', ID, antennaName, errorMsg));
                    end
                end

                % MASK
                app.specObj(idx).Band(ii).Mask = [];
                if contains(Task.Type, 'Rompimento de Máscara Espectral') && Task.Script.Band(ii).MaskTrigger.Status
                    maskInfo  = class.maskLib.FileRead(Task.MaskFile);
                    maskArray = class.maskLib.ArrayConstructor(maskInfo, Task.Script.Band(ii));

                    FindPeaks = Task.Script.Band(ii).MaskTrigger.FindPeaks;
                    if isempty(FindPeaks)
                        FindPeaks = class.Constants.FindPeaks;
                    end

                    app.specObj(idx).Band(ii).Mask = struct('Table', maskInfo.Table, 'Array', maskArray, 'Validations', 0, ...
                                                            'BrokenArray', zeros(1, Task.Script.Band(ii).instrDataPoints), ...
                                                            'BrokenCount', 0, 'Peaks', '', 'TimeStamp', NaT, 'FindPeaks', FindPeaks);
                    app.specObj(idx).LOG(end+1)    = struct('type', 'mask', 'time', datestr(now), 'msg', sprintf('ID %.0f\n%s', ID, jsonencode(maskInfo.Table)));
                end

                % FILE
                app.specObj(idx).Band(ii).File = struct('Fileversion', class.Constants.fileVersion,     ...
                                                        'Basename', sprintf('%s_ID%.0f', baseName, ID), ...
                                                        'Filecount', 0, 'WritedSamples', 0, 'CurrentFile', []);

                [app.specObj(idx).Band(ii).File.Filecount, ...
                    app.specObj(idx).Band(ii).File.CurrentFile] = class.RFlookBinLib.OpenFile(app.specObj(idx), ii, app.General.fileFolder.userPath);

                logMsg = sprintf(['ID: %.0f\n'             ...
                                  'scpiSet_Config: "%s"\n' ...
                                  'scpiSet_Att: "%s"\n'    ...
                                  'rawMetaData: "%s"\n'    ...
                                  'Filename (base): %s'], ID,                                               ...
                                                          app.specObj(idx).Band(ii).SpecificSCPI.configSET, ...
                                                          app.specObj(idx).Band(ii).SpecificSCPI.attSET,    ...
                                                          app.specObj(idx).Band(ii).rawMetaData,            ...
                                                          app.specObj(idx).Band(ii).File.Basename);                
                app.specObj(idx).LOG(end+1) = struct('type', 'startup', 'time', datestr(now), 'msg', logMsg);


                % WATERFALL MATRIX
                DataPoints     = Task.Script.Band(ii).instrDataPoints;
                WaterfallDepth = app.General.Plot.Waterfall.Depth;
                if strcmp(Task.Script.Observation.Type, 'Samples')
                    WaterfallDepth = min([WaterfallDepth, Task.Script.Band(ii).instrObservationSamples]);
                end                

                switch Task.Script.Band(ii).instrLevelUnit
                    case 'dBm';            refLevel = -120;
                    case {'dBµV', 'dBμV'}; refLevel = -13;
                end                

                app.specObj(idx).Band(ii).Waterfall = struct('idx', 0, 'Depth', WaterfallDepth, 'Matrix', -1000 .* ones(WaterfallDepth, DataPoints, 'single'));
            end

            RegularTask_RestartStatus(app, idx, 0)
        end


        %-----------------------------------------------------------------%
        function RegularTask_MainLoop(app)
            app.Flag_running = 1;
            app.Flag_editing = 1;

            stop(app.timerObj_task)

            while app.Flag_running
                if app.Flag_editing
                    app.revisitObj = fcn.RevisitFactors(app.specObj);
                    app.MetaData.HTMLSource = fcn.htmlCode_TaskMetaData(app.specObj, app.revisitObj, app.Table.Selection, app.Tree.SelectedNodes.NodeData);

                    if isempty(app.revisitObj.GlobalRevisitTime)
                        app.Flag_running = 0;
                        break
                    end
                    
                    nn = 0;
                    app.Flag_editing = 0;
                end

                sweepTic = tic;
                for ii = 1:numel(app.specObj)
                    if RegularTask_StatusTaskCheck(app, ii, '')
                        app.Flag_editing = 1;
                        break
                    end

                    if ~strcmp(app.specObj(ii).Status, 'Em andamento')
                        continue
                    end

                    regularTask = ~contains(app.specObj(ii).Task.Type, 'PRÉVIA');
                    
                    hReceiver   = app.specObj(ii).hReceiver;
                    hStreaming  = app.specObj(ii).hStreaming;
                    hGPS        = app.specObj(ii).hGPS;

                    configMode  = true;

                    nBands = numel(app.specObj(ii).Band);    
                    for jj = 0:nBands
                        if mod(nn, app.revisitObj.Band(ii).RevisitFactors(jj+1)) || app.revisitObj.Band(ii).RevisitFactors(jj+1) == -1
                            continue
                        end
                        newTimeStamp = datetime('now');
    
                        if jj == 0
                            % A atualização das coordenadas geográficas do
                            % ponto de monitoração não precisa ser feita para 
                            % a tarefa "Drive-test (Level+Azimuth)" porque essa 
                            % tarefa já possui, no seu datagrama, a informação 
                            % das coordenadas.

                            if app.specObj(ii).Task.Receiver.Config.connectFlag ~= 3
                                RegularTask_gpsData(app, ii, hReceiver, hGPS, newTimeStamp);
                            end

                        else
                            app.specObj(ii) = class.RFlookBinLib.CheckFile(app.specObj(ii), jj, app.General.fileFolder.userPath);
                            
                            try
                                % ANTENNA SWITCH (IF APPLICABLE)
                                RegularTask_AntennaSwitch(app, ii, jj)

                                % RECEIVER RECONFIGURATION (IF APPLICABLE)
                                if (nBands > 1) || (hReceiver.UserData.nTasks > 1)
                                    if configMode
                                        if ismember(app.specObj(ii).Task.Receiver.Config.connectFlag, [2, 3])                                            
                                            class.EB500Lib.OperationMode(hReceiver, app.specObj(ii).Task.Receiver.Config.connectFlag)
                                        end
                                        configMode = false;
                                    end

                                    RegularTask_ConfigBand(app, ii, jj, hReceiver)
                                end

                                attFactor = -1;
                                if ~isempty(app.specObj(ii).GeneralSCPI.attGET)
                                % Bloco try/catch protege eventual erro, o que não causará dano à 
                                % monitoração em si por se tratar de informação não essencial.
                                    try
                                        attFactor = str2double(fcn.WriteRead(hReceiver, app.specObj(ii).GeneralSCPI.attGET));
                                    catch
                                    end
                                end

                                % maskTrigger: Variável local que registra se foi evidenciado rompimento da máscara espectral.
                                maskTrigger = 0;

                                if isempty(app.specObj(ii).Band(jj).Mask)
                                    % SINGLE TRACE
                                    newArray = RegularTask_specData(app, ii, jj, hReceiver, hStreaming, newTimeStamp);
                                    app.specObj(ii).Band(jj).nSweeps = app.specObj(ii).Band(jj).nSweeps+1;
                                
                                else
                                    % BURST OF TRACES
                                    nSweeps  = app.specObj(ii).Band(jj).Mask.FindPeaks.nSweeps;
                                    newArray = zeros(nSweeps, app.specObj(ii).Band(jj).DataPoints, 'single');                                    
                                    for kk = 1:nSweeps
                                        newArray(kk,:) = RegularTask_specData(app, ii, jj, hReceiver, hStreaming, newTimeStamp);
                                        app.specObj(ii).Band(jj).nSweeps = app.specObj(ii).Band(jj).nSweeps+1;
                                    end
                                    smoothedArray = mean(newArray, 1);

                                    % METADATA UPDATE
                                    app.specObj(ii).Band(jj).Mask.Validations = app.specObj(ii).Band(jj).Mask.Validations + 1;

                                    % MASK BROKEN ANALISYS                                    
                                    validationArray = (smoothedArray - app.specObj(ii).Band(jj).Mask.Array) > 0;
                                    if any(validationArray)
                                        app.specObj(ii).Band(jj).Mask.BrokenArray = app.specObj(ii).Band(jj).Mask.BrokenArray + validationArray;

                                        peaksTable = fcn.FindPeaks(app.specObj(ii), jj, smoothedArray, validationArray);
                                        if ~isempty(peaksTable)
                                            app.specObj(ii).Band(jj).Mask.BrokenCount = app.specObj(ii).Band(jj).Mask.BrokenCount + 1;
                                            app.specObj(ii).Band(jj).Mask.Peaks       = peaksTable;
                                            app.specObj(ii).Band(jj).Mask.TimeStamp   = newTimeStamp;

                                            if regularTask
                                                writematrix(jsonencode(rmfield(app.specObj(ii).Band(jj).Mask, {'Table', 'Array', 'Validations', 'BrokenArray', 'FindPeaks'})), ...
                                                    replace(app.specObj(ii).Band(jj).File.CurrentFile.FullPath, {'~', '.bin'}, {'', '.txt'}), "QuoteStrings", "none", "WriteMode", "append")
                                            end

                                            maskTrigger = 1;
                                        end
                                    end

                                    newArray = newArray(end,:);
                                end
                                
                                app.specObj(ii).Error(1,2:4) = {NaT, NaT, 0};

                                % WATERFALL MATRIX
                                idx = app.specObj(ii).Band(jj).Waterfall.idx + 1;
                                if idx > app.specObj(ii).Band(jj).Waterfall.Depth; idx = 1;
                                end

                                app.specObj(ii).Band(jj).Waterfall.idx = idx;
                                app.specObj(ii).Band(jj).Waterfall.Matrix(idx,:) = newArray(:,:,1);

                                % ESTIMATED REVISIT TIME
                                if isempty(app.specObj(ii).Band(jj).LastTimeStamp)
                                    app.specObj(ii).Band(jj).RevisitTime = app.revisitObj.GlobalRevisitTime * app.revisitObj.Band(ii).RevisitFactors(jj+1);
                                else
                                    app.specObj(ii).Band(jj).RevisitTime = ((app.General.Integration.SampleTime-1)*app.specObj(ii).Band(jj).RevisitTime + seconds(newTimeStamp-app.specObj(ii).Band(jj).LastTimeStamp))/app.General.Integration.SampleTime;
                                end
                                app.specObj(ii).Band(jj).LastTimeStamp = newTimeStamp;

                                % PLOT, WRITEDSAMPLES & MASKINFO (IF APPLICABLE)
                                if app.Table.Selection == ii
                                    Layout_errorCount(app, ii)

                                    if app.Tree.SelectedNodes.NodeData == jj
                                        plotFcn.Draw(app, ii, jj)
                                        if ~isempty(app.specObj(ii).Band(jj).Mask)
                                            Layout_lastMaskValidation(app, maskTrigger, ii, jj)
                                        end
                                        app.task_RevisitTime.Text = sprintf('%d varreduras\n%.3f seg', app.specObj(ii).Band(jj).nSweeps, app.specObj(ii).Band(jj).RevisitTime);
                                    end
                                end

                                % FILE
                                if regularTask && (isempty(app.specObj(ii).Band(jj).Mask) || ismember(app.specObj(ii).Task.Script.Band(jj).MaskTrigger.Status, [0, 3]) || ((app.specObj(ii).Task.Script.Band(jj).MaskTrigger.Status == 2) && maskTrigger))
                                    class.RFlookBinLib.EditFile(app.specObj(ii), jj, newArray, attFactor, newTimeStamp)
                                    app.specObj(ii).Band(jj).File.WritedSamples = app.specObj(ii).Band(jj).File.WritedSamples + 1;

                                    if (app.Table.Selection == ii) && (app.Tree.SelectedNodes.NodeData == jj)
                                        app.Sweeps.Text = string(app.specObj(ii).Band(jj).File.WritedSamples);
                                    end                                    
                                end

                                if (app.Table.Selection == ii) && (app.Tree.SelectedNodes.NodeData == jj)
                                    drawnow
                                end
    
                            catch ME
                                % O controle de erro do GPS se dá na função "RegularTask_gpsData".
                                % 
                                % O controle de erro do RECEPTOR se dá aqui, neste trecho da função 
                                % "RegularTask_MainLoop".
                                %
                                % O app tentará reativar a conexão toda vez que o contador de
                                % erro atingir um múltiplo de "class.Constants.errorCountTrigger".
                                % E, além disso, caso ultrapassado o tempo (em segundos) definido 
                                % em "class.Constants.errorTimeTrigger", o app trocará o estado da 
                                % tarefa de "Em andamento" → "Erro".

                                if ME.message == "If you specify a message identifier argument, you must specify the message text argument."
                                    pause(1)
                                end

                                app.specObj(ii).LOG(end+1) = struct('type', 'error (RECEIVER)', 'time', char(newTimeStamp), 'msg', ME.message);
                                RegularTask_errorHandle(app, 'Receiver', ii, newTimeStamp)

                                if app.Table.Selection == ii
                                    Layout_errorCount(app, ii)
                                    drawnow
                                end
                                beep

                                msgError = app.receiverObj.ReconnectAttempt(app.specObj(ii).hReceiver.UserData.instrSelected, ...
                                                                            app.specObj(ii).Task.Receiver.Config.connectFlag, ...
                                                                            app.specObj(ii).Task.Receiver.Config.StartUp{1},  ...
                                                                            app.specObj(ii).Band(jj).SpecificSCPI);
                                if ~isempty(msgError)
                                    RegularTask_StatusTaskCheck(app, ii, 'ErrorTrigger');
                                    break
                                end
                            end
                        end
                    end
                end

                nn = nn+1;
                pause(max(app.revisitObj.GlobalRevisitTime-toc(sweepTic), .001))
            end

            start(app.timerObj_task)

            app.revisitObj = [];
            app.MetaData.HTMLSource = fcn.htmlCode_TaskMetaData(app.specObj, app.revisitObj, app.Table.Selection, app.Tree.SelectedNodes.NodeData);
        end


        %-----------------------------------------------------------------%
        function RegularTask_ConfigBand(app, ii, jj, hReceiver)
            writeline(hReceiver, app.specObj(ii).Band(jj).SpecificSCPI.configSET);
            pause(.001)
            
            if ~isempty(app.specObj(ii).Band(jj).SpecificSCPI.attSET)
                writeline(hReceiver, app.specObj(ii).Band(jj).SpecificSCPI.attSET);
            end
        end


        %-----------------------------------------------------------------%
        function RegularTask_gpsData(app, ii, hReceiver, hGPS, newTimeStamp)
            % O controle de erro do RECEPTOR se dá na função "RegularTask_MainLoop".
            %
            % O controle de erro do GPS, por outro lado, se dá diretamente aqui, 
            % nesta função, e é restrito ao caso em que o receptor é "External",
            % ou seja, não se trata de GPS embarcado no RECEPTOR (GPS conectado
            % à porta USB do computador que executa o app, por exemplo).
            %
            % Caso a tarefa seja do tipo "Drive-test", toda vez que for manifestada 
            % uma desconexão, o app tentará reativar a conexao. Ou, em sendo uma tarefa 
            % de outro tipo, o app tentará reativar a conexão toda vez que o contador de
            % erro atingir um múltiplo de "class.Constants.errorGPSCountTrigger".
             
            gpsData = struct('Status', 0, 'Latitude', -1, 'Longitude', -1, 'TimeStamp', '');

            try
                switch app.specObj(ii).Task.Script.GPS.Type
                    case 'Built-in'
                        gpsData = fcn.gpsBuiltInReader(hReceiver);
                    case 'External'
                        gpsData = fcn.gpsExternalReader(hGPS, 1);
                        app.specObj(ii).Error(2,2:4) = {NaT, NaT, 0};
                end

            catch ME
                app.specObj(ii).LOG(end+1) = struct('type', 'error (GPS)', 'time', char(newTimeStamp), 'msg', ME.message);

                if strcmp(app.specObj(ii).Task.Script.GPS.Type, 'External')
                    RegularTask_errorHandle(app, 'GPS', ii, newTimeStamp)

                    if contains(app.specObj(ii).Task.Type, 'Drive-test') || ~mod(app.specObj(ii).Error.Count(2), class.Constants.errorGPSCountTrigger)
                        app.gpsObj.ReconnectAttempt(hGPS.UserData.instrSelected);
                    end
                end
            end

            % As coordenadas da estação - registradas em app.General.stationInfo
            % - são atualizadas apenas se a estação for do tipo móvel ("Mobile") 
            % e as novas coordenadas geográficas forem válidas.

            if strcmp(app.General.stationInfo.Type, 'Mobile') && gpsData.Status
                app.General.stationInfo.Latitude  = gpsData.Latitude;
                app.General.stationInfo.Longitude = gpsData.Longitude;
            end

            RegularTask_gpsUpdate(app, ii, gpsData, newTimeStamp)
        end


        %-----------------------------------------------------------------%
        function RegularTask_gpsUpdate(app, ii, gpsData, newTimeStamp)
            if isempty(gpsData.TimeStamp)
                gpsData.TimeStamp = char(newTimeStamp);
            end
            app.specObj(ii).lastGPS = gpsData;

            if (app.Table.Selection == ii)
                Layout_lastGPS(app, gpsData)
            end
        end
        
        
        %-----------------------------------------------------------------%
        function RegularTask_AntennaSwitch(app, ii, jj)
            switch app.specObj(ii).Task.Antenna.Switch.Name
                case 'EMSat'
                    msgError = app.EMSatObj.MatrixSwitch(app.specObj(ii).Band(jj).Antenna.SwitchPort,    ...
                                                         app.specObj(ii).Task.Antenna.Switch.OutputPort, ...
                                                         app.specObj(ii).Band(jj).Antenna.LNBChannel,    ...
                                                         app.specObj(ii).Band(jj).Antenna.LNBIndex);
                    if ~isempty(msgError)
                        error(msgError)
                    end

                case 'ERMx'
                    msgError = app.ERMxObj.MatrixSwitch( app.specObj(ii).Band(jj).Antenna.SwitchPort, ...
                                                         app.specObj(ii).Task.Antenna.Switch.OutputPort);
                    if ~isempty(msgError)
                        error(msgError)
                    end
            end
        end


        %-----------------------------------------------------------------%
        function newArray = RegularTask_specData(app, ii, jj, hReceiver, hStreaming, newTimeStamp)
            Timeout = class.Constants.Timeout;
            Flag_success = false;

            switch app.specObj(ii).Task.Receiver.Config.connectFlag
                case 1
                    % Spectrum analyzers (R&S, KeySight, Tektronix, Anritsu)

                    recTic = tic;
                    t1 = toc(recTic);
                    while t1 < Timeout
                        try
                            writeline(hReceiver, app.specObj(ii).GeneralSCPI.dataGET);
                            newArray = readbinblock(hReceiver, 'single');
                                                        
                            if numel(newArray) == app.specObj(ii).Band(jj).DataPoints
                                if strcmp(app.specObj(ii).Task.Receiver.Sync, 'Continuous Sweep')
                                    SyncModeRef = sum(newArray);

                                    if SyncModeRef ~= app.specObj(ii).Band(jj).SyncModeRef
                                        app.specObj(ii).Band(jj).SyncModeRef = SyncModeRef;
                                    else
                                        continue
                                    end                                    
                                end

                                Flag_success = true;
                                break
                            end
    
                        catch
                        end
                        t1 = toc(recTic);
                    end
                    
                case 2
                    % R&S EB500: Tarefas ordinárias
                    
                    taskInfo = struct('Type',       app.specObj(ii).Task.Type,                      ...
                                      'FreqStart',  app.specObj(ii).Task.Script.Band(jj).FreqStart, ...
                                      'FreqStop',   app.specObj(ii).Task.Script.Band(jj).FreqStop,  ...
                                      'DataPoints', app.specObj(ii).Band(jj).DataPoints,            ...
                                      'nDatagrams', app.specObj(ii).Band(jj).Datagrams,             ...
                                      'udpPort',    app.EB500Obj.udpPort);

                    [newArray, Flag_success] = class.EB500Lib.DatagramRead_PSCAN(taskInfo, hReceiver, hStreaming);

                case 3
                    % R&S EB500 - Tarefa "Drive-test (Level+Azimuth)"
                    % O newArray gerado aqui, e apenas aqui, possui informações
                    % de nível, azimute e nota de qualidade do azimute. A dimensão 
                    % dele é 1 (Height) x DataPoints (Width) x 3 (Depth).

                    taskInfo = struct('Type',       app.specObj(ii).Task.Type,                                                                          ...
                                      'FreqCenter', (app.specObj(ii).Task.Script.Band(jj).FreqStart + app.specObj(ii).Task.Script.Band(jj).FreqStop)/2, ...
                                      'FreqSpan',   app.specObj(ii).Task.Script.Band(jj).FreqStop - app.specObj(ii).Task.Script.Band(jj).FreqStart,     ...
                                      'DataPoints', app.specObj(ii).Band(jj).DataPoints,                                                                ...
                                      'udpPort',    app.EB500Obj.udpPort);

                    [newArray, gpsData, Flag_success] = class.EB500Lib.DatagramRead_FFM(taskInfo, hReceiver, hStreaming);

                    % No datagrama tem a informação de gps... então vamos aproveitar! :)
                    RegularTask_gpsUpdate(app, ii, gpsData, newTimeStamp)
            end
            flush(hReceiver)
            
            if Flag_success
                if app.specObj(ii).Band(jj).FlipArray
                    newArray(:,:,1) = flip(newArray(:,:,1));
                end
            else
                error('Não foi lido corretamente o vetor de nível do receptor dentro do tempo limite (%.0f segundos).', Timeout)
            end            
        end


        %-----------------------------------------------------------------%
        function RegularTask_errorHandle(app, errorType, ii, newTimeStamp)
            switch errorType
                case 'Receiver'; idx = 1;
                case 'GPS';      idx = 2;
            end
                                
            if isnat(app.specObj(ii).Error.CreatedTime(idx))
                app.specObj(ii).Error.CreatedTime(idx) = newTimeStamp;
            end
            app.specObj(ii).Error.LastTime(idx) = newTimeStamp;
            app.specObj(ii).Error.Count(idx) = app.specObj(ii).Error.Count(idx) + 1;
        end

        %-----------------------------------------------------------------%
        function Layout_tableBuilding(app, idx)
            tempTable = table('Size', [0, 7],                                                                          ...
                              'VariableTypes', {'double', 'string', 'string', 'string', 'string', 'string', 'string'}, ...
                              'VariableNames', {'ID', 'Name', 'Receiver', 'Created', 'BeginTime', 'EndTime', 'Status'});
            tempTable.Properties.UserData = char(matlab.lang.internal.uuid());
            
            for ii = 1:numel(app.specObj)
                EndTime = '-';
                if ~isnat(app.specObj(ii).Observation.EndTime) && ~isinf(app.specObj(ii).Observation.EndTime)
                    EndTime = datestr(app.specObj(ii).Observation.EndTime, 'dd/mm/yyyy HH:MM:SS');
                end
        
                tempTable(end+1,:) = {app.specObj(ii).ID,                        ...
                                      app.specObj(ii).Task.Script.Name,          ...
                                      app.specObj(ii).IDN,                       ...
                                      app.specObj(ii).Observation.Created,       ...
                                      datestr(app.specObj(ii).Observation.BeginTime, 'dd/mm/yyyy HH:MM:SS'), ...
                                      EndTime,                                   ...
                                      app.specObj(ii).Status};
            end    
        
            if all(~strcmp(tempTable.Status, "Em andamento"))
                app.Flag_running = 0;
            end
        
            if height(tempTable)
                app.Table.Data      = tempTable;
                app.Table.Selection = max([1, idx]);
                app.Table.UserData  = app.Table.Selection;
        
                app.task_ButtonPlay.Enable = 1;
                app.task_ButtonDel.Enable  = 1;
                app.task_ButtonLOG.Enable  = 1;
            else
                app.Table.Data     = table;
                app.Table.UserData = [];
        
                app.task_ButtonPlay.Enable = 0;
                app.task_ButtonDel.Enable  = 0;
                app.task_ButtonLOG.Enable  = 0;
            end
            Layout_errorCount(app, app.Table.Selection)
            drawnow nocallbacks
        
            if ~isempty(app.Tree.SelectedNodes); Layout_treeBuilding(app, app.Tree.SelectedNodes.NodeData)
            else;                                Layout_treeBuilding(app, 1)
            end
        end

        %-----------------------------------------------------------------%
        function Layout_treeBuilding(app, Selection)            
            delete(app.Tree.Children);
            
            if app.Table.Selection
                idx = app.Table.Selection;
                for ii = 1:numel(app.specObj(idx).Task.Script.Band)
                    Antenna = app.specObj(idx).Task.Script.Band(ii).instrAntenna;
                    if ~isempty(Antenna)
                        Antenna = sprintf('(%s)', Antenna);
                    end
        
                    uitreenode(app.Tree, 'Text', sprintf('ID %d: %.3f - %.3f MHz %s',                            ...
                                                         app.specObj(idx).Task.Script.Band(ii).ID,               ...
                                                         app.specObj(idx).Task.Script.Band(ii).FreqStart / 1e+6, ...
                                                         app.specObj(idx).Task.Script.Band(ii).FreqStop  / 1e+6, ...
                                                         Antenna),                                               ...
                                         'NodeData', ii);
                end
                
                app.Tree.SelectedNodes = app.Tree.Children(Selection);
            end
            drawnow nocallbacks
        end

        %-----------------------------------------------------------------%
        function Layout_errorCount(app, idx)
            if ~isempty(idx) && app.specObj(idx).Error.Count(1)
                set(app.errorCount_txt, 'Text', string(app.specObj(idx).Error.Count(1)), 'Visible', 'on')
                app.errorCount_img.Visible = 'on';
            else
                set(app.errorCount_txt, 'Text', '0', 'Visible', 'off')
                app.errorCount_img.Visible = 'off';
            end
        end

        %-----------------------------------------------------------------%
        function Layout_lastGPS(app, gpsData)
            switch gpsData.Status
                case  1; newColor = [0.47,0.67,0.19];
                case  0; newColor = [0.64,0.08,0.18];
                case -1; newColor = [0.50,0.50,0.50];
            end
        
            app.lastGPS_text.Text   = sprintf(['<b style="color: #a2142f; font-size: 14;">%.3f</b> LAT \n' ...
                                               '<b style="color: #a2142f; font-size: 14;">%.3f</b> LON \n' ...
                                               '%s \n%s '], gpsData.Latitude, gpsData.Longitude,           ...
                                                            extractBefore(gpsData.TimeStamp, ' '),         ...
                                                            extractAfter(gpsData.TimeStamp, ' '));
            app.lastGPS_color.Color = newColor;
        end

        %-----------------------------------------------------------------%
        function Layout_lastMaskInitialState(app)
            app.lastMask_text.Enable = 0;
            app.lastMask_text.Text   = {'<b style="color: #a2142f; font-size: 14;">-1</b> ';                ...
                                        'VALIDAÇÕES '; '<b style="color: #a2142f; font-size: 14;">-1</b> '; ...
                                        'ROMPIMENTOS '; '<font style="color: #a2142f;">-1.000 MHz ';        ...
                                        '⌂ -1.0 kHz ';                                                      ...
                                        'Ʌ -1.0 dB </font>';                                                ...
                                        'dd-mmm-yyyy ';                                                     ...
                                        'HH:MM:SS '};
        end

        %-----------------------------------------------------------------%
        function Layout_lastMaskValidation(app, maskTrigger, ii, jj)
            if maskTrigger
                Validations = app.specObj(ii).Band(jj).Mask.Validations;
                BrokenCount = app.specObj(ii).Band(jj).Mask.BrokenCount;
        
                if ~isempty(app.specObj(ii).Band(jj).Mask.Peaks)
                    nPeaks      = sprintf(' (%d)', height(app.specObj(ii).Band(jj).Mask.Peaks));
                    FreqCenter  = app.specObj(ii).Band(jj).Mask.Peaks.FreqCenter(1);
                    BandWidth   = app.specObj(ii).Band(jj).Mask.Peaks.BW(1);
                    Prominence  = app.specObj(ii).Band(jj).Mask.Peaks.Prominence(1);
                    dTimeStamp  = extractBefore(char(app.specObj(ii).Band(jj).Mask.TimeStamp), ' ');
                    hTimeStamp  = extractAfter(char(app.specObj(ii).Band(jj).Mask.TimeStamp), ' ');
                else
                    nPeaks      = '';
                    FreqCenter  = -1;
                    BandWidth   = -1;
                    Prominence  = -1;
                    dTimeStamp  = 'dd-mmm-yyyy';
                    hTimeStamp  = 'HH:MM:SS';
                end
        
                app.lastMask_text.Text = sprintf(['<b style="color: #a2142f; font-size: 14;">%.0f</b> \nVALIDAÇÕES \n'                  ...
                                                  '<b style="color: #a2142f; font-size: 14;">%.0f%s</b> \nROMPIMENTOS \n'               ...
                                                  '<font style="color: #a2142f;">%.3f MHz \n⌂ %.1f kHz \nɅ %.1f dB</font> \n%s \n%s '], ...
                                                  Validations, BrokenCount, nPeaks, FreqCenter, BandWidth, Prominence, dTimeStamp, hTimeStamp);
            else
                app.lastMask_text.Text = replace(app.lastMask_text.Text, [extractBefore(app.lastMask_text.Text, 'VALIDAÇÕES') 'VALIDAÇÕES'], ...
                    sprintf('<b style="color: #a2142f; font-size: 14;">%.0f</b> \nVALIDAÇÕES', app.specObj(ii).Band(jj).Mask.Validations));
            end
        end

        %-----------------------------------------------------------------%
        function logMsg = Misc_logMsg(app, idx)
            logMsg = '';
            if ~isempty(app.specObj(idx).LOG)
                logTable = struct2table(app.specObj(idx).LOG);
                logMsg   = strjoin("<b>" + logTable.time + " - " + upper(logTable.type) + "</b>" + newline + logTable.msg, '\n\n');
            end
        end

    end

    
    methods (Access = public)
        %-----------------------------------------------------------------%
        function appBackDoor(app, callingApp, operationType, varargin)
            try
                switch class(callingApp)
                    case {'auxApp.winInstrument', 'auxApp.winInstrument_exported', ...
                          'auxApp.winTaskList',   'auxApp.winTaskList_exported',   ...
                          'auxApp.winAddTask',    'auxApp.winAddTask_exported',    ...
                          'auxApp.winServer',     'auxApp.winServer_exported',     ...
                          'auxApp.winSettings',   'auxApp.winSettings_exported'}

                        switch operationType
                            case 'closeFcn'
                                auxAppTag = varargin{1};
                                closeModule(app.tabGroupController, auxAppTag, app.General)

                            case 'AddOrEditTask'
                                auxAppTag   = varargin{1};
                                infoEdition = varargin{2};
                                newTask     = varargin{3};

                                closeModule(app.tabGroupController, auxAppTag, app.General)

                                % O try/catch possibilita a inclusão do progressDialog sem que 
                                % exista o risco dele ficar visível, caso ocorra algum erro não
                                % mapeado no método da classe.

                                try
                                    app.progressDialog.Visible = 'visible';
                                    [app.specObj, msgError]    = app.specObj.AddOrEditTask(infoEdition, newTask, app.EMSatObj, app.ERMxObj);
                                    app.progressDialog.Visible = 'hidden';
                    
                                    if isempty(msgError)
                                        RegularTask_timerFcn(app)                                 % Startup of every task
                                    else
                                        appUtil.modalWindow(app.UIFigure, 'warning', msgError);
                                    end
                                catch ME
                                    struct2table(ME.stack)
                                end

                            otherwise
                                error('UnexpectedCall')
                        end

                    case {'auxApp.dockTracking',  'auxApp.dockTracking_exported'}
                        
                        % Esse ramo do switch trata chamados de módulos auxiliares dos 
                        % modos "REPORT" e "MISCELLANEOUS". Algumas das funcionalidades 
                        % desses módulos requerem atualização do appAnalise:
                        % (a) REPORT: atualização do painel de algoritmos.
                        % (b) MISCELLANEOUS: atualização da visualização da árvore (e 
                        %     aspectos decorrentes desta atualização, como painel de 
                        %     metadados e plots).

                        % O flag "updateFlag" provê essa atualização, e o flag "returnFlag" 
                        % evita que o módulo seja "fechado" (por meio da invisibilidade do 
                        % app.popupContainerGrid).

                        updateFlag = varargin{1};
                        returnFlag = varargin{2};

                        if updateFlag
                            % ...
                        end

                        if returnFlag
                            return
                        end
                        
                        app.popupContainerGrid.Visible = 0;
    
                    otherwise
                        error('UnexpectedCall')
                end

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', ME.message);            
            end

            % Caso um app auxiliar esteja em modo DOCK, o progressDialog do
            % app auxiliar coincide com o do appAnalise. Força-se, portanto, 
            % a condição abaixo para evitar possível bloqueio da tela.
            app.progressDialog.Visible = 'hidden';
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            try
                % WARNING MESSAGES
                appUtil.disablingWarningMessages()

                % <GUI>
                app.UIFigure.Position(4) = 660;
                app.popupContainerGrid.Layout.Row = [1,2];
                app.GridLayout.RowHeight = {44, '1x'};
                % </GUI>

                appUtil.winPosition(app.UIFigure)
                jsBackDoor_Initialization(app)
                startup_timerCreation(app)

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', getReport(ME), 'CloseFcn', @(~,~)closeFcn(app));
            end
            
        end

        % Close request function: UIFigure
        function closeFcn(app, event)
            
            % RUNNING TASK CHECK
            if app.Flag_running
                appUtil.modalWindow(app.UIFigure, 'warning', 'Existe uma tarefa em execução...');
                return
            end

            % STARTUP SPECOBJ
            if app.General.startupInfo
                RegularTask_specObjSave(app)
            else
                if isfile(fullfile(app.rootFolder, 'Settings', 'startupInfo.mat'))
                    delete(fullfile(app.rootFolder, 'Settings', 'startupInfo.mat'))
                end
            end

            % GENERAL SETTINGS
            if strcmp(app.General.stationInfo.Type, 'Mobile')
                fcn.GeneralSettings(app.General, app.rootFolder)
            end

            % TIMER
            h = timerfindall;
            if ~isempty(h)
                stop(h); delete(h); clear h
            end

            % PROGRESS DIALOG
            delete(app.progressDialog)

            % DELETE SERVER
            if ~isempty(app.tcpServer)
                delete(app.tcpServer.Server)
            end

            % DELETE APPS
            if isdeployed
                delete(findall(groot, 'Type', 'Figure'))
            else
                delete(app.tabGroupController)    
                delete(app)
            end
            
        end

        % Value changed function: menu_Button1, menu_Button2, 
        % ...and 4 other components
        function menu_mainButtonPushed(app, event)

            % em sendo o ADICIONAR TAREFA, verificar se existe alguma
            % tarefa selecionado em tabela. Caso sim, pergunta se se deseja
            % editar ou adicionar uma nova. ao incluir a tarefa, o módulo é
            % encerrado.

            clickedButton  = event.Source;
            auxAppTag      = clickedButton.Tag;
            inputArguments = menu_auxAppInputArguments(app, auxAppTag);

            if event.Source == app.menu_Button4
                % A operação padrão, ao clicar em app.menu_Button4, é criar uma 
                % nova tarefa. Caso esteja selecionado o módulo de visualização 
                % de tarefas, e esteja selecionada uma tarefa, questiona-se se 
                % deve ser feito a inclusão de uma nova tarefa ou a edição da 
                % selecionada. 
                idx = app.Table.Selection;

                if  ~checkStatusModule(app.tabGroupController, 'TASK:ADD') && app.menu_Button1.Value && ~isempty(idx)
                    msgQuestion   = 'Deseja criar uma nova tarefa, ou editar a tarefa selecionada em tabela?';
                    userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'Criar nova', 'Editar selecionada', 'Cancelar'}, 1, 3);
                    switch userSelection
                        case 'Editar selecionada'
                            if ismember(app.specObj(idx).Status, {'Na fila', 'Em andamento'})
                                appUtil.modalWindow(app.UIFigure, 'warning', 'Uma tarefa no estado "Na fila" ou "Em andamento" não poderá ser editada.');
                                app.menu_Button4.Value = 0;
                                return
                            end

                            inputArguments = {app, struct('type', 'edit', 'idx', idx)};

                        case 'Cancelar'
                            app.menu_Button4.Value = 0;
                            return
                    end
                end
            end

            openModule(app.tabGroupController, event.Source, event.PreviousValue, app.General, inputArguments{:})
            
        end

        % Image clicked function: dockModule_Close, dockModule_Undock
        function menu_DockButtonPushed(app, event)
            
            clickedButton = findobj(app.menu_Grid, 'Type', 'uistatebutton', 'Value', true);
            auxAppTag     = clickedButton.Tag;

            switch event.Source
                case app.dockModule_Undock
                    initialDockState = app.General.operationMode.Dock;
                    app.General.operationMode.Dock = false;

                    inputArguments   = menu_auxAppInputArguments(app, auxAppTag);
                    closeModule(app.tabGroupController, auxAppTag, app.General)
                    openModule(app.tabGroupController, clickedButton, false, app.General, inputArguments{:})

                    app.General.operationMode.Dock = initialDockState;

                case app.dockModule_Close
                    closeModule(app.tabGroupController, auxAppTag, app.General)
            end

        end

        % Image clicked function: AppInfo, FigurePosition
        function menu_ToolbarImageCliced(app, event)
            
            focus(app.jsBackDoor)

            switch event.Source
                case app.FigurePosition
                    app.UIFigure.Position(3:4) = class.Constants.windowSize;
                    appUtil.winPosition(app.UIFigure)

                case app.AppInfo
                    if isempty(app.AppInfo.Tag)
                        app.progressDialog.Visible = 'visible';
                        app.AppInfo.Tag = fcn.htmlCode_appInfo(app.General, app.rootFolder, app.executionMode);
                        app.progressDialog.Visible = 'hidden';
                    end

                    msgInfo = app.AppInfo.Tag;
                    appUtil.modalWindow(app.UIFigure, 'info', msgInfo);
            end

        end

        % Button pushed function: task_ButtonPlay
        function menu_PushButtonPushed_playTask(app, event)
            
            idx = app.Table.Selection;
            if idx 
                switch app.specObj(idx).Status
                    %-----------------------------------------------------%
                    % PLAY
                    %-----------------------------------------------------%
                    case {'Cancelada', 'Erro', 'Concluída'}
                        Timestamp = datetime('now');
        
                        switch app.specObj(idx).Task.Script.Observation.Type
                            case 'Duration'
                                app.specObj(idx).Observation.BeginTime = Timestamp;
                                app.specObj(idx).Observation.EndTime   = Timestamp + seconds(app.specObj(idx).Task.Script.Observation.Duration);
            
                            case 'Time'
                                if strcmp(app.specObj(idx).Status, 'Concluída')
                                    appUtil.modalWindow(app.UIFigure, 'warning', 'Uma tarefa no estado "Concluída" somente poderá ser executada novamente se o tipo do período de observação for "Duração" ou "Quantidade específica de amostras".');
                                    return
                                end
            
                            case 'Samples'
                                app.specObj(idx).Observation.BeginTime = Timestamp;
                                app.specObj(idx).Observation.EndTime   = NaT;
                        end
        
                        app.specObj(idx).Status = 'Na fila';
                        app.specObj(idx).LOG(end+1) = struct('type', 'task', 'time', char(Timestamp), 'msg', 'Reincluída na fila a tarefa.');

                        RegularTask_RestartStatus(app, idx, 1)        
                        RegularTask_timerFcn(app)

                    %-----------------------------------------------------%
                    % STOP
                    %-----------------------------------------------------%
                    case 'Em andamento'
                        RegularTask_StatusTaskCheck(app, idx, 'DeleteButtonPushed');
                end
            end
            
        end

        % Button pushed function: task_ButtonDel
        function menu_PushButtonPushed_delTask(app, event)
            
            idx = app.Table.Selection;
            if idx
                switch app.specObj(idx).Status
                    case 'Em andamento'
                        appUtil.modalWindow(app.UIFigure, 'warning', 'A tarefa precisa ser interrompida antes da tentativa de exclusão.');

                    otherwise
                        if ~app.Flag_running
                            app.specObj(idx) = [];
    
                            Layout_tableBuilding(app, 1)
                            task_TreeSelectionChanged(app)
                        else
                            appUtil.modalWindow(app.UIFigure, 'warning', 'Uma tarefa poderá ser excluída, sendo eliminada da lista de tarefas, somente se não estiver sendo executada nenhuma tarefa.');
                        end
                end
            end

        end

        % Button pushed function: task_ButtonLOG
        function menu_PushButtonPushed_logTask(app, event)

            idx = app.Table.Selection;
            if idx
                appUtil.modalWindow(app.UIFigure, 'warning', Misc_logMsg(app, idx));
            end

        end

        % Image clicked function: task_LeftPanel, task_RightPanel, 
        % ...and 1 other component
        function menu_LayoutPanelVisibility(app, event)
            
            switch event.Source
                case app.task_TopPanel
                    if ~isnumeric(app.task_docGrid.RowHeight{1})
                        app.task_docGrid.RowHeight{1} = 0;
                        app.Table.Visible = 0;
                    else
                        app.task_docGrid.RowHeight{1} = '.75x';
                        app.Table.Visible = 1;
                    end

                case app.task_LeftPanel
                    if app.task_docGrid.ColumnWidth{1}
                        app.task_docGrid.ColumnWidth{1} = 0;
                    else
                        app.task_docGrid.ColumnWidth{1} = 325;
                    end

                case app.task_RightPanel
                    if app.task_docGrid.ColumnWidth{5}
                        app.task_docGrid.ColumnWidth{5} = 0;
                    else
                        app.task_docGrid.ColumnWidth{5} = 120;
                    end
            end
            
        end

        % Selection changed function: Table
        function task_TableSelectionChanged(app, event)

            oldSelection = app.Table.UserData;
            newSelection = app.Table.Selection;

            if isempty(newSelection) && ~isempty(oldSelection)
                app.Table.Selection = oldSelection;
                drawnow

            else
                app.Table.UserData = newSelection;
                Layout_treeBuilding(app, 1)
                task_TreeSelectionChanged(app)
            end
            
        end

        % Selection changed function: Tree
        function task_TreeSelectionChanged(app, event)

            try
                ii = app.Table.Selection;
                jj = app.Tree.SelectedNodes.NodeData;
    
                plotFcn.StartUp(app)
                if ~isempty(app.specObj(ii).Band(jj).Waterfall)
                    idx = app.specObj(ii).Band(jj).Waterfall.idx;
    
                    if idx
                        plotFcn.Draw(app, ii, jj)
                    end
                end
    
                % TASK INFO THAT ARE UPDATED IN REAL TIME
                % (LEFT PANEL)
                app.MetaData.HTMLSource = fcn.htmlCode_TaskMetaData(app.specObj, app.revisitObj, app.Table.Selection, app.Tree.SelectedNodes.NodeData);

    
                % (RIGHT PANEL)
                if ~isempty(app.specObj(ii).Band(jj).File); WritedSamples = app.specObj(ii).Band(jj).File.WritedSamples;
                else;                                       WritedSamples = -1; 
                end
                app.Sweeps.Text = string(WritedSamples);
    
                if ~contains(app.specObj(ii).Task.Type, 'PRÉVIA') && strcmp(app.specObj(ii).Status, 'Em andamento') && app.specObj(ii).Band(jj).Status
                    app.Sweeps_REC.Visible = 1;
                else
                    app.Sweeps_REC.Visible = 0;
                end
    
                if ~isempty(app.specObj(ii).Band(jj).Mask)
                    set(app.Button_MaskPlot, 'Enable', 1)
                    app.lastMask_text.Enable = 1;
                    Layout_lastMaskValidation(app, true, ii, jj)
                else
                    set(app.Button_MaskPlot, 'Enable', 0, 'Value', 0)
                    Layout_lastMaskInitialState(app)
                end
                Layout_lastGPS(app, app.specObj(ii).lastGPS)
    
                % (DOWN STATUS PANEL)
                app.task_Status.Text = sprintf('%s\n%s', app.Table.Data.Receiver(ii), app.Tree.SelectedNodes.Text);
                if ~isempty(app.task_RevisitTime.Text); app.task_RevisitTime.Text = sprintf('%d varreduras\n%.3f seg', app.specObj(ii).Band(jj).nSweeps, app.specObj(ii).Band(jj).RevisitTime);
                else;                                   app.task_RevisitTime.Text = '';
                end

                % PLAY BUTTON
                switch app.specObj(ii).Status
                    case 'Na fila';      set(app.task_ButtonPlay, 'Enable', 'off', 'Icon', 'play_32.png')
                    case 'Em andamento'; set(app.task_ButtonPlay, 'Enable', 'on',  'Icon', 'stop_32.png')
                    otherwise;           set(app.task_ButtonPlay, 'Enable', 'on',  'Icon', 'play_32.png')
                end

            catch
                % Return to initial layout aspect...
                plotFcn.StartUp(app)

                app.MetaData.HTMLSource   = ' ';
                app.Sweeps.Text           = '-1';
                app.Sweeps_REC.Visible    = 0;
                Layout_errorCount(app, [])
                
                set(app.Button_MaskPlot, 'Enable', 0, 'Value', 0)
                Layout_lastMaskInitialState(app)
                
                app.task_Status.Text      = '';
                app.task_RevisitTime.Text = '';

                app.lastGPS_color.Color   = [0.502 0.502 0.502];
                app.lastGPS_text.Text     = {'<b style="color: #a2142f; font-size: 14;">-1.000</b> LAT '; '<b style="color: #a2142f; font-size: 14;">-1.000</b> LON '; ''; 'dd-mmm-yyyy '; 'HH:MM:SS '};
            end
            drawnow

        end

        % Value changed function: Button_Average, Button_MaxHold, 
        % ...and 2 other components
        function task_ButtonPushed_plotTraceMode(app, event)
            
            if isempty(app.Table.Selection) || isempty(app.Tree.SelectedNodes) || app.Button_MaskPlot.Value
                return
            end

            ii = app.Table.Selection;
            jj = app.Tree.SelectedNodes.NodeData;

            if ~isempty(app.specObj(ii).Band(jj).Waterfall)
                idx = app.specObj(ii).Band(jj).Waterfall.idx;

                if idx
                    FreqStart = app.specObj(ii).Task.Script.Band(jj).FreqStart / 1e+6;
                    FreqStop  = app.specObj(ii).Task.Script.Band(jj).FreqStop  / 1e+6;
                    LevelUnit = app.specObj(ii).Task.Script.Band(jj).instrLevelUnit;

                    xArray    = linspace(FreqStart, FreqStop, app.specObj(ii).Band(jj).DataPoints);
                    newArray = app.specObj(ii).Band(jj).Waterfall.Matrix(idx,:);

                    switch event.Source
                        case app.Button_MinHold
                            if app.Button_MinHold.Value
                                plotFcn.minHold(app, ii, jj, xArray, newArray)
                                plotFcn.DataTipModel(app.line_MinHold, LevelUnit)
                            else
                                delete(app.line_MinHold)
                                app.line_MinHold = [];
                            end

                        case app.Button_Average
                            if app.Button_Average.Value
                                plotFcn.Average(app, ii, jj, xArray, newArray)
                                plotFcn.DataTipModel(app.line_Average, LevelUnit)
                            else
                                delete(app.line_Average)
                                app.line_Average = [];
                            end

                        case app.Button_MaxHold
                            if app.Button_MaxHold.Value
                                plotFcn.maxHold(app, ii, jj, xArray, newArray)
                                plotFcn.DataTipModel(app.line_MaxHold, LevelUnit)
                            else
                                delete(app.line_MaxHold)
                                app.line_MaxHold = [];
                            end

                        case app.Button_peakExcursion
                            if app.Button_peakExcursion.Value
                                plotFcn.peakExcursion(app, ii, jj, newArray)
                            else
                                delete(app.peakExcursion)
                                app.peakExcursion = [];
                            end
                    end
                    drawnow nocallbacks
                end
            end

        end

        % Button pushed function: Button_Layout
        function task_ButtonPushed_plotLayout(app, event)
            
            switch app.plotLayout
                case 1; app.plotLayout = 2;
                case 2; app.plotLayout = 3;
                case 3; app.plotLayout = 1;
            end
            plotFcn.Layout(app)

        end

        % Value changed function: Button_MaskPlot
        function task_ButtonPushed_MaskPlot(app, event)
            
            if isempty(app.Table.Selection) || isempty(app.Tree.SelectedNodes)
                return
            end

            ii = app.Table.Selection;
            jj = app.Tree.SelectedNodes.NodeData;
    
            plotFcn.StartUp(app)
            plotFcn.Draw(app, ii, jj)
            drawnow
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 1244 660];
            app.UIFigure.Name = 'appColeta R2024a';
            app.UIFigure.Icon = fullfile(pathToMLAPP, 'Icons', 'icon_32.png');
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeFcn, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {44, '1x', 44};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.BackgroundColor = [1 1 1];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = [1 2];
            app.TabGroup.Layout.Column = 1;

            % Create Tab1_Task
            app.Tab1_Task = uitab(app.TabGroup);
            app.Tab1_Task.Title = 'TASK:VIEW';

            % Create task_Grid
            app.task_Grid = uigridlayout(app.Tab1_Task);
            app.task_Grid.ColumnWidth = {'1x'};
            app.task_Grid.RowHeight = {'1x', 34};
            app.task_Grid.ColumnSpacing = 0;
            app.task_Grid.RowSpacing = 0;
            app.task_Grid.Padding = [0 0 0 0];

            % Create task_docGrid
            app.task_docGrid = uigridlayout(app.task_Grid);
            app.task_docGrid.ColumnWidth = {325, 10, '1x', 32, 120};
            app.task_docGrid.RowHeight = {'0.75x', 17, '1x', '1x'};
            app.task_docGrid.ColumnSpacing = 0;
            app.task_docGrid.RowSpacing = 4;
            app.task_docGrid.Padding = [5 5 5 26];
            app.task_docGrid.Layout.Row = 1;
            app.task_docGrid.Layout.Column = 1;
            app.task_docGrid.BackgroundColor = [1 1 1];

            % Create Table
            app.Table = uitable(app.task_docGrid);
            app.Table.ColumnName = {'ID'; 'TAREFA'; 'RECEPTOR'; 'INCLUSÃO'; 'INÍCIO|OBSERVAÇÃO'; 'FIM|OBSERVAÇÃO'; 'ESTADO'};
            app.Table.ColumnWidth = {40, 'auto', 'auto', 120, 120, 120, 120};
            app.Table.RowName = {};
            app.Table.SelectionType = 'row';
            app.Table.SelectionChangedFcn = createCallbackFcn(app, @task_TableSelectionChanged, true);
            app.Table.Multiselect = 'off';
            app.Table.Layout.Row = 1;
            app.Table.Layout.Column = [1 5];
            app.Table.FontSize = 10;

            % Create Tree_Label
            app.Tree_Label = uilabel(app.task_docGrid);
            app.Tree_Label.VerticalAlignment = 'bottom';
            app.Tree_Label.WordWrap = 'on';
            app.Tree_Label.FontSize = 10;
            app.Tree_Label.Layout.Row = 2;
            app.Tree_Label.Layout.Column = 1;
            app.Tree_Label.Text = 'FAIXA DE FREQUÊNCIA:';

            % Create Tree
            app.Tree = uitree(app.task_docGrid);
            app.Tree.SelectionChangedFcn = createCallbackFcn(app, @task_TreeSelectionChanged, true);
            app.Tree.FontSize = 10;
            app.Tree.Layout.Row = 3;
            app.Tree.Layout.Column = 1;

            % Create MetaData_Panel
            app.MetaData_Panel = uipanel(app.task_docGrid);
            app.MetaData_Panel.Layout.Row = 4;
            app.MetaData_Panel.Layout.Column = 1;

            % Create MetaData_Grid
            app.MetaData_Grid = uigridlayout(app.MetaData_Panel);
            app.MetaData_Grid.ColumnWidth = {'1x'};
            app.MetaData_Grid.RowHeight = {'1x'};
            app.MetaData_Grid.Padding = [0 0 0 0];
            app.MetaData_Grid.BackgroundColor = [1 1 1];

            % Create MetaData
            app.MetaData = uihtml(app.MetaData_Grid);
            app.MetaData.HTMLSource = ' ';
            app.MetaData.Layout.Row = 1;
            app.MetaData.Layout.Column = 1;

            % Create Plot_Panel
            app.Plot_Panel = uipanel(app.task_docGrid);
            app.Plot_Panel.AutoResizeChildren = 'off';
            app.Plot_Panel.BorderType = 'none';
            app.Plot_Panel.BackgroundColor = [1 1 1];
            app.Plot_Panel.Layout.Row = [2 4];
            app.Plot_Panel.Layout.Column = 3;

            % Create PlotTool_Grid
            app.PlotTool_Grid = uigridlayout(app.task_docGrid);
            app.PlotTool_Grid.ColumnWidth = {22, '1x'};
            app.PlotTool_Grid.RowHeight = {22, 22, 22, '1x', 22, 22, 22};
            app.PlotTool_Grid.ColumnSpacing = 3;
            app.PlotTool_Grid.RowSpacing = 3;
            app.PlotTool_Grid.Padding = [5 0 5 0];
            app.PlotTool_Grid.Layout.Row = [2 4];
            app.PlotTool_Grid.Layout.Column = 4;
            app.PlotTool_Grid.BackgroundColor = [1 1 1];

            % Create Button_MinHold
            app.Button_MinHold = uibutton(app.PlotTool_Grid, 'state');
            app.Button_MinHold.ValueChangedFcn = createCallbackFcn(app, @task_ButtonPushed_plotTraceMode, true);
            app.Button_MinHold.Icon = fullfile(pathToMLAPP, 'Icons', 'MinHold_32Filled.png');
            app.Button_MinHold.IconAlignment = 'center';
            app.Button_MinHold.Text = '';
            app.Button_MinHold.BackgroundColor = [0.9804 0.9804 0.9804];
            app.Button_MinHold.Layout.Row = 1;
            app.Button_MinHold.Layout.Column = 1;

            % Create Button_Average
            app.Button_Average = uibutton(app.PlotTool_Grid, 'state');
            app.Button_Average.ValueChangedFcn = createCallbackFcn(app, @task_ButtonPushed_plotTraceMode, true);
            app.Button_Average.Icon = fullfile(pathToMLAPP, 'Icons', 'Average_32Filled.png');
            app.Button_Average.Text = '';
            app.Button_Average.BackgroundColor = [0.9804 0.9804 0.9804];
            app.Button_Average.Layout.Row = 2;
            app.Button_Average.Layout.Column = 1;

            % Create Button_MaxHold
            app.Button_MaxHold = uibutton(app.PlotTool_Grid, 'state');
            app.Button_MaxHold.ValueChangedFcn = createCallbackFcn(app, @task_ButtonPushed_plotTraceMode, true);
            app.Button_MaxHold.Icon = fullfile(pathToMLAPP, 'Icons', 'MaxHold_32Filled.png');
            app.Button_MaxHold.Text = '';
            app.Button_MaxHold.BackgroundColor = [0.9804 0.9804 0.9804];
            app.Button_MaxHold.Layout.Row = 3;
            app.Button_MaxHold.Layout.Column = 1;

            % Create Button_peakExcursion
            app.Button_peakExcursion = uibutton(app.PlotTool_Grid, 'state');
            app.Button_peakExcursion.ValueChangedFcn = createCallbackFcn(app, @task_ButtonPushed_plotTraceMode, true);
            app.Button_peakExcursion.Icon = fullfile(pathToMLAPP, 'Icons', 'Detection_32.png');
            app.Button_peakExcursion.Text = '';
            app.Button_peakExcursion.BackgroundColor = [0.9804 0.9804 0.9804];
            app.Button_peakExcursion.Layout.Row = 5;
            app.Button_peakExcursion.Layout.Column = 1;

            % Create Button_Layout
            app.Button_Layout = uibutton(app.PlotTool_Grid, 'push');
            app.Button_Layout.ButtonPushedFcn = createCallbackFcn(app, @task_ButtonPushed_plotLayout, true);
            app.Button_Layout.Icon = fullfile(pathToMLAPP, 'Icons', 'Layers_18.png');
            app.Button_Layout.BackgroundColor = [0.9804 0.9804 0.9804];
            app.Button_Layout.Layout.Row = 7;
            app.Button_Layout.Layout.Column = 1;
            app.Button_Layout.Text = '';

            % Create Button_MaskPlot
            app.Button_MaskPlot = uibutton(app.PlotTool_Grid, 'state');
            app.Button_MaskPlot.ValueChangedFcn = createCallbackFcn(app, @task_ButtonPushed_MaskPlot, true);
            app.Button_MaskPlot.Enable = 'off';
            app.Button_MaskPlot.Icon = fullfile(pathToMLAPP, 'Icons', 'Mask_32.png');
            app.Button_MaskPlot.Text = '';
            app.Button_MaskPlot.BackgroundColor = [0.9804 0.9804 0.9804];
            app.Button_MaskPlot.Layout.Row = 6;
            app.Button_MaskPlot.Layout.Column = 1;

            % Create TaskInfo_Panel
            app.TaskInfo_Panel = uigridlayout(app.task_docGrid);
            app.TaskInfo_Panel.ColumnWidth = {'1x'};
            app.TaskInfo_Panel.RowHeight = {82, '1x', '1x'};
            app.TaskInfo_Panel.RowSpacing = 5;
            app.TaskInfo_Panel.Padding = [0 0 0 0];
            app.TaskInfo_Panel.Layout.Row = [2 4];
            app.TaskInfo_Panel.Layout.Column = 5;
            app.TaskInfo_Panel.BackgroundColor = [1 1 1];

            % Create Sweeps_Panel
            app.Sweeps_Panel = uipanel(app.TaskInfo_Panel);
            app.Sweeps_Panel.Layout.Row = 1;
            app.Sweeps_Panel.Layout.Column = 1;

            % Create Sweeps_Grid
            app.Sweeps_Grid = uigridlayout(app.Sweeps_Panel);
            app.Sweeps_Grid.ColumnWidth = {32, '1x', 18};
            app.Sweeps_Grid.RowHeight = {27, '1x', 18};
            app.Sweeps_Grid.ColumnSpacing = 0;
            app.Sweeps_Grid.RowSpacing = 0;
            app.Sweeps_Grid.Padding = [5 5 5 5];
            app.Sweeps_Grid.Tag = 'COLORLOCKED';
            app.Sweeps_Grid.BackgroundColor = [1 1 1];

            % Create Sweeps_REC
            app.Sweeps_REC = uiimage(app.Sweeps_Grid);
            app.Sweeps_REC.ScaleMethod = 'scaledown';
            app.Sweeps_REC.Visible = 'off';
            app.Sweeps_REC.Layout.Row = 3;
            app.Sweeps_REC.Layout.Column = 1;
            app.Sweeps_REC.HorizontalAlignment = 'left';
            app.Sweeps_REC.VerticalAlignment = 'bottom';
            app.Sweeps_REC.ImageSource = fullfile(pathToMLAPP, 'Icons', 'REC.gif');

            % Create Sweeps_Label
            app.Sweeps_Label = uilabel(app.Sweeps_Grid);
            app.Sweeps_Label.FontSize = 10;
            app.Sweeps_Label.FontColor = [0.149 0.149 0.149];
            app.Sweeps_Label.Layout.Row = 1;
            app.Sweeps_Label.Layout.Column = [1 3];
            app.Sweeps_Label.Text = {'VARREDURAS'; 'EM ARQUIVO'};

            % Create Sweeps
            app.Sweeps = uilabel(app.Sweeps_Grid);
            app.Sweeps.HorizontalAlignment = 'right';
            app.Sweeps.WordWrap = 'on';
            app.Sweeps.FontSize = 14;
            app.Sweeps.FontWeight = 'bold';
            app.Sweeps.FontColor = [0.6706 0.302 0.349];
            app.Sweeps.Layout.Row = 2;
            app.Sweeps.Layout.Column = [1 3];
            app.Sweeps.Text = '-1';

            % Create errorCount_txt
            app.errorCount_txt = uilabel(app.Sweeps_Grid);
            app.errorCount_txt.HorizontalAlignment = 'right';
            app.errorCount_txt.FontSize = 10;
            app.errorCount_txt.FontWeight = 'bold';
            app.errorCount_txt.FontColor = [1 0.651 0.651];
            app.errorCount_txt.Visible = 'off';
            app.errorCount_txt.Layout.Row = 3;
            app.errorCount_txt.Layout.Column = 2;
            app.errorCount_txt.Text = '0';

            % Create errorCount_img
            app.errorCount_img = uiimage(app.Sweeps_Grid);
            app.errorCount_img.ScaleMethod = 'none';
            app.errorCount_img.Visible = 'off';
            app.errorCount_img.Layout.Row = 3;
            app.errorCount_img.Layout.Column = 3;
            app.errorCount_img.HorizontalAlignment = 'right';
            app.errorCount_img.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Warn_18.png');

            % Create lastMask_Panel
            app.lastMask_Panel = uipanel(app.TaskInfo_Panel);
            app.lastMask_Panel.Layout.Row = 2;
            app.lastMask_Panel.Layout.Column = 1;

            % Create lastMask_Grid
            app.lastMask_Grid = uigridlayout(app.lastMask_Panel);
            app.lastMask_Grid.ColumnWidth = {'1x'};
            app.lastMask_Grid.RowHeight = {27, '1x'};
            app.lastMask_Grid.ColumnSpacing = 2;
            app.lastMask_Grid.RowSpacing = 0;
            app.lastMask_Grid.Padding = [5 5 5 5];
            app.lastMask_Grid.Tag = 'COLORLOCKED';
            app.lastMask_Grid.BackgroundColor = [1 1 1];

            % Create lastMask_label
            app.lastMask_label = uilabel(app.lastMask_Grid);
            app.lastMask_label.VerticalAlignment = 'top';
            app.lastMask_label.FontSize = 10;
            app.lastMask_label.FontColor = [0.149 0.149 0.149];
            app.lastMask_label.Layout.Row = 1;
            app.lastMask_label.Layout.Column = 1;
            app.lastMask_label.Text = {'MÁSCARA'; 'ESPECTRAL'};

            % Create lastMask_text
            app.lastMask_text = uilabel(app.lastMask_Grid);
            app.lastMask_text.HorizontalAlignment = 'right';
            app.lastMask_text.VerticalAlignment = 'top';
            app.lastMask_text.WordWrap = 'on';
            app.lastMask_text.FontSize = 10;
            app.lastMask_text.FontColor = [0.502 0.502 0.502];
            app.lastMask_text.Enable = 'off';
            app.lastMask_text.Layout.Row = 2;
            app.lastMask_text.Layout.Column = 1;
            app.lastMask_text.Interpreter = 'html';
            app.lastMask_text.Text = {'<b style="color: #a2142f; font-size: 14;">-1</b> '; 'VALIDAÇÕES '; '<b style="color: #a2142f; font-size: 14;">-1</b> '; 'ROMPIMENTOS '; '<font style="color: #a2142f;">-1.000 MHz '; '⌂ -1.0 kHz '; 'Ʌ -1.0 dB </font>'; 'dd-mmm-yyyy '; 'HH:MM:SS '};

            % Create lastGPS_Panel
            app.lastGPS_Panel = uipanel(app.TaskInfo_Panel);
            app.lastGPS_Panel.Layout.Row = 3;
            app.lastGPS_Panel.Layout.Column = 1;

            % Create lastGPS_Grid1
            app.lastGPS_Grid1 = uigridlayout(app.lastGPS_Panel);
            app.lastGPS_Grid1.ColumnWidth = {'1x', 18};
            app.lastGPS_Grid1.RowHeight = {27, '1x', 18};
            app.lastGPS_Grid1.ColumnSpacing = 0;
            app.lastGPS_Grid1.RowSpacing = 0;
            app.lastGPS_Grid1.Padding = [5 5 5 5];
            app.lastGPS_Grid1.Tag = 'COLORLOCKED';
            app.lastGPS_Grid1.BackgroundColor = [1 1 1];

            % Create lastGPS_label
            app.lastGPS_label = uilabel(app.lastGPS_Grid1);
            app.lastGPS_label.VerticalAlignment = 'top';
            app.lastGPS_label.FontSize = 10;
            app.lastGPS_label.FontColor = [0.149 0.149 0.149];
            app.lastGPS_label.Layout.Row = 1;
            app.lastGPS_label.Layout.Column = [1 2];
            app.lastGPS_label.Text = {'COORDENADAS'; 'GEOGRÁFICAS'};

            % Create lastGPS_text
            app.lastGPS_text = uilabel(app.lastGPS_Grid1);
            app.lastGPS_text.HorizontalAlignment = 'right';
            app.lastGPS_text.VerticalAlignment = 'top';
            app.lastGPS_text.WordWrap = 'on';
            app.lastGPS_text.FontSize = 10;
            app.lastGPS_text.FontColor = [0.502 0.502 0.502];
            app.lastGPS_text.Layout.Row = [2 3];
            app.lastGPS_text.Layout.Column = [1 2];
            app.lastGPS_text.Interpreter = 'html';
            app.lastGPS_text.Text = {'<b style="color: #a2142f; font-size: 14;">-1.000</b> LAT '; '<b style="color: #a2142f; font-size: 14;">-1.000</b> LON '; 'dd-mmm-yyyy '; 'HH:MM:SS '};

            % Create lastGPS_Grid2
            app.lastGPS_Grid2 = uigridlayout(app.lastGPS_Grid1);
            app.lastGPS_Grid2.ColumnWidth = {'1x'};
            app.lastGPS_Grid2.RowHeight = {12, '1x'};
            app.lastGPS_Grid2.ColumnSpacing = 0;
            app.lastGPS_Grid2.RowSpacing = 0;
            app.lastGPS_Grid2.Padding = [0 0 0 0];
            app.lastGPS_Grid2.Layout.Row = 1;
            app.lastGPS_Grid2.Layout.Column = 2;
            app.lastGPS_Grid2.BackgroundColor = [1 1 1];

            % Create lastGPS_color
            app.lastGPS_color = uilamp(app.lastGPS_Grid2);
            app.lastGPS_color.Layout.Row = 1;
            app.lastGPS_color.Layout.Column = 1;
            app.lastGPS_color.Color = [0.502 0.502 0.502];

            % Create errorCount_txt_2
            app.errorCount_txt_2 = uilabel(app.lastGPS_Grid1);
            app.errorCount_txt_2.HorizontalAlignment = 'right';
            app.errorCount_txt_2.FontSize = 10;
            app.errorCount_txt_2.FontWeight = 'bold';
            app.errorCount_txt_2.FontColor = [1 0.651 0.651];
            app.errorCount_txt_2.Visible = 'off';
            app.errorCount_txt_2.Layout.Row = 3;
            app.errorCount_txt_2.Layout.Column = 1;
            app.errorCount_txt_2.Text = '0';

            % Create errorCount_img_2
            app.errorCount_img_2 = uiimage(app.lastGPS_Grid1);
            app.errorCount_img_2.Visible = 'off';
            app.errorCount_img_2.Layout.Row = 3;
            app.errorCount_img_2.Layout.Column = 2;
            app.errorCount_img_2.HorizontalAlignment = 'right';
            app.errorCount_img_2.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Warn_18.png');

            % Create task_toolGrid
            app.task_toolGrid = uigridlayout(app.task_Grid);
            app.task_toolGrid.ColumnWidth = {22, 22, 5, 22, '1x', '1x', 22, 22, 22};
            app.task_toolGrid.RowHeight = {'1x', 17, '1x'};
            app.task_toolGrid.ColumnSpacing = 5;
            app.task_toolGrid.RowSpacing = 0;
            app.task_toolGrid.Padding = [5 6 5 6];
            app.task_toolGrid.Layout.Row = 2;
            app.task_toolGrid.Layout.Column = 1;

            % Create task_Status
            app.task_Status = uilabel(app.task_toolGrid);
            app.task_Status.WordWrap = 'on';
            app.task_Status.FontSize = 10;
            app.task_Status.Layout.Row = [1 3];
            app.task_Status.Layout.Column = 5;
            app.task_Status.Text = '';

            % Create task_RevisitTime
            app.task_RevisitTime = uilabel(app.task_toolGrid);
            app.task_RevisitTime.HorizontalAlignment = 'right';
            app.task_RevisitTime.WordWrap = 'on';
            app.task_RevisitTime.FontSize = 10;
            app.task_RevisitTime.Layout.Row = [1 3];
            app.task_RevisitTime.Layout.Column = 6;
            app.task_RevisitTime.Text = '';

            % Create task_ButtonPlay
            app.task_ButtonPlay = uibutton(app.task_toolGrid, 'push');
            app.task_ButtonPlay.ButtonPushedFcn = createCallbackFcn(app, @menu_PushButtonPushed_playTask, true);
            app.task_ButtonPlay.Icon = fullfile(pathToMLAPP, 'Icons', 'play_32.png');
            app.task_ButtonPlay.IconAlignment = 'right';
            app.task_ButtonPlay.BackgroundColor = [0.9412 0.9412 0.9412];
            app.task_ButtonPlay.FontSize = 11;
            app.task_ButtonPlay.Enable = 'off';
            app.task_ButtonPlay.Tooltip = {''};
            app.task_ButtonPlay.Layout.Row = [1 3];
            app.task_ButtonPlay.Layout.Column = 1;
            app.task_ButtonPlay.Text = '';

            % Create task_ButtonDel
            app.task_ButtonDel = uibutton(app.task_toolGrid, 'push');
            app.task_ButtonDel.ButtonPushedFcn = createCallbackFcn(app, @menu_PushButtonPushed_delTask, true);
            app.task_ButtonDel.Icon = fullfile(pathToMLAPP, 'Icons', 'Delete_32Red.png');
            app.task_ButtonDel.IconAlignment = 'right';
            app.task_ButtonDel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.task_ButtonDel.FontSize = 11;
            app.task_ButtonDel.Enable = 'off';
            app.task_ButtonDel.Tooltip = {''};
            app.task_ButtonDel.Layout.Row = [1 3];
            app.task_ButtonDel.Layout.Column = 2;
            app.task_ButtonDel.Text = '';

            % Create task_Separator2
            app.task_Separator2 = uiimage(app.task_toolGrid);
            app.task_Separator2.ScaleMethod = 'fill';
            app.task_Separator2.Enable = 'off';
            app.task_Separator2.Layout.Row = 2;
            app.task_Separator2.Layout.Column = 3;
            app.task_Separator2.ImageSource = fullfile(pathToMLAPP, 'Icons', 'LineV.png');

            % Create task_ButtonLOG
            app.task_ButtonLOG = uibutton(app.task_toolGrid, 'push');
            app.task_ButtonLOG.ButtonPushedFcn = createCallbackFcn(app, @menu_PushButtonPushed_logTask, true);
            app.task_ButtonLOG.Icon = fullfile(pathToMLAPP, 'Icons', 'LOG_32.png');
            app.task_ButtonLOG.IconAlignment = 'right';
            app.task_ButtonLOG.BackgroundColor = [0.9412 0.9412 0.9412];
            app.task_ButtonLOG.FontSize = 11;
            app.task_ButtonLOG.Enable = 'off';
            app.task_ButtonLOG.Tooltip = {''};
            app.task_ButtonLOG.Layout.Row = [1 3];
            app.task_ButtonLOG.Layout.Column = 4;
            app.task_ButtonLOG.Text = '';

            % Create task_RightPanel
            app.task_RightPanel = uiimage(app.task_toolGrid);
            app.task_RightPanel.ImageClickedFcn = createCallbackFcn(app, @menu_LayoutPanelVisibility, true);
            app.task_RightPanel.Layout.Row = [1 3];
            app.task_RightPanel.Layout.Column = 9;
            app.task_RightPanel.ImageSource = fullfile(pathToMLAPP, 'Icons', 'layoutRight.png');

            % Create task_LeftPanel
            app.task_LeftPanel = uiimage(app.task_toolGrid);
            app.task_LeftPanel.ImageClickedFcn = createCallbackFcn(app, @menu_LayoutPanelVisibility, true);
            app.task_LeftPanel.Layout.Row = [1 3];
            app.task_LeftPanel.Layout.Column = 8;
            app.task_LeftPanel.ImageSource = fullfile(pathToMLAPP, 'Icons', 'layoutLeft.png');

            % Create task_TopPanel
            app.task_TopPanel = uiimage(app.task_toolGrid);
            app.task_TopPanel.ImageClickedFcn = createCallbackFcn(app, @menu_LayoutPanelVisibility, true);
            app.task_TopPanel.Layout.Row = [1 3];
            app.task_TopPanel.Layout.Column = 7;
            app.task_TopPanel.ImageSource = fullfile(pathToMLAPP, 'Icons', 'layoutTop.png');

            % Create Tab3_InstrumentList
            app.Tab3_InstrumentList = uitab(app.TabGroup);
            app.Tab3_InstrumentList.Title = 'INSTRUMENT';

            % Create Tab2_TaskList
            app.Tab2_TaskList = uitab(app.TabGroup);
            app.Tab2_TaskList.Title = 'TASK:EDIT';

            % Create TASKADDTab
            app.TASKADDTab = uitab(app.TabGroup);
            app.TASKADDTab.Title = 'TASK:ADD';

            % Create Tab4_Server
            app.Tab4_Server = uitab(app.TabGroup);
            app.Tab4_Server.Title = 'SERVER';

            % Create Tab5_Config
            app.Tab5_Config = uitab(app.TabGroup);
            app.Tab5_Config.Title = 'CONFIG';

            % Create menu_Grid
            app.menu_Grid = uigridlayout(app.GridLayout);
            app.menu_Grid.ColumnWidth = {28, 5, 28, 28, 28, 5, 28, 28, '1x', 20, 20, 20, 0, 0};
            app.menu_Grid.RowHeight = {7, '1x', 7};
            app.menu_Grid.ColumnSpacing = 5;
            app.menu_Grid.RowSpacing = 0;
            app.menu_Grid.Padding = [5 5 5 5];
            app.menu_Grid.Tag = 'COLORLOCKED';
            app.menu_Grid.Layout.Row = 1;
            app.menu_Grid.Layout.Column = 1;
            app.menu_Grid.BackgroundColor = [0.2 0.2 0.2];

            % Create menu_Button1
            app.menu_Button1 = uibutton(app.menu_Grid, 'state');
            app.menu_Button1.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button1.Tag = 'TASK:VIEW';
            app.menu_Button1.Tooltip = {'Acompanha execução de tarefas'};
            app.menu_Button1.Icon = fullfile(pathToMLAPP, 'Icons', 'Playback_32Yellow.png');
            app.menu_Button1.IconAlignment = 'top';
            app.menu_Button1.Text = '';
            app.menu_Button1.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button1.FontSize = 11;
            app.menu_Button1.Layout.Row = [1 3];
            app.menu_Button1.Layout.Column = 1;
            app.menu_Button1.Value = true;

            % Create menu_Separator1
            app.menu_Separator1 = uiimage(app.menu_Grid);
            app.menu_Separator1.ScaleMethod = 'fill';
            app.menu_Separator1.Enable = 'off';
            app.menu_Separator1.Layout.Row = [1 3];
            app.menu_Separator1.Layout.Column = 2;
            app.menu_Separator1.VerticalAlignment = 'bottom';
            app.menu_Separator1.ImageSource = fullfile(pathToMLAPP, 'Icons', 'LineV_White.png');

            % Create menu_Button2
            app.menu_Button2 = uibutton(app.menu_Grid, 'state');
            app.menu_Button2.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button2.Tag = 'INSTRUMENT';
            app.menu_Button2.Tooltip = {'Edita lista de instrumentos'};
            app.menu_Button2.Icon = fullfile(pathToMLAPP, 'Icons', 'Connect_36White.png');
            app.menu_Button2.IconAlignment = 'right';
            app.menu_Button2.Text = '';
            app.menu_Button2.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button2.FontSize = 11;
            app.menu_Button2.Layout.Row = [1 3];
            app.menu_Button2.Layout.Column = 3;

            % Create menu_Button3
            app.menu_Button3 = uibutton(app.menu_Grid, 'state');
            app.menu_Button3.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button3.Tag = 'TASK:EDIT';
            app.menu_Button3.Tooltip = {'Edita lista de tarefas'};
            app.menu_Button3.Icon = fullfile(pathToMLAPP, 'Icons', 'Task_36White.png');
            app.menu_Button3.IconAlignment = 'right';
            app.menu_Button3.Text = '';
            app.menu_Button3.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button3.FontSize = 11;
            app.menu_Button3.Layout.Row = [1 3];
            app.menu_Button3.Layout.Column = 4;

            % Create menu_Button4
            app.menu_Button4 = uibutton(app.menu_Grid, 'state');
            app.menu_Button4.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button4.Tag = 'TASK:ADD';
            app.menu_Button4.Tooltip = {'Adiciona nova tarefa'};
            app.menu_Button4.Icon = fullfile(pathToMLAPP, 'Icons', 'AddFile_36White.png');
            app.menu_Button4.IconAlignment = 'right';
            app.menu_Button4.Text = '';
            app.menu_Button4.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button4.FontSize = 11;
            app.menu_Button4.Layout.Row = [1 3];
            app.menu_Button4.Layout.Column = 5;

            % Create menu_Separator2
            app.menu_Separator2 = uiimage(app.menu_Grid);
            app.menu_Separator2.ScaleMethod = 'fill';
            app.menu_Separator2.Enable = 'off';
            app.menu_Separator2.Layout.Row = [1 3];
            app.menu_Separator2.Layout.Column = 6;
            app.menu_Separator2.VerticalAlignment = 'bottom';
            app.menu_Separator2.ImageSource = fullfile(pathToMLAPP, 'Icons', 'LineV_White.png');

            % Create menu_Button5
            app.menu_Button5 = uibutton(app.menu_Grid, 'state');
            app.menu_Button5.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button5.Tag = 'SERVER';
            app.menu_Button5.Tooltip = {'Servidor'};
            app.menu_Button5.Icon = fullfile(pathToMLAPP, 'Icons', 'Server_36White.png');
            app.menu_Button5.IconAlignment = 'right';
            app.menu_Button5.Text = '';
            app.menu_Button5.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button5.FontSize = 11;
            app.menu_Button5.Layout.Row = [1 3];
            app.menu_Button5.Layout.Column = 7;

            % Create menu_Button6
            app.menu_Button6 = uibutton(app.menu_Grid, 'state');
            app.menu_Button6.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button6.Tag = 'CONFIG';
            app.menu_Button6.Tooltip = {'Configurações gerais'};
            app.menu_Button6.Icon = fullfile(pathToMLAPP, 'Icons', 'Settings_36White.png');
            app.menu_Button6.IconAlignment = 'right';
            app.menu_Button6.Text = '';
            app.menu_Button6.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button6.FontSize = 11;
            app.menu_Button6.Layout.Row = [1 3];
            app.menu_Button6.Layout.Column = 8;

            % Create jsBackDoor
            app.jsBackDoor = uihtml(app.menu_Grid);
            app.jsBackDoor.Layout.Row = 2;
            app.jsBackDoor.Layout.Column = 10;

            % Create FigurePosition
            app.FigurePosition = uiimage(app.menu_Grid);
            app.FigurePosition.ImageClickedFcn = createCallbackFcn(app, @menu_ToolbarImageCliced, true);
            app.FigurePosition.Layout.Row = 2;
            app.FigurePosition.Layout.Column = 11;
            app.FigurePosition.ImageSource = fullfile(pathToMLAPP, 'Icons', 'layout1_32White.png');

            % Create AppInfo
            app.AppInfo = uiimage(app.menu_Grid);
            app.AppInfo.ImageClickedFcn = createCallbackFcn(app, @menu_ToolbarImageCliced, true);
            app.AppInfo.Layout.Row = 2;
            app.AppInfo.Layout.Column = 12;
            app.AppInfo.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Dots_32White.png');

            % Create dockModule_Close
            app.dockModule_Close = uiimage(app.menu_Grid);
            app.dockModule_Close.ScaleMethod = 'none';
            app.dockModule_Close.ImageClickedFcn = createCallbackFcn(app, @menu_DockButtonPushed, true);
            app.dockModule_Close.Tag = 'DRIVETEST';
            app.dockModule_Close.Tooltip = {'Fecha módulo'};
            app.dockModule_Close.Layout.Row = 2;
            app.dockModule_Close.Layout.Column = 14;
            app.dockModule_Close.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Delete_12SVG_white.svg');

            % Create dockModule_Undock
            app.dockModule_Undock = uiimage(app.menu_Grid);
            app.dockModule_Undock.ScaleMethod = 'none';
            app.dockModule_Undock.ImageClickedFcn = createCallbackFcn(app, @menu_DockButtonPushed, true);
            app.dockModule_Undock.Tag = 'DRIVETEST';
            app.dockModule_Undock.Tooltip = {'Reabre módulo em outra janela'};
            app.dockModule_Undock.Layout.Row = 2;
            app.dockModule_Undock.Layout.Column = 13;
            app.dockModule_Undock.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Undock_18White.png');

            % Create popupContainerGrid
            app.popupContainerGrid = uigridlayout(app.GridLayout);
            app.popupContainerGrid.ColumnWidth = {'1x', 880, '1x'};
            app.popupContainerGrid.RowHeight = {'1x', 90, 300, 90, '1x'};
            app.popupContainerGrid.ColumnSpacing = 0;
            app.popupContainerGrid.RowSpacing = 0;
            app.popupContainerGrid.Padding = [13 10 0 10];
            app.popupContainerGrid.Layout.Row = 3;
            app.popupContainerGrid.Layout.Column = 1;
            app.popupContainerGrid.BackgroundColor = [1 1 1];

            % Create popupContainer
            app.popupContainer = uipanel(app.popupContainerGrid);
            app.popupContainer.Visible = 'off';
            app.popupContainer.BackgroundColor = [1 1 1];
            app.popupContainer.Layout.Row = [2 4];
            app.popupContainer.Layout.Column = 2;

            % Create SplashScreen
            app.SplashScreen = uiimage(app.popupContainerGrid);
            app.SplashScreen.Layout.Row = 3;
            app.SplashScreen.Layout.Column = 2;
            app.SplashScreen.ImageSource = fullfile(pathToMLAPP, 'Icons', 'SplashScreen.gif');

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = winAppColeta_exported

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
