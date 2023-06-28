function maxHold(app, ii, jj, xArray, newArray)

    switch app.specObj(ii).Status
        case 'Em andamento'
            app.line_MaxHold = plot(app.axes1, xArray, newArray, 'Tag', 'MaxHold', 'Color', app.General.Colors(3,:));
            
        otherwise
            idx = find(all(app.specObj(ii).Band(jj).Waterfall.Matrix == -1000, 2), 1);
            if isempty(idx)
                idx = app.specObj(ii).Band(jj).Waterfall.Depth+1;
            end

            app.line_MaxHold = plot(app.axes1, xArray, max(app.specObj(ii).Band(jj).Waterfall.Matrix(1:idx-1,:), [], 1), 'Tag', 'MaxHold', 'Color', app.General.Colors(3,:));
    end

end