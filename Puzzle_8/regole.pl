% file contenente le regole logiche per l'implementazione del problema 
:- dynamic index_move/2, swap_elements/4.%senza non vede impoprt


% move(CurrentState, NextState)
% Given the current state of the puzzle, find the next state by moving the empty cell 'e' to an adjacent position.
move(CurrentState, NextState):-
    % Find the index of the empty cell in the current state
    nth0(EmptyIndex, CurrentState, e),
    % get the list of adjacent indexes for the empty cell
    index_move(EmptyIndex, AdjacentIndexes),
    % chose one og the adcent indexes to swapo with the empty cell
    member(TargetIndex, AdjacentIndexes),
    % swap 'e' with target index
    swap_elements(CurrentState, EmptyIndex, TargetIndex, NextState).


