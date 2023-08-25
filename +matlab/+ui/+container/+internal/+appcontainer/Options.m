classdef Options < matlab.mixin.SetGet
    %Options Base class for various options classes related to the AppContainer and its children
    %   Includes some hidden utility properties and methods

    % Copyright 2017 The MathWorks, Inc.
    
    properties (Access = protected, Hidden = true)
        ArrayNames;
    end
    
    methods
        function this = Options(varargin)
            if nargin > 0 && ~isempty(varargin{1})
                this.set(varargin{1}{:});
            end
        end
    end
    
    methods (Hidden = true)
        % toStruct Packages options into a struct for transport via the peer model
        %   Includes translation from option names used in the MCOS code to peer model
        %   properties names used by the JavaScript code
        function structure = toStruct(this, nameMap)
            optionNames = fieldnames(this);
            structure = struct;
            for i=1:length(optionNames)
                optionName = optionNames{i};
                if nameMap.isKey(optionName)
                    fieldName = nameMap(optionName);
                    optionValue = this.(optionName);
                    if ~isempty(optionValue) && ~(isscalar(optionValue) && isnumeric(optionValue) &&isnan(optionValue))
                        for j=1:length(optionValue)
                            if isa(optionValue(j), 'matlab.ui.container.internal.appcontainer.Options')
                                optionValue(j) = optionValue(j).toStruct(nameMap);
                            end
                        end
                        if ~isempty(this.ArrayNames) && length(optionValue) == 1 && sum(this.ArrayNames == optionName) > 0
                            % Force creation of an array by the peer model on the JS side
                            optionValue = {optionValue};
                        end
                        structure.(fieldName) = optionValue;
                    end
                end
            end
        end
    end    
end

