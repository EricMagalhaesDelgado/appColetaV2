function errorCount(app, idx)

    if idx && app.specObj(idx).ErrorCount
        set(app.errorCount_txt, 'Text', string(app.specObj(idx).ErrorCount), 'Visible', 'on')
        app.errorCount_img.Visible = 'on';
    else
        set(app.errorCount_txt, 'Text', '0', 'Visible', 'off')
        app.errorCount_img.Visible = 'off';
    end
    drawnow
end