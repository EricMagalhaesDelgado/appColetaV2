classdef AppState < uint8
    %AppState enumerates states associated with an AppContainer
    
    % Copyright 2017 The MathWorks, Inc.
    
   enumeration
       INITIALIZING (0)
       RUNNING (1)
       TERMINATED (2)
   end
end