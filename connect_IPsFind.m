function [localIP, publicIP] = connect_IPsFind(instrIP)

    [~, msg] = system('arp -a');

    msgCell  = strsplit(msg, newline)';
    
    indEmpty = cellfun(@(x) isempty(x), msgCell);
    msgCell(indEmpty) = [];
    
    ind_localIPs = find(cellfun(@(x) contains(x, ' --- '), msgCell));
    ind_instrIPs = find(cellfun(@(x) contains(x, [' ' instrIP ' ']), msgCell));
    
    localIP = '';
    if ~isempty(ind_instrIPs)
        ind_instrIPs = ind_instrIPs(1);
        
        temp = ind_localIPs - ind_instrIPs;
        ind  = find(temp<0);
        ind  = ind(end);
                
        localIP  = char(regexp(msgCell{ind_localIPs(ind)}, '(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})', 'match'));
        publicIP = localIP;
        
    else
        localIPs = {};
        for ii = 1:numel(ind_localIPs)
            localIPs = [localIPs, regexp(msgCell{ind_localIPs(ii)}, '(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})', 'match')];
        end
        
        for jj = 1:numel(localIPs)
            if ~system(sprintf('ping -n 3 -w 1000 -S %s %s', localIPs{jj}, instrIP))
                localIP = localIPs{jj};
                break
            end
        end
        
        publicIP = char(regexp(webread('http://checkip.dyndns.org'), '(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})', 'match'));
    end

end