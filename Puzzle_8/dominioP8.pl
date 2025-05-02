/* 
Rappresentazione classica come una lista di 9 elementi letta riga per riga, e con l'elemento vuoto rappresentato dalla lettera 'e' (empty)

7   3   1
5   e   6
8   2   4

stato iniziale: [1, 2, 3, 4, e, 5, 6, 7, 8]
stato finale: [1, 2, 3, 4, 5, 6, 7, 8, e]

Questa implementazione assume come ipotesi iniziale il fatto che il numero possa comparire una volta sola nella lista!
*/

% Definition of initial and filal domain states
initial_state([7,3,1,5,e,6,8,2,4]).
final_state([1,2,3,4,5,6,7,8,e]).

/* Index_ move defines, for each position (0–8) in the 3x3 puzzle grid, the list of adjacent positions
 with which the empty cell (represented by 'e') can be swapped (listIndexes).
 The grid positions are indexed as follows:

   0  1  2
   3  4  5
   6  7  8

For example, if the empty cell is at position 4 (center), it can move up (1),
down (7), left (3), or right (5), so the list is [1, 3, 5, 7].
*/ 

% index_move(EmptyPosition, ListIndexes):

index_move(0,[1,3]).
index_move(1,[0,2,4]).
index_move(2,[1,5]).
index_move(3,[0,4,6]).
index_move(4,[1,3,5,7]).
index_move(5,[2,4,8]).
index_move(6,[3,7]).
index_move(7,[4,6,8]).
index_move(8,[5,7]).


%Goal state --> goal state of the puzzle when is equal to the final state
% trueif the current state is equal to the desired one
goal(State):-
  final_state(FinalState),
  State = FinalState.

