function lastMaskValidation(app, brokeTrigger, ii, jj)
    if brokeTrigger
        Validations = app.specObj(ii).Band(jj).Mask.Validations;
        BrokenCount = app.specObj(ii).Band(jj).Mask.BrokenCount;

        if ~isempty(app.specObj(ii).Band(jj).Mask.MainPeaks)
            FreqCenter  = app.specObj(ii).Band(jj).Mask.MainPeaks.FreqCenter(1);
            BandWidth   = app.specObj(ii).Band(jj).Mask.MainPeaks.BW(1);
            dTimeStamp  = datestr(app.specObj(ii).Band(jj).Mask.TimeStamp, 'dd/mm/yyyy');
            hTimeStamp  = datestr(app.specObj(ii).Band(jj).Mask.TimeStamp, 'HH:MM:SS');
        else
            FreqCenter  = -1;
            BandWidth   = -1;
            dTimeStamp  = 'dd/mm/yyyy';
            hTimeStamp  = 'HH:MM:SS';
        end

        app.lastMask_text.Text = sprintf(['<b style="color: #a2142f; font-size: 14;">%.0f</b> \nVALIDAÇÕES \n'    ...
                                          '<b style="color: #a2142f; font-size: 14;">%.0f</b> \nROMPIMENTOS \n\n' ...
                                          '<font style="color: #a2142f;">%.3f MHz \n⌂ %.3f kHz</font> \n\n%s \n%s '], ...
                                          Validations, BrokenCount, FreqCenter, BandWidth, dTimeStamp, hTimeStamp);
    else
        app.lastMask_text.Text = replace(app.lastMask_text.Text, [extractBefore(app.lastMask_text.Text, 'VALIDAÇÕES') 'VALIDAÇÕES'], ...
            sprintf('<b style="color: #a2142f; font-size: 14;">%.0f</b> \nVALIDAÇÕES', app.specObj(ii).Band(jj).Mask.Validations));
    end
end