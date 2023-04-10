cSwitch = table('Size', [32, 3] ,                        ...
                'VariableNames', {'port', 'set', 'get'}, ...
                'VariableTypes', {'double', 'string', 'string'});

sTerminator = {'[', '\', ']', '^', '_', '`', 'a', 'b', 'c'};
for ii = 1:32
    Port = num2str(ii);
    if numel(Port) == 1; Port = "0" + Port;
    end
    nTerminator   = mod(ii-1,9);
    cSwitch(ii,:) = {ii, sprintf("{*zs,012,0%s}%.0f", Port, nTerminator), sprintf("{zBs?012,0%s}%s", Port, sTerminator{nTerminator+1})};
end
cSwitch