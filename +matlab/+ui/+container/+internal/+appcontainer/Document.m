classdef Document < matlab.ui.container.internal.appcontainer.AppChild
    %Document Represents an AppContainer document
    %   Provides the ability to set and get document properties as well as listen for changes to the same.

    % Copyright 2017-2020 The MathWorks, Inc.

    properties (Dependent)
        % Contains strings that identify the currently active contexts
        % The "contexts" drive the inclusion of associated tab groups on the toolstrip,
        % controls on the quick access toolbar and panels on the AppContainer borders
        ActiveContexts (1,:) string = {};
        
        % Reflects/controls whether the document is docked 
        Docked (1,1) logical;

        % Identifies the group to which the document belongs
        % See the DocumentGroup class definition
        % This property cannot be changed after the document has been added to a parent container.
        DocumentGroupTag (1,1) string;

        % Reflects/controls whether the document is in full-screen mode
        Fullscreen (1,1) logical;
        
        % Reflects/controls whether the document is allowed to enter full-screen mode
        FullscreenEnabled (1,1) logical;
                
        % Reflects/controls the placement of a document within the document grid 
        Tile (1,1) double {mustBeInteger};

        % Reflects/controls whether the document is visible/hidden.
        Visible (1,1) logical;

        % Controls the visiblity of 'Undock <Document>' option in DocumentContainer's actions menu. Defaults to false.
        % Setting this property to false does not prevent programmatic docking.
        EnableDockControls (1,1) logical;
        
        % Controls if the 'Dock/Undock <Document>' option in the DocumentContainer's action menu is disabled for interaction. Defaults to false.
        % This property does not affect the visibility/ability to dock a document. Look at 'enableDockControls' for that.
        DisableDockControls (1,1) logical;
    end
    
    properties (Dependent, Hidden)
        % Controls whether the document should be hidden after being added to an AppContainer
        Phantom (1,1) logical;
    end
    
    properties
        % This function will be called when the user initiates document close.
        % It should return true if document close can proceed, false otherwise.
        % The document object will be passed as the first arguement to the function.
        CanCloseFcn;
    end

    events
        LocalCloseStarted; % observed by AppContainer/RootApp to detect calls to this document's close method
    end
    
    properties (GetAccess = protected, Constant)
        DocumentMCOSPropertyNames = [matlab.ui.container.internal.appcontainer.AppChild.MCOSPropertyNames ...
                                     {'Tag', 'DocumentGroupTag', 'ActiveContexts', 'Docked', 'Fullscreen', 'FullscreenEnabled', 'Tile', 'Phantom', 'Visible', 'EnableDockControls', 'DisableDockControls'}];
        DocumentJSPropertyNames = [matlab.ui.container.internal.appcontainer.AppChild.JSPropertyNames ...
                                   {'documentId', 'documentType', 'activeContexts', 'isDocked', 'isFullscreen', 'enableFullscreen', 'tile', 'isPhantom', 'isVisible', 'enableDockControls', 'disableDockControls'}];
        DocumentDefaultPropertyValues = [matlab.ui.container.internal.appcontainer.AppChild.DefaultPropertyValues ...
                                         {"", "", [], true, false, false, 0, false, true, false, false}];
        DocumentMCOSToJSNameMap = containers.Map(matlab.ui.container.internal.appcontainer.Document.DocumentMCOSPropertyNames, ...
                                                 matlab.ui.container.internal.appcontainer.Document.DocumentJSPropertyNames);
        DocumentJSToMCOSNameMap = containers.Map(matlab.ui.container.internal.appcontainer.Document.DocumentJSPropertyNames, ...
                                                 matlab.ui.container.internal.appcontainer.Document.DocumentMCOSPropertyNames);
        DocumentDefaultValueMap = containers.Map(matlab.ui.container.internal.appcontainer.Document.DocumentMCOSPropertyNames, ...
                                                 matlab.ui.container.internal.appcontainer.Document.DocumentDefaultPropertyValues);
        DocumentRestrictedPropertyNames = [matlab.ui.container.internal.appcontainer.AppChild.RestrictedPropertyNames ...
                                           {'DocumentGroupTag'}];
        DocumentRestrictedPropertyNameStruct = matlab.ui.container.internal.appcontainer.PeeredProperties.createRestrictedNameStruct( ...
                                               matlab.ui.container.internal.appcontainer.Document.DocumentRestrictedPropertyNames);
    end
    
    methods
        function this = Document(varargin)
            % Override the default value for Closable property to true
            documentDefaultValueMap = matlab.ui.container.internal.appcontainer.Document.DocumentDefaultValueMap;
            documentDefaultValueMap('Closable') = true;

            % Document constructs an AppContainer document
            this = this@matlab.ui.container.internal.appcontainer.AppChild( ...
                matlab.ui.container.internal.appcontainer.Document.DocumentMCOSToJSNameMap, ...
                matlab.ui.container.internal.appcontainer.Document.DocumentJSToMCOSNameMap, ...
                documentDefaultValueMap, ...
                matlab.ui.container.internal.appcontainer.Document.DocumentRestrictedPropertyNameStruct, ...
                varargin);
        end
        
        function varargout = close(this, namedargs)
            % CLOSE(), CLOSE('force',false) Attempts to close the document, 
            % subject to veto by CanCloseFcn.
            %
            % CLOSE('force',true) Forcibly closes the document,  ignoring 
            % CanCloseFcn. This is equivalent to setting Document.Opened to 
            % false.
            %
            % This function returns 'true' if the document was successfully
            % closed, 'false' if veto'ed or if the document was not opened.
            arguments
                this
                namedargs.force (1,1) logical {mustBeNumericOrLogical} = false
            end
            nargoutchk(0, 1);
            
            success = false;
            if this.Opened && (namedargs.force || this.canClose())
                notify(this, 'LocalCloseStarted');
                this.Opened = false;
                success = true;
            end
            
            % Return value
            if nargout < 1
                varargout = {};
            else
                varargout = {success};
            end
        end
        
        function value = get.ActiveContexts(this)
            value = this.getProperty('ActiveContexts');
        end
        
        function set.ActiveContexts(this, value)
            this.setProperty('ActiveContexts', value);
        end
        
        function value = get.Docked(this)
            value = this.getProperty('Docked');
        end
        
        function set.Docked(this, value)
            this.setProperty('Docked', value);
        end
        
        function value = get.DocumentGroupTag(this)
            value = this.getProperty('DocumentGroupTag');
        end
        
        function set.DocumentGroupTag(this, value)
            this.setProperty('DocumentGroupTag', value);
        end
        
        function value = get.Fullscreen(this)
            value = this.getProperty('Fullscreen');
        end
        
        function set.Fullscreen(this, value)
            this.setProperty('Fullscreen', value);
        end
        
        function value = get.FullscreenEnabled(this)
            value = this.getProperty('FullscreenEnabled');
        end
        
        function set.FullscreenEnabled(this, value)
            this.setProperty('FullscreenEnabled', value);
        end
        
        function value = get.Tile(this)
            value = this.getProperty('Tile') + 1;
        end
        
        function set.Tile(this, value)
            this.setProperty('Tile', value - 1);
        end
        
        function value = get.Visible(this)
            value = this.getProperty('Visible');
        end

        function set.Visible(this, value)
            this.setProperty('Visible', value);
        end

        function value = get.EnableDockControls(this)
            value = this.getProperty('EnableDockControls');
        end
        
        function set.EnableDockControls(this, value)
            this.setProperty('EnableDockControls', value);
        end

        function value = get.DisableDockControls(this)
            value = this.getProperty('DisableDockControls');
        end
        
        function set.DisableDockControls(this, value)
            this.setProperty('DisableDockControls', value);
        end 

        function value = get.Phantom(this)
            value = ~this.Visible;
        end
        
        function set.Phantom(this, value)
            this.Visible = ~value;
        end
                
        function set.CanCloseFcn(this, value)
            if isempty(value) || internal.Callback.validate(value)
                this.CanCloseFcn = value;
                if ~isempty(this.PeerNode) && ~isempty(value)
                    this.connectCloseApproverToPeerNode();
                end
                % TODO: elseif isempty(value), remove listener
            else
                error(message('MATLAB:toolstrip:general:invalidFunctionHandle', 'CanCloseFcn'))
            end
        end
    end
    
    methods (Access = protected)
        function handlePeerNode(this)
            if ~isempty(this.CanCloseFcn)
                % Set the can close function again to wire it up to the peer node
                this.CanCloseFcn = this.CanCloseFcn;
            end
        end

        function connectCloseApproverToPeerNode(this)
            hasCloseApprover = this.PeerNode.getProperty('hasCloseApprover');
            if isempty(hasCloseApprover) || ~hasCloseApprover
                this.PeerNode.setProperty('hasCloseApprover', true);            
                % Listen for closeQuery event
                this.addEventListener(this.PeerNode, 'peerEvent', @(event, data) handlePeerEvent(this, data));
            end
        end
    end
    
    methods (Access={?matlab.ui.container.internal.AppContainer, ?matlab.ui.internal.FigureDocument})
        function result = canClose(this)
            if isempty(this.CanCloseFcn)
                result = true;
            else
                % g2360352: Handle exception thrown by CanCloseFcn callback
                % because it can fail silently in non linux platform
                try
                    result = feval(this.CanCloseFcn, this);
                catch ME
                    result = false;
                    warning('backtrace', 'off');
                    warning(['Prevented the document close since an error occurred while running the document''s CanCloseFcn function' newline getReport(ME)]);
                    warning('backtrace', 'on');
                end
            end
        end
    end
    
    methods (Access = private)
        function handlePeerEvent(this, data)
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
            
            if shouldReply
                % Reply to close query
                event.type = 'closeReply';
                event.approve = this.canClose();
                event.id = data.(dataField).id;
                this.dispatchEvent(this.PeerNode, event);
            end
        end
    end
end