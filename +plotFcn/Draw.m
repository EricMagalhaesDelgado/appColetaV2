function Draw(app, ii, jj)

    idx = app.specObj(ii).Band(jj).Waterfall.idx;
    newArray = app.specObj(ii).Band(jj).Waterfall.Matrix(idx,:);

    if isempty(app.line_ClrWrite)
        % Plot Layout
        plotFcn.Layout(app)

        % xArray
        FreqStart = app.specObj(ii).Task.Script.Band(jj).FreqStart / 1e+6;
        FreqStop  = app.specObj(ii).Task.Script.Band(jj).FreqStop  / 1e+6;
        LevelUnit = app.specObj(ii).Task.Script.Band(jj).instrLevelUnit;
        xArray    = linspace(FreqStart, FreqStop, app.specObj(ii).Band(jj).DataPoints);

        % General settings
        [~, strUnit] = class.Constants.yAxisUpLimit(app.specObj(ii).Task.Script.Band(jj).instrLevelUnit);

        [downYLim, upYLim] = bounds(newArray);
        downYLim  = downYLim - mod(downYLim, 10);
        upYLim    = upYLim + 10 - mod(upYLim, 10);        
        diffArray = upYLim - downYLim;

        if diffArray < class.Constants.yMinLimRange
            upYLim = downYLim + class.Constants.yMinLimRange;

        elseif diffArray > class.Constants.yMaxLimRange
            downYLim = upYLim - class.Constants.yMaxLimRange;
        end

        colormap(app.axes2, app.General.Waterfall.Colormap);
        set(app.axes2, XLim=[FreqStart, FreqStop], YLim=[1, app.specObj(ii).Band(jj).Waterfall.Depth], View=[0, 90], CLim=[downYLim, upYLim]);
        ylabel(app.axes2, 'Amostras');

        if ~app.Button_MaskPlot.Value
            % ORDINARY PLOT (SPECTRUM + MASK THRESHOLD)
            ylabel(app.axes1, sprintf('Nível (%s)', strUnit));
            set(app.axes1, XLim=[FreqStart, FreqStop], YLim=[downYLim, upYLim], YScale='linear')

            % Mask threshold
            if ~isempty(app.specObj(ii).Band(jj).Mask)
                maskTable = app.specObj(ii).Band(jj).Mask.Table;
                for kk = 1:height(maskTable)
                    newObj = plot(app.axes1, [maskTable.FreqStart(kk), maskTable.FreqStop(kk)], [maskTable.THR(kk), maskTable.THR(kk)], 'red', ...
                                  Marker='o', MarkerEdgeColor='red', MarkerFaceColor='red', MarkerSize=4, Tag='Mask');
                    plotFcn.DataTipModel(newObj, LevelUnit)
                end
            end
    
            % ClearWrite, MinHold, Average and MaxHold
            app.line_ClrWrite = plot(app.axes1, xArray, newArray, Color=app.General.Colors(4,:), Tag='ClrWrite');
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

            if app.Button_peakExcursion.Value
                plotFcn.peakExcursion(app, ii, jj, newArray)
            end

        else
            % MASK PLOT
            ylabel(app.axes1, 'Rompimento (%)');
            set(app.axes1, XLim=[FreqStart, FreqStop], YLim=[.1, 100], YScale='log')

            KK = 100/app.specObj(ii).Band(jj).Mask.Validations;
            app.line_ClrWrite = plot(app.axes1, xArray, KK .* app.specObj(ii).Band(jj).Mask.BrokenArray, Color=app.General.Colors(4,:), Tag='MaskPlot');
            plotFcn.DataTipModel(app.line_ClrWrite, '%%')
        end

        % Waterfall
        app.surface_WFall = image(app.axes2, xArray, 1:app.specObj(ii).Band(jj).Waterfall.Depth, circshift(app.specObj(ii).Band(jj).Waterfall.Matrix, -idx), CDataMapping='scaled', Tag='Waterfall');
        plotFcn.DataTipModel(app.surface_WFall, LevelUnit)

    else
        if ~app.Button_MaskPlot.Value
            % ORDINARY PLOT (SPECTRUM + MASK THRESHOLD)
            app.line_ClrWrite.YData = newArray;
            
            if ~isempty(app.line_MinHold);  app.line_MinHold.YData = min(app.line_MinHold.YData, newArray);
            end
            if ~isempty(app.line_Average);  app.line_Average.YData = ((app.General.Integration.Trace-1)*app.line_Average.YData + newArray) / app.General.Integration.Trace;
            end
            if ~isempty(app.line_MaxHold);  app.line_MaxHold.YData = max(app.line_MaxHold.YData, newArray);
            end
            if ~isempty(app.peakExcursion); plotFcn.peakExcursion(app, ii, jj, newArray);
            end

        else
            % MASK PLOT
            KK = 100/app.specObj(ii).Band(jj).Mask.Validations;
            app.line_ClrWrite.YData = KK .* app.specObj(ii).Band(jj).Mask.BrokenArray;
        end
        
        app.surface_WFall.CData = circshift(app.specObj(ii).Band(jj).Waterfall.Matrix, -idx);
    end

    switch app.plotLayout
        case 2
            set(app.axes2.Children, 'Visible', 'off')
        case 3
            set(app.axes1.Children, 'Visible', 'off')
    end
    % drawnow
end