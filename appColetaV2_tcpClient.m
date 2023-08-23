% IP e porta do servidor TCP.

IP   = 'localhost';
Port = 8910;
%%
% Cria objeto tcpclient, configura terminador e callback para realizar
% ação, caso recebida mensagem com terminador configurado. No caso, o
% callback nada mais é do que imprimir em tela aquilo que fora recebido.

obj = tcpclient('localhost', 8910);
configureTerminator(obj, "CR/LF")
configureCallback(obj, 'terminator', @(~,~)disp(readline(obj)))
%%
% A senha padrão do servidor TCP é "123456". E os nomes de clientes padrão
% são "Zabbix", "Jupyter" ou "Matlab". Qualquer coisa diferente disso
% retornará erro.

% A mensagem a ser enviada pelo cliente deve ser um JSON encapsulado pelos
% tags "<JSON>" e "</JSON>".

% O JSON é uma estrutura com três chaves: "Key", "ClientName" e "Request".
%%
% TESTE 1:
% Senha em formato errado: ao invés de string, foi enviado um número.

writeline(obj, ['<JSON>' jsonencode(struct('Key', 123456, 'ClientName', 'Zabbix', 'Request', 'MaskStatus')) '</JSON>'])
% <JSON>{"Request":"{\"Key\":123456,\"ClientName\":\"Zabbix\",\"Request\":\"MaskStatus\"}","Answer":"MATLAB:validators:mustBeTextScalar"}</JSON>
%%
% TESTE 2:
% Senha errada: "12345" ao invés de "123456"

writeline(obj, ['<JSON>' jsonencode(struct('Key', '12345', 'ClientName', 'Zabbix', 'Request', 'MaskStatus')) '</JSON>'])
% <JSON>{"Request":"{\"Key\":\"12345\",\"ClientName\":\"Zabbix\",\"Request\":\"MaskStatus\"}","Answer":"tcpServerLib:IncorrectKey"}</JSON>
%%
% TESTE 3:
% Nome do cliente errado: "PowerBI" ao invés de "Zabbix" | "Jupyter" | "Matlab"

writeline(obj, ['<JSON>' jsonencode(struct('Key', '123456', 'ClientName', 'PowerBI', 'Request', 'MaskStatus')) '</JSON>'])
% <JSON>{"Request":"{\"Key\":\"123456\",\"ClientName\":\"PowerBI\",\"Request\":\"MaskStatus\"}","Answer":"tcpServerLib:UnauthorizedClient"}</JSON>
%%
% TESTE 4:
% Nome da requisição errado: "Qualquer coisa" ao invés de "TaskList" | "MaskStatus"

writeline(obj, ['<JSON>' jsonencode(struct('Key', '123456', 'ClientName', 'Matlab', 'Request', 'Qualquer coisa')) '</JSON>'])
% <JSON>{"Request":"{\"Key\":\"123456\",\"ClientName\":\"Matlab\",\"Request\":\"Qualquer coisa\"}","Answer":"tcpServerLib:UnexpectedRequest"}</JSON>
%%
% TESTE 5:
% Informações corretas - requisitado a informação do tipo "TaskList"

writeline(obj, ['<JSON>' jsonencode(struct('Key', '123456', 'ClientName', 'Matlab', 'Request', 'TaskList')) '</JSON>'])