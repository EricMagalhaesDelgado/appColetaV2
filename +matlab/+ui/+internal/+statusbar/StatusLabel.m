classdef StatusLabel < matlab.ui.internal.toolstrip.Label ...
        & matlab.ui.internal.statusbar.mixin.StatusComponent ...
        & matlab.ui.internal.statusbar.mixin.WidgetBehavior_Width
    %StatusLabel A label that can appear on a StatusBar

    % Copyright 2018-2021 The MathWorks, Inc.
    
    methods
        function this = StatusLabel(varargin)
            this@matlab.ui.internal.statusbar.mixin.StatusComponent(varargin);
            this.Type = 'StatusLabel';
        end        
    end
    
    methods (Access = protected)
        
        function buildWidgetPropertyMaps(this)
            % Append StatusLabel unique properties to inherited Label properties
            buildWidgetPropertyMaps@matlab.ui.internal.toolstrip.Label(this);
            mcos = this.WidgetPropertyMap_FromMCOSToPeer.keys();
            peer = this.WidgetPropertyMap_FromPeerToMCOS.keys();
            [mcos1, peer1] = this.getWidgetPropertyNames_Region();
            [mcos2, peer2] = this.getWidgetPropertyNames_Width();
            mcos = [mcos'; mcos1; mcos2];
            peer = [peer'; peer1; peer2];
            this.WidgetPropertyMap_FromMCOSToPeer = containers.Map(mcos, peer);
            this.WidgetPropertyMap_FromPeerToMCOS = containers.Map(peer, mcos);
        end
        
        function handleActionTextUpdate(this, ~)
            % g2345953: flush peer events
            message.type = 'flush_properties';
            message.eventType = 'peerEvent';
            this.getAction().dispatchEvent(message);
        end
    end    
end