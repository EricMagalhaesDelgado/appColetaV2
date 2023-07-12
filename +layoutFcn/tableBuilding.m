function tableBuilding(app, idx)
    tempTable = table('Size', [0, 7],                                                                          ...
                      'VariableTypes', {'double', 'string', 'string', 'string', 'string', 'string', 'string'}, ...
                      'VariableNames', {'ID', 'Name', 'Receiver', 'Created', 'BeginTime', 'EndTime', 'Status'});
    tempTable.Properties.UserData = char(matlab.lang.internal.uuid());
    
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

    if all(~strcmp(tempTable.Status, "Em andamento"))
        app.Flag_running = 0;
    end

    if height(tempTable)
        app.Table.Data = tempTable;
        app.Table.Selection = max([1, idx]);

        app.Button_Edit.Enable = 1;
        app.Button_Play.Enable = 1;
        app.Button_Del.Enable  = 1;
        app.Button_log.Enable  = 1;
    else
        app.Table.Data = table;
        app.Table.Selection = 0;

        app.Button_Edit.Enable = 0;
        app.Button_Play.Enable = 0;
        app.Button_Del.Enable  = 0;
        app.Button_log.Enable  = 0;
    end
    layoutFcn.errorCount(app, app.Table.Selection)
    drawnow nocallbacks

    if ~isempty(app.Tree.SelectedNodes); layoutFcn.treeBuilding(app, app.Tree.SelectedNodes.NodeData)
    else;                                layoutFcn.treeBuilding(app, 1)
    end
end