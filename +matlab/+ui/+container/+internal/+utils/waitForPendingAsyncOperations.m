function waitForPendingAsyncOperations(hObj, timeout)
    arguments
        hObj
        timeout (1,:) double = 60;
    end

    hTimer = timer('TimerFcn', @(h,e)forceCompletion(), 'StartDelay', timeout);
    start(hTimer);

    try
        waitfor(hObj)
    catch ME
        % 'MATLAB:qeBlockedStateExecutor:NeedsToUnblock' is thrown when a qeBlockedState is active and another waitfor is requested.
        % This error is only expected in test environments.
        if (strcmp(ME.identifier, 'MATLAB:qeBlockedStateExecutor:NeedsToUnblock'))
            while hTimer.TasksExecuted == 0
                if ~isvalid(hObj)
                    break;
                end
                matlab.internal.yield
            end
        else
            rethrow(ME);
        end
    end

    if (hTimer.TasksExecuted > 0)
        warning(message('MATLAB:desktop:WaitForTimeoutReached'));
    end
    
    stop(hTimer);
    delete(hTimer);

    function forceCompletion()
        delete(hObj);
    end
end