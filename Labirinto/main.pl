% main.pl
% Confronto tra IDA* e A* per la risoluzione del labirinto

% Funzione principale
main :-
    writeln('=== LABIRINTO SOLVER ==='), nl,
    
    % Mostra stato iniziale e finali
    iniziale(Start),
    format('Posizione iniziale: ~w~n', [Start]),
    
    findall(Goal, finale(Goal), Goals),
    format('Uscite: ~w~n', [Goals]), nl,
    
     % Esegui A*
    writeln('Running A*...'),
    statistics(walltime, [Start2|_]),
    (a_star(Path2, Cost2) ->
        statistics(walltime, [End2|_]),
        Time2 is (End2 - Start2)/1000,
        format('A* - Path: ~w~n', [Path2]),
        format('A* - Steps: ~w, Time: ~3f seconds~n', [Cost2, Time2])
    ;
        statistics(walltime, [End2|_]),
        Time2 is (End2 - Start2)/1000,
        writeln('A* - NO SOLUTION FOUND'),
        format('A* - Time: ~3f seconds~n', [Time2])
    ), nl,

    % Esegui IDA*
    writeln('Running IDA*...'),
    statistics(walltime, [Start1|_]),
    (ida_star(Path1, Cost1) ->
        statistics(walltime, [End1|_]),
        Time1 is (End1 - Start1)/1000,
        format('IDA* - Path: ~w~n', [Path1]),
        format('IDA* - Steps: ~w, Time: ~3f seconds~n', [Cost1, Time1])
    ;
        statistics(walltime, [End1|_]),
        Time1 is (End1 - Start1)/1000,
        writeln('IDA* - NO SOLUTION FOUND'),
        format('IDA* - Time: ~3f seconds~n', [Time1])
    ), nl,
     
    % Confronto finale
    writeln('=== CONFRONTO FINALE ==='),
    (var(Path1) -> writeln('IDA*: Nessuna soluzione') ; format('IDA*: ~w passi, ~3f secondi~n', [Cost1, Time1])),
    (var(Path2) -> writeln('A*: Nessuna soluzione') ; format('A*: ~w passi, ~3f secondi~n', [Cost2, Time2])).

% % Esegui il confronto
% run_comparison :-
%     main.
