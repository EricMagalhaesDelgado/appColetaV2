function antennaSwitch        
LNBName     = Script.Band(ii).instrAntenna;
        antennaName = extractBefore(LNBName, ' ');

        % PASSO 1: comutação para a porta correta da matriz.
        errorMsg = EMSatObj.MatrixSwitch(LNBName);
        if ~isempty(errorMsg)
            error(errorMsg)
        end
end