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

% A senha padrão do servidor TCP é "123456". E os nomes de clientes padrão
% são "Zabbix", "Jupyter" ou "Matlab". Qualquer coisa diferente disso
% retornará erro.

% A mensagem a ser enviada pelo cliente deve ser um JSON com três chaves: 
% "Key", "ClientName" e "Request".

%%
% TESTE 1:
% Senha em formato errado: ao invés de string, foi enviado um número.
msg = struct('Key',        123456,   ...
             'ClientName', 'Zabbix', ...
             'Request',    'MaskStatus');
writeline(obj, jsonencode(msg))
% <JSON>{"Request":"{\"Key\":123456,\"ClientName\":\"Zabbix\",\"Request\":\"MaskStatus\"}","Answer":"MATLAB:validators:mustBeTextScalar"}</JSON>

%%
% TESTE 2:
% Senha errada: "12345" ao invés de "123456"
msg = struct('Key',        '12345',  ...
             'ClientName', 'Zabbix', ...
             'Request',    'MaskStatus');
writeline(obj, jsonencode(msg))
% <JSON>{"Request":"{\"Key\":\"12345\",\"ClientName\":\"Zabbix\",\"Request\":\"MaskStatus\"}","Answer":"tcpServerLib:IncorrectKey"}</JSON>

%%
% TESTE 3:
% Nome do cliente errado: "PowerBI" ao invés de "Zabbix" | "Jupyter" | "Matlab"
msg = struct('Key',        '123456',  ...
             'ClientName', 'PowerBI', ...
             'Request',    'MaskStatus');
writeline(obj, jsonencode(msg))
% <JSON>{"Request":"{\"Key\":\"123456\",\"ClientName\":\"PowerBI\",\"Request\":\"MaskStatus\"}","Answer":"tcpServerLib:UnauthorizedClient"}</JSON>

%%
% TESTE 4:
% Nome da requisição errado: "Qualquer coisa" ao invés de "TaskList" | "MaskStatus"
msg = struct('Key',        '123456', ...
             'ClientName', 'Matlab', ...
             'Request',    'Requisição não prevista');
writeline(obj, jsonencode(msg))
% <JSON>{"Request":"{\"Key\":\"123456\",\"ClientName\":\"Matlab\",\"Request\":\"Requisição não prevista\"}","Answer":"tcpServerLib:UnexpectedRequest"}</JSON>

%%
% TESTE 5:
% Requisições com sintaxes corretas

% (a) Diagnostic
msg = struct('Key',        '123456', ...
             'ClientName', 'Matlab', ...
             'Request',    'Diagnostic');
writeline(obj, jsonencode(msg))
% <JSON>{"Request":"Diagnostic","Answer":{"stationInfo":{"Name":"ERMx-DF-00","Computer":"GR08180769"},"Diagnostic":{"appColeta":{"Release":"R2023a","Version":"1.43"},"EnvVariables":[{"env":"COMPUTERNAME","value":"GR08180769"},{"env":"MATLAB_ARCH","value":"win64"},{"env":"MODEL","value":"3490"},{"env":"PROCESSOR_ARCHITECTURE","value":"AMD64"},{"env":"PROCESSOR_IDENTIFIER","value":"Intel64 Family 6 Model 142 Stepping 10, GenuineIntel"},{"env":"PROCESSOR_LEVEL","value":"6"},{"env":"SERIAL","value":"GSLWWQ2"}],"SystemInfo":[{"parameter":"HostName","value":"GR08180769"},{"parameter":"OSName","value":"Microsoft Windows 10 Pro"},{"parameter":"OSVersion","value":"10.0.19044 N/A compilação 19044"},{"parameter":"ProductID","value":"00330-51301-48751-AAOEM"},{"parameter":"OriginalInstallDate","value":"13/12/2021, 21:14:48"},{"parameter":"SystemBootTime","value":"31/08/2023, 08:19:51"},{"parameter":"SystemManufacturer","value":"Dell Inc."},{"parameter":"SystemModel","value":"Latitude 3490"},{"parameter":"SystemType","value":"x64-based PC"},{"parameter":"BIOSVersion","value":"Dell Inc. 1.26.0, 13/06/2023"},{"parameter":"TotalPhysicalMemory","value":"16.259 MB"},{"parameter":"AvailablePhysicalMemory","value":"3.654 MB"},{"parameter":"VirtualMemoryMaxSize","value":"28.035 MB"},{"parameter":"VirtualMemoryAvailable","value":"8.990 MB"},{"parameter":"VirtualMemoryInUse","value":"19.045 MB"}],"LogicalDisk":{"DeviceID":"C:","FileSystem":"NTFS","FreeSpace":"38272704512","Size":"254526582784"}}}}</JSON>

