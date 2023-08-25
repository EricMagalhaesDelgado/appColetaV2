classdef AppContainer < matlab.ui.container.internal.appcontainer.PeeredProperties
    %AppContainer defines the top-level container for building Apps
    %
    %    These Apps may feature a toolstrip above a working area, optionally
    %    containing panels on the sides and bottom surrounding documents in the center.
    %


    %   Features of the AppContainer include:    
    %
    %     Layout management, including ability of the user to customize layout
    %     Context management, whereby UI elements appear and disappear in response to
    %         context changes (typically document selection).  These elements include
    %         toolstrip tabs, quick access toolbar buttons, side and bottom panels.
    %     Focus management
    %     Docking and undocking
    %     Layout persistence
    %
    %   AppContainer suports three modes of operation.
    %
    %     1. Construct UI exclusively in MATLAB and displayed it in a new CEF
    %     2. Open a new CEF window and display a page that constructs the UI by executing JavaScript
    %     3. Attach to a UI running in a CEF window or web browser
    %
    %   In all three cases the MATLAB AppContainer object may be used to set and get container properties,
    %   add and remove children, set and get child properties.  Note that only children that have been added
    %   via the AppContainer object may be removed by it.
    %
    %   The three modes of operation listed above are established via the AppContainer properties 
    %   and function calls as follows:
    %
    %     1. Default
    %     2. Specify an AppPage property
    %     3. Call attach function

    % Copyright 2017-2022 The MathWorks, Inc.

    properties (Dependent) % These properties are stored in the container peer model
        
        % Contains strings that identify the currently active contexts that are not associated with
        % a document (the latter are activated via Document ActiveContexts properties).
        % The "contexts" drive the inclusion of associated tab groups on the toolstrip,
        % controls on the quick access toolbar and panels on the AppContainer borders
        ActiveContexts (1,:) string;
        
        % Reflects/controls the collapsed state of the bottom panel collection
        BottomCollapsed (1,1) logical;

        % Reflects/controls height of the bottom panel collection
        % If >= 1 pixels are assumed. If < 1 interpreted as a fraction of the container height
        BottomHeight (1,1) double;

        % Reflects/controls the busy state of the App
        % When the App is busy a semi-transparent overlay and spinner appear and user
        % interaction is prevented.
        Busy (1,1) logical;

        % Specifies the initial placement of children
        % The DefaultLayout takes effect if no layout was recovered from the
        % previous session or if CleanStart has been set to true.
        % This property cannot be changed after the container has been made visible.
        DefaultLayout (1,1) struct;

        % Similar to the DefaultLayout property but is a JSON string rather than struct
        % Tile indices in the JSON are zero-based unlike those in the struct which are one-based.
        DefaultLayoutJSON (1,1) string;
        
        % Reflects/controls the relative widths of document grid columns
        % If the goal is to modify several layout properties (and not just DocumentColumnWeights),
        % to set the desired document layout, then use the DocumentLayout property
        DocumentColumnWeights (1,:) double;
        
        % Reflects/controls the document layout grid dimensions
        % If the goal is to modify several layout properties (and not just DocumentGridDimensions),
        % to set the desired document layout, then use the DocumentLayout property
        DocumentGridDimensions (1,2) double {mustBeInteger};
        
        % Reflects/controls the arrangement of documents
        % Effectively this property combines the DocumentGridDimensions, DocumentColumnWeights,
        % DocumentsRowWeights and DocumentTileCoverage, while also including tile occupancy, i.e.
        % which documents appear in each tile.
        %
        %
        % An example for defining DocumentLayout when we have 6 documents as follows:
        % Document 1 with tag "document1" belonging to document-group with tag "group1"
        % Document 2 with tag "document2" belonging to document-group with tag "group1"
        % Document 3 with tag "document3" belonging to document-group with tag "group1"
        % Document 4 with tag "document1" belonging to document-group with tag "group2"
        % Document 5 with tag "document2" belonging to document-group with tag "group2"
        % Document 6 with tag "document3" belonging to document-group with tag "group2"
        % 
        % And we want to show them in the following layout:
        %
        %    ---------------------------
        %   |        |                  |
        %   | Tile 1 |     Tile 2       |
        %   |        |                  |
        %   |        |                  |
        %   |        |                  |
        %   |---------------------------|
        %   |                           |
        %   |         Tile 3            |
        %    ---------------------------
        %   
        % 3 tiles with weights:
        % Column ratio = 0.33: 0.67
        % Row ratio = 0.6: 0.4
        % 
        % Tile 1 contains documents in following order:
        % Document 1, Document 2
        %
        % Tile 2 contains:
        % Document 4, Document 5, Document 3
        %
        % And Tile 3 contains:
        % Document 6
        %
        % NOTE: In a tile, documents belonging to a given group
        % must appear together. For example Tile 2 cannot have
        % documents in order: Document 4, Document 3, Document 5.
        % Since Document 4 and 5 belong to the same group but are
        % not together.
        % 
        % 
        % % MATLAB Code
        % documentLayout = struct;
        % documentLayout.gridDimensions.w = 2;
        % documentLayout.gridDimensions.h = 2;
        %
        % % A total of 3 tiles
        % documentLayout.tileCount = 3;
        %
        % % Set colum and row weights
        % documentLayout.columnWeights = [0.33 0.67];
        % documentLayout.rowWeights = [0.6, 0.4];
        %
        % % Set tile coverage
        % % Tile 1 and Tile 2 occupy row 1 column 1, and
        % % row 2 column 2 respectively. And Tile 3 occupy
        % % all of the second row.
        % documentLayout.tileCoverage = [1 2; 3 3];
        %
        % % Define which documents appear in which tile
        % % Id of a document is defined as <GroupTag>_<DocumentTag>
        % document1State.id = "group1_document1";
        % document2State.id = "group1_document2";
        % document3State.id = "group1_document3";
        % document4State.id = "group2_document1";
        % document5State.id = "group2_document2";
        % document6State.id = "group2_document3";
        % tile1Children = [document1State, document2State];
        % tile2Children = [document4State, document5State, document3State];
        % tile3Children = [document6State];
        % tile1Occupancy.children = tile1Children;
        % tile2Occupancy.children = tile2Children;
        % tile3Occupancy.children = tile3Children;
        % documentLayout.tileOccupancy = [tile1Occupancy tile2Occupancy tile3Occupancy];
        % % Set document layout on app
        % app.DocumentLayout = documentLayout;
        DocumentLayout (1, 1) struct;
        
        % Simialar to the DocumentLayout property but is a JSON string rather than struct
        % Tile indices in the JSON are zero-based unlike those in the struct which are one-based.
        DocumentLayoutJSON (1,1) string;
        
        % Text to be displayed in the area where documents normally appear when none are open
        DocumentPlaceHolderText (1,1) string;
        
        % Reflects/controls the relative heights of document grid rows
        % If the goal is to modify several layout properties (and not just DocumentRowWeights),
        % to set the desired document layout, then use the DocumentLayout property
        DocumentRowWeights (1,:) double;

        % Reflects/controls the position of the document tabs
        % Permissible values are "left", "right", "top" and "bottom
        DocumentTabPosition (1,1) string {mustBeMember(DocumentTabPosition, {'left', 'right', 'bottom', 'top'})};
        
        % Reflects/controls the relationship between document tiles and the underlying grid
        % Specifically a matrix, whose dimensions match the DocumentGridDimensions,
        % identifying the tile associated with each grid cell in row major order.
        % For example [1  1; 2 3] specifies three tiles on a 2 x 2 grid with the
        % first tile spanning two columns.
        % If the goal is to modify several layout properties (and not just DocumentTileCoverage),
        % to set the desired document layout, then use the DocumentLayout property
        DocumentTileCoverage (:,:) double {mustBeInteger, mustBeNonnegative};
        
        % Reflects/controls the state of the app supporting theming
        % If the value is "true" the app will participate with the desktop theming 
        % i.e. if the desktop is in dark theme, then the app will also be in dark theme.
        % If the value is "false" the app will not participate with the desktop theming 
        % i.e. if the desktop is in dark theme, the app will continue to be in default light theme.
        % This property cannot be changed after the app has been been constructed.
        EnableTheming (1,1) logical;
        
        % Reflects/controls the placement of children
        Layout (1,1) struct;
        
        % Similar to the Layout property but is a JSON string rather than struct
        LayoutJSON (1,1) string;
        
        % Reflects/controls the collapsed state of the left panel collection
        LeftCollapsed (1,1) logical;
        
        % Reflects/controls width of the left panel collection
        % If >= 1 pixels are assumed. If < 1 interpreted as a fraction of the container width
        LeftWidth (1,1) double;

        % Permissible values are "true", "false" and "default"
        % If value is "true" a "maximize" button will appear in the upper right of documents.
        % If value is "false" the "maximize" button will not appear.
        % If value is "default" a maximize button will appear conditionally, when there is no
        % tab shown corresponding to the document (see ShowSingleDocumentTab).
        % This property cannot be changed after the container has been made visible.
        OfferDocumentMaximizeButton (1,1) string {mustBeMember(OfferDocumentMaximizeButton, {'default', 'true', 'false'})};

        % Reflects/controls the arrangement of panels around the periphery of the UI
        % This includes the location, size and collapsed state of each panel.
        % Effectively this property combines the BottomCollapsed, BottomHeight, LeftCollapsed, LeftWidth,
        % RightCollapsed, RightWidth properties while also spcecifying the Opened, Region, Index, Collapsed
        % and size properties for each panel.
        PanelLayout (1, 1) struct;
        
        % Similar to the PanelLayout property but is a JSON string rather than struct
        PanelLayoutJSON (1,1) string;        
        
        % If true the container will save and restore open documents across sessions
        % This property cannot be changed after the container has been made visible.
        PersistDocuments (1,1) logical;
        
        % If true the container will save and restore its layout
        % This includes child sizes, locations, collapsed states etc.
        % This property cannot be changed after the container has been made visible.
        PersistLayout (1,1) logical;

        % If true empty space will be reserved for documents when none are open
        % This property cannot be changed after the container has been made visible.
        ReserveDocumentSpace (1,1) logical;

        % Reflects/controls the collapsed state of the right panel collection 
        RightCollapsed (1,1) logical;

        % Reflects/controls width of the right panel collection
        % If >= 1 pixels are assumed. If < 1 interpreted as a fraction of the container width
        RightWidth (1,1) double;
        
        % Reflects/controls the selected child
        % Structure fields include "title", "tag" and "documentGroupTag".
        % When setting the SelectedChild either the Title or the Tag will suffice.
        % The DocumentGroupTag is only relevant for document children and even then
        % can be omitted as long as the specified Title or Tag in unique across all
        % documents in all document groups
        SelectedChild (1,1) struct;

        % Reflects/controls the selected toolstrip tab
        % Structure fields include "title" and "tag".  When setting either
        % will suffice.  When getting both will be available.
        SelectedToolstripTab (1,1) struct;
        
        % If true a tab should appear when only one document is open
        % This property cannot be changed after the container has been made visible.
        ShowSingleDocumentTab (1,1) logical;

        % Uniquely identifies the App.  This string is not displayed
        Tag (1,1) string;
        
        % Displayed as window or page title
        Title (1,1) string;
        
        % Reflects/controls the collapsed state of the toolstrip
        % This property does not distinguish the temporary expanded-on-top state.
        % This state is considered a sub-state of the collapsed state.
        ToolstripCollapsed (1,1) logical;
        
        % If true the container will display a toolstrip at the top
        % Adding a toolstrip tab group to the container or adding a document
        % group with a toolstrip tab group will implcilty set this property to true
        ToolstripEnabled (1,1) logical;
        
        % If true the user will be able to adjust the document area tiling
        % This property cannot be changed after the container has been made visible.
        UserDocumentTilingEnabled (1,1) logical;
       
        % Reflects/controls the position and size of the containing window
        % The values supplied are interpreted as the window left and top positions,
        % width and height in that order.
        WindowBounds (1,4) double;
        
        % Reflects/controls the containing window's maximized state
        % This property is supported when the AppContainer appears in a CEF window
        % but not when in a browser window
        WindowMaximized (1,1) logical;
        
        % Reflects/controls the containing window's minimized state
        % This property is supported when the AppContainer appears in a CEF window
        % but not when in a browser window
        WindowMinimized (1,1) logical;
        
        % Reflects/controls the minimum size of the containing window
        % The values supplied are interpreted as width and height in that order.
        % This property is supported when the AppContainer appears in a CEF window
        % but not when in a browser window
        WindowMinSize (1,2) double;

        % Reflects/controls the width of status bar. If false, status bar width is limited
        % to the region under document container. Otherwise, it spans the whole window.
        % Defaults to false. This property cannot be changed after the container has been made visible.
        StatusBarSpansFullWidth (1,1) logical;
    end
    
    properties (Dependent, SetObservable=true)
        % Reflects/controls the visibility of the containing window
        % This property is supported when the AppContainer appears in a CEF window
        % but not when in a browser window
        Visible (1,1) logical;
    end

    properties (Dependent, Hidden=true)
        Product (1,1) string;
        Scope (1,1) string;
        UndockedPage (1,1) string; % Reflects/Controls the index page for the undocked child window.
    end
    
    properties (Dependent, SetAccess=immutable)
        % Reports the document that was most recently selected among those that are
        % currently open and docked.  This is the document whose context is active.
        % Unlike the DocumentGroup.LastSelected property, AppContainer.LastSelectedDocument
        % spans all DocumentGroups.
        % Structure fields include "title", "tag" and "documentGroupTag".
        LastSelectedDocument (1,1) struct;
    end

    properties (Dependent, SetAccess=immutable, SetObservable = true)
        % The process state of the App
        % Can be monitiored via the StateChanged event
        State (1,1); % matlab.ui.container.internal.appcontainer.AppState;
    end

    properties (SetAccess=private, Hidden=true)
        % The window state of the App
        % Can be monitiored via the WindowStateChanged event
        WindowState (1,1); % matlab.ui.container.internal.appcontainer.AppWindowState;
        % Workaround for g2392129. 
        % TODO: Can be removed as a part of g2292379
        CanCloseExecuted (1,1) logical;
        % Boolean value reflecting whether we are waiting on a response from downstream canCloseFcn - will get set to false by a Ctrl+C interruption (g2780323)
        CanCloseExecuting(1,1) logical;
        % WindowBounds when AppContainer is made visible for the first time
        OriginalWindowBounds (1, 4) double;
        % DocumentsInMotion contains the UUIDs of document objects as keys, and the value of these keys is the action
        % which is currently processing on the client side (Opening or Closing).
        % Key-value pairs are removed from this map when the client fires an asyncOperationComplete event on the ModelRoot.
        DocumentsInMotion = containers.Map();
    end

    properties(Hidden)
        % Synchronous mode is used to enable waitfors on select AppContainer property getters, 
        % to ensure that client side processing is complete before an answer is returned to the server
        % Synchronous mode is currently off by default for AppContainer, but on by default for RootApp
        % When enabled, it delays the return value for LastSelectedDocument, SelectedChild, and hasDocument/getDocuments
        SynchronousMode (1,1) logical = false;
    end

    properties(Constant)
        AsyncMotion_Opening = 'opening';
        AsyncMotion_Closing = 'closing';
    end
    
    properties
        % For Apps defined in JavaScript, specifies the App launch page
        % More specifically, the path from MATLAB root to the launch page.
        % If an AppPage is specified the AppContainer will merely be wrapper
        % that can be used to control the App.
        AppPage (1,1) string = "";
        
        % Controls the behavior of panel sets on the borders of the App.
        % This property cannot be changed after the container has been made visible.
        % The array should contain at most one entry per border (left, right and bottom).
        BorderOptions (1,:); % matlab.ui.container.internal.appcontainer.BorderOptions;

        % This function will be called when the user initiates AppContainer close
        % It should return true if close can proceed, false otherwise.
        % The AppContainer object will be passed as the first arguement to the function.
        CanCloseFcn;
        
        % If true information saved by the previous session will be ignored
        % See the PersistLayout and PersistDocuments properties for more on
        % what is saved across sessions.
        CleanStart (1,1) logical;

        % Defines contexts that may be activated independently of any document.
        % Each context may have associated toolstrip tab groups, panels and/or status bar components.
        % These Contexts are activated by setting the container's ActiveContexts property.
        % This property cannot be changed after the container has been made visible.
        Contexts (1,:); % matlab.ui.container.internal.appcontainer.ContextDefinition;     
        
        % Path to .png file to be displayed as window or page icon
        Icon (1,1) string = "";
        
        % Supplies information needed to load custom JavaScript code.
        % This is only needed if the container will host JavaScript defined panels and/or documents.  
        Extension = {}; % (1,1) matlab.ui.container.internal.appcontainer.ExtensionInfo;
        
        % Specifies another AppContainer to which this AppContainer should be parented
        % If a Parent is specified before this AppContainer is made visible the
        % parent will be asked to create a child window for this AppContainer.
        % Specifying a parent after the AppContainer has been made visible for
        % the first time will have no effect.
        Parent
        
        % If true the containing window will be resizable
        Resizable (1,1) logical = true;
    end
    
    properties (Hidden)
        % Deprecated, set the Extension property instead
        DojoConfig (1,1) string = "";
        
        % If true the AppContainer UI will be hosted in the system browser rather than a MATLAB webwindow
        % TODO: Deprecate this in AppContainer, and move into debug only workflow
        HostInBrowser (1,1) logical;
        
        % Contains array of strings, which are the features to be enabled within AppContainer
        Features (0,:) string;

        % Once activeContexts property is set, we use this property to wait
        % until the client side toolstrip viewmodel changes are finished.
        ActiveContextsSetFinished (1,1) logical;

        % Before setting the activeContexts property, we use this property
        % to wait until all the server side toolstrip viewmodel changes are
        % synced with the client side.
        ToolstripChangesFlushed (1,1) logical;

        % If true the JavaScript rendering code will wait for a debugger to be attached.
        % This can be used to debug JavaScript code that runs immediately after the App is made visible.
        WaitForJavaScriptDebugger (1,1) logical;

        % Reflects the URL of the window the AppContainer instance is hosted in
        WindowURL (1,1) string = "";
    end

    properties (Dependent, Hidden)
        % If true errors thrown be the JavaScript rendering code will be reported via the MATLAB error mechanism
        ReportJavaScriptErrors (1,1) logical;
    end

    properties (Dependent, Hidden) %, SetAccess = private) % TODO: Uncomment after R2022a
        % Returns the port to open for debugging the JavaScript rendering code
        % By default the value is 0, meaning that no debug port will be opened
        DebugPort (1,1) double {mustBeInteger};
    end
    
    properties (Access = private, Constant)
        SupportedFeatures = ["UseWebpack"];
    end
    
    % Reserved for Features. All should be false by default.
    properties (Access = protected, Hidden)
        % If true, the AppContainer UI will load using the Webpack configuration.
        % Else, the AppContainer UI will load using the Dojo configuration.
        UseWebpack (1, 1) logical = false;
    end

    properties (Access = protected)
        ModelChannel;
        MessageChannel;
        ChildContainers (1,:) % Map that contains the handle to the AppContainer instances of the child windows.
    end
    
    properties (Access = private)
        Toolstrip;
        QuickAccessBar;
        GlobalQuickAccessGroup;
        ParentContainer;
        PanelMap;
        PanelOrder;
        DocumentMap;
        DocumentGroupMap;
        TabGroupMap;
        TabGroupOrder;
        StatusBar;
        StatusComponentMap;
        
        UntaggedQabControlCount = 0;
        UntaggedPanelCount = 0;
        UntaggedDocumentGroupCount = 0;
        UntaggedDocumentCount = 0;

        ViewInitialized = false;
        Attached = false;
        NotifyClientsOnWindowStateChange = true;

        MessageSubscription;
        ModelManager;
        ModelRoot;
        ClientDriven = false;
        ToolstripChannel;
        ToolstripModelManager;
        Window;
        BrowserHandle;
        PrivateState (1,1) = matlab.ui.container.internal.appcontainer.AppState.INITIALIZING;
        PrivateWindowState (1,1) = matlab.ui.container.internal.appcontainer.AppWindowState.CLOSED;
        PrivateMinSize;
        DebugPortInternal = 0;
    end
    
    properties (GetAccess = private, Constant)
        MCOSPropertyNames = {
            'Tag', 'Title', 'CleanStart', 'PersistDocuments', 'PersistLayout', ...
            'ReserveDocumentSpace', 'ShowSingleDocumentTab', 'ToolstripEnabled', ...
            'UserDocumentTilingEnabled', 'DefaultLayout', 'PanelLayout', ...
            'ActiveContexts', 'BorderOptions', 'BottomCollapsed', 'BottomHeight', ...
            'Busy', 'Contexts', 'DocumentColumnWeights', ...
            'DocumentGridDimensions', 'DocumentRowWeights', 'DocumentTabPosition', ...
            'DocumentTileCoverage', 'DocumentLayout', 'DocumentPlaceHolderText', ...
            'LastSelectedDocument', 'Layout', 'LeftCollapsed', 'LeftWidth', 'RightCollapsed', 'RightWidth', ...
            'SelectedChild', 'SelectedToolstripTab', 'ToolstripCollapsed', 'Visible', ...
            'WindowBounds', 'WindowMaximized', 'WindowMinimized', ...
            'Product', 'Scope', 'UndockedPage', ...
            'ReportJavaScriptErrors', 'StatusBarSpansFullWidth', ...
            'UseWebpack', 'WindowBoundsModified', 'WindowURL', 'OfferDocumentMaximizeButton', 'EnableTheming'};
        JSPropertyNames = {
            'tag', 'title', 'cleanStart', 'persistDocuments', 'persistLayout', ...
            'reserveDocumentSpace', 'showSingleDocumentTab', 'hasToolstrip', ...
            'userDocumentTilingEnabled', 'defaultLayout', 'panelLayout', ...
            'activeContexts', 'borderOptions', 'isBottomCollapsed', 'bottomHeight', ...
            'isBusy', 'contexts', 'columnWeights', ...
            'gridSize', 'rowWeights', 'tabPosition', ...
            'tileCoverage', 'documentLayout', 'placeHolderText', ...
            'lastSelectedDocument', 'layout', 'isLeftCollapsed', 'leftWidth', 'isRightCollapsed', 'rightWidth', ...
            'selectedChild', 'selectedToolstripTab', 'isToolstripCollapsed', 'isVisible', ...
            'windowBounds', 'isWindowMaximized', 'isWindowMinimized', ...
            'product', 'scope', 'undockedPage', ...
            'reportErrors', 'footerSpansFullWidth', ...
            'useWebpack', 'windowBoundsModified', 'windowURL', 'offerDocumentMaximizeButton', 'enableTheming'};
        DefaultPropertyValues = {
            "", "", false, false, false, ...
            true, true, false, ...
            true, struct(), struct(), ...
            [], {}, false, 0, ...
            false, [], [], ...
            [1 1], [], "top", ...
            1, struct(), "", ...
            [], struct(), false, 0, false, 0, ...
            [], [], false, false, ...
            [100 100 1200 800], false, false, ...
            "", "", "", ...
            false, false, ...
            false, false, "", "default", false};
        RestrictedPropertyNames = {'AppPage', 'BorderOptions', 'CleanStart', 'Contexts', 'DebugPort', 'EnableTheming', 'Tag' ...
                                   'DefaultLayout', 'Extension', 'PersistDocuments', 'PersistLayout', 'Product', ...
                                   'ReserveDocumentSpace', 'Scope', 'UndockedPage', 'ShowSingleDocumentTab', 'ToolstipEnabled', ...
                                   'UserDocumentTilingEnabled', 'ReportJavaScriptErrors', ...
                                   'UseWebpack', 'OfferDocumentMaximizeButton'};
        ContainerMCOSToJSNameMap = containers.Map(matlab.ui.container.internal.AppContainer.MCOSPropertyNames, ...
                                         matlab.ui.container.internal.AppContainer.JSPropertyNames);
        ContainerJSToMCOSNameMap = containers.Map(matlab.ui.container.internal.AppContainer.JSPropertyNames, ...
                                         matlab.ui.container.internal.AppContainer.MCOSPropertyNames);
        ContainerDefaultValueMap = containers.Map(matlab.ui.container.internal.AppContainer.MCOSPropertyNames, ...
                                         matlab.ui.container.internal.AppContainer.DefaultPropertyValues);
        RestrictedPropertyNameStruct = matlab.ui.container.internal.appcontainer.PeeredProperties.createRestrictedNameStruct( ...
                                         matlab.ui.container.internal.AppContainer.RestrictedPropertyNames);
    end

    events        
        StateChanged; % Fired whenever the App process state changes
    end

    events (Hidden=true)
        WindowStateChanged; % Fired whenever the App window state changes

        WindowCreated; % Fired when the window is built to launch AppContainer
    end
    
    methods
        function this = AppContainer(varargin)
            [varargin, features] = matlab.ui.container.internal.AppContainer.extractFeatures(varargin);
            
            % Constructs an AppContainer
            this = this@matlab.ui.container.internal.appcontainer.PeeredProperties( ...
                matlab.ui.container.internal.AppContainer.ContainerMCOSToJSNameMap, ...
                matlab.ui.container.internal.AppContainer.ContainerJSToMCOSNameMap, ...
                matlab.ui.container.internal.AppContainer.ContainerDefaultValueMap, ...
                matlab.ui.container.internal.AppContainer.RestrictedPropertyNameStruct, ...
                varargin);
            
            import matlab.ui.internal.toolstrip.TabGroup;
            this.PanelMap = containers.Map();
            this.ChildContainers =  containers.Map();
            % g2357530: used to maintain order of panels added before app is visible
            this.PanelOrder = string.empty;
            
            this.DocumentMap = containers.Map();
            this.DocumentGroupMap = containers.Map();
            this.TabGroupMap = containers.Map();

            % g2255001: used to maintain order of tabgroups added before app is visible
            this.TabGroupOrder = TabGroup.empty;

            this.StatusComponentMap = containers.Map();
            
            this.parseFeatures(features);
        end

        function success = close(this, namedargs)
            % close(), close('force', false) Attempts to close the AppContainer,
            % subject to veto by CanCloseFcn of AppContainer and its documents.
            %
            % close('force', true) Forcibly closes the AppContainer, ignoring
            % CanCloseFcn.
            %
            % This function returns 'true' if the AppContainer was successfully
            % closed, 'false' if veto'ed.
            arguments
                this
                namedargs.force (1,1) logical {mustBeNumericOrLogical} = false
            end

            success = false;

            if namedargs.force
                % Force close, close the window and run the close tasks without
                % running any CanCloseFcn callbacks.
                if ~isempty(this.Window)
                    this.Window.close();
                end
                this.runCloseTasks(false);
                success = true;
            else
                % Regular close, run the app's and all the open document's
                % CanCloseFcn callbacks. If any CanCloseFcn callback returns
                % false, the AppContainer close will be prevented.
                canCloseFcnResult = this.canClose();
                if canCloseFcnResult
                    documents = this.getDocuments();
                    for i = 1:numel(documents)
                       documentCanCloseFcnResult = documents{i}.canClose();
                       if ~documentCanCloseFcnResult
                          return;
                       end
                    end

                    % No CanCloseFcn callback prevented the AppContainer close,
                    % close the window and run the close tasks.
                    if ~isempty(this.Window)
                        this.Window.close();
                    end

                    this.runCloseTasks(false);
                    success = true;
                end
            end
        end

        function delete(this)
            % delete Closes the AppContainer window and cleans up associated peer model channels
            this.runCloseTasks(true);
        end
        
        function attach(this)
            % Attaches the AppContainer to an already running UI
            this.Attached = true;
            this.initializeView(true);
        end
        
        function value = get.UseWebpack(this)
            value = this.getProperty('UseWebpack');
        end
        
        function set.UseWebpack(this, value)
            this.setProperty('UseWebpack', value);
        end
        
        function value = get.Title(this)
            value = this.getProperty('Title');
        end
        
        function set.Title(this, value)
            this.setProperty('Title', value);
            if ~isempty(this.Window)
                % g2362248: Explicitly set the title on the web window until mw-webwindow
                % is adopted in UIContainer. Not doing this will result in no title updates
                % for AppContainer FloatingPane window in MATLAB Online.
                this.Window.Title = convertStringsToChars(value);
            end
        end
        
        function value = get.Visible(this)
            value = this.getProperty('Visible');
        end
        
        function set.Visible(this, value)
            if this.Attached
                return;
            end
            if value
                if this.HostInBrowser
                    if isempty(this.BrowserHandle)
                        this.initializeView(false);
                        url = connector.getUrl(char(this.composeURN()));
                        status = web(url, '-browser');
