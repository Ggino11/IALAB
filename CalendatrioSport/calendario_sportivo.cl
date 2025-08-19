% costanti per scalabilità del programma e parametrizzare il modello 
% TODO: 10 europee
% TODO: 4 nord-centroamericane
% TODO: 4 asiatiche
% TODO: 4 africane
% TODO: 2 oceania
% TODO: ogni girone devono essere presenti squadre nazionali rappresentanti almeno 3 diverse zone continentali
% TODO: 3 giornate pr turno in cui le 4 squadre di ciascun girone sono impegnate e si affrontano a 2 a 2
% TODO: ogni squadra affronta le altre 3 del girone una per giornata

#const squadre = 32.
#const n_gironi = 8.
#const squadre_per_girone = 4.
#const n_giornate = 3.
% squadre per ogni categoria
#const percat = squadre / 4.

squadra(s1;s2;s3;s4;s5;s6;s7;s8;s9;s10;s11;s12;s13;s14;s15;s16;s17;s18;s19;s20;s21;s22;s23;s24;s25;s26;s27;s28;s29;s30;s31;s32).
giornata(1..n_giornate).
% girone(1..n_gironi).
girone(a;b,c;d;e;f;g;h).
categoria(teste_di_serie;prima_fascia;seconda_fascia;underdog).

% assegno per ogni squadra una categoria
1{ assegna(S,C) : categoria(C)}1 :- squadra(S).
percat{ assegna(S,C) : squadra(S)}percat :- categoria(C).

% ogni squadra in un solo girone
1 { inGirone(S,G) : girone(G) } 1 :- squadra(S).

% esattamente 4 squadre per girone 
squadre_per_girone { inGirone(S,G) : squadra(S) } squadre_per_girone :- girone(G).

% in ogni girone una e una sola squadra per ciascuna categoria
:- girone(G), categoria(C), #count { S : inGirone(S,G), assegna(S,C) } != 1.

% in ogni girone deve esserci una squadra per categoria
% #show assegna/2.
#show inGirone/2.