% costanti per scalabilità del programma e parametrizzare il modello 
% CONST
#const squadre = 32.
#const n_gironi = 8.
#const squadre_per_girone = 4.
#const n_giornate = 3.
% squadre per ogni categoria
#const percat = squadre / 4.

% DOMINIO
squadra(s1;s2;s3;s4;s5;s6;s7;s8;s9;s10;s11;s12;s13;s14;s15;s16;s17;s18;s19;s20;s21;s22;s23;s24;s25;s26;s27;s28;s29;s30;s31;s32).

giornata(1..n_giornate).

girone(a;b;c;d;e;f;g;h).

categoria(teste_di_serie;prima_fascia;seconda_fascia;underdog).

zone_continentali(europa;america_nord_centro;america_sud;asia;africa;oceania).


% ZONE CONTINENTALI
% aogni squadra appartiene a una zona continentale --> non serve vincolo perchè giaò in questo modo implica unicità 
% ogni zona continentale ha un numero di squadre --> esattamente un numero di squadre devono appartenere alla zona esplicitata
10 { appartiene(S,europa) : squadra(S) } 10.

4  { appartiene(S,america_nord_centro) : squadra(S) } 4.

8  { appartiene(S,america_sud) : squadra(S) } 8.

4  { appartiene(S,asia) : squadra(S) } 4.

4  { appartiene(S,africa) : squadra(S) } 4.

2  { appartiene(S,oceania) : squadra(S) } 2.

1 { appartiene(S, Z) : squadra(S), zone_continentali(Z) } 1 :- squadra(S).



% CATEGORIA
% assegno per ogni squadra una categoria
1{ assegna(S,C) : categoria(C)}1 :- squadra(S).
percat{ assegna(S,C) : squadra(S)}percat :- categoria(C).


% GIRONI
% ogni squadra in un solo girone
1 { inGirone(S,G) : girone(G) } 1 :- squadra(S).

% esattamente 4 squadre per girone 
squadre_per_girone { inGirone(S,G) : squadra(S) } squadre_per_girone :- girone(G).

% almeno 3 zone continentali diverse per girone
zonaInGirone(G,Z) :- inGirone(S,G), appartiene(S,Z).

% non ci possono essere meno di 3 zone per girone
:- girone(G), #count { Z : zonaInGirone(G,Z) } < 3.

% in ogni girone una e una sola squadra per ciascuna categoria
% :- girone(G), categoria(C), #count { S : inGirone(S,G), assegna(S,C) } != 1.
% forse megio rappresentare il fatto in questo modo rispetto a riga 34 35
1 { inGirone(S,G) : assegna(S,C) } 1 :- girone(G), categoria(C).


% TURNO
% ogni turno prevede 3 giornate
% trovo tutti gli accoppiamenti per girone 
coppia(S1,S2,G) :- inGirone(S1,G), inGirone(S2,G), S1 < S2.
% ogni coppia gioca una volta sola in una delle 3 giornate
1 { gioca(S1,S2,G,T) : giornata(T) } 1 :- coppia(S1,S2,G). 
% esattamente 2 partite per giornata in ogni girone
2 { gioca(S1,S2,G,T) : coppia(S1,S2,G) } 2 :- girone(G), giornata(T).
% ogni squadra gioca una sola volta per giornata
:- squadra(S), giornata(T), 
   #count { O : gioca(S,O,G,T); O : gioca(O,S,G,T) } != 1.


% CALENDARIO
calendario(G,T,S1,S2) :- gioca(S1,S2,G,T).

% Predicato che mostra squadra, girone, categoria e zona
mostra_info(S, G, C, Z) :- 
    squadra(S),
    girone(G),
    categoria(C),
    assegna(S, C),
    appartiene(S, Z),
    inGirone(S, G).
    
#show mostra_info/4.

% #show assegna/2.
% #show inGirone/2.
% #show appartiene/2.
%#show calendario/4.
