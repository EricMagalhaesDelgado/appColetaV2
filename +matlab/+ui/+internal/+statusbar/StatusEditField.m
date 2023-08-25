classdef StatusEditField < matlab.ui.internal.toolstrip.EditField ...
        & matlab.ui.internal.statusbar.mixin.StatusComponent ...
        & matlab.ui.internal.statusbar.mixin.WidgetBehavior_Width
    %StatusEditFieild An edit field that can appear on a StatusBar

    % Copyright 2018-2021 The MathWorks, Inc.
    
    methods
        function this = StatusEditField(varargin)
            this@matlab.ui.internal.statusbar.mixin.StatusComponent(varargin);
            this.Type = 'StatusTextField';
        end        
    end
    
    methods (Access = protected)
        
        function buildWidgetPropertyMaps(this)
            % Append StatusEditField unique properties to inherited EditField properties
            buildWidgetPropertyMaps@matlab.ui.internal.toolstrip.EditField(this);
            mcos = this.WidgetPropertyMap_FromMCOSToPeer.keys();
            peer = this.WidgetPropertyMap_FromPeerToMCOS.keys();
            [mcos1, peer1] = this.getWidgetPropertyNames_Region();
            [mcos2, peer2] = this.getWidgetPropertyNames_Width();
            mcos = [mcos'; mcos1; mcos2];
            peer = [peer'; peer1; peer2];
            this.WidgetPropertyMap_FromMCOSToPeer = containers.Map(mcos, peer);
            this.WidgetPropertyMap_FromPeerToMCOS = containers.Map(peer, mcos);
        end 
    end    
end