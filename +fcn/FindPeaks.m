function peaksTable = FindPeaks(specObj, idx, smoothedArray, validationArray, Attributes)

    peaksTable = [];

    FreqStart  = specObj.Task.Script.Band(idx).FreqStart;
    FreqStop   = specObj.Task.Script.Band(idx).FreqStop;
    DataPoints = numel(smoothedArray);

    % Frequency = aCoef * Index + bCoef
    aCoef = (FreqStop-FreqStart)/(DataPoints-1);
    bCoef = FreqStart-aCoef;

    tempFig = figure('Visible', 'off');
    matlab.findpeaks_R2021b(smoothedArray, 'MinPeakProminence', Attributes.Proeminence,             ...
                                           'MinPeakDistance',   1000 * Attributes.Distance / aCoef, ...
                                           'MinPeakWidth',      1000 * Attributes.BW / aCoef,       ...
                                           'SortStr',           'descend',                          ...
                                           'Annotate',          'extents');             

    h = findobj(tempFig, Tag='HalfProminenceWidth');
    if ~isempty(h)
        idxFreq = [];
        idxBW   = [];

        for ii = 1:numel(h.XData)/3
            idxData  = h.XData(3*(ii-1)+1:3*(ii-1)+2);
            idxRange = floor(idxData(1)):ceil(idxData(2));

            if any(validationArray(idxRange), 'all')
                idxFreq(end+1,1) = round(mean(idxData));
                idxBW(end+1,1)   = diff(idxData);
            end
        end

        if ~isempty(idxFreq)
            FreqCenter = (aCoef .* idxFreq + bCoef) ./ 1e+6;                                             % Em MHz
            BandWidth  = idxBW .* aCoef ./ 1e+3;                                                         % Em kHz
    
            peaksTable = table(idxFreq, FreqCenter, BandWidth, 'VariableNames', {'idx', 'FreqCenter', 'BW'});
        end
    end
    delete(tempFig)
    
end