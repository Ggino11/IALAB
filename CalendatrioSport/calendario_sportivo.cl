% costanti per scalabilità del programma e parametrizzare il modello 

#const squadre = 32.
#const n_gironi = 8.
#const squadre_per_girone = 4.
#const n_giornate = 3.

squadra(1..squadre).
giornata(1..n_giornate).
girone(1..n_gironi).
categoria(teste_di_serie, prima_fascia, seconda_fascia, underdog).

% assegno per ogni squadra una categoria
1{ assegna(S,C) : categoria(C)}1 :- squadra(S).

% in ogni girone deve esserci una squadra per categoria