%                         [status, this.BrowserHandle] = web(url, '-browser');
                        if status ~= 0
                            % This is an error that should only be seen internally, so no need for localization.
                            error('MATLAB:uiframework:appcontainer:failedToLoadBrowser', 'The page failed to load in the system browser.');
%                             this.BrowserHandle = [];
                        end
                    end
                elseif isempty(this.Window)
                    % Extract the window bounds from the internal properties struct and pass it
                    % to buildWindow rather than setting it on the peer model because the peer model
                    % node constructor doesn't handle structs in the initial property list.
                    windowBounds = this.WindowBounds;
                    if isfield(this.InternalProperties, "windowBounds")
                        windowBounds = this.InternalProperties.windowBounds;
                        if isstruct(windowBounds)
                            windowBounds = [windowBounds.x windowBounds.y windowBounds.w, windowBounds.h];
                        end
                        this.InternalProperties.windowBounds = [];
                        this.InternalProperties = rmfield(this.InternalProperties, "windowBounds");
                    end
                    this.initializeView(false);
                    if isempty(this.Parent)
                        % Adjust to reference to bottom left instead of top left.
                        % When the bounds are set via the peer model this happens on the JavaScript side
                        windowBounds = matlab.ui.container.internal.AppContainer.convertOrigin(windowBounds);
                        this.Window = this.buildWindow(windowBounds);
                    else
                        % TODO: Publish messsge to ask parent to display the App in a child window
                        data.type = 'openChild';
                        data.page = this.composeURN();
                        message.publish(this.Parent.MessageChannel, data);
                    end
                   % TODO: Eventually if has parent app, add this app to its peer model
                end
                
                if ~isempty(this.Window)
                    % calling Window.show should abstract appcontainer from
                    % knowing about the host environement i.e. knowing
                    % whether its matlab online or not. 
                    this.Window.show();
                    this.OriginalWindowBounds = this.Window.Position;
                end
            end
            this.setProperty('Visible', value);
        end
        
        function set.CanCloseFcn(this, value)
            this.CanCloseExecuted = false;
            if isempty(value) || internal.Callback.validate(value)
                this.CanCloseFcn = value;
                if ~isempty(this.PeerNode)
                    this.PeerNode.setProperty('hasCloseApprover', ~isempty(value));
                    if ~isempty(value)
                        % Listen for closeQuery event
                        this.addEventListener(this.ModelRoot, 'peerEvent', @(event, data) handlePeerEvent(this, data)); %#ok<*MCSUP>
                    end % TODO: else remove listener
                end
            else
                error(message('MATLAB:toolstrip:general:invalidFunctionHandle', 'CanCloseFcn'))
            end
        end
        
        function value = get.ActiveContexts(this)
            value = this.getProperty('ActiveContexts');
        end
        
        function set.ActiveContexts(this, value)
            import matlab.ui.container.internal.appcontainer.*;

            this.ActiveContextsSetFinished = false;
            old_value = this.ActiveContexts;
            new_value = value;

            if isempty(old_value)
                old_value = {};
            end

            if isempty(new_value)
                new_value = {};
            end

            isSameValueSet = isequal(old_value, new_value);

            if ~isempty(this.ToolstripModelManager) && ~isSameValueSet && this.PrivateState == AppState.RUNNING
                this.ToolstripChangesFlushed = false;
                toolstripRoot = this.ToolstripModelManager.getRoot();

                % Do a handshake with the client side code. This will
                % guarantee that all the server side toolstrip viewmodel
                % changes are synced with the client side viewmodel.
                toolstripChangesFlushedListener = toolstripRoot.addEventListener('toolstripChangesFlushed', @(varargin) handleToolstripChangesFlush(this));
                toolstripRoot.dispatchEvent('ToolstripHandshake', struct);
                waitfor(this, "ToolstripChangesFlushed", true);

                toolstripChangesFlushedListener.delete();

                % Set up a listener to be able to wait for the
                % activeContexts been set.
                toolstripContextsListener = toolstripRoot.addEventListener('activeContextsSet', @(varargin) handleActiveContextsSet(this));
            end

            if isempty(value)
                value = ""; % peer model doesn't handle empty
            end
            this.setProperty('ActiveContexts', value);
            if ~isempty(this.ToolstripModelManager) && ~isSameValueSet && this.PrivateState == AppState.RUNNING
                % Wait for the activeContexts to be set on the client side
                waitfor(this, "ActiveContextsSetFinished", true);
                toolstripContextsListener.delete();
            end
        end
        
        function set.BorderOptions(this, value)
            % Keep a local copy since the corresonding model entry is JSON encoded
            this.BorderOptions = value;
            for i = 1:length(value)
                options = value{i};
                value{i} = options.convertToJSON();
            end
            this.setProperty('BorderOptions', value);
        end
                
        function value = get.BottomCollapsed(this)
            value = this.getProperty('BottomCollapsed');
        end
        
        function set.BottomCollapsed(this, value)
            this.setProperty('BottomCollapsed', value);
        end
        
        function value = get.BottomHeight(this)
            value = this.getProperty('BottomHeight');
        end
        
        function set.BottomHeight(this, value)
            this.setProperty('BottomHeight', value);
        end
                
        function value = get.Busy(this)
            value = this.getProperty('Busy');
        end
        
        function set.Busy(this, value)
            this.setProperty('Busy', value);
        end

        function value = get.StatusBarSpansFullWidth(this)
            value = this.getProperty('StatusBarSpansFullWidth');
        end

        function set.StatusBarSpansFullWidth(this, value)
            import matlab.ui.container.internal.appcontainer.*;
            if this.PrivateState == AppState.INITIALIZING
                this.setProperty('StatusBarSpansFullWidth', value);
            else
                error('StatusBarSpansFullWidth must be set before container has been made visible.');
            end
        end
        
        function set.Contexts(this, value)
            % Keep a local copy since the corresonding model entry is JSON encoded
            this.Contexts = value;
            for i = 1:length(value)
                context = value{i};
                value{i} = context.convertToJSON();
            end
            this.setProperty('Contexts', value);
        end
        
        function value = get.DefaultLayout(this)
            value = this.getProperty('DefaultLayout');
            if isfield(value, 'documentLayout')
                value.documentLayout = this.adjustTileIndices(value.documentLayout, 1);
            end
        end
        
        function set.DefaultLayout(this, value)
            if isfield(value, 'documentLayout')
                value.documentLayout = this.adjustTileIndices(value.documentLayout, -1);
            end
            this.setProperty('DefaultLayout', value);
        end

        function value = get.DefaultLayoutJSON(this)
            % Pass false to getPeerProperty to suppress conversion to struct
            value = this.getPeerProperty('DefaultLayout', false);
        end

        function set.DefaultLayoutJSON(this, value)
            this.setProperty('DefaultLayout', matlab.ui.container.internal.appcontainer.PeeredProperties.JSON_PREFIX + value);
        end
        
        function value = get.DocumentColumnWeights(this)
            value = this.getProperty('DocumentColumnWeights');
        end
        
        function set.DocumentColumnWeights(this, value)
            this.setProperty('DocumentColumnWeights', value);
        end

        function value = get.DocumentGridDimensions(this)
            value = this.getProperty('DocumentGridDimensions');
            if isstruct(value)
                value = [value.w, value.h];
            end
        end
        
        function set.DocumentGridDimensions(this, value)
            dimensions.w = value(1);
            dimensions.h = value(2);
            this.setProperty('DocumentGridDimensions', dimensions);
        end
        
        function value = get.DocumentLayout(this)
            value = this.adjustTileIndices(this.getProperty('DocumentLayout'), 1);
        end
        
        function set.DocumentLayout(this, value)
            this.setProperty('DocumentLayout', this.adjustTileIndices(value, -1));
        end

        function value = get.DocumentLayoutJSON(this)
            % Pass false to getPeerProperty to suppress conversion to struct
            value = this.getPeerProperty('DocumentLayout', false);
        end
        
        function set.DocumentLayoutJSON(this, value)
            this.setProperty('DocumentLayout', matlab.ui.container.internal.appcontainer.PeeredProperties.JSON_PREFIX + value);
        end
        
        function value = get.DocumentPlaceHolderText(this)
            value = this.getProperty('DocumentPlaceHolderText');
        end
        
        function set.DocumentPlaceHolderText(this, value)
            this.setProperty('DocumentPlaceHolderText', value);
        end
        
        function value = get.DocumentRowWeights(this)
            value = this.getProperty('DocumentRowWeights');
        end
        
        function set.DocumentRowWeights(this, value)
            this.setProperty('DocumentRowWeights', value);
        end
        
        function value = get.DocumentTabPosition(this)
            value = this.getProperty('DocumentTabPosition');
        end
        
        function set.DocumentTabPosition(this, value)
            this.setProperty('DocumentTabPosition', value);
        end
        
        function value = get.DocumentTileCoverage(this)
            value = this.getProperty('DocumentTileCoverage') + 1;
        end
        
        function set.DocumentTileCoverage(this, value)
            this.setProperty('DocumentTileCoverage', value - 1);
        end

        function value = get.EnableTheming(this)
            value = this.getProperty('EnableTheming');
        end
        
        function set.EnableTheming(this, value)
            this.setProperty('EnableTheming', value);
        end
        
        function value = get.LastSelectedDocument(this)
            this.waitForPendingAsyncOperations();
            value = this.getProperty('LastSelectedDocument');
        end
        
        function value = get.Layout(this)
            value = this.getProperty('Layout');
            if isfield(value, 'documentLayout')
                value.documentLayout = this.adjustTileIndices(value.documentLayout, 1);
            end
        end
        
        function set.Layout(this, value)
            if isfield(value, 'documentLayout')
                value.documentLayout = this.adjustTileIndices(value.documentLayout, -1);
            end
            this.setProperty('Layout', value);
        end

        function value = get.LayoutJSON(this)
            % Pass false to getPeerProperty to suppress conversion to struct
            value = this.getPeerProperty('Layout', false);
        end
        
        function set.LayoutJSON(this, value)
            this.setProperty('Layout', matlab.ui.container.internal.appcontainer.PeeredProperties.JSON_PREFIX + value);
        end
        
        function value = get.LeftCollapsed(this)
            value = this.getProperty('LeftCollapsed');
        end
        
        function set.LeftCollapsed(this, value)
            this.setProperty('LeftCollapsed', value);
        end
        
        function value = get.LeftWidth(this)
            value = this.getProperty('LeftWidth');
        end
        
        function set.LeftWidth(this, value)
            this.setProperty('LeftWidth', value);
        end
        
        function value = get.OfferDocumentMaximizeButton(this)
            value = this.getProperty('OfferDocumentMaximizeButton');
        end

        function set.OfferDocumentMaximizeButton(this, value)
            this.setProperty('OfferDocumentMaximizeButton', value);
        end

        function value = get.PanelLayout(this)
            value = this.getProperty('PanelLayout');
        end
        
        function set.PanelLayout(this, value)
            this.setProperty('PanelLayout', value);
        end

        function value = get.PanelLayoutJSON(this)
            % Pass false to getPeerProperty to suppress conversion to struct
            value = this.getPeerProperty('PanelLayout', false);
        end
        
        function set.PanelLayoutJSON(this, value)
            this.setProperty('PanelLayout', matlab.ui.container.internal.appcontainer.PeeredProperties.JSON_PREFIX + value);
        end
        
        function value = get.PersistDocuments(this)
            value = this.getProperty('PersistDocuments');
        end
        
        function set.PersistDocuments(this, value)
            this.setProperty('PersistDocuments', value);
        end
        
        function value = get.PersistLayout(this)
            value = this.getProperty('PersistLayout');
        end
        
        function set.PersistLayout(this, value)
            this.setProperty('PersistLayout', value);
        end
        
        function value = get.ReserveDocumentSpace(this)
            value = this.getProperty('ReserveDocumentSpace');
        end
        
        function set.ReserveDocumentSpace(this, value)
            this.setProperty('ReserveDocumentSpace', value);
        end
        
        function set.Resizable(this, value)
            this.Resizable = value;
            if ~isempty(this.Window)
                this.Window.setResizable(this.Resizable);
            end
        end
        
        function value = get.RightCollapsed(this)
            value = this.getProperty('RightCollapsed');
        end
        
        function set.RightCollapsed(this, value)
            this.setProperty('RightCollapsed', value);
        end
        
        function value = get.RightWidth(this)
            value = this.getProperty('RightWidth');
        end
        
        function set.RightWidth(this, value)
            this.setProperty('RightWidth', value);
        end
        
        function value = get.SelectedChild(this)
            this.waitForPendingAsyncOperations();
            value = this.getProperty('SelectedChild');
        end
        
        function set.SelectedChild(this, value)
            this.setProperty('SelectedChild', value);
        end
        
        function value = get.SelectedToolstripTab(this)
            value = this.getProperty('SelectedToolstripTab');
        end
        
        function set.SelectedToolstripTab(this, value)
            this.setProperty('SelectedToolstripTab', value);
        end
        
        function value = get.ShowSingleDocumentTab(this)
            value = this.getProperty('ShowSingleDocumentTab');
        end
        
        function set.ShowSingleDocumentTab(this, value)
            this.setProperty('ShowSingleDocumentTab', value);
        end
        
        function value = get.State(this)
            if ~isempty(this.Window) && (~isvalid(this.Window) || ~this.Window.isWindowValid)
                value = matlab.ui.container.internal.appcontainer.AppState.TERMINATED;
            else
                value = this.PrivateState;
            end
        end

        function value = get.WindowState(this)
            if ~isempty(this.Window) && ~isvalid(this.Window) && ~this.Window.isWindowValid
                value = matlab.ui.container.internal.appcontainer.AppWindowState.CLOSED;
            else
                value = this.PrivateWindowState;
            end
        end
        
        function value = get.Tag(this)
            value = this.getProperty('Tag');
        end
        
        function set.Tag(this, value)
            this.setProperty('Tag', value);
        end
        
        function value = get.ToolstripCollapsed(this)
            value = this.getProperty('ToolstripCollapsed');
        end
        
        function set.ToolstripCollapsed(this, value)
            this.setProperty('ToolstripCollapsed', value);
        end
        
        function value = get.ToolstripEnabled(this)
            value = this.getProperty('ToolstripEnabled');
        end
        
        function set.ToolstripEnabled(this, value)
            this.setProperty('ToolstripEnabled', value);
        end
        
        function value = get.UserDocumentTilingEnabled(this)
            value = this.getProperty('UserDocumentTilingEnabled');
        end
        
        function set.UserDocumentTilingEnabled(this, value)
            this.setProperty('UserDocumentTilingEnabled', value);
        end
        
        function value = get.WindowBounds(this)
            import matlab.ui.container.internal.appcontainer.*;

            if this.PrivateState ~= AppState.RUNNING && ~isempty(this.Window) && ~isempty(this.AppPage)
                value = this.convertOrigin(this.Window.Position);
            else
                value = this.getProperty('WindowBounds');
            end
            
            if isstruct(value)
                value = [value.x value.y value.w, value.h];
            end
        end
        
        function set.WindowBounds(this, value)
            import matlab.ui.container.internal.appcontainer.*;

            if this.PrivateState ~= AppState.RUNNING && ~isempty(this.Window) && ~isempty(this.AppPage)
                this.Window.Position = this.convertOrigin(value);
            end
            bounds.x = value(1);
            bounds.y = value(2);
            bounds.w = value(3);
            bounds.h = value(4);
            this.setProperty('WindowBounds', bounds);
        end

        function value = get.WindowMaximized(this)
            import matlab.ui.container.internal.appcontainer.*;
            value = ~isempty(this.Window) && ~isempty(this.PrivateWindowState) && this.PrivateWindowState == AppWindowState.MAXIMIZED;
        end

        function set.WindowMaximized(this, value)
            import matlab.ui.container.internal.appcontainer.*;
            if ~isempty(this.Window)
                if value && this.PrivateWindowState ~= AppWindowState.MAXIMIZED
                    this.NotifyClientsOnWindowStateChange = false;
                    this.Window.maximize();
                elseif ~value && this.PrivateWindowState == AppWindowState.MAXIMIZED
                    this.NotifyClientsOnWindowStateChange = false;
                    this.Window.restore();
                end
            end
        end

        function value = get.WindowMinimized(this)
            import matlab.ui.container.internal.appcontainer.*;
            value = ~isempty(this.Window) && ~isempty(this.PrivateWindowState) && this.PrivateWindowState == AppWindowState.MINIMIZED;
        end

        function set.WindowMinimized(this, value)
            import matlab.ui.container.internal.appcontainer.*;
            if ~isempty(this.Window)
                if value && this.PrivateWindowState ~= AppWindowState.MINIMIZED
                    this.NotifyClientsOnWindowStateChange = false;
                    this.Window.minimize();
                elseif ~value && this.PrivateWindowState == AppWindowState.MINIMIZED
                    this.NotifyClientsOnWindowStateChange = false;
                    this.Window.restore();
                end
            end
        end

        function value = get.WindowMinSize(this)
            if isempty(this.Window)
                value = this.PrivateMinSize;
            else
                value = this.Window.MinSize;
            end
        end

        function set.WindowMinSize(this, value)
            if isempty(this.Window)
                this.PrivateMinSize = value;
            else
                this.Window.setMinSize(value);
            end
        end

        function set.Product(this, value)
            this.setProperty('Product', value);
        end
        
        function set.Scope(this, value)
            this.setProperty('Scope', value);
        end

        function set.UndockedPage(this, value)
            this.setProperty('UndockedPage', value);
        end
        
        function value = get.ReportJavaScriptErrors(this)
            value = this.getProperty('ReportJavaScriptErrors');
        end
        
        function set.ReportJavaScriptErrors(this, value)
            this.setProperty('ReportJavaScriptErrors', value);
        end
        
        function set.DojoConfig(this, value)
            this.Extension = matlab.ui.container.internal.appcontainer.ExtensionInfo();
            this.Extension.DebugConfigFile = value;
        end

        function bringToFront(this)
            if ~isempty(this.Window) && isvalid(this.Window)
                this.Window.bringToFront();
            end
        end
        
        function add(this, child)
            % add Adds a child to the container
            %    The child may be a Panel, DocumentGroup, Document, TabGroup,
            %    StatusBar or QABControl
            %
            %    When adding a document the document group with which it is associated must have previously
            %    been added to the AppContainer.
            if isa(child, 'matlab.ui.container.internal.appcontainer.Panel')
                this.addPanel(child);
            elseif isa(child, 'matlab.ui.container.internal.appcontainer.DocumentGroup')
                this.registerDocumentGroup(child);
            elseif isa(child, 'matlab.ui.container.internal.appcontainer.Document')
                this.addDocument(child);
            elseif isa(child, 'matlab.ui.internal.toolstrip.TabGroup')
                this.addTabGroup(child);
            elseif isa(child, 'matlab.ui.internal.statusbar.StatusBar')
                this.addStatusBar(child);
            elseif isa(child, 'matlab.ui.internal.statusbar.mixin.StatusComponent')
                this.addStatusComponent(child);
            elseif isa(child, 'matlab.ui.internal.toolstrip.base.QABControl')
                this.addQabControl(child);
            else
                error("Attempting to add child of unknown type");
            end
        end

        function child = get(this, childType, varargin)
            % get Returns the object representing the specified child
            %    get(PANEL, tagOrTitle) returns the Panel having the specified Tag or Title property
            %    get(DOCUMENT_GROUP, tagOrTitle) returns the DocumentGroup having the specified Tag or Title property
            %    get(DOCUMENT, documentGroupTag, tagOrTitle) returns the Document having the specified DocumentGroupTag property
            %                                                and either the specified Tag or Title property
            %    get(TOOLSTRIP_TAB_GROUP, tagOrTitle) returns the TabGroup having the specified Tag or Title property
            %    get(STATUS_BAR) returns the StatusBar
            import matlab.ui.container.internal.appcontainer.*;
            switch (childType)
                case ChildType.PANEL
                    child = this.getPanel(varargin{1});
                case ChildType.DOCUMENT_GROUP
                    child = this.getDocumentGroup(varargin{1});
                case ChildType.DOCUMENT
                    child = this.getDocument(varargin{1}, varargin{2});
                case ChildType.TOOLSTRIP_TAB_GROUP
                    child = this.getTabGroup(varargin{1});
                case ChildType.STATUS_BAR
                    child = this.getStatusBar();
                otherwise
                    error("Attempting to get child of unknown type");
            end            
        end
        
        function result = has(this, childType, varargin)
            % has Returns a logical value indicating whether the container has the specified child
            %    has(PANEL, tagOrTitle) returns true if the container has a panel with the specified Tag or Title property
            %    has(DOCUMENT_GROUP, tagOrTitle) returns true if the container has a document type with the specified Tag or Title property
            %    has(DOCUMENT, documentGroupTag, tagOrTitle) returns true if the container has a document with the specified
            %                                             DocumentGroupTag property and either the specified Tag or Title property
            %    has(TOOLSTRIP_TAB_GROUP, tagOrTitle) returns true if the container has a tab group with the specified Tag or Title property
            %    has(STATUS_BAR) returns true if the container has a status bar
            import matlab.ui.container.internal.appcontainer.*;
            switch (childType)
                case ChildType.PANEL
                    result = this.hasPanel(varargin{1});
                case ChildType.DOCUMENT_GROUP
                    result = this.hasDocumentGroup(varargin{1});
                case ChildType.DOCUMENT
                    result = this.hasDocument(varargin{1}, varargin{2});
                case ChildType.TOOLSTRIP_TAB_GROUP
                    result = this.hasTabGroup(varargin{1});
                case ChildType.STATUS_BAR
                    result = this.hasStatusBar();
                otherwise
                    error("Querying for child of unknown type");
            end
        end
        
        function addPanel(this, panel)
            import matlab.ui.container.internal.appcontainer.*;
           
            if isa(panel,'matlab.ui.internal.FigurePanel') && this.EnableTheming
                matlab.graphics.internal.themes.figureUseDesktopTheme(panel.Figure);
            end
            if isempty(panel.Tag) || panel.Tag == ""
                this.UntaggedPanelCount = this.UntaggedPanelCount + 1;
                panel.Tag = "panel" + this.UntaggedPanelCount;
            elseif this.hasPanel(panel.Tag) && panel ~= this.getPanel(panel.Tag)
                error("Duplicate panel Tag: " + panel.Tag);
            end
            if this.ViewInitialized
                panel.PeerNode = this.ModelRoot.addChild('panel', panel.getInternalPropertiesForPeer());
            end
            this.PanelMap(char(panel.Tag)) = panel;
            this.PanelOrder(this.PanelOrder==char(panel.Tag)) = []; % remove existing panel if any
            this.PanelOrder(end+1) = char(panel.Tag);
        end

        function registerDocumentGroup(this, group)
            import matlab.ui.container.internal.appcontainer.*;
            if isempty(group.Tag) || group.Tag == ""
                this.UntaggedDocumentGroupCount = this.UntaggedDocumentGroupCount + 1;
                group.Tag = "group" + this.UntaggedDocumentGroupCount;
            elseif this.hasDocumentGroup(group.Tag) && group ~= this.getDocumentGroup(group.Tag)
                error("Duplicate document group Tag: " + group.Tag);
            end
            if ~this.ViewInitialized
                if ~isempty(group.Context) && ~isempty(group.Context.ToolstripTabGroupTags)
                    this.ToolstripEnabled = true;
                end
            else
                group.PeerNode = this.ModelRoot.addChild('documentType', group.getInternalPropertiesForPeer());
            end
            this.DocumentGroupMap(char(group.Tag)) = group;
        end

        function addDocument(this, document)
            import matlab.ui.container.internal.appcontainer.*;
            
            if isa(document,'matlab.ui.internal.FigureDocument') && this.EnableTheming
                matlab.graphics.internal.themes.figureUseDesktopTheme(document.Figure);
            end
            if isempty(document.Tag) || document.Tag == ""
                this.UntaggedDocumentCount = this.UntaggedDocumentCount + 1;
                document.Tag = "document" + this.UntaggedDocumentCount;
            elseif this.hasDocument(document.DocumentGroupTag, document.Tag) && ...
               document ~= this.getDocument(document.DocumentGroupTag, document.Tag)
                error("Duplicate document Tag:" + document.Tag + " in group " + document.DocumentGroupTag);
            end
            if ~isempty(document.DocumentGroupTag)  && ~this.hasDocumentGroup(document.DocumentGroupTag)
                error("Cannot add document to unknown group: " + document.DocumentGroupTag);
            end
            if this.ViewInitialized
                if (isempty(document.DocumentGroupTag) || document.DocumentGroupTag == "") && ...
                        this.UntaggedDocumentGroupCount > 0
                    document.DocumentGroupTag = "group" + 1;
                end
                document.ChildType = class(document);
                document.PeerNode = this.ModelRoot.addChild('document', document.getInternalPropertiesForPeer());
                % handle the case where Opened Property is changed prorammatically
                addlistener(document, 'Opened', 'PostSet', @(src, event) handleDocumentOpenedPropertyChange(this, src, event, true));
                % handle the case where document is closed interactively
                addlistener(document, 'PropertyChanged', @(event, data) handleDocumentPeerNodePropertyChange(this, data, true));
                % handle the case where document is closed programmatically via document.close() method
                addlistener(document, 'LocalCloseStarted', @(event, data) handleDocumentLevelProgrammaticClose(this, data));
            end
            this.addDocumentInMotion(document.UUID, document, this.AsyncMotion_Opening);
            this.addToDocumentMap(char(document.DocumentGroupTag + document.Tag), document);
        end
        
        function addTabGroup(this, tabGroup)
            if ~isprop(tabGroup, 'Tag') || tabGroup.Tag == ""
                error("TabGroup must include a non-empty Tag property");
            end
            if ~this.ViewInitialized
                % If the peer model hasn't been intialized just store the tab group for now
                this.ToolstripEnabled = true;
            else
                if isempty(this.ToolstripChannel)
                    error("Toolstrip is not enabled, cannot add a TabGroup");
                end
                tabGroup.render(this.ToolstripChannel, 'OrphanRoot');
            end
            this.TabGroupMap(char(tabGroup.Tag)) = tabGroup;
            this.TabGroupOrder(this.TabGroupOrder == tabGroup) = []; % remove existing tabgroup
            this.TabGroupOrder(end+1) = tabGroup;
        end
        
        function addStatusBar(this, statusBar)
            if ~isempty(this.StatusBar)
                error("A StatusBar has already been added");
            end

            if ~isprop(statusBar, 'Tag') || statusBar.Tag == ""
                statusBar.Tag = "statusBar";
            end

            this.StatusBar = statusBar;
            if this.ViewInitialized
                statusBar.render(this.ToolstripChannel);
            end
        end
        
        function addStatusComponent(this, statusComponent)
            if ~isprop(statusComponent, 'Tag') || statusComponent.Tag == ""
                error("StatusComponent must include a non-empty Tag property");
            end
            if this.ViewInitialized
                statusComponent.render(this.ToolstripChannel, 'StatusBarRoot');
            end
            this.StatusComponentMap(char(statusComponent.Tag)) = statusComponent;
        end

        function addQabControl(this, qabControl)
            if ~isa(qabControl, 'matlab.ui.internal.toolstrip.base.QABControl')
                error("A QABControl is expected.");
            end

            if isempty(qabControl.Tag) || qabControl.Tag == ""
                this.UntaggedQabControlCount = this.UntaggedQabControlCount + 1;
                qabControl.Tag = "qabControl" + this.UntaggedQabControlCount;
