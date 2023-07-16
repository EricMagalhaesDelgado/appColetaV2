function errorCount(app, idx)

    if idx && app.specObj(idx).Error.Count
        set(app.errorCount_txt, 'Text', string(app.specObj(idx).Error.Count), 'Visible', 'on')
        app.errorCount_img.Visible = 'on';
    else
        set(app.errorCount_txt, 'Text', '0', 'Visible', 'off')
        app.errorCount_img.Visible = 'off';
    end
    drawnow
end