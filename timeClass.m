classdef timeClass

    properties
        GlobalRevisitTime
        Task = struct('idx',            {}, ...
                      'RevisitTimes',   {}, ... % taskList.json
                      'RevisitFactors', {})     % [GPS, BAND1, BAND2... BANDn] = [-1, 1, 3... 5] | [60, 1, 3... 5]

    end


    methods

        function timeObj = timeClass(specObj)

            RevisitTimeArray = [];

            for ii = 1:numel(specObj)
                if specObj(ii).Status == "Em andamento..."
                    timeObj.Task(end+1) = struct('idx',            ii,                                                                      ...
                                                 'RevisitTimes',   [specObj(ii).Task.GPS.RevisitTime, [specObj(ii).Task.Band.RevisitTime]], ...
                                                 'RevisitFactors', []);
                    
                    RevisitTimeArray = [RevisitTimeArray, [specObj(ii).Task.Band.RevisitTime]];
                end
            end

            timeObj.GlobalRevisitTime = min(RevisitTimeArray(RevisitTimeArray ~= -1));

            for ii = 1:numel(timeObj.Task)
                idx = (timeObj.Task(ii).RevisitTimes ~= -1);
                timeObj.Task(ii).RevisitFactors(idx) = fix(timeObj.Task(ii).RevisitTimes(idx) ./ timeObj.GlobalRevisitTime);
            end
            
        end

    end
end