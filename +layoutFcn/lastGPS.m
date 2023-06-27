function lastGPS(app, gpsData)
    switch gpsData.Status
        case  1; newColor = [0.47,0.67,0.19];
        case  0; newColor = [0.64,0.08,0.18];
        case -1; newColor = [0.50,0.50,0.50];
    end

    app.lastGPS_text.Text   = sprintf(['<b style="color: #a2142f; font-size: 14;">%.3f</b> LAT \n'   ...
                                       '<b style="color: #a2142f; font-size: 14;">%.3f</b> LON \n\n' ...
                                       '%s \n%s '], gpsData.Latitude, gpsData.Longitude,             ...
                                                    extractBefore(gpsData.TimeStamp, ' '),           ...
                                                    extractAfter(gpsData.TimeStamp, ' '));
    app.lastGPS_color.Color = newColor;
end