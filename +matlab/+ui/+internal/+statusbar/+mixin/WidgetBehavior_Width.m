classdef (Abstract) WidgetBehavior_Width < handle
    % Mixin class used to add a Width property to status bar widgets

    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties (Dependent, Access = public)
        % Indicates the width of a status bar widget
        Width (1,1) double;
    end
    
    properties (Access = {?matlab.ui.internal.toolstrip.base.Component})
        WidthPrivate = -1;
    end
    
    methods (Abstract, Access = protected)
        setPeerProperty(this)
    end
    
    methods
        % Public API: Get/Set
        function value = get.Width(this)
            value = this.WidthPrivate;
        end
        
        function set.Width(this, value)
            this.WidthPrivate = value;
            this.setPeerProperty('width', value);
        end
    end
    
    methods (Access = protected)
        function [mcos, peer] = getWidgetPropertyNames_Width(this) %#ok<MANU>
            mcos = {'WidthPrivate'};
            peer = {'width'};
        end
    end
end