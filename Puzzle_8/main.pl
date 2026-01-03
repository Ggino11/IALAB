% Load all required modules
:- [dominioP8, utils, regole, heuristic, ida_star, a_star].

% Simple main function
main :-
    writeln('=== 8-PUZZLE SOLVER ==='), nl,
    
    % Show initial state
    initial_state(Initial),
    writeln('Initial state:'),
    print_grid(Initial), nl,
    
    % Run IDA*
    writeln('Running IDA*...'),
    get_time(Start1),
    ida_star(_, Cost1),
    get_time(End1),
    Time1 is End1 - Start1,
    format('IDA* - Cost: ~w moves, Time: ~3f seconds~n', [Cost1, Time1]), nl,
    
    % Run A*
    writeln('Running A*...'),
    get_time(Start2),
    a_star(_, Cost2),
    get_time(End2),
    Time2 is End2 - Start2,
    format('A* - Cost: ~w moves, Time: ~3f seconds~n', [Cost2, Time2]), nl,
    
    writeln('Done.').