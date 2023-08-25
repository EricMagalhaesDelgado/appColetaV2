classdef DocumentGroup < matlab.ui.container.internal.appcontainer.AppChild
    %DocumentGroup Represents an AppContainer document group
    %   Provides the ability to set and get document group properties as well as listen for changes to the same.

    % Copyright 2017-2018 The MathWorks, Inc.

    properties (Dependent)
        % Used to refer to the collection of documents comprising a group.
        % For example, "Editor Files" (whereas the corresponding Title might
        % be simply "Editor").  If a CollectiveLabel is not specified the Title
        % will appear wherever it would have been displayed.
        CollectiveLabel (1,1) string;
        
        % If true documents belonging to the group will always appear in a sub-container
        % This property cannot be changed after the document group has been registered with a container.
        ConstrainToSubContainer (1, 1) logical;
        
        % Specifies where documents belonging to the group should appear relative to documents belonging to other groups
        % The default placement may be overridden by user actions
        % This property cannot be changed after the document group has been registered with a container.
        DefaultRegion (1,1) string {mustBeMember(DefaultRegion, {'left', 'right', 'bottom', 'top'})};

        % Reflects/controls whether the group of documens is docked
        Docked (1,1) logical;

        % Module path to a JavaScript UIComponentFactory used to construct documents within the group from saved state
        % This property cannot be changed after the document group has been registered with a container.

        % For loading a JavaScript UIComponentFactory that is Webpack built, you can either:
        % 1) Configure the JS dependencies through the Extension mechanism and provide the relative path to the factory
        % through this property. See: https://confluence.mathworks.com/pages/viewpage.action?pageId=458273993 for an example.
        % Or,
        % 2) Provide a struct with its "Modules" field set to a ModuleInfo object. See example below:

        % moduleInfo1 = matlab.ui.container.internal.appcontainer.ModuleInfo;
        % moduleInfo1.Path = "/path/to/module/relative/to/matlabroot/";
        % moduleInfo1.Exports = ["TestDocumentFactory"];
        % moduleInfo1.Name = "module_name";
        % documentFactory.Modules(1) = moduleInfo1;

        % Note: The factory can have dependencies that also need to be dynamically loaded. The first module
        % in the module info is treated as the document factory and all additional modules are treated as dependencies.

        % moduleInfo2.Path = "/path/to/another/module";
        % moduleInfo2.Exports = ["AnotherExport"];
        % moduleInfo1.Name = "module_name2";
        % documentFactory.Modules(2) = moduleInfo2;

        % DocumentFactory = documentFactory
        DocumentFactory;

        % For a DocumentGroup the inherited Maximized property is only meaningful when these documents have been sub-tiled. 
        
        % If true when the last document in a sub-container is closed the empty sub-container will remain.
        % By default empty sub-containers will be removed.  This property is only honored
        % when the ConstrainToSubContainer property is true.
        % This property cannot be changed after the document group has been registered with a container.
        RetainEmptySubContainer (1,1) logical;
        
        % Specifies whether a popup header should appear when the mouse hovers near the
        % top of a set of tabs belonging to the group.  When shown the header will offer
        % a drop down with options for managing the documents in the group.
        % If this property is not set the header will be shown.
        ShowGroupHeader (1,1) logical;

        % If true tabs associated with documents in the group can be shrunk below the size required to display the full document title
        % The benefit of such shrinking is that it can forestall the need to scroll tabs
        % This property cannot be changed after the document group has been registered with a container.
        ShrinkTabsToFit (1,1) logical;
        
        % Reflects/controls sub-tiling of group of documents
        SubGridDimensions (1,2) double {mustBeInteger};
                
        % Reflects/controls the placement of the group of documents within the document grid
        Tile (1,1) double {mustBeInteger};
        
        % If true documents in the group are expected to reopen in the next session 
        % This property cannot be changed after the document group has been registered with a container.
        WillReopen (1,1) logical;

        % Controls the visiblity of 'Undock <Type>' option in DocumentContainer's actions menu. Defaults to false.
        % Setting this property to false does not prevent programmatic docking.
        EnableDockControls (1,1) logical;

        % Controls if the 'Undock <Document>' option in the DocumentContainer's action menu is disabled for interaction. Defaults to false.
        % This property does not affect the visibility/ability to dock a document. Look at 'enableDockControls' for that.
        DisableDockControls (1,1) logical;

        % Controls if the tab bar should show when there is only 1 document in the undocked window
        ShowSingleDocumentTab (1,1) logical;
    end
    
    properties (Dependent, SetAccess=immutable)
        % Reports the number of open documents in the group
        DocumentCount;
        
        % Reports the most recently selected document in the group
        % This property will be a structure with "title" and "tag" fields.
        LastSelected;
    end

    properties
        % Defines the context associated with the group.
        % This context will automatically be activated when a document belonging to the group is selected.
        % Such activation will cause the elements (toolstrip tab groups, panels and status component)
        % identified in the group to be shown.
        % The Context property cannot be changed after the document group has been registered with a container.
        Context = {}; % (1,1) matlab.ui.container.internal.appcontainer.ContextDefinition = [];

        % Defines sub-contexts within documents of the group.
        % Each sub-context may have associated toolstrip tab groups, panels and status components.
        % Document sub-contexts are activated by setting the ActiveContexts property of an
        % individual document (see Document).
        % The SubContexts property cannot be changed after the document group has been add to a container
        SubContexts (1,:) = {} % matlab.ui.container.internal.appcontainer.ContextDefinition;
    end
    
    properties (GetAccess = protected, Constant)
        GroupMCOSPropertyNames = [matlab.ui.container.internal.appcontainer.AppChild.MCOSPropertyNames ...
                                 {'Tag', 'CollectiveLabel', 'ConstrainToSubContainer', 'SubContexts', 'DefaultRegion', ...
                                  'DocumentFactory', 'PanelTags', 'RetainEmptySubContainer', 'ShowGroupHeader', 'ShrinkTabsToFit', ...
                                  'StatusComponentTags', 'ToolstripTabGroupTags', 'WillReopen', 'Docked', ...
                                  'SubGridDimensions', 'Tile', 'DocumentCount', 'LastSelected', 'EnableDockControls','DisableDockControls', 'ShowSingleDocumentTab'}];
        GroupJSPropertyNames = [matlab.ui.container.internal.appcontainer.AppChild.JSPropertyNames ...
                               {'typeId', 'collectiveLabel', 'constrainToSubContainer', 'contexts', 'defaultRegion', ...
                                'factoryPath', 'panelIds', 'retainEmptySubContainer', 'showGroupHeader', 'shrinkTabsToFit', ...
                                'statusComponentTags', 'tabGroupTags', 'willReopen', 'isDocked', ...
                                'subGridSize', 'tile', 'documentCount', 'lastSelected', 'enableDockControls', 'disableDockControls', 'showSingleDocumentTab'}];
        GroupDefaultPropertyValues = [matlab.ui.container.internal.appcontainer.AppChild.DefaultPropertyValues ...
                                     {"", "", false, [], 'left', "", [], false, true, false, [], [], false, true, [], 0, 0, [], false, false, true}];
        GroupMCOSToJSNameMap = containers.Map(matlab.ui.container.internal.appcontainer.DocumentGroup.GroupMCOSPropertyNames, ...
                                              matlab.ui.container.internal.appcontainer.DocumentGroup.GroupJSPropertyNames);
        GroupJSToMCOSNameMap = containers.Map(matlab.ui.container.internal.appcontainer.DocumentGroup.GroupJSPropertyNames, ...
                                              matlab.ui.container.internal.appcontainer.DocumentGroup.GroupMCOSPropertyNames);
        GroupDefaultValueMap = containers.Map(matlab.ui.container.internal.appcontainer.DocumentGroup.GroupMCOSPropertyNames, ...
                                              matlab.ui.container.internal.appcontainer.DocumentGroup.GroupDefaultPropertyValues);
        GroupRestrictedPropertyNames = [matlab.ui.container.internal.appcontainer.AppChild.RestrictedPropertyNames ...
                                           {'ConstrainToSubContainer', 'Context', 'DefaultRegion', 'DocumentFactory', ...
                                            'RetainEmptySubContainer', 'ShrinkTabsToFit', 'SubContexts', 'WillReopen'}];
        GroupRestrictedPropertyNameStruct = matlab.ui.container.internal.appcontainer.PeeredProperties.createRestrictedNameStruct( ...
                                               matlab.ui.container.internal.appcontainer.DocumentGroup.GroupRestrictedPropertyNames);
    end
    
    methods

        function this = DocumentGroup(varargin)
            this = this@matlab.ui.container.internal.appcontainer.AppChild( ...
                matlab.ui.container.internal.appcontainer.DocumentGroup.GroupMCOSToJSNameMap, ...
                matlab.ui.container.internal.appcontainer.DocumentGroup.GroupJSToMCOSNameMap, ...
                matlab.ui.container.internal.appcontainer.DocumentGroup.GroupDefaultValueMap, ...
                matlab.ui.container.internal.appcontainer.DocumentGroup.GroupRestrictedPropertyNameStruct, ...
                varargin);
        end
        
        function value = get.ShowSingleDocumentTab(this)
            value = this.getProperty('ShowSingleDocumentTab');
        end
        
        function set.ShowSingleDocumentTab(this, value)
            this.setProperty('ShowSingleDocumentTab', value);
        end

        function value = get.CollectiveLabel(this)
            value = this.getProperty('CollectiveLabel');
        end
        
        function set.CollectiveLabel(this, value)
            this.setProperty('CollectiveLabel', value);
        end
        
        function value = get.ConstrainToSubContainer(this)
            value = this.getProperty('ConstrainToSubContainer');
        end
        
        function set.ConstrainToSubContainer(this, value)
            this.setProperty('ConstrainToSubContainer', value);
        end
        
        function set.Context(this, value)
            this.Context = value;
            if ~isempty(value.PanelTags)
                this.setProperty('PanelTags', value.PanelTags);
            end
            if ~isempty(value.StatusComponentTags)
                this.setProperty('StatusComponentTags', value.StatusComponentTags);
            end
            if ~isempty(value.ToolstripTabGroupTags)
                this.setProperty('ToolstripTabGroupTags', value.ToolstripTabGroupTags);
            end
        end
        
        function value = get.DefaultRegion(this)
            value = this.getProperty('DefaultRegion');
        end
        
        function set.DefaultRegion(this, value)
            this.setProperty('DefaultRegion', value);
        end
        
        function value = get.Docked(this)
            value = this.getProperty('Docked');
        end
        
        function set.Docked(this, value)
            this.setProperty('Docked', value);
        end
        
        function value = get.DocumentFactory(this)
            value = this.getProperty('DocumentFactory');
        end
        
        function set.DocumentFactory(this, value)
            this.setProperty('DocumentFactory', value);
        end
        
        function value = get.RetainEmptySubContainer(this)
            value = this.getProperty('RetainEmptySubContainer');
        end
        
        function set.RetainEmptySubContainer(this, value)
            this.setProperty('RetainEmptySubContainer', value);
        end

        function value = get.ShowGroupHeader(this)
            value = this.getProperty('ShowGroupHeader');
        end
        
        function set.ShowGroupHeader(this, value)
            this.setProperty('ShowGroupHeader', value);
        end
        
        function value = get.ShrinkTabsToFit(this)
            value = this.getProperty('ShrinkTabsToFit');
        end
        
        function set.ShrinkTabsToFit(this, value)
            this.setProperty('ShrinkTabsToFit', value);
        end
        
        function set.SubContexts(this, value)
            % Keep a local copy since the corresonding model entry is JSON encoded
            this.SubContexts = value;
            for i = 1:length(value)
                context = value{i};
                value{i} = context.convertToJSON();
            end
            this.setProperty('SubContexts', value);
        end
        
        function value = get.SubGridDimensions(this)
            value = this.getProperty('SubGridDimensions');
            if isstruct(value)
                value = [value.w, value.h];
            end
        end

        function set.SubGridDimensions(this, value)
            dimensions.w = value(1);
            dimensions.h = value(2);
            this.setProperty('SubGridDimensions', dimensions);
        end
        
        function value = get.Tile(this)
            value = this.getProperty('Tile');
        end
        
        function set.Tile(this, value)
            this.setProperty('Tile', value);
        end
        
        function value = get.WillReopen(this)
            value = this.getProperty('WillReopen');
        end
        
        function set.WillReopen(this, value)
            this.setProperty('WillReopen', value);
        end

        function value = get.DisableDockControls(this)
            value = this.getProperty('DisableDockControls');
        end
        
        function set.DisableDockControls(this, value)
            this.setProperty('DisableDockControls', value);
        end 

        function value = get.EnableDockControls(this)
            value = this.getProperty('EnableDockControls');
        end
        
        function set.EnableDockControls(this, value)
            this.setProperty('EnableDockControls', value);
        end

        
        function value = get.DocumentCount(this)
            value = this.getProperty('DocumentCount', 0);
        end
        
        function value = get.LastSelected(this)
            value = this.getProperty('LastSelected', []);
        end
    end
end