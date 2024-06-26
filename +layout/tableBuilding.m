function tableBuilding(app, idx)
    tempTable = table('Size', [0, 7],                                                                          ...
                      'VariableTypes', {'double', 'string', 'string', 'string', 'string', 'string', 'string'}, ...
                      'VariableNames', {'ID', 'Name', 'Receiver', 'Created', 'BeginTime', 'EndTime', 'Status'});
    tempTable.Properties.UserData = char(matlab.lang.internal.uuid());
    
    for ii = 1:numel(app.specObj)
        EndTime = '-';
        if ~isnat(app.specObj(ii).Observation.EndTime) && ~isinf(app.specObj(ii).Observation.EndTime)
            EndTime = datestr(app.specObj(ii).Observation.EndTime, 'dd/mm/yyyy HH:MM:SS');
        end

        tempTable(end+1,:) = {app.specObj(ii).ID,                        ...
                              app.specObj(ii).Task.Script.Name,          ...
                              app.specObj(ii).IDN,                       ...
                              app.specObj(ii).Observation.Created,       ...
                              datestr(app.specObj(ii).Observation.BeginTime, 'dd/mm/yyyy HH:MM:SS'), ...
                              EndTime,                                   ...
                              app.specObj(ii).Status};
    end    

    if all(~strcmp(tempTable.Status, "Em andamento"))
        app.Flag_running = 0;
    end

    if height(tempTable)
        app.Table.Data      = tempTable;
        app.Table.Selection = max([1, idx]);
        app.Table.UserData  = app.Table.Selection;

        app.task_ButtonEdit.Enable = 1;
        app.task_ButtonPlay.Enable = 1;
        app.task_ButtonDel.Enable  = 1;
        app.task_ButtonLOG.Enable  = 1;
    else
        app.Table.Data     = table;
        app.Table.UserData = [];

        app.task_ButtonEdit.Enable = 0;
        app.task_ButtonPlay.Enable = 0;
        app.task_ButtonDel.Enable  = 0;
        app.task_ButtonLOG.Enable  = 0;
    end
    layout.errorCount(app, app.Table.Selection)
    drawnow nocallbacks

    if ~isempty(app.Tree.SelectedNodes); layout.treeBuilding(app, app.Tree.SelectedNodes.NodeData)
    else;                                layout.treeBuilding(app, 1)
    end
end