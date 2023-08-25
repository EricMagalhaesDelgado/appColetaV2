classdef (Abstract) AppChild < matlab.ui.container.internal.appcontainer.PeeredProperties
    %AppChild is a common base class for the Panel, Document and DocumentGroup classes
    %   It defines properties and methods common to these sub-classes

    % Copyright 2017-2018 The MathWorks, Inc.

    properties (Dependent)
        % TODO: Actions (1,:) matlab.ui.internal.Action;

        % Provides meta data about a child type.
        % Used mostly by derived classes to identify itself.
        ChildType (1, 1) string;

        % If true the user will have the ability to close the child.
        % This property cannot be changed after the child has been added to a parent container.
        Closable (1,1) logical;
        
        % Controls the content of a Panel or Document child
        % This can be set to a string or a struct with arbitrary fields.
        % The content is passed through to the factory that is responsible
        % for creating the child on the JavaScript side.  If a factory is not specified
        % then the content will be treated as HTML to be displayed in the child.
        Content;
        
        % Provides more information about the child
        % Typically this is displayed as a tooltip.
        Description (1,1) string;
        
        % Reflects/controls the position of the child relative to others that share its parent 
        % The parent might be a tab container, in which case the index is associated with tab order
        % or it might be an accordion container, in which case it is associated with the title order
        Index (1,1) double {mustBeInteger};

        % If true the user will have the ability to maximize the child.
        % This property cannot be changed after the child has been added to a parent container.
        Maximizable (1,1) logical;

        % Reflects/controls whether the child is maximized 
        Maximized (1,1) logical;
        
        % Reflects/controls whether the child is selected 
        Selected (1,1) logical;
        
        % Reflects/controls whether the child window is currently visible.
        % More specifically that it is not hidden behind some other child in
        % a tab container, collapsed in an accordion container or within a
        % collapsed border panel 
        Showing (1,1) logical;

        % Uniquely identifies the child
        % By default the Tag cannot be changed after the child has been added to a parent
        % container.  The Document subclass overrides this restriction.
        Tag (1, 1) string;

        % Displayed as child title or tab label
        Title (1,1) string;
        
        % Reflects/controls the position and size of the window containing the child when
        % it is undocked.  The values supplied are interpreted as the window x, y positions,
        % width and height in that order.  For each of the constituent numeric values:
        %    If the value is 0 or >= 1 pixels are assumed.
        %    If 0 < value < 1 the value is assumed to be a fraction of the screen size.
        %    Finally if the value is < 0 a default will be substituted upon use.
        WindowBounds (1,4) double;
    end

    properties (Dependent, Hidden, GetAccess={?matlab.ui.container.internal.AppContainer})
        % Unique uuid which is independent of Tag/Title
        UUID;
    end

    properties (Dependent, SetObservable)
        % Reflects/controls whether the child is open.
        % A child is considered open when it has a presence in the current layout,
        % be it the child window itself or a control, such as a tab, that can be
        % used to access the window.
        Opened (1,1) logical;
    end
    
    properties
        % Arbitrary data that can be associated with the AppChild
        UserData;
    end

    properties (GetAccess = protected, Constant)
        MCOSPropertyNames = {
            'ChildType', 'Closable', 'Content', 'Description', 'Index', 'Maximizable', 'Maximized', 'Opened', 'Selected', 'Showing', 'Title', 'WindowBounds', 'UUID'};
        JSPropertyNames = {
            'childType', 'closable', 'content', 'description', 'index', 'isMaximizable', 'isMaximized', 'isOpen', 'isSelected', 'isShowing', 'title', 'windowBounds', 'uuid'};
        DefaultPropertyValues = {
            '', false, "", "", -1, true, false, false, false, false, "", [-1, -1, -1, -1], ''};
        RestrictedPropertyNames = {'Closable', 'Maximizable', 'Tag'};
    end
    
    methods
        % Constructor
        function this = AppChild(mcosToJSNameMap, jsToMCOSNameMap, defaultValueMap, restrictedNamesStruct, varargin)
            this = this@matlab.ui.container.internal.appcontainer.PeeredProperties( ...
                       mcosToJSNameMap, jsToMCOSNameMap, defaultValueMap, restrictedNamesStruct, varargin{1});

            this.setInternalProperty('UUID', matlab.lang.internal.uuid);
        end
        
        function value = get.ChildType(this)
            value = this.getProperty('ChildType');
        end
        
        function set.ChildType(this, value)
            this.setProperty('ChildType', value);
        end
        
        function value = get.Closable(this)
            value = this.getProperty('Closable');
        end
        
        function set.Closable(this, value)
            this.setProperty('Closable', value);
        end
        
        function set.Content(this, value)
            if isstruct(value)
                value = matlab.ui.container.internal.appcontainer.PeeredProperties.JSON_PREFIX + jsonencode(value);
            end
            this.setProperty('Content', value);
        end

        function value = get.Content(this)
            value = this.getProperty('Content');
        end

        function value = get.Description(this)
            value = this.getProperty('Description');
        end
        
        function set.Description(this, value)
            this.setProperty('Description', value);
        end
        
        function value = get.Index(this)
            value = this.getProperty('Index') + 1;
        end
        
        function set.Index(this, value)
            this.setProperty('Index', value - 1);
        end
        
        function value = get.Maximizable(this)
            value = this.getProperty('Maximizable', false);
        end
        
        function set.Maximizable(this, value)
            this.setProperty('Maximizable', value);
        end
        
        function value = get.Maximized(this)
            value = this.getProperty('Maximized');
        end
        
        function set.Maximized(this, value)
            this.setProperty('Maximized', value);
        end
        
        function value = get.Opened(this)
            value = this.getProperty('Opened', false);
        end
        
        function set.Opened(this, value)
            this.setProperty('Opened', value);
        end
        
        function value = get.Selected(this)
            value = this.getProperty('Selected', false);
        end
        
        function set.Selected(this, value)
            this.setPeerProperty('Selected', value);
        end
        
        function value = get.Showing(this)
            value = this.getProperty('Showing', false);
        end
        
        function set.Showing(this, value)
            this.setPeerProperty('Showing', value);
        end
        
        function value = get.Tag(this)
            value = this.getProperty('Tag');
        end
        
        function set.Tag(this, value)
            this.setProperty('Tag', value);
        end
        
        function value = get.Title(this)
            value = this.getProperty('Title');
        end
        
        function set.Title(this, value)
            this.setProperty('Title', value);
        end

        function value = get.UUID(this)
            value = this.getProperty('UUID');
        end

        function value = get.WindowBounds(this)
            value = this.getProperty('WindowBounds');
            if isstruct(value)
                value = [value.x value.y value.w, value.h];
            end
        end
        
        function set.WindowBounds(this, value)
            bounds.x = value(1);
            bounds.y = value(2);
            bounds.w = value(3);
            bounds.h = value(4);
            this.setProperty('WindowBounds', bounds);
        end
    end
end
