function treeBuilding(app, Selection)            
    delete(app.Tree.Children);
    
    if app.Table.Selection
        idx = app.Table.Selection;
        for ii = 1:numel(app.specObj(idx).Task.Script.Band)
            Antenna = app.specObj(idx).Task.Script.Band(ii).instrAntenna;
            if ~isempty(Antenna)
                Antenna = sprintf('(%s)', Antenna);
            end

            uitreenode(app.Tree, 'Text', sprintf('ID %d: %.3f - %.3f MHz %s',                            ...
                                                 app.specObj(idx).Task.Script.Band(ii).ID,               ...
                                                 app.specObj(idx).Task.Script.Band(ii).FreqStart / 1e+6, ...
                                                 app.specObj(idx).Task.Script.Band(ii).FreqStop  / 1e+6, ...
                                                 Antenna),                                               ...
                                 'NodeData', ii);
        end
        
        app.Tree.SelectedNodes = app.Tree.Children(Selection);
    end
    drawnow nocallbacks
end