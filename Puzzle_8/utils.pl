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