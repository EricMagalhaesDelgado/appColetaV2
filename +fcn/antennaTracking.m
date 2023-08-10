function targetPos = antennaTracking(app, EMSatObj, antennaMetaData)

    for ii = 1:numel(antennaMetaData)
        targetPos   = fcn.antennaParser(antennaMetaData(ii), antennaMetaData(ii).Name);
        antennaName = targetPos.Name;

        switch targetPos.TrackingMode
            case {'Target', 'LookAngles'}
                if isfield(targetPos, 'Target')
                    [tempTargetPos,  errorMsg] = EMSatObj.TargetPositionGET(antennaName, targetPos.Target);
                    if ~isempty(errorMsg)
                        error(errorMsg)
                    end

                    targetPos.Azimuth      = tempTargetPos.Azimuth;
                    targetPos.Elevation    = tempTargetPos.Elevation;
                    targetPos.Polarization = tempTargetPos.Polarization;
                end
        
                [antennaPos, errorMsg] = EMSatObj.AntennaPositionGET(antennaName);
                if ~isempty(errorMsg)
                    error(errorMsg)
                end
        
                if abs(targetPos.Azimuth      - antennaPos.Azimuth)      < 0.2 && ...
                   abs(targetPos.Elevation    - antennaPos.Elevation)    < 0.2 && ...
                   abs(targetPos.Polarization - antennaPos.Polarization) < 0.2
                    msg = sprintf('O conjunto antena/LNB "%s" parece já estar apontado para a posição correta.',  antennaName);
                else
                    msg = sprintf('O conjunto antena/LNB "%s" parece não estar apontado para a posição correta.', antennaName);
                end
                msg = sprintf(['<font style="font-size:11;">%s\n\nPosição atual:'            ...
                               '\n• <span style="color: #808080;">Azimute</span>: %.3fº'     ...
                               '\n• <span style="color: #808080;">Elevação</span>: %.3fº'    ...
                               '\n• <span style="color: #808080;">Polarização</span>: %.3fº' ...
                               '\n\nPosição configurada:'                                    ...
                               '\n• <span style="color: #808080;">Azimute</span>: %.3fº'     ...
                               '\n• <span style="color: #808080;">Elevação</span>: %.3fº'    ...
                               '\n• <span style="color: #808080;">Polarização</span>: %.3fº' ...
                               '\n\nDeseja cancelar a operação de inclusão da tarefa, evitando o apontamento automático do conjunto antena/LNB?</font>'], ...
                               msg, antennaPos.Azimuth, antennaPos.Elevation, antennaPos.Polarization,    ...
                               targetPos.Azimuth, targetPos.Elevation, targetPos.Polarization);

                selection = uiconfirm(app.UIFigure, msg, 'appColeta', 'Interpreter', 'html', 'Options', {'Sim', 'Não'}, 'DefaultOption', 2, 'CancelOption', 2, 'Icon', 'question');                
                if selection == "Sim"
                    error('Operação cancelada pelo usuário.')
                end
                
                auxApp.winTracking(app, antennaPos, targetPos)

            case 'Manual'
                msg = sprintf(['<font style="font-size:11;">O apontamento do conjunto antena/LNB "%s" deverá ser realizado manualmente.'                                    ...
                               '\n\nDeseja cancelar a operação de inclusão da tarefa, reconfigurando esse apontamento para automático ("Target" ou "LookAngles")?</font>'], ...
                               antennaName);

                selection = uiconfirm(app.UIFigure, msg, 'appColeta', 'Interpreter', 'html', 'Options', {'Sim', 'Não'}, 'DefaultOption', 2, 'CancelOption', 2, 'Icon', 'question');                
                if selection == "Sim"
                    error('Operação cancelada para reconfiguração do tipo de apontamento do conjunto antena/LNB "%s".', antennaName)
                end
        end
    end
end