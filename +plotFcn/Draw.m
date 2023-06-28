function Draw(app, ii, jj)

    idx1 = app.specObj(ii).Band(jj).Waterfall.idx;
    idx2 = [idx1+1:app.specObj(ii).Band(jj).Waterfall.Depth, 1:idx1];
    newArray = app.specObj(ii).Band(jj).Waterfall.Matrix(idx1,:);

    if isempty(app.line_ClrWrite)
        % Plot Layout
        plotFcn.Layout(app)

        % xArray
        FreqStart = app.specObj(ii).taskObj.General.Task.Band(jj).FreqStart / 1e+6;
        FreqStop  = app.specObj(ii).taskObj.General.Task.Band(jj).FreqStop  / 1e+6;
        LevelUnit = app.specObj(ii).taskObj.General.Task.Band(jj).instrLevelUnit;
        xArray    = linspace(FreqStart, FreqStop, app.specObj(ii).Band(jj).DataPoints);
        
        % Mask line
        if ~isempty(app.specObj(ii).Band(jj).Mask)
            maskTable = app.specObj(ii).Band(jj).Mask.Table;
            for ii = 1:height(maskTable)
                newObj = plot(app.axes1, [maskTable.FreqStart(ii), maskTable.FreqStop(ii)], [maskTable.THR(ii), maskTable.THR(ii)], 'red', ...
                              'Marker', 'o', 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'MarkerSize', 4, 'Tag', 'Mask');
                plotFcn.DataTipModel(newObj, LevelUnit)
            end
        end

        % General settings
        [upYLim, strUnit] = class.Constants.yAxisUpLimit('dBm');
        downYLim = min(newArray) - mod(min(newArray), 10);
        if diff([downYLim, upYLim]) < class.Constants.yMinLimRange
            upYLim = downYLim + class.Constants.yMinLimRange;
        end
        set(app.axes1, XLim=[FreqStart, FreqStop], YLim=[downYLim, upYLim])

        if diff([downYLim, upYLim]) > class.Constants.yMaxLimRange
            downYLim = downYLim + diff([downYLim, upYLim]) - class.Constants.yMaxLimRange;
        end
        colormap(app.axes2, app.General.Waterfall.Colormap);
        set(app.axes2, XLim=[FreqStart, FreqStop], YLim=[1, app.specObj(ii).Band(jj).Waterfall.Depth], View=[0, 90], CLim=[downYLim, upYLim]);

        ylabel(app.axes1, sprintf('Nível (%s)', strUnit));
        ylabel(app.axes2, 'Amostras');

        % Main lines
        app.line_ClrWrite = plot(app.axes1, xArray, newArray,    'Tag', 'ClrWrite', 'Color', app.General.Colors(4,:));
        plotFcn.DataTipModel(app.line_ClrWrite, LevelUnit)
        
        if app.Button_MinHold.Value
            plotFcn.minHold(app, ii, jj, xArray, newArray)
            plotFcn.DataTipModel(app.line_MinHold, LevelUnit)
        end

        if app.Button_Average.Value
            plotFcn.Average(app, ii, jj, xArray, newArray)
            plotFcn.DataTipModel(app.line_Average, LevelUnit)
        end

        if app.Button_MaxHold.Value
            plotFcn.maxHold(app, ii, jj, xArray, newArray)
            plotFcn.DataTipModel(app.line_MaxHold, LevelUnit)
        end

        % Waterfall
        app.surface_WFall = image(app.axes2, xArray, 1:app.specObj(ii).Band(jj).Waterfall.Depth, app.specObj(ii).Band(jj).Waterfall.Matrix(idx2,:), 'CDataMapping', 'scaled', 'Tag', 'Waterfall');
        plotFcn.DataTipModel(app.surface_WFall, LevelUnit)

    else
        app.line_ClrWrite.YData = newArray;
        if ~isempty(app.line_MinHold);  app.line_MinHold.YData  = min(app.line_MinHold.YData, newArray);
        end
        if ~isempty(app.line_Average);  app.line_Average.YData  = ((app.General.Integration.Trace-1)*app.line_Average.YData + newArray) / app.General.Integration.Trace;
        end
        if ~isempty(app.line_MaxHold);  app.line_MaxHold.YData  = max(app.line_MaxHold.YData, newArray);
        end
        
        app.surface_WFall.CData = app.specObj(ii).Band(jj).Waterfall.Matrix(idx2,:);
    end

    switch app.plotLayout
        case 2
            set(app.axes2.Children, Visible=0)
        case 3
            set(app.axes1.Children, Visible=0)
    end
    drawnow

end