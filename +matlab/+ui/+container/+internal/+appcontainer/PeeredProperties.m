classdef (Abstract) PeeredProperties < matlab.mixin.SetGet
    % This is a base class for classes that store dependent properties in a peer model
    % Its features include:
    %     Ability to temporarily store properties in an internal prior to peer node creation
    %     Mapping between class property names and peer model property names
    %     Conversion of struct property values to JSON and vice-versa
    %     Restricting specified properties to be immutable once the peer node has been created
    
    % Copyright 2021 The MathWorks, Inc.
        
    properties (SetAccess = private, GetAccess = protected)
        MCOSToJSNameMap;
        JSToMCOSNameMap;
        DefaultValueMap;
        RestrictedNameStruct;
        PeerPropertyListener;
    end
    
    properties (SetAccess = public, GetAccess = protected)
        PeerNode;
    end
    
    properties (SetAccess = protected, GetAccess = public)
        InternalProperties; % Stores properties before the peer node has been constructed
    end
        
    properties (GetAccess = protected, Constant)
        JSON_PREFIX = "**JSON**";
    end

    properties (Hidden = true)
        % For Symmetry
        UseMF0ForTS (1,1) logical = true;
    end

    events
        % Fired whenever a property value changes
        PropertyChanged;
    end
    
    methods
        % Constructor
        function this = PeeredProperties(mcosToJSNameMap, jsToMCOSNameMap, defaultValueMap, restrictedNamesStruct, varargin)
            this.MCOSToJSNameMap = mcosToJSNameMap;
            this.JSToMCOSNameMap = jsToMCOSNameMap;
            this.DefaultValueMap = defaultValueMap;
            this.RestrictedNameStruct = restrictedNamesStruct;
            if ~isempty(varargin{1})
                this.set(varargin{1}{:});
            end
        end
        
        function set.PeerNode(this, node)
            this.PeerNode = node;
            this.addPeerPropertyListener(node);
            this.handlePeerNode();
            % Discard the internal properties since they have been transferred to the peer node.
            this.InternalProperties = [];  %#ok<MCSUP>
        end
    end
    
    methods (Access = protected)
        function addPeerPropertyListener(this, node)
            this.PeerPropertyListener = matlab.ui.container.internal.appcontainer.PeeredProperties.addEventListener(node, 'propertySet', @(event, data) handlePeerPropertySet(this, data));
        end

        function handlePeerNode(this) %#ok<MANU>
            % Can be overridden by subclasses to respond when peer node is set
        end
        
        function setPeerProperty(this, name, value)
            if isvalid(this) && ~isempty(this.PeerNode) && isvalid(this.PeerNode)
                % If value is struct or multi-dimensional numeric array then convert to JSON
                if isstruct(value) || (isnumeric(value) && sum(size(value) > 1) > 1)
                    value = matlab.ui.container.internal.appcontainer.PeeredProperties.JSON_PREFIX + jsonencode(value);
                end
                if isstring(value) && isequal(numel(value), 1)
                    value = char(value);
                end
                this.PeerNode.setProperty(this.MCOSToJSNameMap(name), value);
                if isvalid(this) && ~isempty(this.PeerNode) && isvalid(this.PeerNode)
                    % If the PeerNode is still valid after the previous set call, then
                    % dispatch an event to flush the property change queue, lest property changes be
                    % delivered out of order.
                    message.type = 'flush_properties';
                    this.dispatchEvent(this.PeerNode, message);
                end
            end
        end
        
        function value = getPeerProperty(this, name, varargin)
            value = this.PeerNode.getProperty(this.MCOSToJSNameMap(name));
            if isempty(value)
                value = this.DefaultValueMap(name);
            elseif isa(value, 'java.lang.Double[]')
                % The peer model should probably handle this
                value = double(value)';
            elseif (isstring(value) || ischar(value)) && startsWith(value, matlab.ui.container.internal.appcontainer.PeeredProperties.JSON_PREFIX)
                % value is JSON prefixed string or char array, convert to struct unless caller indicated otherwise
                value = extractAfter(value, matlab.ui.container.internal.appcontainer.PeeredProperties.JSON_PREFIX);
                if nargin < 3 || varargin{1}
                    value = jsondecode(char(value));
                end
            elseif isa(value, 'java.util.HashMap')
                % On occasion data is stored and set in Peer layer as a
                % HashMap, so we convert to Struct for downstream users.
                % Note: For now it only happens in MO when RootApp is attached to MO, a set of documents
                % is reloaded from session data service and the 'LastSelectedDocument' property is queried
                % before any changes are made to the property by, for example, someone selecting a document.
                value = matlab.ui.internal.toolstrip.base.Utility.convertFromHashmapToStructure(value);
            end
            if ischar(value)
                value = string(value);
            end
        end
        
        function handlePeerPropertySet(this, data)
            if ~isvalid(this)
                return;
            end
            % Translate property name and pass to listeners
            if isfield(data, 'data') || isprop(data, 'data')
                jsPropertyName = data.data.key;
            elseif isfield(data, 'Data') || isprop(data, 'Data')
                jsPropertyName = data.Data.key;
            else
                jsPropertyName = data.EventData.key;
            end

            metadata = struct;
            if isfield(data, 'originator') && ~isempty(data.originator)
                originator_struct = jsondecode(data.originator);
                if isfield(originator_struct, 'metadata')
                    metadata = originator_struct.metadata;
                end
            end

            if this.JSToMCOSNameMap.isKey(jsPropertyName)
                notify(this, 'PropertyChanged', matlab.ui.container.internal.appcontainer.PropertyChangedEventData( ...
                    this.JSToMCOSNameMap(jsPropertyName), metadata));
            end
        end
        
        function value = getInternalProperty(this, name)
            value = this.InternalProperties.(this.MCOSToJSNameMap(name));
        end
        
        function setInternalProperty(this, name, value)
            this.InternalProperties.(this.MCOSToJSNameMap(name)) = value;
        end
        
        function result = hasInternalProperty(this, name)
            result = isfield(this.InternalProperties, this.MCOSToJSNameMap(name));
        end
        
        function value = getProperty(this, name, varargin)
            if ~isvalid(this)
                if ~isempty(varargin)
                    value = varargin{1};
                else
                    value = [];
                end
            elseif ~isempty(this.PeerNode) && isvalid(this.PeerNode)
                value = this.getPeerProperty(name);
            elseif this.hasInternalProperty(name)
                value = this.getInternalProperty(name);
            elseif ~isempty(varargin)
                value = varargin{1};
            else
                value = this.DefaultValueMap(name);
            end
        end
        
        function setProperty(this, name, value)
            if ~isvalid(this)
                return;
            elseif ~isempty(this.PeerNode) && isvalid(this.PeerNode)
                if isfield(this.RestrictedNameStruct, name)
                    error("Can't set " + name + " after child has been added to App");
                end
                this.setPeerProperty(name, value);
            else
                this.setInternalProperty(name, value);
            end
        end
        
        function returnProperties = getInternalPropertiesForPeer(this)
            % Returns the internal properties after encouding any structs to strings
            returnProperties = struct;
            if ~isempty(this.InternalProperties)
                propertyNames = fieldnames(this.InternalProperties);
                for i=1:length(propertyNames)
                    propertyName = propertyNames{i};
                    propertyValue = this.InternalProperties.(propertyName);
                    if isstruct(propertyValue) || (isnumeric(propertyValue) && sum(size(propertyValue) > 1) > 1)
                        returnProperties.(propertyName) = matlab.ui.container.internal.appcontainer.PeeredProperties.JSON_PREFIX + jsonencode(propertyValue);
                    else
                        returnProperties.(propertyName) = propertyValue;
                    end
                end
            else
                % Peer model node addChild is unhappy if given an empty properties struct,
                % so put something in it.
                returnProperties.ignore = 'ignore';
            end
        end

        % Dispatch peer event from server to client
        function dispatchEvent(~, node, structure)
            if ~isempty(node) && isvalid(node)
                if matlab.ui.container.internal.appcontainer.PeeredProperties.isMVMNode(node)
                    node.dispatchEvent('peerEvent',[],node,structure);
                elseif matlab.ui.container.internal.appcontainer.PeeredProperties.isCPPVMNode(node)
                    node.dispatchEvent('peerEvent',structure);
                else
                    node.dispatchEvent(structure);
                end
            end
        end
    end
    
    methods (Access = protected, Static=true)
        function s = createRestrictedNameStruct(restrictedNames)
            s = struct();
            for name = restrictedNames
                s.(name{1}) = true;
            end
        end
        
        function listener = addEventListener(node, eventname, callback)
            listener = [];
            if ~isempty(node) && isvalid(node)
                if matlab.ui.container.internal.appcontainer.PeeredProperties.isVMNode(node)
                    listener = node.addEventListener(eventname, callback);
                else
                    listener = addlistener(node, eventname, callback);
                end
            end
        end
        
        function vmNode = isVMNode(node)
            if matlab.ui.container.internal.appcontainer.PeeredProperties.isMVMNode(node) ||...
              matlab.ui.container.internal.appcontainer.PeeredProperties.isCPPVMNode(node)
                vmNode = true;
            else
                vmNode = false;
            end
        end
        
        function vmNode = isMVMNode(node)
            if isa(node, 'viewmodel.internal.impl.mf0.MF0ViewModel') ||...
              isa(node, 'viewmodel.internal.impl.mf0.MF0ViewModelManager')
                vmNode = true;
            else
                vmNode = false;
            end
        end
        
        function vmNode = isCPPVMNode(node)
            if isa(node, 'viewmodel.internal.ViewModelManager') ||...
              isa(node, 'viewmodel.internal.ViewModel')
                vmNode = true;
            else
                vmNode = false;
            end
        end
    end
end
