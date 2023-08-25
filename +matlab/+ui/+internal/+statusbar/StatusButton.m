classdef StatusButton < matlab.ui.internal.toolstrip.Button ...
        & matlab.ui.internal.statusbar.mixin.StatusComponent
    %StatusButton A button that can appear on a StatusBar

    % Copyright 2018-2021 The MathWorks, Inc.
    
    methods
        function this = StatusButton(varargin)
            this@matlab.ui.internal.statusbar.mixin.StatusComponent(varargin);
            this.Type = 'StatusPushButton';
        end        
    end
    
    methods (Access = protected)
        
        function buildWidgetPropertyMaps(this)
            % Append StatusButton unique properties to inherited Button properties
            buildWidgetPropertyMaps@matlab.ui.internal.toolstrip.Button(this);
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