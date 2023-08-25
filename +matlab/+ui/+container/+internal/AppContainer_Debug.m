classdef AppContainer_Debug < matlab.ui.container.internal.AppContainer
    % AppContainer_Debug  Open App Container in debug mode for internal use only.

    % Copyright 2019-2021 The MathWorks, Inc.    
    methods
        function this = AppContainer_Debug(varargin)
            % Constructs an AppContainer
            this@matlab.ui.container.internal.AppContainer(varargin{:});
        end
    end
    
    methods (Access = protected)
        % Override superclass method
        function page = getPage(this)
            % This method could be simplified by pulling the AppPage logic up a level, but for readability this was chosen
            % If more subclasses of AppContainer come into existence, we may want to do the above.
            if this.UseWebpack
                buildPath = "/web";
            else
                buildPath = "_dojo";
            end
            
            if this.AppPage ~= ""
                page = this.AppPage;
                if this.CleanStart
                    if ~contains(page, '?')
                        page = page + "?";
                    else 
                        page = page + "&";
                    end
                    page = page + "cleanStart=true";
                end
            else
                page = strcat("/toolbox/matlab/appcontainer", buildPath, "/index-debug.html");
            end
        end
        
        % Override superclass method
        function page = addExtensionsInfoToQueryParameters(this, page)
            page = this.addExtensionInfoToQueryParameters(this.Extension.DebugConfigFile, "dojoConfig", page, false);
            page = this.addExtensionInfoToQueryParameters(this.Extension.DebugCSSFile, "cssFile", page, false);

            if this.UseWebpack
                modules = this.Extension.Modules;
                for idx = 1:length(modules)
                    page = this.addExtensionInfoToQueryParameters(modules(idx).Path, sprintf("modulePath[%d]", idx - 1), page, true);
                    page = this.addExtensionInfoToQueryParameters(modules(idx).Exports, sprintf("moduleExports[%d]", idx - 1), page, false);
                    page = this.addExtensionInfoToQueryParameters(modules(idx).Name, sprintf("moduleName[%d]", idx - 1), page, false);
                    page = this.addExtensionInfoToQueryParameters(modules(idx).DebugDependenciesJSONPath, sprintf("debugDependencies[%d]", idx - 1), page, false);
                end
            end
        end

        function setUndockedPage(this)
            % Do not set the UndockedPage property in Debug mode to use the
            % default debug page for undocking.
        end
    end
end
