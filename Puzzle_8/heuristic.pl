% Heuristic file for the problem

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
