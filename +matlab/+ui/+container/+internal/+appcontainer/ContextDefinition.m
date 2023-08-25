classdef ContextDefinition < matlab.ui.container.internal.appcontainer.Options
    %ContextDefinition Defines a context by identifying associated elements
    %
    %   Contexts can be global, defined at the AppContainer level or document driven,
    %   defined on a DocumentGroup.  The identified elements (panels, toolstrip tabs and
    %   status bar components) will be shown when the context is activated, either explicilty
    %   or by virtue of document selection.

    % Copyright 2017-2018 The MathWorks, Inc.
    
    properties
        % Identifies the context
        Tag (1,1) string;
                
        % Contains strings identifying panels associated with the context
        % These panels will appear when the context is active
        PanelTags (1,:) string = {};

        % Contains strings identifying status bar components associate with the context
        % These components will appear on the status bar when the context is active.
        StatusComponentTags (1,:) string = {};

        % Contains strings identifying the tab groups associated with the context
        % These tab groups will appear on the toolstrip when the context is active
        ToolstripTabGroupTags (1,:) string = {};
    end
    
    properties (GetAccess = private, Constant)
        MCOSPropertyNames = {'Tag', 'PanelTags', 'StatusComponentTags', 'ToolstripTabGroupTags'};
        JSPropertyNames   = {'contextId', 'panelIds', 'statusComponentTags', 'tabGroupTags'};
        MCOSToJSNameMap   = containers.Map(matlab.ui.container.internal.appcontainer.ContextDefinition.MCOSPropertyNames, ...
                                           matlab.ui.container.internal.appcontainer.ContextDefinition.JSPropertyNames);
    end
    
    methods
        function this = ContextDefinition(varargin)
            this = this@matlab.ui.container.internal.appcontainer.Options(varargin);
            this.ArrayNames = ["PanelTags" "StatusComponentTags", "ToolstripTabGroupTags"];
        end
    end
    
    methods (Access = {?matlab.ui.container.internal.AppContainer, ?matlab.ui.container.internal.appcontainer.DocumentGroup}, Hidden = true)
        function json = convertToJSON(this)
            structure = this.toStruct(matlab.ui.container.internal.appcontainer.ContextDefinition.MCOSToJSNameMap);
            json = jsonencode(structure);
        end
    end
end