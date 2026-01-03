% IDA* Algorithm for Maze Solving
% Iterative Deepening A* - memory efficient version of A*
% Optimized version with transposition table for visited states

:- dynamic(min_exceeded/1).
:- dynamic(ida_visited/2).  % Transposition table: ida_visited(State, G)

% Entry point - inizializza e avvia la ricerca
ida_star(Solution, Cost) :-
    retractall(min_exceeded(_)),
    retractall(ida_visited(_,_)),
    retractall(manhattan_cache(_,_)),
    iniziale(Start),
    manhattan(Start, H0),
    ida_loop(Start, H0, Solution, Cost).

% Loop principale IDA* - itera aumentando il threshold
ida_loop(Start, Threshold, Solution, Cost) :-
    retractall(min_exceeded(_)),
    retractall(ida_visited(_,_)),  % Pulisci transposition table ad ogni iterazione
    assertz(min_exceeded(inf)),
    (   dfs_bounded(Start, [], 0, Threshold, Solution, Cost)
    ->  true
    ;   min_exceeded(NewThreshold),
        NewThreshold \= inf,
        NewThreshold > Threshold,
        ida_loop(Start, NewThreshold, Solution, Cost)
    ).

% DFS con limite - cerca una soluzione entro il threshold
% Caso base: stato finale raggiunto
dfs_bounded(State, Path, G, _Threshold, Solution, G) :-
    finale(State), !,
    reverse(Path, Solution).

% Caso ricorsivo: esplora i successori
dfs_bounded(State, Path, G, Threshold, Solution, Cost) :-
    % Ottimizzazione: controlla se abbiamo già visitato questo stato con costo minore
    (   ida_visited(State, OldG), OldG =< G
    ->  fail  % Già visitato con costo migliore
    ;   true
    ),
    % Registra la visita
    retractall(ida_visited(State, _)),
    assertz(ida_visited(State, G)),
    
    applicabile(Action, State),
    trasforma(Action, State, NextState),
    \+ member(NextState, Path),  % Evita cicli nel percorso corrente
    costo(State, NextState, StepCost),
    NewG is G + StepCost,
    manhattan(NextState, H),
    F is NewG + H,
    (   F =< Threshold
    ->  dfs_bounded(NextState, [Action|Path], NewG, Threshold, Solution, Cost)
    ;   update_min_exceeded(F),
        fail
    ).

% Aggiorna il valore minimo che ha superato il threshold
update_min_exceeded(F) :-
    min_exceeded(CurrentMin),
    (   CurrentMin = inf
    ->  retract(min_exceeded(inf)),
        assertz(min_exceeded(F))
    ;   F < CurrentMin
    ->  retract(min_exceeded(CurrentMin)),
        assertz(min_exceeded(F))
    ;   true
    ).

% Wrapper per eseguire IDA* e mostrare i risultati
runIDAStar :-
    writeln('=== Running IDA* ==='),
    statistics(walltime, [TimeStart|_]),
    (   ida_star(Solution, Cost)
    ->  statistics(walltime, [TimeEnd|_]),
        Time is (TimeEnd - TimeStart)/1000,
        format('IDA* SOLUTION FOUND~n'),
        format('Path: ~w~n', [Solution]),
        format('Steps: ~w~n', [Cost]),
        format('Time: ~3f seconds~n', [Time])
    ;   statistics(walltime, [TimeEnd|_]),
        Time is (TimeEnd - TimeStart)/1000,
        format('IDA* - NO SOLUTION FOUND~n'),
        format('Time: ~3f seconds~n', [Time])
    ).