function htmlCode = metadataInfo(taskMetaData)
    d = class.Constants.english2portuguese();

    htmlCode = '<font style="font-family: Helvetica; font-size: 10px;">';
    for ii = 1:numel(taskMetaData)
        htmlCode = sprintf('%s<b>%s</b>', htmlCode, taskMetaData(ii).group);
        
        structFields = fields(taskMetaData(ii).value);    
        for jj = 1:numel(structFields)
            Field = structFields{jj};
            Value = taskMetaData(ii).value.(Field);
            if isnumeric(Value)
                Value = string(Value);
            end
    
            if isKey(d, Field)
                Field = d(Field);
            end
            
            htmlCode = sprintf('%s\n• <span style="color: #808080;">%s:</span> %s', htmlCode, Field, Value);
        end
        htmlCode = sprintf('%s\n\n', htmlCode);
    end
    htmlCode = replace(sprintf('%s</font>', strtrim(htmlCode)), newline, '<br>');
end