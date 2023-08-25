classdef ChildType < uint8
    %ChildType enumerates the types of children that may be hosted by an AppContainer
    
    % Copyright 2017 The MathWorks, Inc.
    
   enumeration
       PANEL (1)
       DOCUMENT (2)
       DOCUMENT_GROUP (3)
       TOOL_BAR (4)
       TOOLSTRIP_TAB_GROUP (5)
       STATUS_BAR (6)
   end
end