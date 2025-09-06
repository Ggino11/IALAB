
applicabile(nord, pos(Riga, Colonna)):-
    Riga > 1,
    RigaSopra is Riga - 1,
    \+ occupata(pos(RigaSopra, Colonna)).

applicabile(sud, pos(Riga, Colonna)):-
    num_righe(N),
    Riga < N, 
    RigaSotto is Riga + 1,
    \+ occupata(pos(RigaSotto, Colonna)).

applicabile(est, pos(Riga, Colonna)):-
    num_colonne(NC),
    Colonna < NC,
    ColonnaDestra is Colonna + 1,
    \+ occupata(pos(Riga, ColonnaDestra)).

applicabile(ovest, pos(Riga, Colonna)):-
    Colonna > 1,
    ColonnaSinistra is Colonna - 1,
    \+ occupata(pos(Riga, ColonnaSinistra)).



% trasforma(Azione,StatoAttuale,StatoNuovo)
trasforma(nord,pos(Riga, Colonna), pos(RigaSopra, Colonna)):-
    RigaSopra is Riga - 1.

trasforma(sud, pos(Riga, Colonna), pos(RigaSotto, Colonna)):-
    RigaSotto is Riga + 1.

trasforma(est, pos(Riga,Colonna), pos(Riga, ColonnaDestra)):-
    ColonnaDestra is Colonna + 1.

trasforma(ovest, pos(Riga, Colonna), pos(Riga, ColonnaSinistra)):- ColonnaSinistra is Colonna - 1.

% calcolo del costo per andare da uno stato ad un nuovo stato
costo(pos(_,_), pos(_,_), Costo):-
    Costo is 1.

% calcolo della distanza minima
distanza_min([L|Ls], Min):-
    distanza_min(Ls, L, Min).

distanza_min([], Min, Min).

distanza_min([L|Ls], Min0, Min):-
    Min1 is min(L, Min0),
    distanza_min(Ls, Min1, Min).