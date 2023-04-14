function maskArray = mask_ArrayConstructor(maskInfo, Band)
    
    % Limiar igual a 1000 (inatingível)
    maskArray = ones(1, Band.instrDataPoints) * 1e+3;

    freq = linspace(Band.FreqStart /1e+6,  ...
                    Band.FreqStop  / 1e+6, ...
                    Band.instrDataPoints);
    
    maskTable = mask_TableConstructor(maskInfo);
    
    % Subtituição do limiar inatingível pelo threshold da faixa
    for ii = 1:height(maskTable)
        maskArray(freq >= maskTable(ii,1) & freq <= maskTable(ii,2)) = maskTable(ii,3);
    end             
     
end

function maskTable = mask_TableConstructor(maskInfo)
    
    if isempty(maskInfo.unmasked)
        if isempty(maskInfo.THR)
            maskTable = [];
        else
            maskTable = [maskInfo.FreqStart, maskInfo.FreqStop, maskInfo.THR];
        end
        
    else
        FreqStart = [maskInfo.FreqStart; maskInfo.unmasked.Frequency + ceil(maskInfo.unmasked.BW/2)];
        FreqStop  = [maskInfo.unmasked.Frequency - ceil(maskInfo.unmasked.BW/2); maskInfo.FreqStop];
        maskTable = [FreqStart, FreqStop, maskInfo.THR];
    end
    
end