classdef StatusBar  < matlab.ui.internal.toolstrip.base.Container
    %StatusBar defines a status bar that may appear at the bottom of an App
    %
    %    The status bar may host a limited set of controls that display information
    %    about the overall status of an App.  Supported controls include:
    % 
    %    1. StatusButton
    %    2. StatusLabel
    %    3. StatusEditField
    %    4. StatusGroup
    %    5. StatusProgressBar
    %    6. StatusToggleButton

    % Copyright 2018-2020 The MathWorks, Inc.
    
    methods
        
        function this = StatusBar()
            % Constructs a status bar
            this = this@matlab.ui.internal.toolstrip.base.Container('StatusBar');
        end
        
        function render(this, channel, varargin)
            render@matlab.ui.internal.toolstrip.base.Container(this, channel, 'StatusBar');
            if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                manager = matlab.ui.internal.toolstrip.base.ToolstripService.get(channel);
                manager.move(this.Peer, manager.getByType('StatusBarRoot')); 
            else
                manager = com.mathworks.peermodel.PeerModelManagers.getInstance(channel);
                manager.move(this.Peer, manager.getByType('StatusBarRoot').get(0)); 
            end
                       
        end
    end
    
    % Abstract methods from matlab.ui.internal.toolstrip.base.Component
    methods (Access = protected)

        function rules = getInputArgumentRules(this) %#ok<MANU>
            rules.input0 = true;
        end
        
        function buildWidgetPropertyMaps(this)
            [mcos, peer] = this.getWidgetPropertyNames_Container();
            this.WidgetPropertyMap_FromMCOSToPeer = containers.Map(mcos, peer);
            this.WidgetPropertyMap_FromPeerToMCOS = containers.Map(peer, mcos);
        end 
    end 
end

