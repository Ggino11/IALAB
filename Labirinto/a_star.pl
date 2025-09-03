a_star(SolutionPath, Cost) :-
    iniziale(InitialState),
    manhattan(InitialState, H),
    F is 0 + H, 
    a_star_search([[F, 0, [], InitialState]], [], SolutionPath, Cost).

a_star_search([[_, G, Path, CurrentState]|_], _, SolutionPath, Cost) :-
    finale(CurrentState), !,
    reverse(Path, SolutionPath),
    Cost = G.

a_star_search([[_, G, Path, CurrentState]|RestOpen], Closed, SolutionPath, Cost) :-
    
    NewClosed = [CurrentState|Closed],
    
    findall([NextF, NextG, NextPath, NextState],
        (   applicabile(Action, CurrentState),
            trasforma(Action, CurrentState, NextState),
            \+ member(NextState, NewClosed), 
            \+ (member([_, _, _, ExistingState], RestOpen), ExistingState == NextState), % Evita duplicati in open
            costo(CurrentState, NextState, StepCost),
            NextG is G + StepCost,
            manhattan(NextState, H),
            NextF is NextG + H,
            NextPath = [Action|Path]  
        ),
        Successors
    ),
    
   
    append(Successors, RestOpen, NewOpenUnsorted),
    sort(NewOpenUnsorted, NewOpenSorted),
    a_star_search(NewOpenSorted, NewClosed, SolutionPath, Cost).

a_star_search([], _, _, _) :-
    writeln('No solution found - open list is empty').


runAStar :-
    statistics(walltime, [TimeStart|_]),
    (a_star(Solution, Cost) ->
    
        format('=== SOLUTION FOUND ===~n'),
        format('Path: ~w~n', [Solution]),
        format('Steps: ~w~n', [Cost]),
        statistics(walltime, [TimeEnd|_]),
        Time is (TimeEnd - TimeStart)/1000,
        format('Time: ~3f seconds~n', [Time])
    ;
        format('NO SOLUTION FOUND~n')
    ).