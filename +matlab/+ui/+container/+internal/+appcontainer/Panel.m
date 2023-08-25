classdef Panel < matlab.ui.container.internal.appcontainer.AppChild
    %Panel Represents an AppContainer panel
    %   Provides the ability to set and get panel properties as well as listen for changes to the same.

    % Copyright 2017 The MathWorks, Inc.

    properties (Dependent)

        % Reflects/controls whether the panel is collapsed in its parent
        % accordion container. In other words, it controls whether the panel
        % should be collapsed vertically when there are multiple panels in
        % the accordion container in left/right regions. For collapsing the
        % entire set of panels on a border, refer to AppContainer's LeftCollapsed,
        % RightCollapsed and BottomCollapsed properties.
        Collapsed (1,1) logical;
        
        % If true the user will have the ability to collapse the panel
        % This affects only the ability to collapse an individual panel
        % its parent accordion container not the ability to collapse the
        % entire set of panels on a border.
        % This property cannot be changed after the panel has been added to a parent container.
        Collapsible (1,1) logical;
        
        % True if the panel is associated with a context.  Such panels are
        % only shown when the associated context is active. 
        % This property cannot be changed after the panel has been added to a parent container.
        Contextual (1,1) logical;

        % Module path to a JavaScript UIComponentFactory used to create the client-side panel widget
        % This property cannot be changed after the panel has been added to a parent container.

        % For loading a JavaScript UIComponentFactory that is Webpack built, you can either:
        % 1) Configure the JS dependencies through the Extension mechanism and provide the relative path to the factory
        % through this property. See: https://confluence.mathworks.com/pages/viewpage.action?pageId=458273993 for an example.
        % Or,
        % 2) rovide a struct with its "Modules" field set to a ModuleInfo object. See example below:

        % moduleInfo1 = matlab.ui.container.internal.appcontainer.ModuleInfo;
        % moduleInfo1.Path = "/path/to/module/relative/to/matlabroot/";
        % moduleInfo1.Exports = ["TestPanelFactory"];
        % moduleInfo1.Name = "module_name";
        % panelFactory.Modules(1) = moduleInfo1;

        % Note: The factory can have dependencies that also need to be dynamically loaded. The first module
        % in the module info is treated as the panel factory and all additional modules are treated as dependencies.

        % moduleInfo2.Path = "/path/to/another/module";
        % moduleInfo2.Exports = ["AnotherExport"];
        % moduleInfo1.Name = "module_name2";
        % panelFactory.Modules(2) = moduleInfo2;

        % Factory = panelFactory
        Factory;

        % Indicates which border regions a panel can be moved to
        % It contains strings identifying the permitted border regions.
        % If this property is not set, then movement to any border will be
        % permitted by default. 
        % This property cannot be changed after the panel has been added to a parent container.
        PermissibleRegions (1,:) string {mustBeMember(PermissibleRegions, {'left', 'right', 'bottom'})};
        
        % Specifies the height that should be allocated to the panel provided there is flexibility to do so
        %    If the value is >= 1 pixels are assumed.
        %    If the value is > 0 and < 1 it is interpreted as a fraction of the container height.
        %    If the value is <= 0 it will be ignored.
        % If this property is not set a default height will be allocated (typically 1/nth
        % of the immediate parent height, where n is the number of panels the parent has). 
        % This property cannot be changed after the panel has been added to a parent container.
        PreferredHeight (1,1) double;
        
        % Specifies the width that should be allocated to the panel provided there is flexibility to do so
        % The value is interpreted in a manner similar to that described for the preferredHeight
        % This property cannot be changed after the panel has been added to a parent container.
        PreferredWidth (1,1) double;
        
        % Specifies the border on which the panel will be placed
        Region (1,1) string {mustBeMember(Region, {'left', 'right', 'bottom'})};
        
        % If true the user will be able to adjust the height of the panel
        % The height is always adjustable for panels that appear on the bottom.
        % Hence this property only applies to panels on the left or right.
        % The width of such panels is always adjustable.
        % This property cannot be changed after the panel has been added to a parent container.
        Resizable (1,1) logical;
    end
    
    properties (GetAccess = protected, Constant)
        PanelMCOSPropertyNames = [matlab.ui.container.internal.appcontainer.AppChild.MCOSPropertyNames ...
                                  {'Tag', 'Collapsible', 'Contextual', 'Factory', 'PermissibleRegions', 'Region', ...
                                   'Resizable', 'Collapsed', 'PreferredHeight', 'PreferredWidth', 'Region'}];
        PanelJSPropertyNames = [matlab.ui.container.internal.appcontainer.AppChild.JSPropertyNames ...
                                {'panelId', 'isCollapsible', 'isContextual', 'factoryPath', 'permissibleRegions', 'region', ...
                                 'isResizable', 'isCollapsed', 'preferredHeight', 'preferredWidth', 'region'}];
        PanelDefaultPropertyValues = [matlab.ui.container.internal.appcontainer.AppChild.DefaultPropertyValues ...
                                      {"", true, false, "", [], 'left', 'true', false, 0, 0, "left"}];
        PanelMCOSToJSNameMap = containers.Map(matlab.ui.container.internal.appcontainer.Panel.PanelMCOSPropertyNames, ...
                                              matlab.ui.container.internal.appcontainer.Panel.PanelJSPropertyNames);
        PanelJSToMCOSNameMap = containers.Map(matlab.ui.container.internal.appcontainer.Panel.PanelJSPropertyNames, ...
                                              matlab.ui.container.internal.appcontainer.Panel.PanelMCOSPropertyNames);
        PanelDefaultValueMap = containers.Map(matlab.ui.container.internal.appcontainer.Panel.PanelMCOSPropertyNames, ...
                                              matlab.ui.container.internal.appcontainer.Panel.PanelDefaultPropertyValues);
        PanelRestrictedPropertyNames = [matlab.ui.container.internal.appcontainer.AppChild.RestrictedPropertyNames ...
                                        {'Collapsible', 'Contextual', 'Factory', 'PermissibleRegions', 'PreferredHeight', 'PreferredWidth', 'Resizable'}];
        PanelRestrictedPropertyNameStruct = matlab.ui.container.internal.appcontainer.PeeredProperties.createRestrictedNameStruct( ...
                                            matlab.ui.container.internal.appcontainer.Panel.PanelRestrictedPropertyNames);
    end
    
    methods
        function this = Panel(varargin)
            this = this@matlab.ui.container.internal.appcontainer.AppChild( ...
                matlab.ui.container.internal.appcontainer.Panel.PanelMCOSToJSNameMap, ...
                matlab.ui.container.internal.appcontainer.Panel.PanelJSToMCOSNameMap, ...
                matlab.ui.container.internal.appcontainer.Panel.PanelDefaultValueMap, ...
                matlab.ui.container.internal.appcontainer.Panel.PanelRestrictedPropertyNameStruct, ...
                varargin);
        end
        
        function value = get.Collapsed(this)
            value = this.getProperty('Collapsed');
        end
        
        function set.Collapsed(this, value)
            this.setProperty('Collapsed', value);
        end
                
        function value = get.Collapsible(this)
            value = this.getProperty('Collapsible');
        end
        
        function set.Collapsible(this, value)
            this.setProperty('Collapsible', value);
        end
        
        function value = get.Contextual(this)
            value = this.getProperty('Contextual');
        end
        
        function set.Contextual(this, value)
            this.setProperty('Contextual', value);
        end
        
        function value = get.Factory(this)
            value = this.getProperty('Factory');
        end
        
        function set.Factory(this, value)
            this.setProperty('Factory', value);
        end
        
        function value = get.PermissibleRegions(this)
            value = this.getProperty('PermissibleRegions');
        end
        
        function set.PermissibleRegions(this, value)
            this.setProperty('PermissibleRegions', value);
        end
        
        function value = get.PreferredHeight(this)
            value = this.getProperty('PreferredHeight');
        end
        
        function set.PreferredHeight(this, value)
            this.setProperty('PreferredHeight', value);
        end
        
        function value = get.PreferredWidth(this)
            value = this.getProperty('PreferredWidth');
        end
        
        function set.PreferredWidth(this, value)
            this.setProperty('PreferredWidth', value);
        end
        
        function value = get.Resizable(this)
            value = this.getProperty('Resizable');
        end
        
        function set.Resizable(this, value)
            this.setProperty('Resizable', value);
        end
                
        function value = get.Region(this)
            value = this.getProperty('Region');
        end
        
        function set.Region(this, value)
            this.setProperty('Region', value);
        end
    end
end