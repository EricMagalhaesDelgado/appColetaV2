classdef (Abstract) Constants

    properties (Constant)
        windowSize     = [1244, 660]
        windowMinSize  = [ 640, 580]

        gps2locAPI     = 'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=<Latitude>&longitude=<Longitude>&localityLanguage=pt'
        gps2loc_City   = 'city'
        gps2loc_Unit   = 'principalSubdivisionCode'

        yMinLimRange   = 80                                                 % Minimum y-Axis limit range
        yMaxLimRange   = 100                                                % Maximum y-Axis limit range

        switchTimes    = 3                                                  % Maximum attempts to switch the antenna
        switchPause    = 0.050                                              % Pause in seconds to ask antenna's name after its switch attempt (must be greater than 40ms)
        antACUPause    = 1                                                  % Pause in seconds to wait for ACU messages (ACU could be locked by Compass!)

        errorTrigger   = 10                                                 % Maximum error count before change the status of the task ("In progress" to "Error")

        Timeout        = 10                                                 % Maximum time in seconds to extract valid info from receiver
        idnTimeout     = 1                                                  % Maximum time in seconds to extract IDN info from receiver
        gpsTimeout     = 1                                                  % Maximum time in seconds to receive bytes from GPS
        fileVersion    = 'RFlookBin v.2/1'

        checkIP        = 'http://checkip.dyndns.org'

        tcpServerPort  = 24000
        recDefaultPort = 24001                                              % See "EB500Lib.json"
        gpsDefaultPort = {'COM1', 24002}                                    % See "GPSLib.json"
    end

    methods (Static = true)
        function [upYLim, strUnit] = yAxisUpLimit(Unit)
            switch lower(Unit)
                case 'dbm';                    upYLim = -20; strUnit = 'dBm';
                case {'dbµv', 'dbμv', 'dbuv'}; upYLim =  87; strUnit = 'dBµV';
                case {'dbµv/m', 'dbμv/m'};     upYLim = 100; strUnit = 'dBµV/m';
            end
        end
    end

end