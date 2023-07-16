function [udpPortArray, idx] = udpSockets(udpPortArray, Port)

    idx = [];   
    for ii = 1:numel(udpPortArray)
        if udpPortArray{ii}.LocalPort == Port
            idx = ii;
            break
        end
    end
    
    if isempty(idx)
        idx = numel(udpPortArray)+1;
        udpPortArray(idx) = {udpport('datagram', 'IPV4', 'LocalPort', Port, 'ByteOrder', 'big-endian')};
    end

end