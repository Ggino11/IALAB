 % Carica tutti i file necessari
 :- [dominioP8, utils, regole]. % njon capisco peche il warniung se nnon metto il dynamic import per ogni funzione


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
    writeln('Mossa da centro:'), writeln(Next).