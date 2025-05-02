% Heuristic file for the problem
:-dynamic final_state/1. % sempre stesso problema non mi prende ill predicato se non lo metto tramite dynamic 

% Heuristic function to calculate the numnber of missplacede cells in the puzzle
count_missplaced([],[],Count, Result) :-
    Result is Count. % if the list is empty return the count
count_missplaced([HeadCS|TailCS], [HeadFS|TailFS], Count, NewResult) :-
    % if the head of the current state is not equal to the head of the final state increment the count
    HeadCS \== HeadFS, !,
    NewCount is Count +1,
    count_missplaced(TailCS,TailFS,NewCount,NewResult).
count_missplaced([_|TailCS],[_|TailFS], Count, Result):-
    % if the head of the lists are equal skip the heads [_] and keep the recursion going on the tails of the 2 lists
    count_missplaced(TailCS,TailFS, Count, Result).
%forse meglio aggiungere una wrapper per far diventare count missplaced un predicato /2 e non /4 (?)
wrapper_count_missplaced(CurrentState, H):-
    final_state(FinalState),
    count_missplaced(CurrentState,FinalState, 0, H). % H heuristic value result of count missplaced