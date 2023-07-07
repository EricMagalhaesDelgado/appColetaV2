classdef taskList

    % Campo "Observation" do arquivo "taskList.json" possui a seguinte estrutura:
    % (a) 'Type'        - 'Duration' | 'Time' | 'Samples'
    % (b) 'BeginTime'   - 'dd/mm/yyyy HH:MM:SS'
    % (c) 'EndTime'     - 'dd/mm/yyyy HH:MM:SS'
    % (d) 'Duration'    - 'inf' | 'infinite' | '\d+\s*(seconds|second|sec|minutes|min|hours|hr)
    %
    % De forma geral,
    % - 'Duration': demanda apenas informação constante no campo 'Duration';
    % - 'Time'....: demanda apenas informações constantes nos campos 'BeginTime' e 'EndTime'; 
    % - 'Samples'.: demanda apenas informações constantes nos campos 'ObservationSamples' de cada uma das faixas - vide campo 'Band' do arquivo "taskList.json".
    %
    % Ao ler o arquivo taskList.json, o campo 'Duration' é editado para computar a duração da tarefa em segundos (valor numérico), o que somente é aplicável quando tipo de observação for 'Duration'

    % Campo "GPS" do arquivo "taskList.json" possui a seguinte estrutura:
    % (a) 'Type'        - 'auto' | 'manual'
    % (b) 'Latitude'    - valor numérico, aplicável apenas quando 'Type' igual a 'manual'
    % (c) 'Longitude'   - valor numérico, aplicável apenas quando 'Type' igual a 'manual'
    % (d) 'RevisitTime' - valor numérico, representante o tempo de revisita em segundos, aplicável apenas quando 'Type' igual a 'auto'
    %
    % Ao incluir uma tarefa, o campo 'Type', caso seja igual a 'auto', será alterado por 'Built-in' (GPS embarcado no receptor) ou 'External'.

    % Campo "Band" do arquivo "taskList.json" possui estrutura com informações sobre a programação do receptor e lógica da tarefa. Em destaque:
    % (a) 'RFMode'      - 'High Sensitivity' | 'Normal' | 'Low Distortion'
    % (b) 'TraceMode'   - 'ClearWrite' | 'Average' | 'MaxHold' | 'MinHold'
    % (c) 'Detector'    - 'Sample' | 'Average/RMS' | 'Positive Peak' | 'Negative Peak'
    % (d) 'LevelUnit'   - 'dBm' | 'dBµV'
    % (e) 'Trigger'     - 0 | 1 | 2
    %     Se o tipo de tarefa for "Rompimento de máscara espectral":
    %     - 0: a informação coletada será escrita em arquivo, não sendo avaliado rompimento da máscara;
    %     - 1: será avaliado rompimento da máscara, sendo a informação coletada escrita em arquivo apenas se evidenciado o rompimento.
    %     - 2: será avaliado rompimento da máscara, não havendo escrita em arquivo.
    %     Para os outros tipos de tarefa - "Monitoração ordinária" e "Drive-test", o valor desse parâmetro não terá nenhum efeito.
    % (f) 'Enable'    - 0 | 1

    methods (Static)
        %-----------------------------------------------------------------%
        function [List, msgError] = file2raw(RootFolder)
            try
                List = jsondecode(fileread(fullfile(RootFolder, 'Settings', 'taskList.json')));
                msgError = '';
                
                for ii = 1:numel(List)
                    switch List(ii).Observation.Type
                        case 'Duration'
                            List(ii).Observation.Duration = lower(List(ii).Observation.Duration);
                            if ismember(List(ii).Observation.Duration, {'inf', 'infinite'})
                                List(ii).Observation.Duration = inf;
                            else
                                durationStr = regexpi(List(ii).Observation.Duration, '(?<value>\d+)\s*(?<unit>(seconds|second|sec|minutes|minute|min|hours|hour|hr))', 'names');
                                if ~isempty(durationStr)
                                    switch durationStr.unit
                                        case {'seconds', 'second', 'sec'}; List(ii).Observation.Duration = str2double(durationStr.value);
                                        case {'minutes', 'minute', 'min'}; List(ii).Observation.Duration = str2double(durationStr.value)*60;
                                        case {'hours', 'hour', 'hr'};      List(ii).Observation.Duration = str2double(durationStr.value)*3600;
                                    end
                                else
                                    List(ii).Observation.Duration = 600;
                                end
                            end
                            List(ii).Observation.BeginTime = '';
                            List(ii).Observation.EndTime   = '';
    
                        case 'Time'
                            List(ii).Observation.Duration = [];
    
                        case 'Samples'
                            List(ii).Observation = struct('Type', 'Samples', 'BeginTime', '', 'EndTime', '', 'Duration', []);
                    end
        
                    if ~any([List(ii).Band.Enable])
                        List(ii).Band(1).Enable = 1;
                    end
                end

            catch ME
                List = struct('Name', 'appColeta HOM_1',                                                                  ...
                              'BitsPerSample', 8,                                                                         ...
                              'Observation', struct('Type', 'Duration', 'BeginTime', '', 'EndTime', '', 'Duration', 600), ...
                              'GPS',         struct('Type', 'auto', 'Latitude', [], 'Longitude', [], 'RevisitTime', 10),  ...
                              'Band',        struct('ID',                 1,              ...
                                                    'Description',        'Faixa 1 de 1', ...
                                                    'ObservationSamples', [],             ...
                                                    'FreqStart',          76000000,       ...
                                                    'FreqStop',           108000000,      ...                                              
                                                    'StepWidth',          5000,           ...
                                                    'Resolution',         30000,          ...
                                                    'RFMode',             'Normal',       ...
                                                    'TraceMode',          'ClearWrite',   ...
                                                    'Detector',           'Sample',       ...
                                                    'LevelUnit',          'dBm',          ...
                                                    'RevisitTime',         0.1,           ...
                                                    'IntegrationFactor',   1,             ...
                                                    'Trigger',             1,             ...
                                                    'Enable',              1));
                msgError = ME.message;
            end
        end


        %-----------------------------------------------------------------%
        function Task = app2raw(Task)
            if ismember(Task.Observation.Type, {'Duration', 'Samples'})
                Task.Observation.BeginTime = '';
                Task.Observation.EndTime   = '';
            end

            if ismember(Task.GPS.Type, {'Built-in', 'External'})
                Task.GPS.Type = 'auto';
            end
        end
    end
end