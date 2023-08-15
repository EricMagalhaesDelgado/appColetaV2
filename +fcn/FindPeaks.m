function peaksTable = FindPeaks(specObj, idx, smoothedArray, validationArray)

    peaksTable = [];

    Attributes = specObj.Band(idx).Mask.FindPeaks;
    FreqStart  = specObj.Task.Script.Band(idx).FreqStart;
    FreqStop   = specObj.Task.Script.Band(idx).FreqStop;
    DataPoints = numel(smoothedArray);

    % Frequency = aCoef * Index + bCoef
    aCoef = (FreqStop-FreqStart)/(DataPoints-1);
    bCoef = FreqStart-aCoef;

    % Findpeaks
    idxRange = matlab.findpeaks(smoothedArray, 'MinPeakProminence', Attributes.Proeminence,             ...
                                               'MinPeakDistance',   1000 * Attributes.Distance / aCoef, ...
                                               'MinPeakWidth',      1000 * Attributes.BW / aCoef,       ...
                                               'SortStr',           'descend');
    for ii = height(idxRange):-1:1
        idxValidation = floor(idxRange(ii,1)):ceil(idxRange(ii,2));
        if all(~validationArray(idxValidation))
            idxRange(ii,:) = [];
        end
    end

    if ~isempty(idxRange)
        idxFreq    = mean(idxRange, 2);
        FreqCenter = (aCoef .* idxFreq + bCoef) ./ 1e+6;                    % Em MHz
        BandWidth  = (idxRange(:,2)-idxRange(:,1)) * aCoef / 1e+3;          % Em kHz

        peaksTable = table(round(idxFreq), FreqCenter, BandWidth, 'VariableNames', {'idx', 'FreqCenter', 'BW'});
    end
end