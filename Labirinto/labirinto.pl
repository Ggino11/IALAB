/* Dominio del labirito generato con python */

num_righe(10).
num_colonne(10).

iniziale(pos(2,4)).

% Posizioni finali (uscite)
finale(pos(10,10)).
finale(pos(8,1)).

% Celle occupate (ostacoli)
occupata(pos(1,1)).
occupata(pos(6,1)).
occupata(pos(9,1)).
occupata(pos(1,2)).
occupata(pos(6,2)).
occupata(pos(9,2)).
occupata(pos(6,3)).
occupata(pos(8,3)).
occupata(pos(9,3)).
occupata(pos(6,5)).
occupata(pos(8,5)).
occupata(pos(9,5)).
occupata(pos(4,6)).
occupata(pos(5,6)).
occupata(pos(6,6)).
occupata(pos(8,6)).
occupata(pos(9,6)).
occupata(pos(4,7)).
occupata(pos(4,8)).
occupata(pos(5,8)).
occupata(pos(5,9)).
occupata(pos(7,9)).
occupata(pos(9,9)).
occupata(pos(7,10)).
occupata(pos(9,10)).
