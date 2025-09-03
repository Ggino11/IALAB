/* Dominio del labirinto generato tramite python */

num_righe(10).
num_colonne(10).

iniziale(pos(4,2)).

% Posizioni finali (uscite)
finale(pos(10,10)).
finale(pos(1,8)).

% Celle occupate (ostacoli)
% occupata(pos(4,6)).
occupata(pos(1,1)).
occupata(pos(1,6)).
occupata(pos(1,9)).
occupata(pos(2,1)).
occupata(pos(2,6)).
occupata(pos(2,9)).
occupata(pos(3,6)).
occupata(pos(3,8)).
occupata(pos(3,9)).
occupata(pos(5,6)).
occupata(pos(5,8)).
occupata(pos(5,9)).
occupata(pos(6,4)).
occupata(pos(6,5)).
occupata(pos(6,6)).
occupata(pos(6,8)).
occupata(pos(6,9)).
occupata(pos(7,4)).
occupata(pos(8,4)).
occupata(pos(8,5)).
occupata(pos(9,5)).
occupata(pos(9,7)).
occupata(pos(9,9)).
occupata(pos(10,7)).
occupata(pos(10,9)).
                  