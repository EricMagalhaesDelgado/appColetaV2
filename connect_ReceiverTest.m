function [taskSCPI, taskBand, warnMsg] = connect_ReceiverTest(taskObj, EMSatObj)

    hReceiver  = taskObj.Receiver.Handle;
    instrInfo  = taskObj.General.SCPI;
    rawBand    = taskObj.General.Task.Band;

    taskSCPI   = struct('scpiSet_Reset',   '',                                 ...
                        'scpiSet_Startup', instrInfo.StartUp{1},               ...
                        'scpiSet_Sync',    '',                                 ...
                        'scpiGet_Att',     instrInfo.scpiQuery_Attenuation{1}, ...
                        'scpiGet_Data',    instrInfo.scpiTraceData{1});    
    taskBand   = struct('scpiSet_Config',  '', ...
                        'scpiSet_Att',     '', ...
                        'scpiSet_Answer',  '', ...
                        'FreqStart',       [], ...
                        'FreqStop',        [], ...
                        'Datagrams',       [], ...
                        'DataPoints',      [], ...
                        'SyncModeRef',     [], ...
                        'FlipArray',       [], ...
                        'nSweeps',          0, ...
                        'LastTimeStamp',   [], ...
                        'RevisitTime',     [], ...
                        'Waterfall',       [], ...
                        'Mask',            [], ...
                        'File',            [], ...
                        'Antenna',         '', ...
                        'uuid',            '', ...
                        'Status',          true);
    warnMsg    = {};


    % RECEIVER STARTUP
    if ~hReceiver.UserData.nTasks && strcmp(taskObj.Receiver.Reset, 'On')
        taskSCPI.scpiSet_Reset = instrInfo.scpiReset{1};
        writeline(hReceiver, instrInfo.scpiReset{1});

        pause(instrInfo.ResetPause)
    end
    
    writeline(hReceiver, instrInfo.StartUp{1});

    if ~hReceiver.UserData.nTasks
        switch taskObj.Receiver.Sync
            case 'Single Sweep'; scpiSet_Sync = 'INITiate:CONTinuous OFF';
            otherwise;           scpiSet_Sync = 'INITiate:CONTinuous ON';       % 'Continuous Sweep' | 'Streaming'
        end
        taskSCPI.scpiSet_Sync = scpiSet_Sync;
        writeline(hReceiver, scpiSet_Sync);
    end

    % CONFIG TEST FOR EACH BAND
    TraceMode_Values   = strsplit(instrInfo.Trace_Values{1}, ',');
    AverageMode_Values = instrInfo.AverageMode_Values{1};
    Detector_Values    = strsplit(instrInfo.Detector_Values{1},  ',');
    LevelUnit_Values   = strsplit(instrInfo.LevelUnit_Values{1}, ',');

    rawFields = {'TraceMode',        ...
                 'AverageMode',      ...
                 'AveragCount',      ...
                 'Detector',         ...
                 'LevelUnit',        ...
                 'FreqStart',        ...
                 'FreqStop',         ...
                 'DataPoints',       ...
                 'StepWidth',        ...
                 'ResolutionMode',   ...
                 'ResolutionValue',  ...
                 'Selectivity',      ...
                 'SensitivityMode',  ...
                 'Preamp',           ...
                 'AttenuationMode',  ...
                 'AttenuationValue', ...
                 'SampleTimeMode',   ...
                 'SampleTimeValue',  ...
                 'minFreqRange',     ...
                 'maxFreqRange',     ...
                 'VideoBandwidth'};
    rawFields = rawFields(instrInfo.scpiQuery_IDs{1});

    for ii = 1:numel(rawBand)        
        ResolutionMode  = 0;
        SampleTimeMode  = 1;
        SampleTimeValue = 0;

        % TraceMode
        switch rawBand(ii).TraceMode
            case 'ClearWrite'; idxTraceMode = 1;
            case 'Average';    idxTraceMode = 2;
            case 'MaxHold';    idxTraceMode = 3;
            case 'MinHold';    idxTraceMode = 4;
        end
        TraceMode = TraceMode_Values{idxTraceMode};
        
        AverageMode = [];
        if ~isempty(AverageMode_Values); AverageMode = AverageMode_Values(idxTraceMode);
        end

        % Average count
        AverageCount = rawBand(ii).IntegrationFactor;
        
        % Detector
        switch rawBand(ii).instrDetector
            case 'Sample';        Detector = Detector_Values{1};
            case 'Average/RMS';   Detector = Detector_Values{2};
            case 'Positive Peak'; Detector = Detector_Values{3};
            case 'Negative Peak'; Detector = Detector_Values{4};
        end
        
        % LevelUnit
        switch rawBand(ii).instrLevelUnit
            case 'dBm';            LevelUnit = LevelUnit_Values{1};
            case {'dBµV', 'dBμV'}; LevelUnit = LevelUnit_Values{2};
        end                
        
        % FreqStart/FreqStop
        if strcmp(taskObj.Antenna.Switch, 'EMSat')
            antIndex  = find(strcmp(EMSatObj.LNB.Name, rawBand(ii).instrAntenna), 1);
            lnbOffset = double(EMSatObj.LNB.Offset(antIndex));
            FlipArray = EMSatObj.LNB.Inverted(antIndex);

            freqBand  = abs([rawBand(ii).FreqStart, rawBand(ii).FreqStop] - lnbOffset);
            FreqStart = min(freqBand);
            FreqStop  = max(freqBand);
        else
            FlipArray = [];
            FreqStart = rawBand(ii).FreqStart;
            FreqStop  = rawBand(ii).FreqStop;            
        end

        % DataPoints, StepWidth, Resolution, Selectivity
        DataPoints      = rawBand(ii).instrDataPoints;
        StepWidth       = (rawBand(ii).FreqStop - rawBand(ii).FreqStart) ./ (rawBand(ii).instrDataPoints - 1);
        ResolutionValue = str2double(extractBefore(rawBand(ii).instrResolution, ' kHz')) .* 1e+3;
        Selectivity     = rawBand(ii).instrSelectivity;
        
        % SensitivityMode, Preamp, AttenuationMode, AttenuationValue
        if ~isempty(rawBand(ii).instrSensitivityMode)
            SensitivityMode = rawBand(ii).instrSensitivityMode;
        end
        
        switch rawBand(ii).instrPreamp
            case 'On'; Preamp = 1;
            otherwise; Preamp = 0;
        end
        
        switch rawBand(ii).instrAttMode
            case 'Auto'; AttenuationMode = 1;
            otherwise;   AttenuationMode = 0;
        end
        
        if ~AttenuationMode; AttenuationValue = str2double(extractBefore(rawBand(ii).instrAttFactor, ' dB'));
        else;                AttenuationValue = 0;
        end

        % SCPI main string
        replaceCell = {'%Trace%',            TraceMode;                 ... 
                       '%AverageMode%',      num2str(AverageMode);      ...
                       '%AverageCount%',     num2str(AverageCount);      ...
                       '%Detector%',         Detector;                  ...
                       '%LevelUnit%',        LevelUnit;                 ...
                       '%FreqStart%',        num2str(FreqStart);        ...
                       '%FreqStop%',         num2str(FreqStop);         ...
                       '%DataPoints%',       num2str(DataPoints);       ...
                       '%StepWidth%',        num2str(StepWidth);        ...
                       '%ResolutionMode%',   num2str(ResolutionMode);   ...
                       '%ResolutionValue%',  num2str(ResolutionValue);  ...
                       '%Selectivity%',      Selectivity;               ...
                       '%SensitivityMode%',  SensitivityMode;           ...
                       '%Preamp%',           num2str(Preamp);           ...
                       '%AttenuationMode%',  num2str(AttenuationMode);  ...
                       '%AttenuationValue%', num2str(AttenuationValue); ...
                       '%SampleTimeMode%',   num2str(SampleTimeMode);   ...
                       '%SampleTimeValue%',  num2str(SampleTimeValue)};
        
        scpiSet_Config = replace(instrInfo.scpiGeneral{1}, replaceCell(:,1), replaceCell(:,2));
        scpiSet_Att    = '';
        
        % Tenta programar valores...
        writeline(hReceiver, scpiSet_Config);
        pause(instrInfo.BandPause)
        
        if ~AttenuationMode & ~isempty(instrInfo.scpiAttenuation{1})
            scpiSet_Att = replace(char(instrInfo.scpiAttenuation{1}), '%AttenuationValue%', num2str(AttenuationValue));
            writeline(hReceiver, scpiSet_Att);
        end
        
        % Confirma que foram programados corretamente os valores no sensor...
        tic
        t1 = toc;
        while t1 < 5
            flush(hReceiver)
            rawAnswer = deblank(writeread(hReceiver, instrInfo.scpiQuery{1}));
            
            if ~isempty(rawAnswer); break
            else;                   pause(1); t1 = toc;
            end
        end

        if isempty(rawAnswer); error(msgConstructor(1, 'Empty string', scpiSet_Config, ''))
        end

        splitAnswer    = strsplit(rawAnswer, ';');
        scpiSet_Answer = [];

        for jj = 1:numel(rawFields)
            scpiSet_Answer.(rawFields{jj}) = splitAnswer{jj};
        end
        scpiSet_Answer = jsonencode(scpiSet_Answer);

        for jj = 1:numel(instrInfo.scpiQuery_IDs{1})
            Trigger = rawFields{jj};

            switch instrInfo.scpiQuery_IDs{1}(jj)
                case  1; if ~strcmp(splitAnswer{jj}, TraceMode);                                  error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case  2; if str2double(splitAnswer{jj}) ~= AverageMode;                           error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case  3; if str2double(splitAnswer{jj}) ~= AverageCount;               warnMsg{end+1} = msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer);  end
                case  4; if ~strcmp(splitAnswer{jj}, Detector);                                   error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case  5; if ~strcmp(splitAnswer{jj}, LevelUnit);                                  error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case  6; if str2double(splitAnswer{jj}) ~= FreqStart;                             error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case  7; if str2double(splitAnswer{jj}) ~= FreqStop;                              error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case  8; if str2double(splitAnswer{jj}) ~= DataPoints;                            error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case  9; if str2double(splitAnswer{jj}) ~= StepWidth;                             error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case 10; if str2double(splitAnswer{jj}) ~= ResolutionMode;                        error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case 11; if str2double(splitAnswer{jj}) ~= ResolutionValue;                       error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case 12; if ~contains(Selectivity, splitAnswer{jj}, 'IgnoreCase', true);          error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case 13; if splitAnswer{jj}             ~= SensitivityMode;                       error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case 14; if str2double(splitAnswer{jj}) ~= Preamp;                     warnMsg{end+1} = msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer);  end
                case 15; if str2double(splitAnswer{jj}) ~= AttenuationMode;                       error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case 16; if ~AttenuationMode & (str2double(splitAnswer{jj}) ~= AttenuationValue); error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
                case 17; if str2double(splitAnswer{jj}) ~= SampleTimeMode;                        error(msgConstructor(2, Trigger, scpiSet_Config, scpiSet_Answer)); end
            end
        end

        taskBand(ii).scpiSet_Config = scpiSet_Config;
        taskBand(ii).scpiSet_Att    = scpiSet_Att;
        taskBand(ii).scpiSet_Answer = scpiSet_Answer;
        taskBand(ii).DataPoints     = DataPoints;
        taskBand(ii).SyncModeRef    = -1;
        taskBand(ii).FlipArray      = FlipArray;
        taskBand(ii).nSweeps        = 0;
        taskBand(ii).Antenna        = AntennaExtract(taskObj, ii);
        taskBand(ii).uuid           = char(matlab.lang.internal.uuid());
        taskBand(ii).Status         = true;
    end

