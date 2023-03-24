function [taskSCPI, taskBand] = connect_Receiver_WriteReadTest(taskObj)

    hReceiver  = taskObj.Receiver.Handle;
    instrInfo  = taskObj.General.SCPI;
    rawBand    = taskObj.General.Task.Band;
    
    taskBand   = struct('scpiSet_Config', '', ...
                        'Datagrams',      [], ...
                        'DataPoints',     [], ...
                        'SyncModeRef',    [], ...
                        'Mask',           [], ...
                        'Matrix',         [], ...
                        'File', struct('Filename',        '', ...
                                       'Filecount',       [], ...
                                       'AlocatedSamples', [], ...
                                       'WritedSamples',   [], ...
                                       'Handle',          []));

    % TraceMode, Average, Detector, LevelUnit, DataPoints possible values
    TraceMode_Values   = strsplit(instrInfo.Trace_Values{1}, ',');
    AverageMode_Values = instrInfo.AverageMode_Values{1};
    Detector_Values    = strsplit(instrInfo.Detector_Values{1},  ',');
    LevelUnit_Values   = strsplit(instrInfo.LevelUnit_Values{1}, ',');
    
    % Loop
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
            case 'dBm'   ; LevelUnit = LevelUnit_Values{1};
            case 'dBμV'  ; LevelUnit = LevelUnit_Values{2};
        end                
        
        % FreqStart, FreqStop, DataPoints, StepWidth, Resolution,
        % Selectivity
        FreqStart       = rawBand(ii).FreqStart;
        FreqStop        = rawBand(ii).FreqStop;
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
        
        % Tenta programar valores...
        writeline(hReceiver, scpiSet_Config);
        pause(instrInfo.BandPause{1})
        
        if ~AttenuationMode && ~isempty(instrInfo.scpiAttenuation{1})
            writeline(hReceiver, replace(instrInfo.scpiAttenuation{1}, '%AttenuationValue%', num2str(AttenuationValue)));
        end
        
        % Confirma que foram programados corretamente os valores no sensor...
        tic
        t1 = toc;
        while t1 < 10
            flush(hReceiver)
            rawAnswer = deblank(writeread(hReceiver, instrInfo.scpiQuery{1}));
            
            if ~isempty(rawAnswer); break
            else;                   pause(1); t1 = toc;
            end
        end

        if isempty(rawAnswer); error('Empty string')
        end

        splitAnswer = strsplit(rawAnswer, ';');
        for jj = 1:numel(instrInfo.scpiQuery_IDs{1})
            switch instrInfo.scpiQuery_IDs{1}(jj)
                case  1; if ~strcmp(splitAnswer{jj}, TraceMode);                                  error('%s\nTraceMode',       rawAnswer); end
                case  2; if str2double(splitAnswer{jj}) ~= AverageMode;                           error('%s\nAverageMode',     rawAnswer); end
                case  3; if str2double(splitAnswer{jj}) ~= AverageCount;                          warning('%s\nAverageCount',  rawAnswer); end % INSERIR NO LOG A IMPOSSIBILIDADE DE PROGRAMAR O VALOR
                case  4; if ~strcmp(splitAnswer{jj}, Detector);                                   error('%s\nDetector',        rawAnswer); end
                case  5; if ~strcmp(splitAnswer{jj}, LevelUnit);                                  error('%s\nLevelUnit',       rawAnswer); end                        
                case  6; if str2double(splitAnswer{jj}) ~= FreqStart;                             error('%s\nFreqStart',       rawAnswer); end
                case  7; if str2double(splitAnswer{jj}) ~= FreqStop;                              error('%s\nFreqStop',        rawAnswer); end
                case  8; if str2double(splitAnswer{jj}) ~= DataPoints;                            error('%s\nDataPoints',      rawAnswer); end
                case  9; if str2double(splitAnswer{jj}) ~= StepWidth;                             error('%s\nStepWidth',       rawAnswer); end
                case 10; if str2double(splitAnswer{jj}) ~= ResolutionMode;                        error('%s\nResolutionMode',  rawAnswer); end
                case 11; if str2double(splitAnswer{jj}) ~= ResolutionValue;                       error('%s\nResolutionValue', rawAnswer); end
                case 12; if ~contains(Selectivity, splitAnswer{jj}, 'IgnoreCase', true);          error('%s\nSelectivity',     rawAnswer); end
                case 13; if splitAnswer{jj}             ~= SensitivityMode;                       error('%s\nSensitivityMode', rawAnswer); end
                case 14; if str2double(splitAnswer{jj}) ~= Preamp;                                warning('%s\nPreamp',        rawAnswer); end  % INSERIR NO LOG A IMPOSSIBILIDADE DE PROGRAMAR O VALOR
                case 15; if str2double(splitAnswer{jj}) ~= AttenuationMode;                       error('%s\AttenuationMode',  rawAnswer); end
                case 16; if ~AttenuationMode & (str2double(splitAnswer{jj}) ~= AttenuationValue); error('%s\AttenuationValue', rawAnswer); end
                case 17; if str2double(splitAnswer{jj}) ~= SampleTimeMode;                        error('%s\SampleTimeMode',   rawAnswer); end
            end
        end


        taskSCPI(ii) = struct('scpiSet_Reset',   instrInfo.scpiReset{1},                                                                       ...
                              'scpiSet_Startup', instrInfo.StartUp{1},                                                                         ...
                              'scpiSet_Att',     replace(char(instrInfo.scpiAttenuation{1}), '%AttenuationValue%', num2str(AttenuationValue)), ...
                              'scpiGet_Att',     instrInfo.scpiQuery_Attenuation{1},                                                           ...
                              'scpiGet_Data',    instrInfo.scpiTraceData{1});

        taskBand(ii).scpiSet_Config = scpiSet_Config;
        taskBand(ii).DataPoints     = DataPoints;
        taskBand(ii).Mask           = [];                           % PENDENTE
        taskBand(ii).Matrix         = [];                           % PENDENTE k * ones(128, DataPoints, 'single')
        taskBand(ii).File           = [];                           % PENDENTE
    end

end