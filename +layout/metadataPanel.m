function htmlCode = metadataPanel(app)

    ii = app.Table.Selection;
    jj = app.Tree.SelectedNodes.NodeData;

    Task   = app.specObj(ii).Task;
    Script = Task.Script;

    [observationType, observationSamples, StepWidth, receiverRevisitTime, gpsRevisitTime, maskTrigger] = metadataPanel_ViewForm(app, ii, jj);
    
    dataStruct = struct('group', 'TAREFA',                                                         ...
                        'value', struct('Type',          Task.Type,                                ...
                                        'Observation',   observationType,                          ...
                                        'FileVersion',   class.Constants.fileVersion,              ...
                                        'BitsPerSample', sprintf('%d bits', Script.BitsPerSample), ...
                                        'Receiver',      app.specObj(ii).IDN,                      ...
                                        'gpsType',       Script.GPS.Type));
    
    dataStruct(2).group = 'RECEPTOR';
    dataStruct(2).value = struct('StepWidth',  StepWidth,                       ...
                                 'DataPoints', Script.Band(jj).instrDataPoints, ...
                                 'Resolution', Script.Band(jj).instrResolution);
    
    % VBW
    % instrVBW será igual a {} caso se trate do R&S EB500; em se tratando de
    % um analisador, o instrVBW será originalmente igual a "auto" (caso na
    % tarefa o seu valor seja igual a -1) ou o valor mais próximo da relação 
    % de VBWs disponíveis no analisador (atualmente incluído apenas R&S FSL, 
    % FSVR e FSW).
    if ~isempty(Script.Band(jj).instrVBW) && ~strcmp(Script.Band(jj).instrVBW, 'auto')
        dataStruct(2).value.VBW = Script.Band(jj).instrVBW;
    end

    dataStruct(2).value.Detector          = Script.Band(jj).instrDetector;
    dataStruct(2).value.TraceMode         = Script.Band(jj).TraceMode;
    dataStruct(2).value.IntegrationFactor = Script.Band(jj).IntegrationFactor;
    dataStruct(2).value.Reset             = Task.Receiver.Reset;
    dataStruct(2).value.Sync              = Task.Receiver.Sync;
    
    dataStruct(3).group = 'ANTENA';
    dataStruct(3).value = app.specObj(ii).Band(jj).Antenna;

    dataStruct(4).group = 'TEMPO DE REVISITA';
    dataStruct(4).value = struct('Receiver', receiverRevisitTime, ...
                                 'GPS',      gpsRevisitTime);

    dataStruct(5).group = 'OUTROS ASPECTOS';
    dataStruct(5).value = struct('Description',        Script.Band(jj).Description, ...
                                 'ObservationSamples', observationSamples,          ...
                                 'MaskTrigger',        maskTrigger);
    
    htmlCode = textFormatGUI.struct2PrettyPrintList(dataStruct);
end


%-------------------------------------------------------------------------%
function [observationType, observationSamples, StepWidth, receiverRevisitTime, gpsRevisitTime, maskTrigger] = metadataPanel_ViewForm(app, ii, jj)
    Task   = app.specObj(ii).Task;
    Script = Task.Script;

    % ObservationType
    switch Script.Observation.Type
        case "Duration"; observationType = "Duração específica";
        case "Samples";  observationType = "Quantidade específica de amostras";
        case "Time";     observationType = "Período específico";
    end

    % ObservationSamples
    if observationType == "Quantidade específica de amostras"
        observationSamples = Script.Band(jj).instrObservationSamples;
    else
        observationSamples = -1;
    end

    % StepWidth
    if isnumeric(Script.Band(jj).instrStepWidth)
        StepWidth = sprintf('%.3f kHz', Script.Band(jj).instrStepWidth/1e+3);
    else
        StepWidth = Script.Band(jj).instrStepWidth;
    end
    
    % Receiver RevisitTime
    receiverRevisitTime = sprintf('%.3f seg', Script.Band(jj).RevisitTime);
    try
        if app.revisitObj.Band(ii).RevisitFactors(jj+1) ~= -1
            receiverRevisitTime = sprintf('%.3f → %.3f seg (norm)', Script.Band(jj).RevisitTime, ...
                                                                    app.revisitObj.GlobalRevisitTime * app.revisitObj.Band(ii).RevisitFactors(jj+1));
        end
    catch
    end
       
    % GPS RevisitTime
    if ~isempty(Script.GPS.RevisitTime)
        gpsRevisitTime = sprintf('%.3f seg', Script.GPS.RevisitTime);

        try
            if app.revisitObj.Band(ii).RevisitFactors(1) ~= -1
                gpsRevisitTime = sprintf('%.3f → %.3f seg (norm)', Script.GPS.RevisitTime, ...
                                                                   app.revisitObj.GlobalRevisitTime * app.revisitObj.Band(ii).RevisitFactors(1));
            end
        catch
        end
    else
        gpsRevisitTime = 'NA';
    end

    % MaskTrigger
    if ~isempty(app.specObj(ii).Band(jj).Mask)
        maskTrigger = struct('Status',    Task.Script.Band(jj).MaskTrigger.Status, ...
                             'FindPeaks', app.specObj(ii).Band(jj).Mask.FindPeaks);
    else
        maskTrigger = 'NA';
    end
end