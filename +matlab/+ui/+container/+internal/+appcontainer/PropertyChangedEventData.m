classdef (ConstructOnLoad) PropertyChangedEventData < event.EventData
    %PropertyChangedEventData EventData subclass associated with AppContainer and AppChild PropertyChanged events
    %   Includes the name of the property that has changed

    % Copyright 2021 The MathWorks, Inc.
    
    properties
        PropertyName
        MetaData
    end
    
    methods
        function this = PropertyChangedEventData(propertyName, metaData)
            this.PropertyName = propertyName;
            this.MetaData = metaData;
        end
    end
end

