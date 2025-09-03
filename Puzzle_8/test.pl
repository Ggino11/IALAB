
 :- [dominioP8, utils, regole, heuristic]. % njon capisco peche il warniung se non metto il dynamic import per ogni funzione


% --------------------------------------------
% TEST PER prime funzionin iplementate
% caricare il file [test]. e chiamnare iu comando test. a terminale
% --------------------------------------------

test :-
    dominioP8:initial_state(S),
    writeln('Stato iniziale:'), writeln(S),
    dominioP8:index_move(4, Adjs),
    writeln('Adiacenti al centro:'), writeln(Adjs),
    utils:swap_elements([a,b,c,d], 1, 2, SwapResult),
    writeln('Swap b-c:'), writeln(SwapResult),
    regole:move([1,2,3,4,e,5,6,7,8], Next),
    writeln('Mossa da centro:'), writeln(Next),
    writeln('Test euristica count_missplaced:'),
    heuristic:count_missplaced([1,2,3,4,5,6,7,8,e], [7,3,1,5,e,6,8,2,4], 0, MissplacedCount),
    writeln('Numero di celle fuori posto:'), writeln(MissplacedCount).