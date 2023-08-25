classdef StatusToggleButton < matlab.ui.internal.toolstrip.ToggleButton ...
        & matlab.ui.internal.statusbar.mixin.StatusComponent
    %StatusButton A toggle button that can appear on a StatusBar

    % Copyright 2018-2021 The MathWorks, Inc.
    
    methods
        function this = StatusToggleButton(varargin)
            this@matlab.ui.internal.statusbar.mixin.StatusComponent(varargin);
            this.Type = 'StatusToggleButton';
        end        
    end
    
    methods (Access = protected)
        
        function buildWidgetPropertyMaps(this)
            % Append StatusToggleButton unique properties to inherited ToggleButton properties
            buildWidgetPropertyMaps@matlab.ui.internal.toolstrip.ToggleButton(this);
            mcos = this.WidgetPropertyMap_FromMCOSToPeer.keys();
            peer = this.WidgetPropertyMap_FromPeerToMCOS.keys();
            [mcos1, peer1] = this.getWidgetPropertyNames_Region();
            mcos = [mcos'; mcos1];
            peer = [peer'; peer1];
            this.WidgetPropertyMap_FromMCOSToPeer = containers.Map(mcos, peer);
            this.WidgetPropertyMap_FromPeerToMCOS = containers.Map(peer, mcos);
        end 
    end    
end