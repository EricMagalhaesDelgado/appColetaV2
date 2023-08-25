classdef (Abstract) StatusComponent < matlab.mixin.SetGet
    % Mixin class used to identify components that can be placed on a status bar and support a Region property for such components

    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties (Dependent, Access = public)
        % Indicates the region of the status bar in which a component should be placed
        Region (1,1) string {mustBeMember(Region, {'left', 'right'})};
    end
    
    properties (Access = {?matlab.ui.internal.toolstrip.base.Component})
        RegionPrivate = 'left';
    end
    
    methods (Abstract, Access = protected)
        setPeerProperty(this)
    end
    
    methods
        function this = StatusComponent(varargin)
            if ~isempty(varargin{1}) && ~isempty(varargin{1}{:})
                this.set(varargin{1}{:});
            end
        end
        
        % Public API: Get/Set
        function value = get.Region(this)
            value = this.RegionPrivate;
        end
        
        function set.Region(this, value)
            this.RegionPrivate = value;
            this.setPeerProperty('region', value);
        end
    end
    
    methods (Access = protected)
        function [mcos, peer] = getWidgetPropertyNames_Region(this) %#ok<MANU>
            mcos = {'RegionPrivate'};
            peer = {'region'};
        end
    end
end