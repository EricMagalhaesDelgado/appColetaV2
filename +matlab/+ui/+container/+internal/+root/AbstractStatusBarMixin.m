classdef (Abstract) AbstractStatusBarMixin < matlab.mixin.SetGet
    % This mixin class for matlab.ui.container.internal.RootApp enables RootApp to
    % interface with the MATLAB Desktop StatusBar
    % Its features include:
    %     Set the status text of the StatusBar
    %     Clear the status text of the StatusBar
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties (GetAccess = private)
        Status (1,:) string;
    end

    properties (Access = protected, Constant = true)
        StatusBarChannel = '/motw/statusbar';
        StatusBarType = 'matlab.ui.internal.statusbar.StatusBar';
        StatusComponentType = 'matlab.ui.internal.statusbar.mixin.StatusComponent';
    end

    properties (Access = private, Constant = true)
        StatusPropertyComponentTag = genvarname(matlab.lang.internal.uuid);
    end

    properties (Access = private)
        ActiveStatusComponent = matlab.ui.internal.statusbar.StatusLabel.empty();
        MessageSubscription;
    end

    methods
        function set.Status(this, statusStr)
            if isempty(statusStr) || (isequal(numel(statusStr), 1) && strcmp(statusStr, ""))
                this.clearStatus();
            elseif isequal(numel(statusStr), 1)
                status = matlab.ui.internal.statusbar.StatusLabel();
                status.Text = char(statusStr);
                status.Tag = this.StatusPropertyComponentTag;
                this.setStatus(status);
            else
                throw(MException(message('MATLAB:class:RequireString')));
            end
        end
    end

    methods (Access = private)
        function handleGetStatusResponse(this, callback, data)
            message.unsubscribe(this.MessageSubscription);
            this.MessageSubscription = [];
            callback(data);
        end
    end

    methods (Hidden = true)
        function varargout = setStatus(this, statusComponent)
            narginchk(2, 2);
            nargoutchk(0, 1); % output not supported right now, but we will not error if asked
            
            if numel(statusComponent) > 1
                throw(MException(message('MATLAB:class:MustBeScalar')));
            end
            
            if isa(statusComponent, this.StatusComponentType)
                this.clearStatus();
                this.setStatusComponent(statusComponent);
                this.ActiveStatusComponent = statusComponent;
            else
                throw(MException(message('MATLAB:class:WrongObjectType', this.StatusComponentType)));
            end
            
            if nargout > 0
                varargout = {[]};
            else
                varargout = {};
            end
        end
        
        function clearStatus(this, varargin)
            narginchk(1, 2); % 2 inputs not supported right now, but we will not error if given 2
            if ~isempty(this.ActiveStatusComponent)
                this.clearStatusComponent(this.ActiveStatusComponent);
                if strcmp(this.ActiveStatusComponent.Tag, this.StatusPropertyComponentTag)
                    this.ActiveStatusComponent.delete();
                end
                this.ActiveStatusComponent = matlab.ui.internal.statusbar.StatusLabel.empty();
            end
        end

        function qeGetStatus(this, callback)
            this.MessageSubscription = message.subscribe(this.StatusBarChannel, @(data) this.handleGetStatusResponse(callback, data));

            data.type = 'getStatus';
            message.publish(this.StatusBarChannel, data);
        end
    end

    methods (Abstract, Access = protected)
        setStatusComponent(this, statusComponent)
        clearStatusComponent(this, componentOrTag)
    end
end
