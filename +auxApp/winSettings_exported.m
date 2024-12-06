classdef winSettings_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        EditionModeLabel               matlab.ui.control.Label
        toolGrid                       matlab.ui.container.GridLayout
        toolButton_edit                matlab.ui.control.Button
        MainPanel                      matlab.ui.container.Panel
        MainPanelGrid                  matlab.ui.container.GridLayout
        Tab1_Panel                     matlab.ui.container.Panel
        general_Grid                   matlab.ui.container.GridLayout
        Tab2_Panel                     matlab.ui.container.Panel
        server_Grid                    matlab.ui.container.GridLayout
        server_Status                  matlab.ui.control.DropDown
        server_StatusLabel             matlab.ui.control.Label
        server_Port                    matlab.ui.control.NumericEditField
        server_PortLabel               matlab.ui.control.Label
        server_IP                      matlab.ui.control.EditField
        server_IPLabel                 matlab.ui.control.Label
        server_ClientList              matlab.ui.control.EditField
        server_ClientListLabel         matlab.ui.control.Label
        server_Key                     matlab.ui.control.EditField
        server_KeyLabel                matlab.ui.control.Label
        general_gpu                    matlab.ui.control.DropDown
        general_gpuLabel               matlab.ui.control.Label
        general_versionLabel           matlab.ui.control.Label
        general_stationPanel           matlab.ui.container.Panel
        general_stationGrid            matlab.ui.container.GridLayout
        general_lastSessionInfoGrid    matlab.ui.container.GridLayout
        general_lastSessionInfo        matlab.ui.control.CheckBox
        general_lastSessionInfoLabel   matlab.ui.control.Label
        general_stationLongitude       matlab.ui.control.NumericEditField
        general_stationLongitudeLabel  matlab.ui.control.Label
        general_stationLatitude        matlab.ui.control.NumericEditField
        general_stationLatitudeLabel   matlab.ui.control.Label
        general_stationType            matlab.ui.control.DropDown
        general_stationTypeLabel       matlab.ui.control.Label
        general_stationName            matlab.ui.control.EditField
        general_stationNameLabel       matlab.ui.control.Label
        general_stationLabel           matlab.ui.control.Label
        general_versionPanel           matlab.ui.container.Panel
        general_versionGrid            matlab.ui.container.GridLayout
        AppVersion                     matlab.ui.control.HTML
        Tab3_Panel                     matlab.ui.container.Panel
        plot_Grid                      matlab.ui.container.GridLayout
        plot_IntegrationPanel          matlab.ui.container.Panel
        plot_IntegrationGrid           matlab.ui.container.GridLayout
        plot_IntegrationTrace          matlab.ui.control.NumericEditField
        plot_IntegrationTraceLabel     matlab.ui.control.Label
        plot_IntegrationTime           matlab.ui.control.NumericEditField
        plot_IntegrationTimeLabel      matlab.ui.control.Label
        plot_IntegrationLabel          matlab.ui.control.Label
        plot_WaterfallPanel            matlab.ui.container.Panel
        plot_WaterfallGrid             matlab.ui.container.GridLayout
        plot_WaterfallColormap         matlab.ui.control.DropDown
        plot_WaterfallColormapLabel    matlab.ui.control.Label
        plot_WaterfallDepth            matlab.ui.control.DropDown
        plot_WaterfallDepthLabel       matlab.ui.control.Label
        plot_WaterfallLabel            matlab.ui.control.Label
        plot_colorsGrid                matlab.ui.container.GridLayout
        plot_colorsMaxHold             matlab.ui.control.Button
        plot_colorsClearWrite          matlab.ui.control.Button
        plot_colorsAverage             matlab.ui.control.Button
        plot_colorsMinHold             matlab.ui.control.Button
        plot_colorsLabel               matlab.ui.control.Label
        plot_TiledSpacing              matlab.ui.control.DropDown
        plot_TiledSpacingLabel         matlab.ui.control.Label
        plot_InteractionsPanel         matlab.ui.container.Panel
        plot_InteractionsGrid          matlab.ui.container.GridLayout
        plot_RestoreViewVisibility     matlab.ui.control.Image
        plot_RestoreView               matlab.ui.control.Image
        plot_ZoomOutVisibility         matlab.ui.control.Image
        plot_ZoomOut                   matlab.ui.control.Image
        plot_ZoomInVisibility          matlab.ui.control.Image
        plot_ZoomIn                    matlab.ui.control.Image
        plot_PanVisibility             matlab.ui.control.Image
        plot_Pan                       matlab.ui.control.Image
        plot_DatatipVisibility         matlab.ui.control.Image
        plot_Datatip                   matlab.ui.control.Image
        plot_InteractionsLabel         matlab.ui.control.Label
        Tab3_Grid                      matlab.ui.container.GridLayout
        plot_refresh                   matlab.ui.control.Image
        Tab3_Image                     matlab.ui.control.Image
        Tab3_Title                     matlab.ui.control.Label
        Tab2_GridTitle                 matlab.ui.container.GridLayout
        Tab2_Image                     matlab.ui.control.Image
        Tab2_Title                     matlab.ui.control.Label
        Tab1_GridTitle                 matlab.ui.container.GridLayout
        Tab1_Image                     matlab.ui.control.Image
        Tab1_Title                     matlab.ui.control.Label
        ButtonGroupPanel               matlab.ui.container.ButtonGroup
        ButtonGroup_Edit               matlab.ui.control.RadioButton
        ButtonGroup_View               matlab.ui.control.RadioButton
    end

    
    properties
        %-----------------------------------------------------------------%
        Container
        isDocked = false
        
        CallingApp
        rootFolder

        General
        editedGeneral
        editedFlag = false
    end
    

    methods (Access = private)
        %-----------------------------------------------------------------%
        function Layout(app)
            % PAINEL "VERSÃO"                
            AppVersion_updatePanel(app)

            % PAINEL "CONFIGURAÇÕES GERAIS"
            app.general_stationName.Value        = app.editedGeneral.stationInfo.Name;
            app.general_stationType.Items        = {app.editedGeneral.stationInfo.Type};
            app.general_stationLatitude.Value    = app.editedGeneral.stationInfo.Latitude;
            app.general_stationLongitude.Value   = app.editedGeneral.stationInfo.Longitude;
            app.general_lastSessionInfo.Value    = app.editedGeneral.startupInfo;

            switch app.editedGeneral.tcpServer.Status
                case 0; app.server_Status.Items  = {'OFF'};
                case 1; app.server_Status.Items  = {'ON'};
            end

            app.server_Key.Value        = app.editedGeneral.tcpServer.Key;
            app.server_ClientList.Value = strjoin(app.editedGeneral.tcpServer.ClientList, ', ');
            app.server_IP.Value         = app.editedGeneral.tcpServer.IP;
            app.server_Port.Value       = app.editedGeneral.tcpServer.Port;
            
            graphRender = opengl('data');
            switch graphRender.HardwareSupportLevel
                case 'basic'; app.general_gpu.Items = {'hardwarebasic'};
                case 'full';  app.general_gpu.Items = {'hardware'};
                case 'none';  app.general_gpu.Items = {'software'};
                otherwise;    app.general_gpu.Items = {graphRender.HardwareSupportLevel}; % "driverissue"
            end

            % PAINEL "PLOT"
            Layout_plotInteractions(app)
            Layout_plotTiledSpacing(app)

            app.plot_colorsMinHold.BackgroundColor    = app.editedGeneral.Plot.MinHold.Color;
            app.plot_colorsAverage.BackgroundColor    = app.editedGeneral.Plot.Average.Color;
            app.plot_colorsMaxHold.BackgroundColor    = app.editedGeneral.Plot.MaxHold.Color;
            app.plot_colorsClearWrite.BackgroundColor = app.editedGeneral.Plot.ClearWrite.Color;
            
            app.plot_WaterfallColormap.Items          = {app.editedGeneral.Plot.Waterfall.Colormap};
            app.plot_WaterfallDepth.Items             = {num2str(app.editedGeneral.Plot.Waterfall.Depth)};

            app.plot_IntegrationTrace.Value           = app.editedGeneral.Integration.Trace;
            app.plot_IntegrationTime.Value            = app.editedGeneral.Integration.SampleTime;
        end

        %-----------------------------------------------------------------%
        function AppVersion_updatePanel(app)
            % Versão
            htmlContent = auxApp.config.htmlCode_AppVersion(app.CallingApp.General, app.CallingApp.executionMode);
            app.AppVersion.HTMLSource = htmlContent;
        end

        %-----------------------------------------------------------------%
        function Layout_plotInteractions(app)
            set(findobj(app.plot_InteractionsGrid, Tag='InteractionVisibility'), Visible=0)

            for ii = 1:numel(app.CallingApp.axes1.Toolbar.Children)
                switch app.CallingApp.axes1.Toolbar.Children(ii).Tag
                    case 'datacursor';  h = app.plot_DatatipVisibility;
                    case 'pan';         h = app.plot_PanVisibility;
                    case 'zoomin';      h = app.plot_ZoomInVisibility;
                    case 'zoomout';     h = app.plot_ZoomOutVisibility;
                    case 'restoreview'; h = app.plot_RestoreViewVisibility;
                end

                if app.CallingApp.axes1.Toolbar.Children(ii).Visible
                    h.Visible = 1;
                end
            end
        end


        %-----------------------------------------------------------------%
        function Layout_plotTiledSpacing(app)
            app.plot_TiledSpacing.Value = app.CallingApp.axes1.Parent.TileSpacing;
        end


        %-----------------------------------------------------------------%
        function status = IPv4Validation(app, ipAddress)
            status   = true;
            ipString = regexp(ipAddress, '\d*[.]{1}\d{1,3}[.]{1}\d{1,3}[.]{1}\d*', 'match');
            
            if isempty(ipString)
                status = false;
            else
                ipArray = cellfun(@(x) str2double(x), strsplit(char(ipString), '.'));
                if any(ipArray > 255) || any(isnan(ipArray))
                    status = false;
                end                    
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp)
            
            % A razão de ser deste app é possibilitar visualização/edição 
            % do arquivo "GeneralSettings.json".
            
            app.CallingApp = mainapp;
            app.rootFolder = app.CallingApp.rootFolder;
            app.General    = app.CallingApp.General;
            app.editedGeneral = app.General;

            if app.isDocked
                app.GridLayout.Padding(4) = 19;
            else
                appUtil.winPosition(app.UIFigure)
            end

            Layout(app)
            
        end

        % Close request function: UIFigure
        function closeFcn(app, event)
            
            if app.editedFlag
                appUtil.generalSettingsSave(class.Constants.appName, app.rootFolder, app.CallingApp.General_I, app.CallingApp.executionMode)

                app.CallingApp.General = app.General;
                eval(sprintf('opengl %s', app.General.openGL))
            end

            appBackDoor(app.CallingApp, app, 'closeFcn', 'CONFIG')
            delete(app)
            
        end

        % Selection changed function: ButtonGroupPanel
        function ValueChanged_OperationMode(app, event)
            
            %-------------------------------------------------------------%
            % ## MODO DE VISUALIZAÇÃO ##
            %-------------------------------------------------------------%
            if app.ButtonGroup_View.Value
                % Aspectos relacionados à indicação visual de que se trata 
                % do modo de visualização:
                app.EditionModeLabel.Visible = 0;
                app.toolButton_edit.Visible  = 0;
                app.plot_refresh.Visible     = 0;

                % Desabilita edição do conteúdo dos campos...
                set(findobj(app.general_stationGrid,  'Type', 'uinumericeditfield', '-or', 'Type', 'uieditfield'), Editable='off')
                set(findobj(app.server_Grid,          'Type', 'uinumericeditfield', '-or', 'Type', 'uieditfield'), Editable='off')
                set(findobj(app.plot_WaterfallGrid,   'Type', 'uinumericeditfield', '-or', 'Type', 'uieditfield'), Editable='off')
                set(findobj(app.plot_IntegrationGrid, 'Type', 'uinumericeditfield', '-or', 'Type', 'uieditfield'), Editable='off')
                
                app.general_lastSessionInfo.Enable = 0;

                set(app.general_stationType,    'Items', {app.general_stationType.Value})
                set(app.server_Status,          'Items', {app.server_Status.Value})
                set(app.general_gpu,            'Items', {app.general_gpu.Value})
                set(app.plot_WaterfallColormap, 'Items', {app.plot_WaterfallColormap.Value})
                set(app.plot_WaterfallDepth,    'Items', {app.plot_WaterfallDepth.Value})

                % Essa última validação é essencial para desfazer alterações 
                % que não foram salvas. Ou seja, o usuário fez alterações
                % em app.General (que estavam armazenadas na sua cópia -
                % app.editedGeneral) e não clicou no botão "Confirma edição".

                if ~isequal(app.General, app.editedGeneral)
                    app.editedGeneral = app.General;
                    Layout(app)
                end

            %-------------------------------------------------------------%
            % ## MODO DE EDIÇÃO ##
            %-------------------------------------------------------------%
            else
                % Aspectos relacionados à indicação visual de que se trata 
                % do modo de edição:
                app.EditionModeLabel.Visible = 1;
                app.toolButton_edit.Visible  = 1;
                app.plot_refresh.Visible     = 1;

                % Habilita edição do conteúdo dos campos...
                set(findobj(app.general_stationGrid,  'Type', 'uinumericeditfield', '-or', 'Type', 'uieditfield'), Editable='on')
                set(findobj(app.server_Grid,          'Type', 'uinumericeditfield', '-or', 'Type', 'uieditfield'), Editable='on')
                set(findobj(app.plot_WaterfallGrid,   'Type', 'uinumericeditfield', '-or', 'Type', 'uieditfield'), Editable='on')
                set(findobj(app.plot_IntegrationGrid, 'Type', 'uinumericeditfield', '-or', 'Type', 'uieditfield'), Editable='on')
                app.general_lastSessionInfo.Enable = 1;

                set(app.general_stationType,    'Items', {'Fixed', 'Mobile'})
                set(app.server_Status,          'Items', {'ON', 'OFF'})
                set(app.plot_WaterfallColormap, 'Items', {'gray', 'hot', 'jet', 'summer', 'turbo', 'winter'})
                set(app.plot_WaterfallDepth,    'Items', {'64', '128', '256', '512'})

                if ismember(app.general_gpu.Value, {'hardwarebasic', 'hardware', 'software'})
                    set(app.general_gpu,        'Items', {'hardwarebasic', 'hardware', 'software'})
                else
                    set(app.general_gpu,        'Items', {'hardwarebasic', 'hardware', 'software', app.general_gpu.Value})
                end
            end

        end

        % Value changed function: general_gpu, general_lastSessionInfo, 
        % ...and 13 other components
        function ValueChanged_Parameter(app, event)
            
            switch event.Source
                %---------------------------------------------------------%
                case app.general_stationName
                    if isempty(regexp(app.general_stationName.Value, '^EMSat$|^UMS.*|^ERMx-[A-Z]{2}-[0-9][1-9]$', 'once'))
                        msgQuestion   = ['O nome esperado de uma estação é <b>"ERMx-UF-XX"</b>, sendo "UF" a sigla da unidade da '     ...
                                         'federação e XX dois dígitos numéricos (01 a 99). Além disso, são previstas inclusões '       ...
                                         'de nomes de estações iniciando com <b>"UMS</b>" ou <b>"EMSat"</b>.<br><br>O nome inserido, ' ...
                                         'contudo, difere dessas opções. Deseja continuar?'];
                        userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);
                            if strcmp(userSelection, 'Não')
                                app.general_stationName.Value = event.PreviousValue;
                                return
                            end
                    end

                    app.editedGeneral.stationInfo.Name = app.general_stationName.Value;

                %---------------------------------------------------------%
                case app.general_stationType
                    app.editedGeneral.stationInfo.Type      = app.general_stationType.Value;

                %---------------------------------------------------------%
                case app.general_stationLatitude
                    app.editedGeneral.stationInfo.Latitude  = app.general_stationLatitude.Value;

                %---------------------------------------------------------%
                case app.general_stationLongitude
                    app.editedGeneral.stationInfo.Longitude = app.general_stationLongitude.Value;

                %---------------------------------------------------------%
                case app.general_lastSessionInfo
                    app.editedGeneral.startupInfo = app.general_lastSessionInfo.Value;                    

                %---------------------------------------------------------%
                case app.server_Status
                    switch app.server_Status.Value
                        case 'ON';  app.editedGeneral.tcpServer.Status = 1;
                        case 'OFF'; app.editedGeneral.tcpServer.Status = 0;
                    end

                case app.server_Key
                    app.server_Key.Value = replace(app.server_Key.Value, ' ', '');
                    app.editedGeneral.tcpServer.Key = app.server_Key.Value;

                case app.server_ClientList
                    app.server_ClientList.Value = replace(app.server_ClientList.Value, ' ', '');
                    
                    if isempty(app.server_ClientList.Value)
                        app.editedGeneral.tcpServer.ClientList = {};
                    else
                        app.editedGeneral.tcpServer.ClientList = strsplit(app.server_ClientList.Value, ',');
                    end

                    app.server_ClientList.Value = strjoin(app.editedGeneral.tcpServer.ClientList, ', ');

                case app.server_IP
                    app.server_IP.Value = strtrim(app.server_IP.Value);

                    if IPv4Validation(app, app.server_IP.Value) || isempty(app.server_IP.Value)
                        app.editedGeneral.tcpServer.IP = app.server_IP.Value;
                    else
                        app.server_IP.Value = event.PreviousValue;
                        appUtil.modalWindow(app.UIFigure, 'warning', 'Endereço inválido (IPv4).');
                    end

                case app.server_Port
                    app.editedGeneral.tcpServer.Port = app.server_Port.Value;

                %---------------------------------------------------------%
                case app.general_gpu
                    if ismember(app.general_gpu.Value, {'hardwarebasic', 'hardware', 'software'})
                        app.editedGeneral.openGL = app.general_gpu.Value;
                    end

                %---------------------------------------------------------%
                case app.plot_colorsMinHold
                    app.editedGeneral.Plot.MinHold.Color = rgb2hex(event.Source.BackgroundColor);

                %---------------------------------------------------------%
                case app.plot_colorsAverage
                    app.editedGeneral.Plot.Average.Color = rgb2hex(event.Source.BackgroundColor);

                %---------------------------------------------------------%
                case app.plot_colorsMaxHold
                    app.editedGeneral.Plot.MaxHold.Color = rgb2hex(event.Source.BackgroundColor);

                %---------------------------------------------------------%
                case app.plot_colorsClearWrite
                    app.editedGeneral.Plot.ClearWrite.Color = rgb2hex(event.Source.BackgroundColor);

                %---------------------------------------------------------%
                case app.plot_WaterfallColormap
                    app.editedGeneral.Plot.Waterfall.Colormap = app.plot_WaterfallColormap.Value;

                case app.plot_WaterfallDepth
                    app.editedGeneral.Plot.Waterfall.Depth = str2double(app.plot_WaterfallDepth.Value);
                
                %---------------------------------------------------------%
                case app.plot_IntegrationTrace
                    app.editedGeneral.Integration.Trace = app.plot_IntegrationTrace.Value;

                case app.plot_IntegrationTime
                    app.editedGeneral.Integration.SampleTime = app.plot_IntegrationTime.Value;
            end
            
        end

        % Image clicked function: plot_refresh
        function plotImageClicked_refresh(app, event)
            
            % Axes toolbar
            Interactions = class.Constants.Interactions;
            plotFcn.axesInteractions(app.CallingApp.axes1, Interactions)
            plotFcn.axesInteractions(app.CallingApp.axes2, Interactions)
            Layout_plotInteractions(app)

            app.CallingApp.axes1.Parent.TileSpacing = 'tight';            
            Layout_plotTiledSpacing(app)

            % Others parameters...
            defaultGeneral = struct('Colors',     [0.38,0.60,0.73;  ...
                                                   0.39,0.83,0.07;  ...
                                                   1.00,0.07,0.65;  ...
                                                   0.93,0.69,0.13], ...
                                    'Waterfall',   struct('Colormap', 'winter', 'Depth', 512), ...
                                    'Integration', struct('Trace', 10, 'SampleTime', 10));

            if ~isequal(app.editedGeneral.Colors,      defaultGeneral.Colors)    || ...
               ~isequal(app.editedGeneral.Waterfall,   defaultGeneral.Waterfall) || ...
               ~isequal(app.editedGeneral.Integration, defaultGeneral.Integration)

                app.editedGeneral.Colors      = defaultGeneral.Colors;
                app.editedGeneral.Waterfall   = defaultGeneral.Waterfall;
                app.editedGeneral.Integration = defaultGeneral.Integration;

                Layout(app)
                ValueChanged_OperationMode(app)
            end

        end

        % Image clicked function: plot_Datatip, plot_Pan, 
        % ...and 3 other components
        function plotImageClicked_Interactions(app, event)
            
            % Interações atuais:
            for ii = 1:numel(app.CallingApp.axes1.Toolbar.Children)
                if isprop(app.CallingApp.axes1.Toolbar.Children(ii), 'Value') && app.CallingApp.axes1.Toolbar.Children(ii).Value
                    appUtil.modalWindow(app.UIFigure, 'warning', 'Operação não realizada! É preciso desabilitar qualquer interação com os plots...');
                    return
                end
            end

            % Interações desejadas:
            switch event.Source
                case app.plot_Datatip;     h = app.plot_DatatipVisibility;
                case app.plot_Pan;         h = app.plot_PanVisibility;
                case app.plot_ZoomIn;      h = app.plot_ZoomInVisibility;
                case app.plot_ZoomOut;     h = app.plot_ZoomOutVisibility;
                case app.plot_RestoreView; h = app.plot_RestoreViewVisibility;
            end
            h.Visible = ~h.Visible;
            
            finalInteractions = {};
            if app.plot_DatatipVisibility.Visible;     finalInteractions = [finalInteractions, 'datacursor' ]; end
            if app.plot_PanVisibility.Visible;         finalInteractions = [finalInteractions, 'pan'        ]; end
            if app.plot_ZoomInVisibility.Visible;      finalInteractions = [finalInteractions, 'zoomin'     ]; end
            if app.plot_ZoomOutVisibility.Visible;     finalInteractions = [finalInteractions, 'zoomout'    ]; end
            if app.plot_RestoreViewVisibility.Visible; finalInteractions = [finalInteractions, 'restoreview']; end

            plotFcn.axesInteractions(app.CallingApp.axes1, finalInteractions)
            plotFcn.axesInteractions(app.CallingApp.axes2, finalInteractions)

            if isempty(finalInteractions)
                app.CallingApp.axes1.PickableParts = 'none';
                app.CallingApp.axes2.PickableParts = 'none';
            else
                app.CallingApp.axes1.PickableParts = 'visible';
                app.CallingApp.axes2.PickableParts = 'visible';
            end

            Layout_plotInteractions(app)

        end

        % Value changed function: plot_TiledSpacing
        function plotDropDown_TiledSpacing(app, event)
            
            app.CallingApp.axes1.Parent.TileSpacing = app.plot_TiledSpacing.Value;
            
        end

        % Button pushed function: plot_colorsAverage, 
        % ...and 3 other components
        function plotButtonPushed_colors(app, event)
            
            if app.ButtonGroup_Edit.Value
                initialColor  = event.Source.BackgroundColor;
                selectedColor = uisetcolor(initialColor);
                figure(app.UIFigure)
    
                if ~isequal(initialColor, selectedColor)
                    switch event.Source
                        case app.plot_colorsMinHold;    app.plot_colorsMinHold.BackgroundColor    = selectedColor;
                        case app.plot_colorsAverage;    app.plot_colorsAverage.BackgroundColor    = selectedColor;
                        case app.plot_colorsMaxHold;    app.plot_colorsMaxHold.BackgroundColor    = selectedColor;
                        case app.plot_colorsClearWrite; app.plot_colorsClearWrite.BackgroundColor = selectedColor;
                    end
    
                    ValueChanged_Parameter(app, event)
                end
            end

        end

        % Button pushed function: toolButton_edit
        function toolButtonPushed_edit(app, event)
            
            % Finalizada a edição, avalia-se se algum parâmetro foi, de fato, 
            % alterado, colocando essa informação na variável app.editedFlag.
            % Por fim, volta-se ao "MODO DE VISUALIZAÇÃO", clicando-se
            % programaticamente no botão de controle e, posteriormente,
            % acionando o seu callback.

            if ~isequal(app.General, app.editedGeneral)
                app.General    = app.editedGeneral;
                app.editedFlag = true;
            end
            
            app.ButtonGroup_View.Value = 1;
            ValueChanged_OperationMode(app)

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app, Container)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            if isempty(Container)
                app.UIFigure = uifigure('Visible', 'off');
                app.UIFigure.AutoResizeChildren = 'off';
                app.UIFigure.Position = [100 100 940 540];
                app.UIFigure.Name = 'appAnalise';
                app.UIFigure.Icon = 'icon_48.png';
                app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeFcn, true);

                app.Container = app.UIFigure;

            else
                if ~isempty(Container.Children)
                    delete(Container.Children)
                end

                app.UIFigure  = ancestor(Container, 'figure');
                app.Container = Container;
                app.isDocked  = true;
            end

            % Create GridLayout
            app.GridLayout = uigridlayout(app.Container);
            app.GridLayout.ColumnWidth = {'1x', 110};
            app.GridLayout.RowHeight = {22, '1x', 22};
            app.GridLayout.ColumnSpacing = 5;
            app.GridLayout.RowSpacing = 5;
            app.GridLayout.BackgroundColor = [1 1 1];

            % Create ButtonGroupPanel
            app.ButtonGroupPanel = uibuttongroup(app.GridLayout);
            app.ButtonGroupPanel.SelectionChangedFcn = createCallbackFcn(app, @ValueChanged_OperationMode, true);
            app.ButtonGroupPanel.BorderWidth = 0;
            app.ButtonGroupPanel.BackgroundColor = [1 1 1];
            app.ButtonGroupPanel.Layout.Row = 1;
            app.ButtonGroupPanel.Layout.Column = 1;

            % Create ButtonGroup_View
            app.ButtonGroup_View = uiradiobutton(app.ButtonGroupPanel);
            app.ButtonGroup_View.Text = 'Visualizar parâmetros';
            app.ButtonGroup_View.FontSize = 11;
            app.ButtonGroup_View.Position = [12 1 128 22];
            app.ButtonGroup_View.Value = true;

            % Create ButtonGroup_Edit
            app.ButtonGroup_Edit = uiradiobutton(app.ButtonGroupPanel);
            app.ButtonGroup_Edit.Text = 'Editar parâmetros';
            app.ButtonGroup_Edit.FontSize = 11;
            app.ButtonGroup_Edit.Position = [193 1 109 22];

            % Create MainPanel
            app.MainPanel = uipanel(app.GridLayout);
            app.MainPanel.Layout.Row = 2;
            app.MainPanel.Layout.Column = [1 2];

            % Create MainPanelGrid
            app.MainPanelGrid = uigridlayout(app.MainPanel);
            app.MainPanelGrid.ColumnWidth = {286, 286, '1x'};
            app.MainPanelGrid.RowHeight = {22, '1x'};
            app.MainPanelGrid.ColumnSpacing = 20;
            app.MainPanelGrid.RowSpacing = 5;
            app.MainPanelGrid.BackgroundColor = [1 1 1];

            % Create Tab1_GridTitle
            app.Tab1_GridTitle = uigridlayout(app.MainPanelGrid);
            app.Tab1_GridTitle.ColumnWidth = {18, '1x'};
            app.Tab1_GridTitle.RowHeight = {'1x'};
            app.Tab1_GridTitle.ColumnSpacing = 5;
            app.Tab1_GridTitle.RowSpacing = 5;
            app.Tab1_GridTitle.Padding = [2 2 2 2];
            app.Tab1_GridTitle.Tag = 'COLORLOCKED';
            app.Tab1_GridTitle.Layout.Row = 1;
            app.Tab1_GridTitle.Layout.Column = 1;
            app.Tab1_GridTitle.BackgroundColor = [0.749 0.749 0.749];

            % Create Tab1_Title
            app.Tab1_Title = uilabel(app.Tab1_GridTitle);
            app.Tab1_Title.FontSize = 11;
            app.Tab1_Title.Layout.Row = 1;
            app.Tab1_Title.Layout.Column = 2;
            app.Tab1_Title.Text = 'VERSÃO';

            % Create Tab1_Image
            app.Tab1_Image = uiimage(app.Tab1_GridTitle);
            app.Tab1_Image.Layout.Row = 1;
            app.Tab1_Image.Layout.Column = 1;
            app.Tab1_Image.HorizontalAlignment = 'left';
            app.Tab1_Image.ImageSource = 'LT_settings.png';

            % Create Tab2_GridTitle
            app.Tab2_GridTitle = uigridlayout(app.MainPanelGrid);
            app.Tab2_GridTitle.ColumnWidth = {18, '1x'};
            app.Tab2_GridTitle.RowHeight = {'1x'};
            app.Tab2_GridTitle.ColumnSpacing = 5;
            app.Tab2_GridTitle.RowSpacing = 5;
            app.Tab2_GridTitle.Padding = [2 2 2 2];
            app.Tab2_GridTitle.Tag = 'COLORLOCKED';
            app.Tab2_GridTitle.Layout.Row = 1;
            app.Tab2_GridTitle.Layout.Column = 2;
            app.Tab2_GridTitle.BackgroundColor = [0.749 0.749 0.749];

            % Create Tab2_Title
            app.Tab2_Title = uilabel(app.Tab2_GridTitle);
            app.Tab2_Title.FontSize = 11;
            app.Tab2_Title.Layout.Row = 1;
            app.Tab2_Title.Layout.Column = 2;
            app.Tab2_Title.Text = 'CONFIGURAÇÕES GERAIS';

            % Create Tab2_Image
            app.Tab2_Image = uiimage(app.Tab2_GridTitle);
            app.Tab2_Image.Layout.Row = 1;
            app.Tab2_Image.Layout.Column = 1;
            app.Tab2_Image.HorizontalAlignment = 'left';
            app.Tab2_Image.ImageSource = 'LT_Dots2.png';

            % Create Tab3_Grid
            app.Tab3_Grid = uigridlayout(app.MainPanelGrid);
            app.Tab3_Grid.ColumnWidth = {18, '1x', 14};
            app.Tab3_Grid.RowHeight = {'1x'};
            app.Tab3_Grid.ColumnSpacing = 5;
            app.Tab3_Grid.RowSpacing = 5;
            app.Tab3_Grid.Padding = [2 2 2 2];
            app.Tab3_Grid.Tag = 'COLORLOCKED';
            app.Tab3_Grid.Layout.Row = 1;
            app.Tab3_Grid.Layout.Column = 3;
            app.Tab3_Grid.BackgroundColor = [0.749 0.749 0.749];

            % Create Tab3_Title
            app.Tab3_Title = uilabel(app.Tab3_Grid);
            app.Tab3_Title.FontSize = 11;
            app.Tab3_Title.Layout.Row = 1;
            app.Tab3_Title.Layout.Column = 2;
            app.Tab3_Title.Text = 'PLOT';

            % Create Tab3_Image
            app.Tab3_Image = uiimage(app.Tab3_Grid);
            app.Tab3_Image.Layout.Row = 1;
            app.Tab3_Image.Layout.Column = 1;
            app.Tab3_Image.HorizontalAlignment = 'left';
            app.Tab3_Image.ImageSource = 'LT_Detection.png';

            % Create plot_refresh
            app.plot_refresh = uiimage(app.Tab3_Grid);
            app.plot_refresh.ImageClickedFcn = createCallbackFcn(app, @plotImageClicked_refresh, true);
            app.plot_refresh.Visible = 'off';
            app.plot_refresh.Layout.Row = 1;
            app.plot_refresh.Layout.Column = 3;
            app.plot_refresh.HorizontalAlignment = 'left';
            app.plot_refresh.VerticalAlignment = 'bottom';
            app.plot_refresh.ImageSource = 'Refresh_18.png';

            % Create Tab3_Panel
            app.Tab3_Panel = uipanel(app.MainPanelGrid);
            app.Tab3_Panel.AutoResizeChildren = 'off';
            app.Tab3_Panel.Layout.Row = 2;
            app.Tab3_Panel.Layout.Column = 3;

            % Create plot_Grid
            app.plot_Grid = uigridlayout(app.Tab3_Panel);
            app.plot_Grid.RowHeight = {17, 42, 17, 22, 17, 80, 17, 63, 17, '1x'};
            app.plot_Grid.RowSpacing = 5;
            app.plot_Grid.Padding = [10 10 10 5];
            app.plot_Grid.BackgroundColor = [1 1 1];

            % Create plot_InteractionsLabel
            app.plot_InteractionsLabel = uilabel(app.plot_Grid);
            app.plot_InteractionsLabel.VerticalAlignment = 'bottom';
            app.plot_InteractionsLabel.FontSize = 10;
            app.plot_InteractionsLabel.FontWeight = 'bold';
            app.plot_InteractionsLabel.Layout.Row = 1;
            app.plot_InteractionsLabel.Layout.Column = 1;
            app.plot_InteractionsLabel.Text = 'Interações:';

            % Create plot_InteractionsPanel
            app.plot_InteractionsPanel = uipanel(app.plot_Grid);
            app.plot_InteractionsPanel.BackgroundColor = [1 1 1];
            app.plot_InteractionsPanel.Layout.Row = 2;
            app.plot_InteractionsPanel.Layout.Column = [1 2];

            % Create plot_InteractionsGrid
            app.plot_InteractionsGrid = uigridlayout(app.plot_InteractionsPanel);
            app.plot_InteractionsGrid.ColumnWidth = {16, 16, 16, 16, 16, '1x'};
            app.plot_InteractionsGrid.RowHeight = {'1x', 10};
            app.plot_InteractionsGrid.RowSpacing = 3;
            app.plot_InteractionsGrid.Padding = [10 2 10 8];
            app.plot_InteractionsGrid.BackgroundColor = [1 1 1];

            % Create plot_Datatip
            app.plot_Datatip = uiimage(app.plot_InteractionsGrid);
            app.plot_Datatip.ImageClickedFcn = createCallbackFcn(app, @plotImageClicked_Interactions, true);
            app.plot_Datatip.Tooltip = {'Datatip'};
            app.plot_Datatip.Layout.Row = 1;
            app.plot_Datatip.Layout.Column = 1;
            app.plot_Datatip.ImageSource = 'AxesToolbar_Datatip.png';

            % Create plot_DatatipVisibility
            app.plot_DatatipVisibility = uiimage(app.plot_InteractionsGrid);
            app.plot_DatatipVisibility.ScaleMethod = 'fill';
            app.plot_DatatipVisibility.Tag = 'InteractionVisibility';
            app.plot_DatatipVisibility.Tooltip = {'Datatip'};
            app.plot_DatatipVisibility.Layout.Row = 2;
            app.plot_DatatipVisibility.Layout.Column = 1;
            app.plot_DatatipVisibility.ImageSource = 'LT_LineH.png';

            % Create plot_Pan
            app.plot_Pan = uiimage(app.plot_InteractionsGrid);
            app.plot_Pan.ImageClickedFcn = createCallbackFcn(app, @plotImageClicked_Interactions, true);
            app.plot_Pan.Tooltip = {'Pan'};
            app.plot_Pan.Layout.Row = 1;
            app.plot_Pan.Layout.Column = 2;
            app.plot_Pan.ImageSource = 'AxesToolbar_Pan.png';

            % Create plot_PanVisibility
            app.plot_PanVisibility = uiimage(app.plot_InteractionsGrid);
            app.plot_PanVisibility.ScaleMethod = 'fill';
            app.plot_PanVisibility.Tag = 'InteractionVisibility';
            app.plot_PanVisibility.Tooltip = {'Datatip'};
            app.plot_PanVisibility.Layout.Row = 2;
            app.plot_PanVisibility.Layout.Column = 2;
            app.plot_PanVisibility.ImageSource = 'LT_LineH.png';

            % Create plot_ZoomIn
            app.plot_ZoomIn = uiimage(app.plot_InteractionsGrid);
            app.plot_ZoomIn.ImageClickedFcn = createCallbackFcn(app, @plotImageClicked_Interactions, true);
            app.plot_ZoomIn.Tooltip = {'Zoom in'};
            app.plot_ZoomIn.Layout.Row = 1;
            app.plot_ZoomIn.Layout.Column = 3;
            app.plot_ZoomIn.ImageSource = 'AxesToolbar_ZoomIn.png';

            % Create plot_ZoomInVisibility
            app.plot_ZoomInVisibility = uiimage(app.plot_InteractionsGrid);
            app.plot_ZoomInVisibility.ScaleMethod = 'fill';
            app.plot_ZoomInVisibility.Tag = 'InteractionVisibility';
            app.plot_ZoomInVisibility.Tooltip = {'Datatip'};
            app.plot_ZoomInVisibility.Layout.Row = 2;
            app.plot_ZoomInVisibility.Layout.Column = 3;
            app.plot_ZoomInVisibility.ImageSource = 'LT_LineH.png';

            % Create plot_ZoomOut
            app.plot_ZoomOut = uiimage(app.plot_InteractionsGrid);
            app.plot_ZoomOut.ImageClickedFcn = createCallbackFcn(app, @plotImageClicked_Interactions, true);
            app.plot_ZoomOut.Tooltip = {'Zoom out'};
            app.plot_ZoomOut.Layout.Row = 1;
            app.plot_ZoomOut.Layout.Column = 4;
            app.plot_ZoomOut.ImageSource = 'AxesToolbar_ZoomOut.png';

            % Create plot_ZoomOutVisibility
            app.plot_ZoomOutVisibility = uiimage(app.plot_InteractionsGrid);
            app.plot_ZoomOutVisibility.ScaleMethod = 'fill';
            app.plot_ZoomOutVisibility.Tag = 'InteractionVisibility';
            app.plot_ZoomOutVisibility.Tooltip = {'Datatip'};
            app.plot_ZoomOutVisibility.Layout.Row = 2;
            app.plot_ZoomOutVisibility.Layout.Column = 4;
            app.plot_ZoomOutVisibility.ImageSource = 'LT_LineH.png';

            % Create plot_RestoreView
            app.plot_RestoreView = uiimage(app.plot_InteractionsGrid);
            app.plot_RestoreView.ImageClickedFcn = createCallbackFcn(app, @plotImageClicked_Interactions, true);
            app.plot_RestoreView.Tooltip = {'Restore view'};
            app.plot_RestoreView.Layout.Row = 1;
            app.plot_RestoreView.Layout.Column = 5;
            app.plot_RestoreView.ImageSource = 'AxesToolbar_RestoreView.png';

            % Create plot_RestoreViewVisibility
            app.plot_RestoreViewVisibility = uiimage(app.plot_InteractionsGrid);
            app.plot_RestoreViewVisibility.ScaleMethod = 'fill';
            app.plot_RestoreViewVisibility.Tag = 'InteractionVisibility';
            app.plot_RestoreViewVisibility.Tooltip = {'Datatip'};
            app.plot_RestoreViewVisibility.Layout.Row = 2;
            app.plot_RestoreViewVisibility.Layout.Column = 5;
            app.plot_RestoreViewVisibility.ImageSource = 'LT_LineH.png';

            % Create plot_TiledSpacingLabel
            app.plot_TiledSpacingLabel = uilabel(app.plot_Grid);
            app.plot_TiledSpacingLabel.VerticalAlignment = 'bottom';
            app.plot_TiledSpacingLabel.FontSize = 10;
            app.plot_TiledSpacingLabel.FontWeight = 'bold';
            app.plot_TiledSpacingLabel.Layout.Row = 3;
            app.plot_TiledSpacingLabel.Layout.Column = [1 2];
            app.plot_TiledSpacingLabel.Text = 'Espaçamento entre eixos:';

            % Create plot_TiledSpacing
            app.plot_TiledSpacing = uidropdown(app.plot_Grid);
            app.plot_TiledSpacing.Items = {'loose', 'compact', 'tight', 'none'};
            app.plot_TiledSpacing.ValueChangedFcn = createCallbackFcn(app, @plotDropDown_TiledSpacing, true);
            app.plot_TiledSpacing.FontSize = 11;
            app.plot_TiledSpacing.BackgroundColor = [1 1 1];
            app.plot_TiledSpacing.Layout.Row = 4;
            app.plot_TiledSpacing.Layout.Column = [1 2];
            app.plot_TiledSpacing.Value = 'loose';

            % Create plot_colorsLabel
            app.plot_colorsLabel = uilabel(app.plot_Grid);
            app.plot_colorsLabel.VerticalAlignment = 'bottom';
            app.plot_colorsLabel.FontSize = 10;
            app.plot_colorsLabel.FontWeight = 'bold';
            app.plot_colorsLabel.Layout.Row = 5;
            app.plot_colorsLabel.Layout.Column = 1;
            app.plot_colorsLabel.Text = 'Cores:';

            % Create plot_colorsGrid
            app.plot_colorsGrid = uigridlayout(app.plot_Grid);
            app.plot_colorsGrid.ColumnWidth = {'1x'};
            app.plot_colorsGrid.RowHeight = {20, 20, 20, 20};
            app.plot_colorsGrid.ColumnSpacing = 0;
            app.plot_colorsGrid.RowSpacing = 0;
            app.plot_colorsGrid.Padding = [0 0 0 0];
            app.plot_colorsGrid.Layout.Row = 6;
            app.plot_colorsGrid.Layout.Column = [1 2];
            app.plot_colorsGrid.BackgroundColor = [1 1 1];

            % Create plot_colorsMinHold
            app.plot_colorsMinHold = uibutton(app.plot_colorsGrid, 'push');
            app.plot_colorsMinHold.ButtonPushedFcn = createCallbackFcn(app, @plotButtonPushed_colors, true);
            app.plot_colorsMinHold.HorizontalAlignment = 'right';
            app.plot_colorsMinHold.VerticalAlignment = 'top';
            app.plot_colorsMinHold.BackgroundColor = [0.3804 0.6 0.7294];
            app.plot_colorsMinHold.FontSize = 10;
            app.plot_colorsMinHold.FontColor = [1 1 1];
            app.plot_colorsMinHold.Layout.Row = 4;
            app.plot_colorsMinHold.Layout.Column = 1;
            app.plot_colorsMinHold.Text = 'MinHold';

            % Create plot_colorsAverage
            app.plot_colorsAverage = uibutton(app.plot_colorsGrid, 'push');
            app.plot_colorsAverage.ButtonPushedFcn = createCallbackFcn(app, @plotButtonPushed_colors, true);
            app.plot_colorsAverage.HorizontalAlignment = 'right';
            app.plot_colorsAverage.VerticalAlignment = 'top';
            app.plot_colorsAverage.BackgroundColor = [0.3882 0.8314 0.0706];
            app.plot_colorsAverage.FontSize = 10;
            app.plot_colorsAverage.FontColor = [1 1 1];
            app.plot_colorsAverage.Layout.Row = 3;
            app.plot_colorsAverage.Layout.Column = 1;
            app.plot_colorsAverage.Text = 'Tendência central';

            % Create plot_colorsClearWrite
            app.plot_colorsClearWrite = uibutton(app.plot_colorsGrid, 'push');
            app.plot_colorsClearWrite.ButtonPushedFcn = createCallbackFcn(app, @plotButtonPushed_colors, true);
            app.plot_colorsClearWrite.HorizontalAlignment = 'right';
            app.plot_colorsClearWrite.VerticalAlignment = 'top';
            app.plot_colorsClearWrite.BackgroundColor = [0.9294 0.6902 0.1294];
            app.plot_colorsClearWrite.FontSize = 10;
            app.plot_colorsClearWrite.FontColor = [1 1 1];
            app.plot_colorsClearWrite.Layout.Row = 2;
            app.plot_colorsClearWrite.Layout.Column = 1;
            app.plot_colorsClearWrite.Text = 'ClearWrite';

            % Create plot_colorsMaxHold
            app.plot_colorsMaxHold = uibutton(app.plot_colorsGrid, 'push');
            app.plot_colorsMaxHold.ButtonPushedFcn = createCallbackFcn(app, @plotButtonPushed_colors, true);
            app.plot_colorsMaxHold.HorizontalAlignment = 'right';
            app.plot_colorsMaxHold.VerticalAlignment = 'top';
            app.plot_colorsMaxHold.BackgroundColor = [1 0.0706 0.651];
            app.plot_colorsMaxHold.FontSize = 10;
            app.plot_colorsMaxHold.FontColor = [1 1 1];
            app.plot_colorsMaxHold.Layout.Row = 1;
            app.plot_colorsMaxHold.Layout.Column = 1;
            app.plot_colorsMaxHold.Text = 'MaxHold';

            % Create plot_WaterfallLabel
            app.plot_WaterfallLabel = uilabel(app.plot_Grid);
            app.plot_WaterfallLabel.VerticalAlignment = 'bottom';
            app.plot_WaterfallLabel.FontSize = 10;
            app.plot_WaterfallLabel.FontWeight = 'bold';
            app.plot_WaterfallLabel.Layout.Row = 7;
            app.plot_WaterfallLabel.Layout.Column = 1;
            app.plot_WaterfallLabel.Text = 'Waterfall:';

            % Create plot_WaterfallPanel
            app.plot_WaterfallPanel = uipanel(app.plot_Grid);
            app.plot_WaterfallPanel.BackgroundColor = [1 1 1];
            app.plot_WaterfallPanel.Layout.Row = 8;
            app.plot_WaterfallPanel.Layout.Column = [1 2];

            % Create plot_WaterfallGrid
            app.plot_WaterfallGrid = uigridlayout(app.plot_WaterfallPanel);
            app.plot_WaterfallGrid.RowHeight = {17, 22};
            app.plot_WaterfallGrid.RowSpacing = 5;
            app.plot_WaterfallGrid.Padding = [10 10 10 5];
            app.plot_WaterfallGrid.BackgroundColor = [1 1 1];

            % Create plot_WaterfallDepthLabel
            app.plot_WaterfallDepthLabel = uilabel(app.plot_WaterfallGrid);
            app.plot_WaterfallDepthLabel.VerticalAlignment = 'bottom';
            app.plot_WaterfallDepthLabel.FontSize = 10;
            app.plot_WaterfallDepthLabel.Layout.Row = 1;
            app.plot_WaterfallDepthLabel.Layout.Column = 2;
            app.plot_WaterfallDepthLabel.Text = 'Profundidade:';

            % Create plot_WaterfallDepth
            app.plot_WaterfallDepth = uidropdown(app.plot_WaterfallGrid);
            app.plot_WaterfallDepth.Items = {'64', '128', '256', '512'};
            app.plot_WaterfallDepth.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.plot_WaterfallDepth.FontSize = 11;
            app.plot_WaterfallDepth.BackgroundColor = [1 1 1];
            app.plot_WaterfallDepth.Layout.Row = 2;
            app.plot_WaterfallDepth.Layout.Column = 2;
            app.plot_WaterfallDepth.Value = '128';

            % Create plot_WaterfallColormapLabel
            app.plot_WaterfallColormapLabel = uilabel(app.plot_WaterfallGrid);
            app.plot_WaterfallColormapLabel.VerticalAlignment = 'bottom';
            app.plot_WaterfallColormapLabel.FontSize = 10;
            app.plot_WaterfallColormapLabel.Layout.Row = 1;
            app.plot_WaterfallColormapLabel.Layout.Column = 1;
            app.plot_WaterfallColormapLabel.Text = 'Mapa de cor:';

            % Create plot_WaterfallColormap
            app.plot_WaterfallColormap = uidropdown(app.plot_WaterfallGrid);
            app.plot_WaterfallColormap.Items = {'gray', 'hot', 'jet', 'summer', 'turbo', 'winter'};
            app.plot_WaterfallColormap.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.plot_WaterfallColormap.FontSize = 11;
            app.plot_WaterfallColormap.BackgroundColor = [1 1 1];
            app.plot_WaterfallColormap.Layout.Row = 2;
            app.plot_WaterfallColormap.Layout.Column = 1;
            app.plot_WaterfallColormap.Value = 'jet';

            % Create plot_IntegrationLabel
            app.plot_IntegrationLabel = uilabel(app.plot_Grid);
            app.plot_IntegrationLabel.VerticalAlignment = 'bottom';
            app.plot_IntegrationLabel.FontSize = 10;
            app.plot_IntegrationLabel.FontWeight = 'bold';
            app.plot_IntegrationLabel.Layout.Row = 9;
            app.plot_IntegrationLabel.Layout.Column = 1;
            app.plot_IntegrationLabel.Text = 'Integração:';

            % Create plot_IntegrationPanel
            app.plot_IntegrationPanel = uipanel(app.plot_Grid);
            app.plot_IntegrationPanel.BackgroundColor = [1 1 1];
            app.plot_IntegrationPanel.Layout.Row = 10;
            app.plot_IntegrationPanel.Layout.Column = [1 2];

            % Create plot_IntegrationGrid
            app.plot_IntegrationGrid = uigridlayout(app.plot_IntegrationPanel);
            app.plot_IntegrationGrid.RowHeight = {17, 22};
            app.plot_IntegrationGrid.ColumnSpacing = 20;
            app.plot_IntegrationGrid.RowSpacing = 5;
            app.plot_IntegrationGrid.Padding = [10 10 10 5];
            app.plot_IntegrationGrid.BackgroundColor = [1 1 1];

            % Create plot_IntegrationTimeLabel
            app.plot_IntegrationTimeLabel = uilabel(app.plot_IntegrationGrid);
            app.plot_IntegrationTimeLabel.VerticalAlignment = 'bottom';
            app.plot_IntegrationTimeLabel.FontSize = 10;
            app.plot_IntegrationTimeLabel.Layout.Row = 1;
            app.plot_IntegrationTimeLabel.Layout.Column = 2;
            app.plot_IntegrationTimeLabel.Text = 'Tempo médio escrita:';

            % Create plot_IntegrationTime
            app.plot_IntegrationTime = uieditfield(app.plot_IntegrationGrid, 'numeric');
            app.plot_IntegrationTime.Limits = [3 100];
            app.plot_IntegrationTime.RoundFractionalValues = 'on';
            app.plot_IntegrationTime.ValueDisplayFormat = '%d';
            app.plot_IntegrationTime.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.plot_IntegrationTime.Editable = 'off';
            app.plot_IntegrationTime.FontSize = 11;
            app.plot_IntegrationTime.Layout.Row = 2;
            app.plot_IntegrationTime.Layout.Column = 2;
            app.plot_IntegrationTime.Value = 10;

            % Create plot_IntegrationTraceLabel
            app.plot_IntegrationTraceLabel = uilabel(app.plot_IntegrationGrid);
            app.plot_IntegrationTraceLabel.VerticalAlignment = 'bottom';
            app.plot_IntegrationTraceLabel.FontSize = 10;
            app.plot_IntegrationTraceLabel.Layout.Row = 1;
            app.plot_IntegrationTraceLabel.Layout.Column = 1;
            app.plot_IntegrationTraceLabel.Text = 'Traço médio:';

            % Create plot_IntegrationTrace
            app.plot_IntegrationTrace = uieditfield(app.plot_IntegrationGrid, 'numeric');
            app.plot_IntegrationTrace.Limits = [3 100];
            app.plot_IntegrationTrace.RoundFractionalValues = 'on';
            app.plot_IntegrationTrace.ValueDisplayFormat = '%d';
            app.plot_IntegrationTrace.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.plot_IntegrationTrace.Editable = 'off';
            app.plot_IntegrationTrace.FontSize = 11;
            app.plot_IntegrationTrace.Layout.Row = 2;
            app.plot_IntegrationTrace.Layout.Column = 1;
            app.plot_IntegrationTrace.Value = 10;

            % Create general_versionPanel
            app.general_versionPanel = uipanel(app.MainPanelGrid);
            app.general_versionPanel.BackgroundColor = [1 1 1];
            app.general_versionPanel.Layout.Row = 2;
            app.general_versionPanel.Layout.Column = 1;

            % Create general_versionGrid
            app.general_versionGrid = uigridlayout(app.general_versionPanel);
            app.general_versionGrid.ColumnWidth = {'1x'};
            app.general_versionGrid.RowHeight = {'1x'};
            app.general_versionGrid.ColumnSpacing = 0;
            app.general_versionGrid.RowSpacing = 0;
            app.general_versionGrid.Padding = [0 0 0 0];
            app.general_versionGrid.BackgroundColor = [1 1 1];

            % Create AppVersion
            app.AppVersion = uihtml(app.general_versionGrid);
            app.AppVersion.Layout.Row = 1;
            app.AppVersion.Layout.Column = 1;

            % Create Tab1_Panel
            app.Tab1_Panel = uipanel(app.MainPanelGrid);
            app.Tab1_Panel.Layout.Row = 2;
            app.Tab1_Panel.Layout.Column = 2;

            % Create general_Grid
            app.general_Grid = uigridlayout(app.Tab1_Panel);
            app.general_Grid.ColumnWidth = {'1x'};
            app.general_Grid.RowHeight = {17, 138, 17, '1x', 17, 22};
            app.general_Grid.ColumnSpacing = 5;
            app.general_Grid.RowSpacing = 5;
            app.general_Grid.Padding = [10 10 10 5];
            app.general_Grid.BackgroundColor = [1 1 1];

            % Create general_stationLabel
            app.general_stationLabel = uilabel(app.general_Grid);
            app.general_stationLabel.VerticalAlignment = 'bottom';
            app.general_stationLabel.FontSize = 10;
            app.general_stationLabel.FontWeight = 'bold';
            app.general_stationLabel.Layout.Row = 1;
            app.general_stationLabel.Layout.Column = 1;
            app.general_stationLabel.Text = 'Estação:';

            % Create general_stationPanel
            app.general_stationPanel = uipanel(app.general_Grid);
            app.general_stationPanel.Layout.Row = 2;
            app.general_stationPanel.Layout.Column = 1;

            % Create general_stationGrid
            app.general_stationGrid = uigridlayout(app.general_stationPanel);
            app.general_stationGrid.RowHeight = {17, 22, '1x', 22, 17};
            app.general_stationGrid.RowSpacing = 5;
            app.general_stationGrid.Padding = [10 9 10 4];
            app.general_stationGrid.BackgroundColor = [1 1 1];

            % Create general_stationNameLabel
            app.general_stationNameLabel = uilabel(app.general_stationGrid);
            app.general_stationNameLabel.VerticalAlignment = 'bottom';
            app.general_stationNameLabel.FontSize = 10;
            app.general_stationNameLabel.Layout.Row = 1;
            app.general_stationNameLabel.Layout.Column = 1;
            app.general_stationNameLabel.Text = 'Nome:';

            % Create general_stationName
            app.general_stationName = uieditfield(app.general_stationGrid, 'text');
            app.general_stationName.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.general_stationName.Editable = 'off';
            app.general_stationName.FontSize = 11;
            app.general_stationName.Layout.Row = 2;
            app.general_stationName.Layout.Column = 1;

            % Create general_stationTypeLabel
            app.general_stationTypeLabel = uilabel(app.general_stationGrid);
            app.general_stationTypeLabel.VerticalAlignment = 'bottom';
            app.general_stationTypeLabel.FontSize = 10;
            app.general_stationTypeLabel.FontWeight = 'bold';
            app.general_stationTypeLabel.Layout.Row = 1;
            app.general_stationTypeLabel.Layout.Column = 2;
            app.general_stationTypeLabel.Text = 'Tipo:';

            % Create general_stationType
            app.general_stationType = uidropdown(app.general_stationGrid);
            app.general_stationType.Items = {'Fixed', 'Mobile'};
            app.general_stationType.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.general_stationType.FontSize = 11;
            app.general_stationType.BackgroundColor = [1 1 1];
            app.general_stationType.Layout.Row = 2;
            app.general_stationType.Layout.Column = 2;
            app.general_stationType.Value = 'Fixed';

            % Create general_stationLatitudeLabel
            app.general_stationLatitudeLabel = uilabel(app.general_stationGrid);
            app.general_stationLatitudeLabel.VerticalAlignment = 'bottom';
            app.general_stationLatitudeLabel.FontSize = 10;
            app.general_stationLatitudeLabel.Layout.Row = 3;
            app.general_stationLatitudeLabel.Layout.Column = 1;
            app.general_stationLatitudeLabel.Text = {'Latitude:'; '(graus decimais)'};

            % Create general_stationLatitude
            app.general_stationLatitude = uieditfield(app.general_stationGrid, 'numeric');
            app.general_stationLatitude.ValueDisplayFormat = '%.6f';
            app.general_stationLatitude.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.general_stationLatitude.Tag = 'task_Editable';
            app.general_stationLatitude.Editable = 'off';
            app.general_stationLatitude.FontSize = 11;
            app.general_stationLatitude.Layout.Row = 4;
            app.general_stationLatitude.Layout.Column = 1;
            app.general_stationLatitude.Value = -1;

            % Create general_stationLongitudeLabel
            app.general_stationLongitudeLabel = uilabel(app.general_stationGrid);
            app.general_stationLongitudeLabel.VerticalAlignment = 'bottom';
            app.general_stationLongitudeLabel.FontSize = 10;
            app.general_stationLongitudeLabel.Layout.Row = 3;
            app.general_stationLongitudeLabel.Layout.Column = 2;
            app.general_stationLongitudeLabel.Text = {'Longitude:'; '(graus decimais)'};

            % Create general_stationLongitude
            app.general_stationLongitude = uieditfield(app.general_stationGrid, 'numeric');
            app.general_stationLongitude.ValueDisplayFormat = '%.6f';
            app.general_stationLongitude.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.general_stationLongitude.Tag = 'task_Editable';
            app.general_stationLongitude.Editable = 'off';
            app.general_stationLongitude.FontSize = 11;
            app.general_stationLongitude.Layout.Row = 4;
            app.general_stationLongitude.Layout.Column = 2;
            app.general_stationLongitude.Value = -1;

            % Create general_lastSessionInfoGrid
            app.general_lastSessionInfoGrid = uigridlayout(app.general_stationGrid);
            app.general_lastSessionInfoGrid.ColumnWidth = {16, '1x'};
            app.general_lastSessionInfoGrid.RowHeight = {'1x'};
            app.general_lastSessionInfoGrid.ColumnSpacing = 2;
            app.general_lastSessionInfoGrid.RowSpacing = 0;
            app.general_lastSessionInfoGrid.Padding = [0 0 0 0];
            app.general_lastSessionInfoGrid.Layout.Row = 5;
            app.general_lastSessionInfoGrid.Layout.Column = [1 2];
            app.general_lastSessionInfoGrid.BackgroundColor = [1 1 1];

            % Create general_lastSessionInfoLabel
            app.general_lastSessionInfoLabel = uilabel(app.general_lastSessionInfoGrid);
            app.general_lastSessionInfoLabel.FontSize = 10;
            app.general_lastSessionInfoLabel.Layout.Row = 1;
            app.general_lastSessionInfoLabel.Layout.Column = 2;
            app.general_lastSessionInfoLabel.Text = 'Leitura dados armazenados na última sessão.';

            % Create general_lastSessionInfo
            app.general_lastSessionInfo = uicheckbox(app.general_lastSessionInfoGrid);
            app.general_lastSessionInfo.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.general_lastSessionInfo.Enable = 'off';
            app.general_lastSessionInfo.Text = '';
            app.general_lastSessionInfo.FontSize = 10;
            app.general_lastSessionInfo.Layout.Row = 1;
            app.general_lastSessionInfo.Layout.Column = 1;

            % Create general_versionLabel
            app.general_versionLabel = uilabel(app.general_Grid);
            app.general_versionLabel.VerticalAlignment = 'bottom';
            app.general_versionLabel.FontSize = 10;
            app.general_versionLabel.FontWeight = 'bold';
            app.general_versionLabel.Layout.Row = 3;
            app.general_versionLabel.Layout.Column = 1;
            app.general_versionLabel.Text = 'Servidor TCP:';

            % Create general_gpuLabel
            app.general_gpuLabel = uilabel(app.general_Grid);
            app.general_gpuLabel.VerticalAlignment = 'bottom';
            app.general_gpuLabel.FontSize = 10;
            app.general_gpuLabel.FontWeight = 'bold';
            app.general_gpuLabel.FontColor = [0.149 0.149 0.149];
            app.general_gpuLabel.Layout.Row = 5;
            app.general_gpuLabel.Layout.Column = 1;
            app.general_gpuLabel.Text = 'Unidade gráfica:';

            % Create general_gpu
            app.general_gpu = uidropdown(app.general_Grid);
            app.general_gpu.Items = {};
            app.general_gpu.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.general_gpu.FontSize = 11;
            app.general_gpu.BackgroundColor = [1 1 1];
            app.general_gpu.Layout.Row = 6;
            app.general_gpu.Layout.Column = 1;
            app.general_gpu.Value = {};

            % Create Tab2_Panel
            app.Tab2_Panel = uipanel(app.general_Grid);
            app.Tab2_Panel.Layout.Row = 4;
            app.Tab2_Panel.Layout.Column = 1;

            % Create server_Grid
            app.server_Grid = uigridlayout(app.Tab2_Panel);
            app.server_Grid.RowHeight = {17, 22, '1x', 22, 17, 22};
            app.server_Grid.RowSpacing = 5;
            app.server_Grid.Padding = [10 8 10 4];
            app.server_Grid.BackgroundColor = [1 1 1];

            % Create server_KeyLabel
            app.server_KeyLabel = uilabel(app.server_Grid);
            app.server_KeyLabel.VerticalAlignment = 'bottom';
            app.server_KeyLabel.FontSize = 10;
            app.server_KeyLabel.Layout.Row = 1;
            app.server_KeyLabel.Layout.Column = 2;
            app.server_KeyLabel.Text = 'Chave:';

            % Create server_Key
            app.server_Key = uieditfield(app.server_Grid, 'text');
            app.server_Key.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.server_Key.Editable = 'off';
            app.server_Key.FontSize = 11;
            app.server_Key.Layout.Row = 2;
            app.server_Key.Layout.Column = 2;

            % Create server_ClientListLabel
            app.server_ClientListLabel = uilabel(app.server_Grid);
            app.server_ClientListLabel.VerticalAlignment = 'bottom';
            app.server_ClientListLabel.FontSize = 10;
            app.server_ClientListLabel.Layout.Row = 3;
            app.server_ClientListLabel.Layout.Column = [1 2];
            app.server_ClientListLabel.Text = {'Lista de clientes:'; '(valores separados por vírgula)'};

            % Create server_ClientList
            app.server_ClientList = uieditfield(app.server_Grid, 'text');
            app.server_ClientList.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.server_ClientList.Editable = 'off';
            app.server_ClientList.FontSize = 11;
            app.server_ClientList.Layout.Row = 4;
            app.server_ClientList.Layout.Column = [1 2];

            % Create server_IPLabel
            app.server_IPLabel = uilabel(app.server_Grid);
            app.server_IPLabel.VerticalAlignment = 'bottom';
            app.server_IPLabel.FontSize = 10;
            app.server_IPLabel.Layout.Row = 5;
            app.server_IPLabel.Layout.Column = [1 2];
            app.server_IPLabel.Text = 'Endereço IP (OpenVPN):';

            % Create server_IP
            app.server_IP = uieditfield(app.server_Grid, 'text');
            app.server_IP.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.server_IP.Editable = 'off';
            app.server_IP.FontSize = 11;
            app.server_IP.Layout.Row = 6;
            app.server_IP.Layout.Column = 1;

            % Create server_PortLabel
            app.server_PortLabel = uilabel(app.server_Grid);
            app.server_PortLabel.VerticalAlignment = 'bottom';
            app.server_PortLabel.FontSize = 10;
            app.server_PortLabel.Layout.Row = 5;
            app.server_PortLabel.Layout.Column = 2;
            app.server_PortLabel.Text = 'Porta:';

            % Create server_Port
            app.server_Port = uieditfield(app.server_Grid, 'numeric');
            app.server_Port.Limits = [1 65535];
            app.server_Port.RoundFractionalValues = 'on';
            app.server_Port.ValueDisplayFormat = '%d';
            app.server_Port.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.server_Port.Editable = 'off';
            app.server_Port.FontSize = 11;
            app.server_Port.Layout.Row = 6;
            app.server_Port.Layout.Column = 2;
            app.server_Port.Value = 1;

            % Create server_StatusLabel
            app.server_StatusLabel = uilabel(app.server_Grid);
            app.server_StatusLabel.VerticalAlignment = 'bottom';
            app.server_StatusLabel.FontSize = 10;
            app.server_StatusLabel.Layout.Row = 1;
            app.server_StatusLabel.Layout.Column = 1;
            app.server_StatusLabel.Text = 'Estado:';

            % Create server_Status
            app.server_Status = uidropdown(app.server_Grid);
            app.server_Status.Items = {'ON', 'OFF'};
            app.server_Status.ValueChangedFcn = createCallbackFcn(app, @ValueChanged_Parameter, true);
            app.server_Status.FontSize = 11;
            app.server_Status.BackgroundColor = [0.9412 0.9412 0.9412];
            app.server_Status.Layout.Row = 2;
            app.server_Status.Layout.Column = 1;
            app.server_Status.Value = 'ON';

            % Create toolGrid
            app.toolGrid = uigridlayout(app.GridLayout);
            app.toolGrid.ColumnWidth = {0, 22, '1x', '1x', 110};
            app.toolGrid.RowHeight = {'1x'};
            app.toolGrid.ColumnSpacing = 5;
            app.toolGrid.RowSpacing = 0;
            app.toolGrid.Padding = [0 0 0 0];
            app.toolGrid.Layout.Row = 3;
            app.toolGrid.Layout.Column = [1 2];
            app.toolGrid.BackgroundColor = [1 1 1];

            % Create toolButton_edit
            app.toolButton_edit = uibutton(app.toolGrid, 'push');
            app.toolButton_edit.ButtonPushedFcn = createCallbackFcn(app, @toolButtonPushed_edit, true);
            app.toolButton_edit.Icon = 'LT_edit.png';
            app.toolButton_edit.IconAlignment = 'right';
            app.toolButton_edit.HorizontalAlignment = 'right';
            app.toolButton_edit.BackgroundColor = [1 1 1];
            app.toolButton_edit.FontSize = 11;
            app.toolButton_edit.Visible = 'off';
            app.toolButton_edit.Layout.Row = 1;
            app.toolButton_edit.Layout.Column = 5;
            app.toolButton_edit.Text = 'Confirma edição';

            % Create EditionModeLabel
            app.EditionModeLabel = uilabel(app.GridLayout);
            app.EditionModeLabel.BackgroundColor = [0.6392 0.0784 0.1804];
            app.EditionModeLabel.HorizontalAlignment = 'center';
            app.EditionModeLabel.FontSize = 11;
            app.EditionModeLabel.FontColor = [1 1 1];
            app.EditionModeLabel.Visible = 'off';
            app.EditionModeLabel.Layout.Row = 1;
            app.EditionModeLabel.Layout.Column = 2;
            app.EditionModeLabel.Text = 'MODO DE EDIÇÃO';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = winSettings_exported(Container, varargin)

            % Create UIFigure and components
            createComponents(app, Container)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            if app.isDocked
                delete(app.Container.Children)
            else
                delete(app.UIFigure)
            end
        end
    end
end
