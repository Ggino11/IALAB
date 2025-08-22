% CONST
#const n_settimane = 24.
#const max_ore_docente_pgiorno = 4.

% DOMINIO
settimana(1..n_settimane).
settimana_full_time(7; 16).
giorno_settimana(venerdi;sabato).
giorno_settimana_full_time(lunedi;martedi;mercoledi;giovedi;venerdi; sabato).
% ore disponibili per ogni giorno
ore_giorno(lunedi, 8).
ore_giorno(martedi, 8).
ore_giorno(mercoledi, 8).
ore_giorno(giovedi, 8).
ore_giorno(venerdi, 8).
ore_giorno(sabato, 6).

% Definizione fatti per gli insegnamenti: insegnamento(Nome, Docente, OreTotali) 
insegnamento("Project Management", "Muzzetto", 14).
insegnamento("Fondamenti di ICT e Paradigmi di Programmazione", "Pozzato", 14).
insegnamento("Linguaggi di markup", "Schifanella Rossano", 20).
insegnamento("La gestione della qualità", "Tomatis", 10).
insegnamento("Ambienti di sviluppo e linguaggi client-side per il web", "Micalizio", 20).
insegnamento("Progettazione grafica e design di interfacce", "Terranova", 10).
insegnamento("Progettazione di basi di dati", "Mazzei", 20).
insegnamento("Strumenti e metodi di interazione nei Social media", "Giordani", 14).
insegnamento("Acquisizione ed elaborazione di immagini statiche - grafica", "Zanchetta", 14).
insegnamento("Accessibilità e usabilità nella progettazione multimediale", "Gena", 14).
insegnamento("Marketing digitale", "Muzzetto", 10).
insegnamento("Elementi di fotografia digitale", "Vargiu", 10).
insegnamento("Risorse digitali per il progetto: collaborazione e documentazione", "Boniolo", 10).
insegnamento("Tecnologie server-side per il web", "Damiano", 20).
insegnamento("Tecniche e strumenti di Marketing digitale", "Zanchetta", 10).
insegnamento("Introduzione ai social media management", "Suppini", 14).
insegnamento("Acquisizione ed elaborazione del suono", "Valle", 10).
insegnamento("Acquisizione ed elaborazione di sequenze di immagini digitali", "Ghidelli", 20).
insegnamento("Comunicazione pubblicitaria e comunicazione pubblica", "Gabardi", 14).
insegnamento("Semiologia e multimedialità", "Santangelo", 10).
insegnamento("Crossmedia: articolazione delle scritture multimediali", "Taddeo", 20).
insegnamento("Grafica 3D", "Gribaudo", 20).
insegnamento("Progettazione e sviluppo di applicazioni web su dispositivi mobile I", "Schifanella Rossano", 10).
insegnamento("Progettazione e sviluppo di applicazioni web su dispositivi mobile II", "Schifanella Claudio", 10).
insegnamento("La gestione delle risorse umane", "Lombardo", 10).
insegnamento("I vincoli giuridici del progetto: diritto del media", "Travostino", 10).

% Definizione regole per docenti,e ore per insegnamento (estratti automaticamente dagli insegnamenti)
docente(D) :- insegnamento(_, D, _).
tot_ore_insegnamento(I, O) :- insegnamento(I, _, O).

% un giorno del master è definito da una settimana, un giorno della settimana e un numero di ore
giorno_master(S, G, O) :- settimana(S), not settimana_full_time(S), giorno_settimana(G), ore_giorno(G, O).
giorno_master(S, G, O) :- settimana_full_time(S), giorno_settimana_full_time(G), ore_giorno(G, O).

%primo vincolo
% Regola di assegnazione: allo stesso giorno(2,3,4 ore per giorno)
{ assegna(I, S, G, O) : insegnamento(I, _, _), giorno_master(S, G, MaxOre), O = 2..4, O <= MaxOre }.

%secondo vincolo
% Vincolo stesso docente non può svolgere più di 4 ore di lezione di un giorno (max 4 ore/giorno)
:- giorno_master(S, G, _), 
   docente(D), 
   #sum{ O : assegna(I, S, G, O), insegnamento(I, D, _) } > max_ore_docente_pgiorno.

% Vincoli di sicurezza sulle ore
:- assegna(_, _, _, O), O < 2.    % No meno di 2 ore
:- assegna(_, _, _, O), O > 4.    % No più di 4 ore          

%#show docente/1.
%#show tot_ore_insegnamento/2.
%#show ore_giorno/2.
%#show giorno_master/3.
#show assegna/4.



