classdef StatusProgressBar  < matlab.ui.internal.toolstrip.base.Control ...
        & matlab.ui.internal.statusbar.mixin.StatusComponent ...
        & matlab.ui.internal.statusbar.mixin.WidgetBehavior_Width
    %StatusProgressBar A progress bar that can appear on a status bar

    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties (Dependent, Access = public)
        % If true the status bar will convey indeterminate activity rather than monotonic progress
        Indeterminate (1,1) logical;
        
        % Specifies the color of the progress bar based on the type of activity being conveyed
        ColorStyle (1,1) string {mustBeMember(ColorStyle, {'info', 'error', 'warning', 'success'})};
        
        % The percent completion when not indeterminate
        Value (1,1) double {mustBeInteger};
    end
    
    properties (Access = {?matlab.ui.internal.toolstrip.base.Component})
        IndeterminatePrivate = false;
        ColorStylePrivate = 'info';
        ValuePrivate = 0;
    end
    
    methods
        function this = StatusProgressBar(varargin)
            this = this@matlab.ui.internal.toolstrip.base.Control('StatusProgressBar');
            this@matlab.ui.internal.statusbar.mixin.StatusComponent(varargin);
        end
        
        function value = get.Indeterminate(this)
            value = this.IndeterminatePrivate;
        end
        
        function set.Indeterminate(this, value)
            this.IndeterminatePrivate = value;
            this.setPeerProperty('indeterminate', value);
        end
        
        function value = get.ColorStyle(this)
            value = this.ColorStylePrivate;
        end
        
        function set.ColorStyle(this, value)
            this.ColorStylePrivate = value;
            this.setPeerProperty('colorStyle', value);
        end
        
        function value = get.Value(this)
            value = this.ValuePrivate;
        end
        
        function set.Value(this, value)
            this.ValuePrivate = value;
            this.setPeerProperty('value', value);
        end
    end
    
    % Abstract methods from matlab.ui.internal.toolstrip.base.Component and matlab.ui.internal.toolstrip.base.Control
    methods (Access = protected)

        function rules = getInputArgumentRules(this) %#ok<MANU>
            rules.input0 = true;
        end
        
        function buildWidgetPropertyMaps(this)
            [mcos, peer] = this.getWidgetPropertyNames_Control();
            [mcos1, peer1] = this.getWidgetPropertyNames_Region();
            [mcos2, peer2] = this.getWidgetPropertyNames_Width();
            mcos = [mcos; mcos1; mcos2; {'IndeterminatePrivate'; 'ColorStylePrivate'; 'ValuePrivate'}];
            peer = [peer; peer1; peer2; {'indeterminate'; 'colorStyle'; 'value'}];
            this.WidgetPropertyMap_FromMCOSToPeer = containers.Map(mcos, peer);
            this.WidgetPropertyMap_FromPeerToMCOS = containers.Map(peer, mcos);
        end 
        
        function addActionProperties(this) %#ok<MANU>
        end
        
        function result = checkAction(this, control) %#ok<INUSD>
            result = true;
        end
             
    end 
end