end


%-------------------------------------------------------------------------%
function msg = msgConstructor(Type, Trigger, scpiSet_Config, scpiSet_Answer)
    switch Type
        case 1
            msg = sprintf(['Triggered parameter: "%s\n"' ...
                           'scpiSet_Config: %s'], Trigger, scpiSet_Config);
        case 2                                                              % 'error' | 'warning'
            msg = sprintf(['Triggered parameter: "%s"\n' ...
                           'scpiSet_Config: %s\n'        ...
                           'scpiSet_Answer: %s'], Trigger, scpiSet_Config, scpiSet_Answer);
    end
end


%-------------------------------------------------------------------------%
function AntennaInfo = AntennaExtract(taskObj, idx1)
    AntennaName     = taskObj.General.Task.Band(idx1).instrAntenna;
    AntennaMetaData = rmfield(taskObj.Antenna.MetaData, 'Installation');
    AntennaFields   = fieldnames(AntennaMetaData);

    if ~isempty(AntennaName)
        idx2 = find(strcmp({AntennaMetaData.Name}, AntennaName), 1);
        AntennaMetaData = AntennaMetaData(idx2);
    end

    for ii = numel(AntennaFields):-1:1
        if AntennaMetaData.(AntennaFields{ii}) == "NA"
            AntennaMetaData = rmfield(AntennaMetaData, AntennaFields{ii});
        end
    end
    AntennaInfo = jsonencode(AntennaMetaData);
end