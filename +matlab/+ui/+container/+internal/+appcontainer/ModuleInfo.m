classdef ModuleInfo < handle
    % ModuleInfo defines a class used to tell ExtensionInfo the path and exports provides by a modules.

    % Copyright 2021 The MathWorks, Inc.

    properties
        % Name of the module. If the name is not provided, the name defaults to
        % the the folder pointed to by the "Path" property.
        % (eg: if "Path" is "path/to/folder", then "Name" is "folder")
        Name (1,1) string = "";

        % String of the relative path to a module from matlabroot.
        Path (:,:) string = "";

        % String array of exports provided by a module located at the Path.
        Exports (:,:) string = "";

        % String of the relative path to JSON file listing transitive dependencies (js_dependencies.json)
        % from matlabroot.
        % Only used by AppContainer_Debug with 'UseWebpack' = true
        DebugDependenciesJSONPath (:,:) string = "";
    end
end
