classdef RootApp < matlab.ui.container.internal.AppContainer ...
    & matlab.ui.container.internal.root.AbstractStatusBarMixin
    %RootApp A singleton providing access to the core MATLAB UI
    %   Currently RootApp is only valid for MATLAB Online but when the Java Desktop is
    %   replaced by a JavaSrcript implementation it will be possible to access the desktop
    %   UI via RootApp.

    % Copyright 2018-2021 The MathWorks, Inc.

    properties (Access = protected, Constant = true)
        ClassName = 'matlab.ui.container.internal.RootApp';
        ClassAnchor = '<a href="matlab:doc matlab.ui.container.internal.RootApp">RootApp</a>';
    end

    methods (Static)
        function instance = getInstance()
            if feature('webui') && ~desktop('-inuse')
                % g2841958 - Throw a warning when desktop is not available.
                warning(message('MATLAB:desktop:desktopNotFoundCommandFailure'));
            end
            matlab.ui.container.internal.RootApp.handleTerminatedSingleton();
            instance = matlab.ui.container.internal.RootApp.setGetInstance();
            if isempty(instance) || ~isvalid(instance)
                instance = matlab.ui.container.internal.RootApp.setGetInstance(matlab.ui.container.internal.RootApp());
            end
        end
    end
    
    methods (Access = private, Static)
        % Facilitates persistence of a single RootApp instance
        function result = setGetInstance(value)
            mlock;
            persistent instance;
            if nargin
                if isempty(value)
                    delete(instance);
                end
                instance = value;
            end
            result = instance;
        end
        
        function handleTerminatedSingleton()
            % Clears instance when App terminated
            import matlab.ui.container.internal.appcontainer.*;
            instance = matlab.ui.container.internal.RootApp.setGetInstance();
            if ~isempty(instance) && (~isvalid(instance) || (instance.State == AppState.TERMINATED))
                if mislocked('matlab.ui.container.internal.RootApp.setGetInstance')
                    munlock('matlab.ui.container.internal.RootApp.setGetInstance');
                end
                matlab.ui.container.internal.RootApp.setGetInstance([]);
            end
        end
        
        function handleSingletonStateChange()
            matlab.ui.container.internal.RootApp.handleTerminatedSingleton();
        end
    end
    
    methods (Access = private)
        function this = RootApp()
            % Private constructor allows enforcement of singleton pattern
            appOptions.Tag = "motw";
            this@matlab.ui.container.internal.AppContainer(appOptions);
            this.addEventListener(this, 'StateChanged', @(~, ~) matlab.ui.container.internal.RootApp.handleSingletonStateChange());
            this.SynchronousMode = true;
            this.attach();
        end

        function app = findAssociatedAppForDocument(this, document)
            mainContainerMap = containers.Map(this.Tag, this);
            allContainerMap = [mainContainerMap; this.ChildContainers];
            for key = keys(allContainerMap)
                childApp = allContainerMap(key{1});
                if childApp.hasDocument(document.DocumentGroupTag, document.Tag)
                    app = childApp;
                    return;
                end
            end
            app = [];
        end
    end
    
    methods
        function panel = getCurrentFolderPanel(this)
            panel = this.getPanel("cfb");
        end
        
        function panel = getWorkspacePanel(this)
            panel = this.getPanel("workspace");
        end
        
        function panel = getCommandPanel(this)
            panel = this.getPanel("commandWindow");
        end
        
        function group = getEditorGroup(this)
            group = this.getDocumentGroup("editorFile");
        end

        function group = getFigureGroup(this)
            group = this.getDocumentGroup("figure");
        end
        
        function group = getVariableGroup(this)
            group = this.getDocumentGroup("variable");
        end

        function bringDocumentToFront(this, document)
            % Selects the document and brings the window containing the
            % document to front.
            document.Selected = true;
            app = this.findAssociatedAppForDocument(document);
            if ~isempty(app)
                data.type = 'bringDocumentToFront';
                data.id = document.Tag;
                message.publish(app.MessageChannel, data);
            end
        end
    end

    methods (Static = true, Access = private)
        function sendStatusMessage(type, value)
            import matlab.ui.container.internal.root.AbstractStatusBarMixin

            narginchk(1, 2);
            data.type = type;
            if nargin > 1
                data.value = value;
            end
            message.publish(AbstractStatusBarMixin.StatusBarChannel, data);
        end
    end

    % ===== matlab.ui.container.internal.root.AbstractStatusBarMixin Concrete Implementations =====
    methods (Access = protected)
        function setStatusComponent(this, statusComponent)
            if isa(statusComponent, 'matlab.ui.internal.statusbar.StatusLabel')
                this.sendStatusMessage('setStatus', statusComponent.Text);
            end
        end

        function clearStatusComponent(this, ~)
            this.sendStatusMessage('clearStatus');
        end
    end

    % ===== AppContainer Overrides =====
    methods
        function add(this, child)
            % ADD Adds a child to the container
            %    The child may be a Panel, DocumentGroup, Document, TabGroup or QABControl
            %
            %    When adding a document the document group with which it is associated must have previously
            %    been added to the AppContainer.
            if isa(child, this.StatusBarType) || isa(child, this.StatusComponentType)
                throw(MException(message('MATLAB:class:InvalidArgument', 'add', strcat(this.ClassName, '.add'))));
            else
                add@matlab.ui.container.internal.AppContainer(this, child);
            end
        end

        function child = get(this, childType, varargin)
            % GET Returns the object representing the specified child
            %    get(PANEL, tagOrTitle) returns the Panel having the specified Tag or Title property
            %    get(DOCUMENT_GROUP, tagOrTitle) returns the DocumentGroup having the specified Tag or Title property
            %    get(DOCUMENT, documentGroupTag, tagOrTitle) returns the Document having the specified DocumentGroupTag property
            %                                                and either the specified Tag or Title property
            %    get(TOOLSTRIP_TAB_GROUP, tagOrTitle) returns the TabGroup having the specified Tag or Title property
            if isa(childType, this.StatusBarType) || isa(childType, this.StatusComponentType)
                throw(MException(message('MATLAB:class:InvalidArgument', 'get', strcat(this.ClassName, '.get'))));
            else
                child = get@matlab.ui.container.internal.AppContainer(this, childType, varargin);
            end
        end

        function result = has(this, childType, varargin)
            % HAS Returns a logical value indicating whether the container has the specified child
            %    has(PANEL, tagOrTitle) returns true if the container has a panel with the specified Tag or Title property
            %    has(DOCUMENT_GROUP, tagOrTitle) returns true if the container has a document type with the specified Tag or Title property
            %    has(DOCUMENT, documentGroupTag, tagOrTitle) returns true if the container has a document with the specified
            %                                             DocumentGroupTag property and either the specified Tag or Title property
            %    has(TOOLSTRIP_TAB_GROUP, tagOrTitle) returns true if the container has a tab group with the specified Tag or Title property
            if isa(childType, this.StatusBarType) || isa(childType, this.StatusComponentType)
                throw(MException(message('MATLAB:class:InvalidArgument', 'has', strcat(this.ClassName, '.has'))));
            else
                result = has@matlab.ui.container.internal.AppContainer(this, childType, varargin);
            end
        end

        function bringToFront(this)
            % Bring the main desktop window to front. Note that this will only work if the desktop is open within a CEF window.
            data.type = 'bringToFront';
            message.publish(this.MessageChannel, data);
        end
    end

    % ===== AppContainer Overrides =====
    methods (Hidden = true)
        function statusbar = getStatusBar(varargin)
            statusbar = [];
        end

        function statusComponent = getStatusComponent(varargin)
            statusComponent = []';
        end
        
        function result = hasStatusBar(varargin)
            result = false;
        end

        function result = hasStatusComponent(varargin)
            result = false;
        end

        % TODO: Find out how to make these methods private instead of throwing an error

        function addStatusBar(this, ~)
            throw(MException(message('MATLAB:class:MethodRestricted', 'addStatusBar', this.ClassAnchor)));
        end
        
        function addStatusComponent(this, ~)
            throw(MException(message('MATLAB:class:MethodRestricted', 'addStatusComponent', this.ClassAnchor)));
        end

        function removeStatusComponent(this, ~)
            throw(MException(message('MATLAB:class:MethodRestricted', 'removeStatusComponent', this.ClassAnchor)));
        end
    end
    
    % ===== AppContainer Overrides =====
    methods (Access = protected)
        function value = get_StatusBarSpansFullWidth(varargin)
            value = false;
        end

        % TODO: Find out how to make this method private instead of throwing an error
        function set_StatusBarSpansFullWidth(this, ~)
            throw(MException(message('MATLAB:class:MethodRestricted', 'set.StatusBarSpansFullWidth', this.ClassAnchor)));
        end

        function uiBuilderChannel = getUIBuilderChannel(this)
            if ~isempty(this.ToolstripChannel)
                uiBuilderChannel = this.ToolstripChannel;
            else
                uiBuilderChannel = '/DefaultUIBuilderPeerModelChannel';
            end
        end

        function handleStartedMessage(this)
            reply.type = 'attach';
            reply.modelChannel = this.ModelChannel;
            message.publish(this.MessageChannel, reply);
        end
    end
end