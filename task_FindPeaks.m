function Peaks = task_FindPeaks(specObj, idx, smoothedArray, Attributes)

    FreqStart  = specObj.taskObj.General.Task.Band(idx).FreqStart;
    FreqStop   = specObj.taskObj.General.Task.Band(idx).FreqStop;
    DataPoints = numel(smoothedArray);

    % Frequency = aCoef * Index + bCoef
    aCoef = (FreqStop-FreqStart)/(DataPoints-1);
    bCoef = FreqStart-aCoef;

    delete(findobj(Type='Line', Tag='HalfProminenceWidth'))
    drawnow nocallbacks

    tempFig = figure;
    findpeaks(smoothedArray, 'NPeaks',            Attributes.NPeaks,                  ...
                             'MinPeakHeight',     Attributes.THR,                     ...
                             'MinPeakProminence', Attributes.Proeminence,             ...
                             'MinPeakDistance',   1000 * Attributes.Distance / aCoef, ...
                             'MinPeakWidth',      1000 * Attributes.BW / aCoef,       ...
                             'SortStr',           'descend',                          ...
                             'Annotate',          'extents');
             

    h = findobj(Type='Line', Tag='HalfProminenceWidth');
    if ~isempty(h)
        for ii = 1:numel(h.XData)/3
            newIndex(ii,1)    = round(mean(h.XData(3*(ii-1)+1:3*(ii-1)+2)));
            newBW_Index(ii,1) = diff(h.XData(3*(ii-1)+1:3*(ii-1)+2));
        end

        newFreq = (aCoef .* newIndex + bCoef) ./ 1e+6;                                                  % Em MHz
        newBW   = newBW_Index * aCoef / 1e+6;                                                           % Em MHz

        Peaks = jsonencode(table(newFreq, newBW, 'VariableNames', {'Frequency', 'BW'}));
    else
        Peaks = '';
    end
    delete(tempFig)
    
end