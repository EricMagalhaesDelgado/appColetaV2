classdef (Abstract) Constants

    properties (Constant)
        windowSize    = [1244, 660]
        windowMinSize = [ 640, 580]
        fileVersion   = 'RFlookBin v.2/1'
        gps2locAPI    = 'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=<Latitude>&longitude=<Longitude>&localityLanguage=pt'
        Timeout       = 10                                                  % Maximum time in seconds to extract valid array of data from receiver
        yMinLimRange  = 80                                                  % Minimum y-Axis limit range
        yMaxLimRange  = 100                                                 % Maximum y-Axis limit range
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