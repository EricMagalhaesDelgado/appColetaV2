classdef (Abstract) Constants

    properties (Constant)
        stationName     = 'EMSat'

        windowSize      = [1244, 660]
        windowMinSize   = [ 640, 580]

        gps2locAPI      = 'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=<Latitude>&longitude=<Longitude>&localityLanguage=pt'
        gps2loc_City    = 'city'
        gps2loc_Unit    = 'principalSubdivisionCode'

        yMinLimRange    = 80                                                % Minimum y-Axis limit range
        yMaxLimRange    = 100                                               % Maximum y-Axis limit range

        switchTimes     = 3                                                 % Maximum attempts to switch the antenna
        switchPause     = 0.050                                             % Pause in seconds to ask antenna's name after its switch attempt (must be greater than 40ms)
        antACUPause     = 1                                                 % Pause in seconds to wait for ACU messages (ACU could be locked by Compass!)

        Timeout         = 10                                                % Maximum time in seconds to extract valid info from receiver
        udpTimeout      = 3                                                 % Maximum time in seconds to receive a specific number of datagrams 
        idnTimeout      = 1                                                 % Maximum time in seconds to extract IDN info from receiver
        gpsTimeout      = 1                                                 % Maximum time in seconds to receive bytes from GPS
        fileVersion     = 'RFlookBin v.2/1'

        checkIP         = 'http://checkip.dyndns.org'

        udpDefaultPort  = 24001                                             % See "EB500Lib.json"
        gpsDefaultPort  = {'COM1', 24002}                                   % See "GPSLib.json"

        tcpServerStatus = 0
        tcpServerIP     = '172.24.5.159'                                    % OpenVPN address
        tcpServerPort   = 8910

        errorTimeTrigger     = 60                                           % Minimum time in seconds to change the status of the task ("In progress" to "Error") in case of a persistent error
        errorCountTrigger    = 10                                           % ~mod(errorCount, errorCountTrigger) defines instants in which app will try to reconnect to the receiver
        errorGPSCountTrigger = 100                                          % ~mod(errorCount, errorCountTrigger) defines instants in which app will try to reconnect to the GPS
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