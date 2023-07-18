classdef tcpServerLib

    properties
        App
        Server
    end

    % Notas:
    % - configurado apenas escuta de porta para o servidor, além de callback que será executado toda vez que for recebida uma mensagem terminada em "CR/LF".
    % - configurado servidor e cliente p/ uso dos terminadores "CR/LF" (embutidos na mensagem textual quando em uso writeline).

    % write|writeline|read|readline

    % writeline(tcpClient, jsonencode(struct('type', 'type1')))
    % msgSentByServer = struct2table(jsondecode(readline(tcpClient)))

    % Ou...
    % write(tcpClient, sprintf('%s\r\n', jsonencode(struct('type', 'type1'))))
    % msgSentByServer = read(tcpClient, tcpClient.NumBytesAvailable, 'char')

    methods
        %-----------------------------------------------------------------%
        function obj = tcpServerLib(app)
            obj.App = app;

            try
                obj.Server = tcpserver(class.Constants.tcpServerIP, class.Constants.tcpServerPort);
            catch
                obj.Server = tcpserver(class.Constants.tcpServerPort);
            end
            
            set(obj.Server, UserData = table('Size', [0, 5],                                                    ...
                                             'VariableTypes', {'string', 'string', 'double', 'string', 'cell'}, ...
                                             'VariableNames', {'timestamp', 'ip', 'port', 'message', 'status'}));

            configureTerminator(obj.Server, "CR/LF")
            configureCallback(obj.Server, "terminator", @(~,~)obj.receivedMessage)
        end


        %-----------------------------------------------------------------%
        function receivedMessage(obj)
            while obj.Server.NumBytesAvailable
                rawMsg = readline(obj.Server);
                try
                    decodedMsg = jsondecode(rawMsg);

                    switch decodedMsg.type
                        case 'type1'
                            writeline(obj.Server, jsonencode(obj.App.EMSatObj.LNB))
                        case 'type2'
                            writeline(obj.Server, jsonencode(obj.App.EMSatObj.switchCommand))
                        case 'type3'
                            idx = obj.App.specObj.Band.Waterfall.idx;
                            write(obj.Server, obj.App.specObj.Band.Waterfall.Matrix(idx,:), 'single');
                        otherwise
                            error('tcpServerLib:UnexpectedRequest', 'Unexpected Request')
                    end
                    obj.Server.UserData(end+1,:) = {char(datetime('now', 'Format', 'dd/MM/yyyy HH:mm:ss')), obj.Server.ClientAddress, obj.Server.ClientPort, rawMsg, 'success'};
                    
                catch ME
                    writeline(obj.Server, sprintf('Received message: %s\nError identifier: %s', rawMsg, ME.identifier))
                    obj.Server.UserData(end+1,:) = {char(datetime('now', 'Format', 'dd/MM/yyyy HH:mm:ss')), obj.Server.ClientAddress, obj.Server.ClientPort, rawMsg, ME.message};
                end
            end
        end
    end
end