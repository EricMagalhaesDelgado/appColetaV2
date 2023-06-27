function tableBuilding(app, idx)
    tempTable = table('Size', [0, 7],                                                                          ...
                      'VariableTypes', {'double', 'string', 'string', 'string', 'string', 'string', 'string'}, ...
                      'VariableNames', {'ID', 'Name', 'Receiver', 'Created', 'BeginTime', 'EndTime', 'Status'});

    
    for ii = 1:numel(app.specObj)
        EndTime = '-';
        if ~isnat(app.specObj(ii).Observation.EndTime)
            EndTime = datestr(app.specObj(ii).Observation.EndTime, 'dd/mm/yyyy HH:MM:SS');
        end

        tempTable(end+1,:) = {app.specObj(ii).ID,                        ...
                              app.specObj(ii).taskObj.General.Task.Name, ...
                              app.specObj(ii).hReceiver.UserData.IDN,    ...
                              app.specObj(ii).Observation.Created,       ...
                              datestr(app.specObj(ii).Observation.BeginTime, 'dd/mm/yyyy HH:MM:SS'), ...
                              EndTime,                                   ...
                              app.specObj(ii).Status};
    end

    app.Table.Data = tempTable;
    app.Table.Selection = max([1, idx]);

    if ~isempty(app.Tree.SelectedNodes); layoutFcn.treeBuilding(app, app.Tree.SelectedNodes.NodeData)
    else;                                layoutFcn.treeBuilding(app, 1)
    end
    drawnow
end