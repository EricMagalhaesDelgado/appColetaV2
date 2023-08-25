function StartUp(app)

    cla(app.axes1)
    cla(app.axes2)

    app.line_ClrWrite = [];
    app.line_MinHold  = [];
    app.line_Average  = [];
    app.line_MaxHold  = [];
    app.peakExcursion = [];
    app.surface_WFall = [];
    
end