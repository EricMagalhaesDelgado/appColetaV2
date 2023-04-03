function timeObj = task_RevisitFactors(specObj)

    timeObj = struct('GlobalRevisitTime', [],             ...
                     'Band', struct('RevisitTimes',   [], ...
                                    'RevisitFactors', []));

    RevisitTimeArray = [];
    for ii = 1:numel(specObj)
        if specObj(ii).Status == "Em andamento..."
            timeObj.Band(ii) = struct('RevisitTimes',   [specObj(ii).taskObj.Task.GPS.RevisitTime, [specObj(ii).taskObj.General.Task.Band.RevisitTime]], ...
                                      'RevisitFactors', []);
            
            RevisitTimeArray = [RevisitTimeArray, [specObj(ii).taskObj.General.Task.Band.RevisitTime]];
        end
    end

    timeObj.GlobalRevisitTime = min(RevisitTimeArray);

    for ii = 1:numel(specObj)
        if ~isempty(timeObj.Band(ii).RevisitTimes)
            idx = (timeObj.Band(ii).RevisitTimes ~= -1);
            timeObj.Band(ii).RevisitFactors(idx) = fix(timeObj.Band(ii).RevisitTimes(idx) ./ timeObj.GlobalRevisitTime);
        end
    end
    
end