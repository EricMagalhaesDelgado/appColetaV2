classdef StatusGroup  < matlab.ui.internal.toolstrip.base.Container ...
        & matlab.ui.internal.statusbar.mixin.StatusComponent
    %StatusGroup A status group can be used to visually group a set of controls appearing on a status bar

    % Copyright 2018-2021 The MathWorks, Inc.
    
    methods
        
        function this = StatusGroup(varargin)
            this@matlab.ui.internal.statusbar.mixin.StatusComponent(varargin);
            this = this@matlab.ui.internal.toolstrip.base.Container('StatusGroup');
        end
    end
    
    % Abstract methods from matlab.ui.internal.toolstrip.base.Component
    methods (Access = protected)

        function rules = getInputArgumentRules(this) %#ok<MANU>
            rules.input0 = true;
        end
        
        function buildWidgetPropertyMaps(this)
            [mcos, peer] = this.getWidgetPropertyNames_Container();
            [mcos1, peer1] = this.getWidgetPropertyNames_Region();
            mcos = [mcos; mcos1];
            peer = [peer; peer1];
            this.WidgetPropertyMap_FromMCOSToPeer = containers.Map(mcos, peer);
            this.WidgetPropertyMap_FromPeerToMCOS = containers.Map(peer, mcos);
        end 
    end 
end