%             elseif this.hasQabControl(qabControl.Tag) && qabControl ~= this.getQabControl(qabControl.Tag)
%                 error("Duplicate qabControl Tag: " + qabControl.Tag);
            end

            % TODO: Check for duplicates of Common Controls

            if isempty(this.GlobalQuickAccessGroup)
                this.createGlobalQAGroup();
            end
			% TODO: Update second input when it becomes a property instead of an input string
            this.GlobalQuickAccessGroup.add(qabControl, 'rtl');
            qabControl.addedToQuickAccess();

%             this.QabControlMap(char(qabControl.Tag)) = qabControl;
        end
        
        function removeQabControl(this, tagOrTitle)
            qabControl = this.GlobalQuickAccessGroup.getChildByTag(tagOrTitle);
%             if isempty(qabControl) % handle title
%                 qabControl = this.GlobalQuickAccessGroup.getChildByTag();
%                 for i = 1:numel(qabControl)
%
%                 end
%             end
            
            if ~isempty(qabControl)
                this.GlobalQuickAccessGroup.remove(qabControl);
                qabControl.addedToQuickAccess(false);
            end
        end
        
%         function qabControl = getQabControl(this, tagOrTitle)
%             qabControl = this.getQabControlFromMap(tagOrTitle);
%             if isempty(qabControl)
%                 % Not found.  Look in the peer model
%                 node = this.getQabControlClientNode(tagOrTitle);
%                 if ~isempty(node)
%                     qabControl = this.addQabControlFromPeerNode(node);
%                 end
%             end
%         end
% 
%         function addQabControlFromPeerNode(this, node)
% 
%         end
% 
%         function getQabControlClientNode(this, tagOrTitle)
% 
%         end
% 
%         function getQabControlFromMap(this, tagOrTitle)
% 
%         end
% 
%         function hasQabControl(this, tagOrTitle)
% 
%         end
        
        function panel = getPanel(this, tagOrTitle)
            panel = this.getPanelFromMap(tagOrTitle);
            if isempty(panel)
                % Not found.  Look in the peer model
                node = this.getPanelNodeAddedByClient(tagOrTitle);
                if ~isempty(node)
                    panel = this.addPanelFromPeerNode(node);
                end
            end
        end    
        
        function documentGroup = getDocumentGroup(this, tagOrTitle)
            if this.DocumentGroupMap.isKey(char(tagOrTitle))
                % Get by Tag
                documentGroup = this.DocumentGroupMap(char(tagOrTitle));
            else
                % Look for by title
                documentGroup = this.getDocumentGroupByTitle(tagOrTitle);
                if isempty(documentGroup)
                    % Not found.  Look in the peer model
                    node = this.getDocumentGroupNodeAddedByClient(tagOrTitle);
                    if ~isempty(node)
                        documentGroup = this.addDocumentGroupFromPeerNode(node);
                    end
                end
            end
        end    

        function document = getDocument(this, documentGroupTag, tagOrTitle)
            if ischar(documentGroupTag) && ischar(tagOrTitle)
                key = [documentGroupTag tagOrTitle];
            else
                key = char(documentGroupTag + tagOrTitle);
            end
            if this.isInDocumentMap(key)
                % Get by Tag
                document = this.getFromDocumentMap(key);
            else
                % Look for by title
                document = this.getDocumentByTitle(documentGroupTag, tagOrTitle);
                if isempty(document)
                    % Not found.  Look in the peer model
                    node = this.getDocumentNodeAddedByClient(documentGroupTag, tagOrTitle);
                    if ~isempty(node)
                        document = this.addDocumentFromPeerNode(node, key);
                    end
                end
            end
        end
        
        function tabGroup = getTabGroup(this, tag)
            tabGroup = [];
            if this.TabGroupMap.isKey(char(tag))
                % Get by tag
                tabGroup = this.TabGroupMap(char(tag));
            end
        end    
        
        function statusBar = getStatusBar(this)
            statusBar = this.StatusBar;
        end
        
        function statusComponent = getStatusComponent(this, tag)
            statusComponent = []';
            if this.StatusComponentMap.isKey(char(tag))
                statusComponent = this.StatusComponentMap(char(tag));
            end  
        end
        
        function panels = getPanels(this)
            % getPanels Returns a cell array containing all the panels in the AppContainer
            if isvalid(this) && this.ClientDriven
                % Find all panels in the peer model.  Add entries for any not already
                % in the panel map
                children = this.ModelRoot.getChildren();
                for index = 1:length(children)
                    if strcmp(children(index).Type, 'panel')
                        node = children(index);
                        tag  = node.getProperty('panelId');
                        if ~this.PanelMap.isKey(tag)
                            this.addPanelFromPeerNode(node);
                        end
                    end       
                end
            end
            panels = this.PanelMap.values();
        end
        
        function groups = getDocumentGroups(this)
            % getDocumentGroups Returns a cell array containing all the document groups in the AppContainer

            if isvalid(this) && this.ClientDriven
                % Find all document groups in the peer model.  Add entries for any not already
                % in the document group map
                children = this.ModelRoot.getChildren();
                for index = 1:length(children)
                    if strcmp(children(index).Type, 'documentType')
                        node = children(index);
                        tag  = node.getProperty('typeId');
                        if ~this.DocumentGroupMap.isKey(tag)
                            this.addDocumentGroupFromPeerNode(node);
                        end
                    end       
                end
            end
            groups = this.DocumentGroupMap.values();
        end

        function documents = getDocuments(this, varargin)
            % getDocuments Returns a cell array containing all the documents in the AppContainer or a DocumentGroup
            %    getDocuments() returns all documents in the AppContainer
            %    getDocuments(documentGroupTag) returns all documents belonging to the DocumentGroup having the given tag

            if nargin > 1
                groupTag = string(varargin{1});
            else
                groupTag = "";
            end
        
            documents = this.getDocumentsWithFilter('GroupTag', groupTag, 'Property', 'Visible');
            for key = keys(this.ChildContainers)
                childApp = this.ChildContainers(key{1});
                documents = [documents childApp.getDocuments()];
            end
        end
        function result = hasPanel(this, tagOrTitle)
            result = this.PanelMap.isKey(char(tagOrTitle)) || ...
                     ~isempty(this.getPanelByTitle(tagOrTitle)) || ...
                     ~isempty(this.getPanelNodeAddedByClient(tagOrTitle));
        end
        
        function result = hasDocumentGroup(this, tagOrTitle)
            result = this.DocumentGroupMap.isKey(char(tagOrTitle)) || ...
                     ~isempty(this.getDocumentGroupByTitle(tagOrTitle)) || ...
                     ~isempty(this.getDocumentGroupNodeAddedByClient(tagOrTitle));
        end
        
        function result = hasDocument(this, documentGroupTag, tagOrTitle)
            this.waitForPendingAsyncOperations();

            result = this.isInDocumentMap(char(documentGroupTag + tagOrTitle)) || ...
                     ~isempty(this.getDocumentByTitle(documentGroupTag, tagOrTitle)) || ...
                     ~isempty(this.getDocumentNodeAddedByClient(documentGroupTag, tagOrTitle));
        end
        
        function result = hasTabGroup(this, tag)
            result = this.TabGroupMap.isKey(char(tag)) || ...
                     ~isempty(this.getTabGroupNode(tag));
        end
        
        function result = hasStatusBar(this)
            result = ~isempty(this.StatusBar);
        end
        
        function result = hasStatusComponent(this, tag)
            result = this.StatusComponentMap.isKey(char(tag));
        end
        
        function removePanel(this, tagOrTitle)
            panel = this.getPanelFromMap(tagOrTitle);
            if isempty(panel)
                error("Panel not found: " + tagOrTitle);
            end
            
            % Find node under model root (by Tag)
            [node, index] = this.getPanelNode(panel.Tag, this.ModelRoot);
            if index < 0
                error("Can not remove panel unless it was added via AppContainer: " + tagOrTitle);
            end
            
            this.PanelMap.remove(char(panel.Tag));
            this.PanelOrder(this.PanelOrder==char(panel.Tag)) = [];
            if ismethod(this.ModelRoot, 'deleteChild')
                this.ModelRoot.deleteChild(index);
            else
                node.delete();
            end
            delete(panel);

            % g2324933: Force a flush of changes to account for a use case of subsequent addPanel
            % notification. A subsequent addPanel notification should not be combined with this
            % removePanel notification. In this scenario, the order of messages received on the
            % client side is important. Flushing makes sure the removePanel message is received
            % first on the client side and all other subsequent notifications are received later.
            matlab.internal.yield;
        end

        function closeDocument(this, documentGroupTag, tagOrTitle, varargin)
            % Trigger close, removal will follow automatically
            document = this.getDocument(documentGroupTag, tagOrTitle);
            if isempty(document)
                error("Document not found: " + tagOrTitle + " in group" + documentGroupTag);
            end
            force = false;
            if nargin > 3
                force = varargin{1};
            end

            if force || document.canClose()
                if isvalid(document) % if canclose method didn't kill the doc
                    % g2266722: wait for opening motion to complete before
                    % proceeding
                    if this.SynchronousMode
                        if this.isDocumentInMotion(document.UUID) && strcmp(this.getMotionOfDocument(document.UUID), this.AsyncMotion_Opening)
                            this.waitForPendingAsyncOperations();
                        end
                    else
                        waitfor(document, "Opened", true); % maintain compatibility until AppContainers have SynchronousMode on by default
                    end
                   
                    % add document to DocumentsInMotion after running canClose method, since canClose implementation may
                    % actually close the doc instead of returning a
                    % boolean, or canClose methods may query other DocumentsInMotion-dependent properties
                    this.addDocumentInMotion(document.UUID, document, this.AsyncMotion_Closing);
                    document.Opened = false;

                    % wait till the document is deleted to as a proxy to know the client side
                    % was done processing the close of the document. see geck g2218468
                    if this.SynchronousMode
                        this.waitForPendingAsyncOperations();
                    else
                        waitfor(document); % maintain compatibility until AppContainers have SynchronousMode on by default
                    end
                end
            end
        end
    end
    
    methods
        function port = get.DebugPort(this)
            if ~isempty(this.Window)
                port = this.Window.RemoteDebuggingPort;
            else
                port = this.DebugPortInternal;
            end
        end

        function set.DebugPort(this, port)
            % Should only be used internally, so no need for localization
            this.throwWarning('MATLAB:uiframework:appcontainer:deprecatedAlternative', "DEPRECATED: Setting 'DebugPort' property will be removed in a future release. Use 'port = app.DebugPort;' to query the debug port instead.");
            this.DebugPortInternal = port;
        end

        function windowURL = get.WindowURL(this)
            windowURL = this.getProperty('WindowURL');
        end
    end

    methods (Access = protected, Static = true)
        function [params, features] = extractFeatures(params)
            features = string([]);

            for idx = 1:length(params)
                arg = params{idx};

                if strcmp(arg, 'Features')
                    features = params{idx + 1};
                    params(idx:idx + 1) = [];
                elseif isfield(arg, 'Features')
                    features = arg.Features;
                    params{idx} = rmfield(arg, 'Features');
                end

                if ~isempty(features)
                    features = string(features);
                    features = intersect(features, matlab.ui.container.internal.AppContainer.SupportedFeatures);
                    return;
                end
            end  
        end
    end
    
    methods (Access = protected)       
        function handlePeerNode(this)
            import matlab.ui.internal.toolstrip.TabGroup;
            % Set the can close function again to wire it up to the peer node
            if ~isempty(this.CanCloseFcn)
                this.CanCloseFcn = this.CanCloseFcn;
            end
            
            % Re add tab groups, status bar, status components, panels, document groups and documents
            % that were added before the peer model was initialized but not if the AppContainer attached to
            % or launched a JS built UIContainer. In the latter case the adds will already have occurred.
            if ~this.Attached && this.AppPage == ""
                tabGroups = this.TabGroupOrder; % we want to add tabgroups in the order they were added by user
                this.TabGroupOrder = TabGroup.empty; % reset tab group order
                for i = 1:length(tabGroups)
                    tabGroup = tabGroups(i);
                    this.addTabGroup(tabGroup);
                end

                if ~isempty(this.StatusBar)
                    statusBar = this.StatusBar;
                    this.StatusBar = [];
                    this.addStatusBar(statusBar);
                end

                statusComponents = this.StatusComponentMap.values();
                for i = 1:length(statusComponents)
                    this.addStatusComponent(statusComponents{i});
                end

                panels = this.PanelOrder;
                this.PanelOrder = string.empty; % reset panel order after attaching app
                for i = 1:length(panels)
                    panelTag=panels(i);
                    this.addPanel(this.PanelMap(panelTag));
                end

                documentGroups = this.DocumentGroupMap.values();
                for i = 1:length(documentGroups)
                    this.registerDocumentGroup(documentGroups{i});
                end

                % We do not want the DocumentMap to be refreshed here
                documents = this.getAllFromDocumentMap(true);
                for i = 1:length(documents)
                    this.addDocument(documents{i});
                end
            end
        end
        
        function page = getPage(this)
            if this.UseWebpack
                buildPath = "/web";
            else
                buildPath = "_dojo";
            end
            
            if this.AppPage ~= ""
                page = this.AppPage;
                if this.CleanStart
                    if ~contains(page, '?')
                        page = page + "?";
                    else 
                        page = page + "&";
                    end
                    page = page + "cleanStart=true";
                end
            elseif ~isempty(this.Extension) && ~this.UseWebpack
                page = strcat("/toolbox/matlab/appcontainer", buildPath, "/index-extensible.html");
            else
                page = strcat("/toolbox/matlab/appcontainer", buildPath, "/index.html");
            end
        end
        
        function page = addExtensionsInfoToQueryParameters(this, page)
            page = this.addExtensionInfoToQueryParameters(this.Extension.ReleaseCSSFiles, "cssFiles", page, false);
            if this.UseWebpack
                modules = this.Extension.Modules;
                for idx = 1:length(modules)
                    page = this.addExtensionInfoToQueryParameters(modules(idx).Path, sprintf("modulePath[%d]", idx - 1), page, true);
                    page = this.addExtensionInfoToQueryParameters(modules(idx).Exports, sprintf("moduleExports[%d]", idx - 1), page, false);
                    page = this.addExtensionInfoToQueryParameters(modules(idx).Name, sprintf("moduleName[%d]", idx - 1), page, false);
                end
            else
                page = this.addExtensionInfoToQueryParameters(this.Extension.ReleasePackageNames, "packageNames", page, true);
                page = this.addExtensionInfoToQueryParameters(this.Extension.ReleasePackageLocations, "packageLocations", page, true);
                page = this.addExtensionInfoToQueryParameters(this.Extension.ReleaseMainFileNames, "mainFileNames", page, true);
            end
        end
        
        function page = addExtensionInfoToQueryParameters(~, extension, queryParameter, page, throwError)
            if ~isempty(extension) && all(extension ~= "")
                page = page + "&" + queryParameter + "=" + strjoin(extension, ',');
            elseif throwError
                error(extensionName + " property of ExtensionInfo should not be empty");
            end
        end

        function setUndockedPage(this)
              if ~this.UseWebpack
                  this.UndockedPage = "undocked.html";
              end
        end

        function handleStartedMessage(this)
            if this.AppPage ~= ""
                reply.type = 'attach';
                reply.modelChannel = this.ModelChannel;
                if ~isempty(this.ToolstripChannel)
                    reply.toolstripChannel = this.ToolstripChannel;
                end
                message.publish(this.MessageChannel, reply);
            end
            this.setStateToRunning();
        end
    end

    methods (Access = ?matlab.unittest.TestCase)
        function handleReceivedMessage(this, data)
            import matlab.ui.container.internal.appcontainer.*;
            switch (data.type)
                case 'uiContainerSpawned'
                    appOptions.Tag = data.id;
                    childApp = matlab.ui.container.internal.AppContainer(appOptions);
                    childApp.ParentContainer = this;
                    childApp.attach();
                    this.ChildContainers(char(data.id)) = childApp;
                case 'clientReady'
                    if this.AppPage == ""
                        dataStr.type = 'start';
                        this.dispatchEvent(this.ModelRoot, dataStr);
                    end
                case 'started'
                    this.handleStartedMessage();
                case 'terminated'
                    if ~isempty(this.ParentContainer)
                        remove(this.ParentContainer.ChildContainers, char(this.Tag));
                    end
                    this.runCloseTasks(false);
                case 'error'
                    disp(data.message);
                    disp(data.stack);
                case 'removeOpeningDocument'
                    % Remove the document from documentsinMotion and from
                    % the Model.
                    data = data.data;
                    this.removeDocumentInMotion(data.uuid, this.AsyncMotion_Opening);
                    props.childType = 'document';
                    props.documentId = data.documentTag;
                    props.documentType = data.documentGroupTag;
                    eventData.data = props;
                    this.removeChildFromModel(eventData);
            end
        end
    end

    methods (Access = private)
        function parseFeatures(this, features)
            for idx = 1:numel(features)
                feature = features(idx);
                set(this, feature, true);
            end
        end

        function initializeView(this, attach)
            import matlab.ui.internal.toolstrip.base.*;
            import peermodel.internal.*;
            import viewmodel.internal.*;

            if this.ViewInitialized
                return;
            end
            this.ViewInitialized = true;

            if isempty(this.Tag) || this.Tag == ""
                if attach
                    error("Tag must be specified in order to attach");
                else
                    this.Tag = char(matlab.lang.internal.uuid);
                end
            end
            
            this.MessageChannel = "/" + this.Tag + "/uicontainer";
             % Start connector
            connector.ensureServiceOn;
            this.MessageSubscription = message.subscribe(this.MessageChannel, @(data) handleReceivedMessage(this, data));
           
           
            
            % Start ModelRoot peer model. Will be used to add to the container from the server (MATLAB) side
            % In attach workflow, the model will also be updated from the client side (JavaScript)
            uuid = char(matlab.lang.internal.uuid);
            this.ModelChannel = ['/app/' uuid];
            this.ModelManager = ViewModelManagerFactory.getViewModelManager(this.ModelChannel);
            % View Model callbacks are made to be asynchronous as described in 
            % https://confluence.mathworks.com/display/MABIS/View+Model+Callbacks+Asynchronicity
            % This is a temporary opt in mechanism that can be removed later when the View Model
            % callbacks are async by default
            if ismethod(this.ModelManager, 'setAsyncFlag')
                this.ModelManager.setAsyncFlag(true);
            end

            this.ModelRoot = this.ModelManager.setRoot('Root');
            this.addEventListener(this.ModelRoot, 'containerModelBuilt', @(~, ~) setStateToRunning(this));
            this.addEventListener(this.ModelRoot, 'childRemoveRequest', @(event, data) removeChildFromModel(this, data));
            this.addEventListener(this.ModelRoot, 'childAddRequest', @(event, data) addChildToModel(this, data));
            this.addEventListener(this.ModelRoot, 'asyncOperationComplete', @(event, data) notifyAsyncOperationIsComplete(this, data));
            
            % g2573485: Set the index page to be used for undocked child windows
            % Only set this property for AppContainer workflows that
            % create a new view.
            if (this.AppPage == "" && ~attach)
                this.setUndockedPage();
            end

            this.ModelRoot.setProperties(this.getInternalPropertiesForPeer());

            if this.AppPage ~= "" || attach
                this.ClientDriven = true;
                data.type = 'attach';
                data.modelChannel = this.ModelChannel;
                data.useMF0ForTS = this.UseMF0ForTS;
                message.publish(this.MessageChannel, data);
            end

            if this.ToolstripEnabled || ~isempty(this.StatusBar)
                % Start toolstrip/status bar peer model
                uuid = char(matlab.lang.internal.uuid);
                this.ToolstripChannel = ['/app/' uuid];
                this.ToolstripModelManager = ToolstripService.initialize(this.ToolstripChannel);
                this.ToolstripModelManager.getRoot().addChild('StatusBarRoot');
                this.ToolstripModelManager.getRoot().addChild('QAGroupRoot');
                % The above line should not be necessary but this root is not created
                % by ToolstripService.initialize and is expected in TabGroup.render
                ActionService.initialize([this.ToolstripChannel '_Action']);
                
                % Once the peer model is ready, we need to create and 
                % attach the TS, and attach the QAB
                this.Toolstrip = addlistener(this, 'StateChanged', @(~, ~)this.attachToolstrip());
            end

            % Set PeerNode.  Needs to be done after toolstrip channel initialized because
            % it may trigger tag group adds
            this.PeerNode = this.ModelRoot;
        end

        function notifyAsyncOperationIsComplete(this, eventData)
            data = eventData.data;
            properties = data.properties;
            switch data.operationName
                case 'childRemoved'
                    switch data.childType
                        case 'document'
                            this.removeDocumentInMotion(data.properties.uuid, this.AsyncMotion_Closing);
                    end
                case 'childAdded'
                    switch data.childType
                        case 'document'
                            this.removeDocumentInMotion(data.properties.uuid, this.AsyncMotion_Opening);
                    end
            end
        end
        
        function runCloseTasks(this, deleteCall)
            import matlab.ui.container.internal.appcontainer.*;
            % Safety checks:
            % Handle is invalid in two cases:
            % Case 1: once when the deletion has
            % been initiated and the properties have been cleared 
            % Case 2: When the handle is deleted and is no longer accessible.
            if ~isvalid(this)
                % Check if 'State' property exists(For Case 2) or Check for Case 1
                if ~isprop(this, 'State') || this.PrivateState == AppState.TERMINATED
                    return
                end
            end
            if ~isempty(this.MessageChannel)
                data.type = 'detach';
                message.publish(this.MessageChannel, data);
            end

            % CEF Window
            if ~isempty(this.Window)
                if deleteCall
                    % Delete the window since AppContainer handle is deleted
                    delete(this.Window);

                    % Don't notify clients when the window is closed programmatically
                    this.NotifyClientsOnWindowStateChange = false;
                    
                    this.Window = [];
                end

                this.updateWindowState(AppWindowState.CLOSED);
            end

            % Browser Window
            if ~isempty(this.BrowserHandle)
                if deleteCall
                    % Close the browser handle since AppContainer handle is deleted
                    close(this.BrowserHandle);

                    % Don't notify clients when the window is closed programmatically
                    this.NotifyClientsOnWindowStateChange = false;

                    this.BrowserHandle = [];
                end

                this.updateWindowState(AppWindowState.CLOSED);
            end

            % Notify listeners before deleting internal objects
            if this.PrivateState ~= AppState.TERMINATED
                this.PrivateState = AppState.TERMINATED;
                % delete children after setting state, but before notifying
                % listeners, so that children can query state of parent if
                % they desire, but are cleaned up before any listeners are
                % called
                this.destroyChildren();

                % Fix for g2333190
                % call cleanup in the end, so that destroyChildren method can
                % access the ClientRoot node.
                % --
                % g2367218: Call cleanup before notifying of state change to prevent
                % downstream code from deleting "this" before we can
                % complete cleanup.  Accompanied by a safety check in cleanup

                this.cleanup();
                notify(this, 'StateChanged');
            else
                % Fix for g2333190
                % call cleanup in the end, so that destroyChildren method can
                % access the ClientRoot node.
                this.cleanup();
            end
        end

        function attachToolstrip(this)
            import matlab.ui.container.internal.appcontainer.*;
            if this.PrivateState == AppState.RUNNING
                delete(this.Toolstrip);
                this.Toolstrip = matlab.ui.internal.toolstrip.Toolstrip();
                this.Toolstrip.Tag = "uirootToolstrip";
                this.Toolstrip.attach(this.ToolstripChannel);
                % Toolstrip creates the QuickAccessBar automatically
                this.QuickAccessBar = this.Toolstrip.getQuickAccessBar();
                
                % If the Global QAGroup was already created, add it to the
                % QAB
                if ~isempty(this.GlobalQuickAccessGroup)
                    this.QuickAccessBar.add(this.GlobalQuickAccessGroup);
                end
            end
        end
        
        function createGlobalQAGroup(this)
            if isempty(this.GlobalQuickAccessGroup)
                this.GlobalQuickAccessGroup = matlab.ui.internal.toolstrip.impl.QuickAccessGroup();
                this.GlobalQuickAccessGroup.Tag = 'globalQaGroup';
            end
            
            % If the QAB has already been attached, add the global QAGroup
            % to the QAB
            if ~isempty(this.QuickAccessBar)
                this.QuickAccessBar.add(this.GlobalQuickAccessGroup);
            end
        end
        
        function page = composeURN(this)
            page = this.getPage();
            if ~contains(page, '?')
                page = page + "?";
            else 
                page = page + "&";
            end
            page = page + "channel=" + this.ModelChannel;
            if ~isempty(this.ToolstripChannel)
                page = page + "&toolstripChannel=" + this.ToolstripChannel;
            end
            if this.AppPage == ""
                page = page + "&id=" + this.Tag;
            end

            if this.UseMF0ForTS
                page = page + "&UseMF0ForTS=true";
            else
                page = page + "&UseMF0ForTS=false";
            end

            if this.WaitForJavaScriptDebugger
                page = page + "&waitForJavascriptDebugger=true";
            else
                page = page + "&waitForJavascriptDebugger=false";
            end

            if ~isempty(this.Extension)
                page = this.addExtensionsInfoToQueryParameters(page);
            end
        end
        
        function window = buildWindow(this, windowBounds)
            url = connector.getUrl(char(this.composeURN()));
            window = matlab.internal.webwindow(url, this.getOpenPort());
            notify(this, 'WindowCreated');
            if this.AppPage == ""
                % If launching from a custom page, assume that page will set the following
                window.Title = char(this.Title);
                if ~isempty(this.Icon) && this.Icon ~= ""
                    window.Icon = char(this.Icon);
                end
                if ~isempty(windowBounds)
                    window.Position = windowBounds;
                    % We extracted the window bounds from the internal
                    % properties struct in 'Set.Visible' because the peer
                    % model node constructor doesn't handle structs in the
                    % initial property list.  Now we should set it back.
                    this.WindowBounds = matlab.ui.container.internal.AppContainer.convertOrigin(windowBounds);
                end
            end
            % The following properties can't currently be set by the page
            % (the JavaScript cefclient API does not support them).
            window.setResizable(this.Resizable);
            if ~isempty(this.PrivateMinSize)
                window.setMinSize(this.PrivateMinSize);
            end

            % Ensure that the State property is updated properly on window close
            window.CustomWindowClosingCallback = @windowClosingCallback;

            % Ensure that the State property is updated properly when window closes unexpectedly.
            window.MATLABWindowExitedCallback = @windowExitedCallback;

            window.WindowStateCallback = @windowStateChangeHandler;

            window.WindowResized = @windowResizedCallback;

            function windowResizedCallback (win, ~)
                % if window position is modified, set WindowBoundsModified flag.
                if ~all(win.Position==this.OriginalWindowBounds)
                    this.setPeerProperty("WindowBoundsModified", true);
                    win.WindowResized = [];
                end
            end

            function windowExitedCallback(win, ~)
                win.close();
                this.runCloseTasks(false);
            end

            function windowStateChangeHandler(~, windowState)
                import matlab.ui.container.internal.appcontainer.*;

                switch (windowState)
                    case 'WindowRestored'
                        this.updateWindowState(AppWindowState.NORMAL)
                    case 'WindowMinimized'
                        this.updateWindowState(AppWindowState.MINIMIZED)
                    case 'WindowMaximized'
                        this.updateWindowState(AppWindowState.MAXIMIZED)
                end
            end

            function windowClosingCallback(win, ~)
                % Call canClose if it was not already called by
                % handlePeerEvent
                if ~this.CanCloseExecuted
                    result = this.canClose();
                    % Resetting CanCloseExecuted since canClose was
                    % called from windowClosingCallback
                    this.CanCloseExecuted = false;
                end
                % Window should close in 3 cases:
                % Case 1: The App does not have a CanCloseFcn.
                % Case 2: The App has a CanCloseFcn and has already been
                % executed. This only happens in the handlePeerEvent code
                % path.
                % Case 3: If CanClose was called within this
                % 'windowClosingCallback' and the canClose returns true.
                canWindowClose = isempty(this.CanCloseFcn) || this.CanCloseExecuted ...
                    || (exist('result', 'var') && result) ;
                if canWindowClose
                    win.close();
                    this.runCloseTasks(false);
                end
            end
        end

        function updateWindowState(this, newWindowState)
            if this.PrivateWindowState ~= newWindowState
                this.PrivateWindowState = newWindowState;
                if this.NotifyClientsOnWindowStateChange
                    notify(this, 'WindowStateChanged');
                end
                this.NotifyClientsOnWindowStateChange = true;
            end
        end
        
        function tabGroups = getAllTabGroups(this)
           tabGroups = values(this.TabGroupMap);
        end

        function allChildren = getAllChildren(this)
            panels = this.getPanels();
            documents = this.getDocuments();
            invisibleDocuments = this.getInvisibleDocuments();
            documentGroups = this.getDocumentGroups();
            statusBar = this.getStatusBar();
            tabGroups = this.getAllTabGroups();

            allChildren = [panels, documents, invisibleDocuments, documentGroups, tabGroups];

            if ~isempty(statusBar)
                allChildren = [allChildren, {statusBar}];
            end

            % QABControls?, StatusComponents?
        end

        function destroyChildren(this)
            children = this.getAllChildren();
            
            for i = 1:numel(children)
                child = children{i};
                delete(child);
            end
        end

        function port = getOpenPort(this)
            port = this.DebugPort;
            % Launch the CEF app with a debug port greater than 1024
            if port <= 1024
                port = matlab.internal.getDebugPort();
            end
        end
        
        function result = canClose(this)
            if isempty(this.CanCloseFcn)
                result = true;
            elseif ~this.CanCloseExecuting
                this.clearDocumentsInMotion(); % clear DocsInMotion here incase user's canCloseFcn includes a waitfor/uiwait which conflicts with qeblockedstate (test-only issue)
                % g2360352: Handle exception thrown by CanCloseFcn callback
                % because it can fail silently in non linux platform
                try
                    this.setCanCloseExecuting(true);
                    cleanupObj = onCleanup(@()setCanCloseExecuting(this, false));
                    result = feval(this.CanCloseFcn, this);
                catch ME
                    result = false;
                    warning('backtrace', 'off');
                    warning(['Prevented the app close since an error occurred while running the app''s CanCloseFcn function' newline getReport(ME)]);
                    warning('backtrace', 'on');
                end
            end
            this.CanCloseExecuted = true;
        end

        function setCanCloseExecuting(this, value)
            this.CanCloseExecuting = value;
        end
        
        function cleanup(this)
            % g2333190: safety check to see if "this" is not deleted
            if ~isvalid(this)
                return
            end

            this.clearDocumentsInMotion();

            if ~isempty(this.MessageSubscription)
                message.unsubscribe(this.MessageSubscription);
                this.MessageSubscription = '';
            end
            if ~isempty(this.ModelChannel)
                if ~isempty(this.ModelRoot)
                    this.ModelRoot.delete();
                end

                this.ModelChannel = '';
            end

            if ~isempty(this.ToolstripChannel)
                if this.UseMF0ForTS
                    if isvalid(this.ToolstripModelManager)
                        this.ToolstripModelManager.delete();
                    end
                else
                    com.mathworks.peermodel.PeerModelManagers.cleanup(this.ToolstripChannel);
                    this.ToolstripChannel = '';
                end
            end
        end
        
        function updatedLayout = adjustTileIndices(this, documentLayout, adjustment)
            if isfield(documentLayout, 'tileCoverage')
                documentLayout.tileCoverage = documentLayout.tileCoverage + adjustment;
                if adjustment < 0 && any(documentLayout.tileCoverage < 0, 'all')
                    error("tileCoverage value out of range 1 to tile count");
                end
            end
            if isfield(documentLayout, 'nesting')
                documentLayout.nesting = this.adjustTileIndices(documentLayout.nesting, adjustment);
            end
            updatedLayout = documentLayout;
        end
        
        function setStateToRunning(this)
            import matlab.ui.container.internal.appcontainer.*;
            if this.PrivateState == AppState.INITIALIZING
                this.PrivateState = AppState.RUNNING;
                notify(this, 'StateChanged');
            end
        end

        function removeChildFromModel(this, data)
            eventData = data.data;

            [node, index] = this.findChildInModel(eventData);

            if index >= 0 && ~isempty(node)
                if isfield(eventData, 'removeRequestOrigin')
                    node.setProperty('removeRequestOrigin', eventData.removeRequestOrigin);
                end

                if ismethod(this.ModelRoot, 'deleteChild')
                    this.ModelRoot.deleteChild(index);
                else
                    node.delete();
                end
            end
        end

        function addChildToModel(this, data)
            eventData = data.data;

            [node, index] = this.findChildInModel(eventData);

            if index >= 0 && ~isempty(node)
                return;
            end

            this.ModelRoot.addChild(eventData.childType, eventData);
        end

        function [node, index] = findChildInModel(this, props)
            switch (props.childType)
                case 'panel'
                    [node, index] = this.getPanelNode(props.panelId, this.ModelRoot);
                case 'documentType'
                    [node, index] = this.getDocumentGroupNode(props.typeId, this.ModelRoot);
                case 'document'
                    if isfield(props, 'documentId')
                        documentTagOrTitle = props.documentId;
                    else
                        documentTagOrTitle = props.title;
                    end
                    [node, index] = this.getDocumentNode(props.documentType, documentTagOrTitle, this.ModelRoot);
            end
        end

        function handleDocumentPeerNodePropertyChange(this, data, addedByServer)
            % By default the document should be destroyed when Opened property is received as false
            destroyOnClose = 1;
            % Unless, it is a temporary close and destoryOnClose flag is received as false from the client
            if isstruct(data.MetaData) && isfield(data.MetaData, 'destroyOnClose') && ~isempty(data.MetaData.destroyOnClose)
                destroyOnClose = data.MetaData.destroyOnClose;
            end

            if isvalid(this) && strcmp(data.PropertyName, 'Opened') && ~data.Source.Opened && destroyOnClose
                % Find node under model root (by Tag)
                document = data.Source;
                this.runCloseDocumentTasks(document, addedByServer);
            end
        end
        
        function handleDocumentOpenedPropertyChange(this, ~, event, addedByServer)
            document = event.AffectedObject;
            if document.Opened == 0
                this.runCloseDocumentTasks(document, addedByServer);
            end
        end

        function handleDocumentLevelProgrammaticClose(this, data)
            document = data.Source;
            this.addDocumentInMotion(document.UUID, document, this.AsyncMotion_Closing);
        end
        
        function runCloseDocumentTasks(this, document, addedByServer)
            if document.Visible
                this.removeFromDocumentMap(char(document.DocumentGroupTag + document.Tag));
                if addedByServer && document.Visible
                    % Find node under model root (by Tag)
                    [node, index] = matlab.ui.container.internal.AppContainer.getDocumentNode(document.DocumentGroupTag, document.Tag, this.ModelRoot);
                    if index >= 0
                        if ismethod(this.ModelRoot, 'deleteChild')
                            this.ModelRoot.deleteChild(index);
                        else
                            % node.delete();
                        end
                    end
                end
                delete(document);
            end
        end

        function handlePeerEvent(this, data)
            if isvalid(this)
                shouldReply = false;
                dataField = '';
                
                if (isfield(data, 'EventData') && strcmp(data.EventData.type, 'closeQuery'))
                    shouldReply = true;
                    dataField = 'EventData';
                elseif (isfield(data, 'Data') && strcmp(data.Data.type, 'closeQuery'))
                    shouldReply = true;
                    dataField = 'Data';
                elseif (isfield(data, 'data') && strcmp(data.data.type, 'closeQuery'))
                    shouldReply = true;
                    dataField = 'data';
                end
                if shouldReply && ~this.CanCloseExecuting % not already processing a close request
                    % Reply to close query
                    event.type = 'closeReply';
                    event.approve = this.canClose();
                    event.id = data.(dataField).id;
                    this.dispatchEvent(this.ModelRoot, event);
                end
            end
        end
        
        function panel = addPanelFromPeerNode(this, node)
            import matlab.ui.container.internal.appcontainer.*;
            panel = Panel();
            panel.PeerNode = node;
            this.PanelMap(char(panel.Tag)) = panel;
            this.PanelOrder(this.PanelOrder==char(panel.Tag)) = [];
            this.PanelOrder(end+1) = char(panel.Tag);
        end
        
        function panel = getPanelFromMap(this, tagOrTitle)
            if this.PanelMap.isKey(char(tagOrTitle))
                % Get by Tag
                panel = this.PanelMap(char(tagOrTitle));
            else
                % Look for by title
                panel = this.getPanelByTitle(tagOrTitle);
            end
        end    
        
        function panel = getPanelByTitle(this, title)
            panel = matlab.ui.container.internal.AppContainer.getChildFromMapByTitle(this.PanelMap, title);
        end
        
        function documentGroup = getDocumentGroupByTitle(this, title)
            documentGroup = matlab.ui.container.internal.AppContainer.getChildFromMapByTitle(this.DocumentGroupMap, title);
        end

        function documentGroup = addDocumentGroupFromPeerNode(this, node)
            import matlab.ui.container.internal.appcontainer.*;
            documentGroup = DocumentGroup();
            documentGroup.PeerNode = node;
            this.DocumentGroupMap(char(documentGroup.Tag)) = documentGroup;
        end
        
        function document = addDocumentFromPeerNode(this, node, key)
            import matlab.ui.container.internal.appcontainer.*;
            document = Document();
            document.PeerNode = node;
            % handle the case where Opened Property is changed prorammatically
            addlistener(document, 'Opened', 'PostSet', @(src, event) handleDocumentOpenedPropertyChange(this, src, event, true));
            % handle the case where document is closed interactively
            addlistener(document, 'PropertyChanged', @(event, data) handleDocumentPeerNodePropertyChange(this, data, false));
            this.addToDocumentMap(char(key), document);
        end
        
        function document = getDocumentByTitle(this, documentGroupTag, title)
            document = [];
            documents = this.getAllFromDocumentMap();
            for i=1:length(documents)
                if documents{i}.DocumentGroupTag == documentGroupTag && documents{i}.Title == title
                    document = documents{i};
                    break;
                end
            end
        end
        
        function node = getPanelNodeAddedByClient(this, panelTagOrTitle)
            if this.ClientDriven
                [node, ~] = this.getPanelNode(panelTagOrTitle, this.ModelRoot);
            else
                node = [];
            end
        end
        
        function [node, index] = getPanelNode(~, panelTagOrTitle, peerRoot)
            node = [];
            index = -1;
            if isempty(peerRoot)
                return;
            end
            if ismethod(peerRoot, 'getChildren')
                children = peerRoot.getChildren();
            else
                children = peerRoot.Children;
            end
            for index = 1:length(children)
                if strcmp(children(index).Type, 'panel') && ...
                   (strcmp(children(index).getProperty('panelId'), panelTagOrTitle) || ...
                    strcmp(children(index).getProperty('title'), panelTagOrTitle))
                   node = children(index);
                   break;
                end       
            end
        end

        function [node, index] = getDocumentGroupNode(this, typeTagOrTitle, peerRoot)
            node = [];
            index = -1;
            if isempty(peerRoot)
                return;
            end
            if ismethod(peerRoot, 'getChildren')
                children = peerRoot.getChildren();
            else
                children = peerRoot.Children;
            end
            for index = 1:length(children)
                if strcmp(children(index).Type, 'documentType') && ...
                   (strcmp(children(index).getProperty('typeId'), typeTagOrTitle) || ...
                    strcmp(children(index).getProperty('title'), typeTagOrTitle))
                   node = children(index);
                   break;
                end
            end
        end

        function node = getDocumentGroupNodeAddedByClient(this, typeTagOrTitle)
            node = [];
            if ~this.ClientDriven
                return;
            end

            [node, ~] = this.getDocumentGroupNode(typeTagOrTitle, this.ModelRoot);
        end
        
        function node = getDocumentNodeAddedByClient(this, typeTag, documentTagOrTitle)
            if this.ClientDriven
                [node, ~] = matlab.ui.container.internal.AppContainer.getDocumentNode(typeTag, documentTagOrTitle, this.ModelRoot);
            else
                node = [];
            end
        end
        
        function node = getTabGroupNode(this, tag)
            orphanRoot = this.ToolstripModelManager.getByType('OrphanRoot');
            node = [];

            if this.UseMF0ForTS
                if isvalid(orphanRoot)
                    children = orphanRoot.getChildren();
                    for i = 1:length(children)
                        if strcmp(children(i).getType, 'TabGroup') && ...
                           strcmp(children(i).getProperty('tag'), tag)
                           node = children(i);
                           break;
                        end
                    end
                end
            else
                if orphanRoot.size > 0
                    children = orphanRoot.get(0).Children;
                    for i = 0:children.size-1
                        if strcmp(children.get(i).getType, 'TabGroup') && ...
                           strcmp(children.get(i).getProperty('tag'), tag)
                           node = children.get(i);
                           break;
                        end
                    end
                end
            end
        end

        function docMap = getDocumentMap(this, varargin)
            this.refreshDocumentMap(varargin{:});
            docMap = this.DocumentMap;
        end

        function bool = isInDocumentMap(this, key, varargin)
            docMap = this.getDocumentMap(varargin{:});
            bool = docMap.isKey(key);
        end

        function value = getFromDocumentMap(this, key, varargin)
            docMap = this.getDocumentMap(varargin{:});
            value = docMap(key);
        end

        function values = getAllFromDocumentMap(this, varargin)
            docMap = this.getDocumentMap(varargin{:});
            this.waitForPendingAsyncOperations();
            values = docMap.values();
        end

        function keys = getDocumentMapKeys(this, varargin)
            docMap = this.getDocumentMap(varargin{:});
            keys = docMap.keys();
        end

        function addToDocumentMap(this, key, value, varargin)
            this.DocumentMap(key) = value;
        end

        function removeFromDocumentMap(this, key, varargin)
            docMap = this.getDocumentMap(varargin{:});
            if isKey(docMap, key)
                docMap.remove(key);
            end
        end

        function addDocumentInMotion(this, uuid, hDoc, pendingMotion)
            import matlab.ui.container.internal.appcontainer.*;
            
            % synchronicity logic only in effect for docked, visble documents in RootApp
            % exclude undocked documents from synchronicity logic for now (g2837589)
            if this.State ~= AppState.RUNNING || ~hDoc.Visible || hDoc.Phantom || ~hDoc.Docked || ...
                ~this.getDocumentGroup(hDoc.DocumentGroupTag).Docked || (~isa(this, 'matlab.ui.container.internal.RootApp') && ~this.Visible)
                return;
            end

            % create documentsInMotion map if not already created
            if ~isvalid(this.DocumentsInMotion)
                this.DocumentsInMotion = containers.Map;
            end
            % check that document is not already in map.
            % if it is, see if it is holding a different pending motion that needs to be updated (such as may be the case when rapidly opening and closing)
            if ~isKey(this.DocumentsInMotion, uuid) || ~strcmp(this.DocumentsInMotion(uuid),pendingMotion)
                this.DocumentsInMotion(uuid) = pendingMotion;
            end
        end

        function removeDocumentInMotion(this, uuid, completeMotion)
            import matlab.ui.container.internal.appcontainer.*;
            if this.State ~= AppState.RUNNING || (~isa(this, 'matlab.ui.container.internal.RootApp') && ~this.Visible)
                return
            end

            if ~isvalid(this.DocumentsInMotion)
                return;
            end

            % check for mismatch between completeMotion and the one stored in map - do not delete until the expected pendingMotion is confirmed complete
            if isKey(this.DocumentsInMotion, uuid) && strcmp(this.DocumentsInMotion(uuid), completeMotion)
                remove(this.DocumentsInMotion, uuid);
                if this.DocumentsInMotion.Count == 0
                    delete(this.DocumentsInMotion);
                end
            end
        end

        function clearDocumentsInMotion(this)
            if isvalid(this.DocumentsInMotion)
                delete(this.DocumentsInMotion);
            end
        end

        function value = isDocumentInMotion(this, uuid)
            if isvalid(this.DocumentsInMotion) && isKey(this.DocumentsInMotion, uuid)
                value = true;
            else
                value = false;
            end
        end

        function value = getMotionOfDocument(this, uuid)
            if isvalid(this.DocumentsInMotion) && isKey(this.DocumentsInMotion, uuid)
                value = this.DocumentsInMotion(uuid);
            else
                value = '';
            end
        end
        
        function refreshDocumentMap(this, doNotClear)
            if (nargin < 2 || ~doNotClear) && this.ViewInitialized && (this.PrivateState == matlab.ui.container.internal.appcontainer.AppState.RUNNING)
                % Clear client documents from the local map
                keysToRemove = [];
                allKeys = this.DocumentMap.keys();
                for i = 1:numel(allKeys)
                    key = allKeys{i};
                    if isvalid(this.DocumentMap(key)) && strcmp(this.DocumentMap(key).ChildType, "")
                        keysToRemove{end+1} = key;
                    elseif isvalid(this.DocumentMap(key)) && key ~= strcat(this.DocumentMap(key).DocumentGroupTag, this.DocumentMap(key).Tag) && ...
                        key ~= strcat(this.DocumentMap(key).DocumentGroupTag, this.DocumentMap(key).Title)

                        % key has gone out of sync with childId, likely due
                        % to a rename event. Delete the old key, as the new
                        % up-to-date one will be added when we query the client
                        keysToRemove{end+1} = key;
                    end
                end

                for i = 1:length(keysToRemove)
                    this.DocumentMap.remove(keysToRemove{i});
                end
            end
            
            % Add Documents added by Client
            if this.ClientDriven
                % Find all documents in the model (if any) and add to map.
                children = this.ModelRoot.getChildren();
                for index = 1:length(children)
                    if strcmp(children(index).Type, 'document')
                        node = children(index);
                        docType = string(node.getProperty('documentType'));
                        docId = string(node.getProperty('documentId'));
                        if isempty(docId)
                            node.setProperty('documentId', char(matlab.lang.internal.uuid));
                            docId = string(node.getProperty('documentId'));
                        end
                        key  = char(docType + docId);
                        % g2786154: documents which are invisible at creation do not initialize the isOpen property to a boolean value
                        if ~this.DocumentMap.isKey(key) && node.hasProperty('isOpen') && node.getProperty('isOpen')
                            this.addDocumentFromPeerNode(node, key);
                        end
                    end
                end
            end
        end
        
        function invisibleDocuments = getInvisibleDocuments(this, varargin)
            % getInvisibleDocuments Returns a cell array containing all the invisible documents in the AppContainer or a DocumentGroup
            %    getInvisibleDocuments() returns all invisible documents in the AppContainer
            %    getInvisibleDocuments(documentGroupTag) returns all invisible documents belonging to the DocumentGroup having the given tag

            if nargin > 1
                groupTag = string(varargin{1});
            else
                groupTag = "";
            end

            invisibleDocuments = this.getDocumentsWithFilter('GroupTag', groupTag, 'Property', 'Visible', 'Negation', true);
        end

        function documents = getDocumentsWithFilter(this, options)
            arguments
                this
                options.GroupTag (1,1) string = ""
                options.Property (1,1) string = ""
                options.Negation (1,1) logical = false
            end

            allDocuments = this.getAllFromDocumentMap();

            documents = {};
            for index = 1 : length(allDocuments)
                document = allDocuments{index};
                if isvalid(document) && (options.GroupTag == "" || document.DocumentGroupTag == options.GroupTag)
                    if (options.Property ~= "" && ...
                       (options.Negation && get(document, options.Property)) || ...
                       (~options.Negation && ~get(document, options.Property)))
                        continue;
                    end
                    documents{end + 1} = document; %#ok<AGROW>
                end
            end
        end

        function handleActiveContextsSet(this)
            this.ActiveContextsSetFinished = true;
        end

        function handleToolstripChangesFlush(this)
            this.ToolstripChangesFlushed = true;
        end

        function waitForPendingAsyncOperations(this)
            import matlab.ui.container.internal.appcontainer.*;
            if ~this.SynchronousMode || ~isvalid(this.DocumentsInMotion) || this.DocumentsInMotion.Count == 0 || ...
                this.State ~= AppState.RUNNING || (~isa(this, 'matlab.ui.container.internal.RootApp') && ~this.Visible)
                return;
            end
            matlab.ui.container.internal.utils.waitForPendingAsyncOperations(this.DocumentsInMotion);
        end
    end
        
    methods (Access = private, Static = true)
        function throwWarning(id, msg)
            backtraceStruct = warning('query', 'backtrace');
            warning('off', 'backtrace');
            warning(id, msg);
            warning(backtraceStruct.state, 'backtrace');
        end
        
        function [node, index] = getDocumentNode(typeTag, documentTagOrTitle, peerRoot)
            node = [];
            index = -1;
            if isempty(peerRoot)
                return;
            end
            if ismethod(peerRoot, 'getChildren')
                children = peerRoot.getChildren();
            else
                children = peerRoot.Children;
            end
            for index = 1:length(children)
                if strcmp(children(index).Type, 'document') && ...
                   strcmp(children(index).getProperty('documentType'), typeTag) && ...
                   (strcmp(children(index).getProperty('documentId'), documentTagOrTitle) || ...
                    strcmp(children(index).getProperty('title'), documentTagOrTitle))
                   node = children(index);
                   break;
                end       
            end
        end
        
        function child = getChildFromMapByTitle(map, title)
            child = [];
            children = map.values();
            for i=1:length(children)
                if children{i}.Title == title
                    child = children{i};
                    break;
                end
            end
        end
        
        function windowBounds = convertOrigin(windowBounds)
            screenSize = get(0, 'ScreenSize');
            windowBounds(2) = screenSize(4) - windowBounds(2) - windowBounds(4);
        end
    end
end
