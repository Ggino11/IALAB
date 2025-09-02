% Heuristic --> Distanza di Manhattan
% la somma delle differenze assolutre tra le coordinate x e y du dye punti
% uso abs/1 per valore assoluto 


% manhattan(CurrentPos, Distance)
% distance: la distanza di Manhattan calcolata fino all'obiettivo più vicino
manhattan(pos(CurrentR, CurrentCol), Distance) :-
    % 'findall' trova tutte le soluzioni per un obiettivo e le raccoglie in una lista.
    % La variabile 'DistanceToGoal' calcola la distanza di Manhattan per ogni obiettivo trovato.
    findall(DistanceToGoal,
            (finale(pos(GoalR, GoalCol)),
             DistanceToGoal is abs(CurrentR - GoalR) + abs(CurrentCol - GoalCol)),
            DistancesList),
    %trova la distanza minima tra tutte quelle calcolate.
    distanza_min(DistancesList, Distance).