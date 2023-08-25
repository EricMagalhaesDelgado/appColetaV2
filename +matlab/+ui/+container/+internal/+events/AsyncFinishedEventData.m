classdef AsyncFinishedEventData < event.EventData
   properties
      Properties = [];
   end
   methods
      function eventData = AsyncFinishedEventData(value)
         eventData.Properties = value;
      end
   end
end