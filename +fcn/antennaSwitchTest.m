function antennaSwitchTest(app, EMSatObj, Script, AntennaMetaData)

    for ii = 1:numel(Script.Band)
        targetName  = Script.Band(ii).instrTarget;
        LNBName     = Script.Band(ii).instrAntenna;
        antennaName = extractBefore(LNBName, ' ');

        % PASSO 1: comutação para a porta correta da matriz.
        errorMsg = EMSatObj.MatrixSwitch(LNBName);
        if ~isempty(errorMsg)
            error(errorMsg)
        end

        % PASSO 2: identifica posição de apontamento (além da posição atual).
        if ~isempty(targetName)
            [targetPos,  errorMsg] = EMSatObj.TargetPositionGET(antennaName, targetName);
            if ~isempty(errorMsg)
                error(errorMsg)
            end
        else
            [~, antennaStruct] = AntennaExtract(Script, ii, AntennaMetaData);
            targetPos = struct('Azimuth',      antennaStruct.Azimuth,   ...
                               'Elevation',    antennaStruct.Elevation, ...
                               'Polarization', antennaStruct.Polarization);
        end

        [antennaPos, errorMsg] = EMSatObj.AntennaPositionGET(antennaName);
        if ~isempty(errorMsg)
            error(errorMsg)
        end

        % PASSO 3: uiconfirm
        if abs(targetPos.Azimuth - antennaPos.Azimuth) < 0.2 && ...
                abs(targetPos.Elevation - antennaPos.Elevation) < 0.2 && ...
                abs(targetPos.Polarization - antennaPos.Polarization) < 0.2
            msg = sprintf('O conjunto antena/LNB "%s" parece já estar apontado para a posição correta.', LNBName);
        else
            msg = sprintf('O conjunto antena/LNB "%s" parece não estar apontado para a posição correta.', LNBName);
        end
        msg = sprintf(['<font style="font-size:11;">%s\n\nPOSIÇÃO ATUAL:'            ...
                       '\n• <span style="color: #808080;">Azimute</span>: %.3fº'     ...
                       '\n• <span style="color: #808080;">Elevação</span>: %.3fº'    ...
                       '\n• <span style="color: #808080;">Polarização</span>: %.3fº' ...
                       '\n\nPOSIÇÃO CONFIGURADA:'                                    ...
                       '\n• <span style="color: #808080;">Azimute</span>: %.3fº'     ...
                       '\n• <span style="color: #808080;">Elevação</span>: %.3fº'    ...
                       '\n• <span style="color: #808080;">Polarização</span>: %.3fº' ...
                       '\n\nDeseja conduzir o apontamento do conjunto antena/LNB agora?</font>'], ...
                       msg, antennaPos.Azimuth, antennaPos.Elevation, antennaPos.Polarization,    ...
                       targetPos.Azimuth, targetPos.Elevation, targetPos.Polarization);
        selection = uiconfirm(app.UIFigure, msg, 'appColeta', 'Interpreter', 'html', 'Options', {'Sim', 'Não'}, 'DefaultOption', 1, 'CancelOption', 2, 'Icon', 'question');
        
        if selection == "Sim"
            % abrir app de apontamento...
            return
        end
    end
end


%-------------------------------------------------------------------------%
function [AntennaInfo, AntennaMetaData] = AntennaExtract(Script, idx1, AntennaMetaData)
    AntennaName     = Script.Band(idx1).instrAntenna;
    AntennaMetaData = rmfield(AntennaMetaData, 'Installation');
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

    AntennaMetaData.Azimuth      = str2double(extractBefore(AntennaMetaData.Azimuth,      'º'));
    AntennaMetaData.Elevation    = str2double(extractBefore(AntennaMetaData.Elevation,    'º'));
    AntennaMetaData.Polarization = str2double(extractBefore(AntennaMetaData.Polarization, 'º'));
end
