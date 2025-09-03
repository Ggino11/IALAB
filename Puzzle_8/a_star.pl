
% A* algorithm for the 8-puzzle problem

:- dynamic initial_state/1, wrapper_count_missplaced/2, print_grid/1, goal/1, move/2, print_final_solution/1.
:- set_prolog_flag(answer_write_options, [quoted(true), portray(true), max_depth(0)]).

% Entry point for A* search
% a_star(-SolutionPath, -Cost)
% Launches A* search from initial state
a_star(SolutionPath, Cost) :-
    initial_state(InitialState),
    wrapper_count_missplaced(InitialState, H),
    F is 0 + H, % g=0, h=H for initial state
    % Initialize with: [f_cost, g_cost, path, current_state]
    a_star_search([[F, 0, [InitialState], InitialState]], [], SolutionPath, Cost).

% Main A* search loop
% a_star_search(+OpenList, +ClosedList, -SolutionPath, -Cost)
% OpenList: list of [F, G, Path, State] sorted by F cost
% ClosedList: list of already explored states
a_star_search([[_, G, Path, CurrentState]|_], _, SolutionPath, Cost) :-
    goal(CurrentState), !,
    reverse(Path, SolutionPath),
    Cost = G,
    writeln('Path to reach final state:'),
    print_final_solution(SolutionPath).

a_star_search([[_, G, Path, CurrentState]|RestOpen], Closed, SolutionPath, Cost) :-
    % % Debug output
    % write('Exploring state with f='), write(F), write(', g='), write(G), nl,
    % print_grid(CurrentState), nl,
    
    % Add current state to closed list
    NewClosed = [CurrentState|Closed],
    
    % Generate successors
    findall([NextF, NextG, NextPath, NextState],
        (   move(CurrentState, NextState),
            \+ member(NextState, Path),     % Avoid cycles in current path
            \+ member(NextState, NewClosed), % Avoid already explored states
            NextG is G + 1,                 % Cost increases by 1
            wrapper_count_missplaced(NextState, H),
            NextF is NextG + H,             % f = g + h
            NextPath = [NextState|Path]
        ),
        Successors
    ),
    
    % Merge successors with remaining open list and sort by F cost
    append(Successors, RestOpen, NewOpenUnsorted),
    sort(NewOpenUnsorted, NewOpenSorted),
    
    % Continue search
    a_star_search(NewOpenSorted, NewClosed, SolutionPath, Cost).

a_star_search([], _, _, _) :-
    writeln('No solution found - open list is empty').