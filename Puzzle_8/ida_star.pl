%:- consult(utils,regole,heuristic,dominioP8).
:- set_prolog_flag(answer_write_options, [quoted(true), portray(true), max_depth(0)]). % to avoid abbreviation in the outpu lists

% iterative deeping A* search alg f(n) = g(n) + h(n)
ida_star(SolutionPath,Cost):-
    initial_state(InitialState), % get initial state and count h(n)
    wrapper_count_missplaced(InitialState,H), %H heuristic value result of count 
    ida_loop([[InitialState]],H,SolutionPath,Cost).

ida_loop(Paths, Threshold, SolutionPath, Cost):-
    bounded_search(Paths,Threshold,Result, NewThreshold),
    ( Result = found(SolutionPath,Cost) 
    -> true
    ;% format("No solution under ~w. Next threshold = ~w\n\n", [Threshold, NextThreshold]),
    ida_loop(Paths, NewThreshold, SolutionPath, Cost)
    ).

% ricerca a profondità limitata su f
bounded_search([], _, no_solution, inf). % no more paths to explore
bounded_search([Path|Other], Threshold, Result, MinAbove) :-
    Path = [Current|_],
    length(Path, L), 
    G is L - 1,                          % Cost from start to current node
    wrapper_count_missplaced(Current, H), % Heuristic estimate
    F is G + H,                          % Total cost estimate
    
    % % Debug printof each sate
    % format("Current state (g=~w, h=~w, f=~w):\n", [G, H, F]),
    % print_grid(Current), nl,             % Print current grid state
    
    ( goal(Current) ->                   % If current state is the goal
        reverse(Path, SolutionPath),     % Reverse path to get correct order
        Result = found(SolutionPath, G), % Return solution
        MinAbove = Threshold,
        
        % Print the full solution path
        writeln('\nPath to reaach final state:'),
        print_final_solution(SolutionPath)
        
    ; F > Threshold ->                   % If cost exceeds threshold
        bounded_search(Other, Threshold, Result2, Min2),
        MinAbove is min(F, Min2),       % Track minimum exceeding cost
        Result = Result2
        
    ;                                   % Else expand current node
        findall(
            [Next|Path],
            ( move(Current, Next),       % Generate valid moves
              \+ member(Next, Path)      % Avoid cycles
            ),
            NextPaths
        ),
        append(NextPaths, Other, AllPaths),
        bounded_search(AllPaths, Threshold, Result, MinAbove)
    ).