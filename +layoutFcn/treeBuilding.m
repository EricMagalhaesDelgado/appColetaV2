function treeBuilding(app, Selection)            
    delete(app.Tree.Children);
    
    if app.Table.Selection
        idx = app.Table.Selection;
        for ii = 1:numel(app.specObj(idx).Band)
            Antenna = app.specObj(idx).taskObj.General.Task.Band(ii).instrAntenna;
            if ~isempty(Antenna)
                Antenna = sprintf('(%s)', Antenna);
            end

            uitreenode(app.Tree, 'Text', sprintf('ID %d: %.3f - %.3f MHz %s',                                     ...
                                                 app.specObj(idx).taskObj.General.Task.Band(ii).ThreadID,         ...
                                                 app.specObj(idx).taskObj.General.Task.Band(ii).FreqStart / 1e+6, ...
                                                 app.specObj(idx).taskObj.General.Task.Band(ii).FreqStop  / 1e+6, ...
                                                 Antenna),                                                        ...
                                 'NodeData', ii);
        end
        
        app.Tree.SelectedNodes = app.Tree.Children(Selection);
%         focus(app.Tree)
    end
    drawnow nocallbacks
end