classdef AppWindowState < uint8
    %AppWindowState enumerates states associated with an AppContainer

     % Copyright 2020 The MathWorks, Inc.

   enumeration
        CLOSED (0)
        NORMAL (1)
        MINIMIZED (2)
        MAXIMIZED (3)
   end
end