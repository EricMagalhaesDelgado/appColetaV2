function [udpPortArray, udpIndex] = connect_udpSockets(udpPortArray, Parameters)

    Parameters = jsondecode(Parameters);
    Port       = Parameters.Port;
    Timeout    = Parameters.Timeout;

    udpIndex = [];   
    for ii = 1:numel(udpPortArray)
        if udpPortArray{ii}.LocalPort == Port
            udpIndex = ii;
            break
        end
    end
    
    if isempty(udpIndex)
        udpIndex = numel(udpPortArray)+1;
        udpPortArray(udpIndex) = {udpport('datagram', 'IPV4', 'LocalPort', Port, 'ByteOrder', 'big-endian', 'Timeout', Timeout)};
    end

end