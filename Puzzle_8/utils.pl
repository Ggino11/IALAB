% set_elem(List, Index, Elem, NewList)
% Rplace the element at Index in List with Elem returning a new list
set_elem(List, Index, Elem, NewList):-
    same_length(List, NewList), %ensure lists are same size
    append(Prefix, [_|Suffix], List), %split list into prefix and suffix
    length(Prefix, Index), %length of prefix is Index
    append(Prefix, [Elem|Suffix], NewList). %append prefix with new element and suffix
    

% swap_elements(List, Index1, Index2, NewList)
% in move func swap_elements(CurrentState, EmptyIndex, TargetIndex, NextState) 
% Swaps the elements at Index1 and Index2 in List to create NewList.
swap_elements(List, Index1, Index2, NewList):-
    %Find indexes of elements to swap
    nth0(Index1,List,Elem1),
    %find inefx of second element to swap
    nth0(Index2, List, Elem2),
    %replace the element at Index1 with the element at Index2
    set_elem(List, Index1, Elem2, TempList),
    %replace the element at Index2 with the element at Index1
    set_elem(TempList, Index2, Elem1, NewList).


% print_grid(State)
% Prints the 3x3 grid for a single state
print_grid([A,B,C,D,E,F,G,H,I]) :-
    format('+---+---+---+\n'),
    format('| ~w | ~w | ~w |\n', [A,B,C]),
    format('+---+---+---+\n'),
    format('| ~w | ~w | ~w |\n', [D,E,F]),
    format('+---+---+---+\n'),
    format('| ~w | ~w | ~w |\n', [G,H,I]),
    format('+---+---+---+\n').

% print_state(State)
% Prints the move made between two states in a descriptive way
print_move(PrevState, CurrentState) :-
    nth0(EmptyIndex, CurrentState, e),
    nth0(EmptyIndex, PrevState, MovedTile),  % The tile that moved into the empty space
    MovedTile \= e,
    nth0(TileIndex, PrevState, e),
    format("Move tile ~w from position ~w to position ~w (empty)\n", [MovedTile, TileIndex, EmptyIndex]).

% print_solution(SolutionPath)
% Prints the entire solution path as a sequence of moves
print_solution([]).
print_solution([_]). % Single state (initial state)
print_solution([State1, State2|Rest]) :-
    print_move(State1, State2),
    print_solution([State2|Rest]).

print_final_solution(SolutionPath) :-
    print_solution(SolutionPath),
    last(SolutionPath, FinalState),
    writeln('\nFinal state:'),
    print_grid(FinalState),
    length(SolutionPath, Length),
    Cost is Length - 1,
    format('\nTotal moves: ~w\n', [Cost]).
