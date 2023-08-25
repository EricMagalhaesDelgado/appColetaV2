classdef BorderOptions < matlab.ui.container.internal.appcontainer.Options
    %BorderOptions Defines options that control the collective behavior of the panels on a particular border of an AppContainer
    %
    %   These options are set on the AppContainer.

    % Copyright 2017-2018 The MathWorks, Inc.

    properties
        % Indicates which border the options apply to
        Region (1,1) string {mustBeMember(Region, {'left', 'right', 'bottom'})} = "left";
        
        % If true the user will be able to collapse the set of panels occupying the border
        Collapsible (1,1) logical = true;
        
        % Size in pixels to which the border's panel set may be reduced without collapsing
        MinSize (1,1) double = 120;
        
        % If true the panel set occupying the border will be resized proportionally when the overall container size changes
        Proportional (1,1) logical = true;

        % If true the user will be able to adjust the free dimension of the panel set occupying the border
        Resizable (1,1) logical = true;
    end
    
    properties (GetAccess = private, Constant)
        MCOSPropertyNames = {'Region', 'Collapsible', 'MinSize', 'Proportional', 'Resizable'};
        JSPropertyNames   = {'region', 'isCollapsible', 'minSize', 'isProportional', 'isResizable'};
        MCOSToJSNameMap   = containers.Map(matlab.ui.container.internal.appcontainer.BorderOptions.MCOSPropertyNames, ...
                                           matlab.ui.container.internal.appcontainer.BorderOptions.JSPropertyNames);
    end
    
    methods
        function this = BorderOptions(varargin)
            this = this@matlab.ui.container.internal.appcontainer.Options(varargin);
        end
    end
    
    methods (Access = {?matlab.ui.container.internal.AppContainer}, Hidden = true)
        function json = convertToJSON(this)
            structure = this.toStruct(matlab.ui.container.internal.appcontainer.BorderOptions.MCOSToJSNameMap);
            json = jsonencode(structure);
        end
    end
end