% (a) PositionList
msg = struct('Key',        '123456', ...
             'ClientName', 'Matlab', ...
             'Request',    'PositionList');
writeline(obj, jsonencode(msg))
% <JSON>{"Request":"PositionList","Answer":{"stationInfo":{"Name":"ERMx-DF-00","Computer":"GR08180769"},"positionList":[]}}</JSON>
% <JSON>{"Request":"PositionList","Answer":{"stationInfo":{"Name":"ERMx-DF-00","Computer":"GR08180769"},"positionList":[{"IDN":"TEKTRONIX,SA2500PC,B000000,7.050","gpsType":"Built-in","gpsStatus":1,"Latitude":45.4992027777778,"Longitude":-122.823165833333},{"IDN":"TEKTRONIX,SA2500PC,B000000,7.050","gpsType":"Manual","gpsStatus":-1,"Latitude":-12.5,"Longitude":-38.5}]}}</JSON>

% (a) TaskList
msg = struct('Key',        '123456', ...
             'ClientName', 'Matlab', ...
             'Request',    'TaskList');
writeline(obj, jsonencode(msg))
% <JSON>{"Request":"TaskList","Answer":{"stationInfo":{"Name":"ERMx-DF-00","Computer":"GR08180769"},"taskList":[]}}</JSON>
% <JSON>{"Request":"TaskList","Answer":{"stationInfo":{"Name":"ERMx-DF-00","Computer":"GR08180769"},"taskList":[{"IDN":"TEKTRONIX,SA2500PC,B000000,7.050","TaskName":"appColeta HOM_2","Observation":{"Type":"Samples","BeginTime":"01-Sep-2023 12:21:28","EndTime":null},"Band":{"FreqStart":7.6E+7,"FreqStop":1.08E+8,"ObservationSamples":1000,"nSweeps":79,"Mask":[]},"MaskTable":[],"Status":"Cancelada"},{"IDN":"TEKTRONIX,SA2500PC,B000000,7.050","TaskName":"appColeta HOM_1","Observation":{"Type":"Duration","BeginTime":"01-Sep-2023 12:22:53","EndTime":"01-Sep-2023 12:32:53"},"Band":[{"FreqStart":7.6E+7,"FreqStop":1.08E+8,"nSweeps":106,"Mask":{"Validations":53,"BrokenCount":53,"Peaks":[{"idx":376,"FreqCenter":100,"BW":82.8,"Prominence":48.9}],"TimeStamp":"01-Sep-2023 12:24:19","FindPeaks":{"nSweeps":2,"Proeminence":30,"Distance":25,"BW":10}}},{"FreqStart":1.08E+8,"FreqStop":1.37E+8,"nSweeps":53,"Mask":[]},{"FreqStart":4.5E+8,"FreqStop":4.7E+8,"nSweeps":53,"Mask":[]}],"MaskTable":[{"FreqStart":20,"FreqStop":101,"THR":-50},{"FreqStart":105,"FreqStop":118,"THR":-70},{"FreqStart":420,"FreqStop":460,"THR":-75},{"FreqStart":3650,"FreqStop":4150,"THR":-60}],"Status":"Em andamento"}]}}</JSON>