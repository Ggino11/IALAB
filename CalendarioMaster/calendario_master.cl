% CONST
#const n_settimane = 24.
#const max_ore_docente_pgiorno = 4.

% DOMINIO
settimana(1..n_settimane).
% settimana_full_time(7; 16).
giorno(lunedi;martedi;mercoledi;giovedi;venerdi; sabato).

%   precede/2 indica l'ordine dei giorni della settimana
%   precede/4 indica l'ordinamento di due date
precede(lun, mar; mar, mer; mer, gio; gio, ven; ven, sab).
precede(X,Z) :- precede(X,Y), precede(Y,Z).


precede(S1, G1, S2, G2) :- settimana(S1), settimana(S2), giorno(G1), giorno(G2), S1 < S2.
precede(S1, G1, S2, G2) :- settimana(S1), settimana(S2), giorno(G1), giorno(G2), S1 = S2, precede(G1, G2).

% ore disponibili per ogni giorno
ore(S, venerdi, 8) :- settimana(S).
ore(S, sabato, 6) :- settimana(S).
ore(7, G, 8) :- giorno(G), G != sabato.
ore(7, sabato, 6).
ore(16, G, 8) :- giorno(G), G != sabato.
ore(16, sabato, 6).
ore(S, G, 0) :- settimana(S), giorno(G), not ore(S, G, 6), not ore(S, G, 8).


%Definizione regole per docenti,e ore per insegnamento (estratti automaticamente dagli insegnamenti)
docente(D) :- insegnamento(_, D, _).
% tot_ore_insegnamento(I, O) :- insegnamento(I, _, O).

% Definizione fatti per gli insegnamenti: insegnamento(Nome, Docente, OreTotali) 
insegnamento(project_management,                                                    muzzetto,    14).
insegnamento(fondamenti_di_ICT_e_paradigmi_di_programmazione,                       pozzato,     14).
insegnamento(linguaggi_di_markup,                                                   gena,        20).
insegnamento(la_gestione_della_qualita,                                             tomatis,     10).
insegnamento(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web,               micalizio,   20).
insegnamento(progettazione_grafica_e_design_di_interfacce,                          terranova,   10).
insegnamento(progettazione_di_basi_di_dati,                                         mazzei,      20).
insegnamento(strumenti_e_metodi_di_interazione_nei_social_media,                    giordani,    14).
insegnamento(acquisizione_ed_elaborazione_di_immagini_statiche_grafica,             zanchetta,   14).
insegnamento(accessibilita_e_usabilita_nella_progettazione_multimediale,            gena,        14).
insegnamento(marketing_digitale,                                                    muzzetto,    10).
insegnamento(elementi_di_fotografia_digitale,                                       vargiu,      10).
insegnamento(risorse_digitali_per_il_progetto_collaborazione_e_documentazione,      boniolo,     10).
insegnamento(tecnologie_server_side_per_il_web,                                     damiano,     20).
insegnamento(tecniche_e_strumenti_di_marketing_digitale,                            zanchetta,   10).
insegnamento(introduzione_al_social_media_management,                               suppini,     14).
insegnamento(acquisizione_ed_elaborazione_del_suono,                                valle,       10).
insegnamento(acquisizione_ed_elaborazione_di_sequenze_di_immagini_digitali,         ghidelli,    20).
insegnamento(comunicazione_pubblicitaria_e_comunicazione_pubblica,                  gabardi,     14).
insegnamento(semiologia_e_multimedialita,                                           santangelo,  10).
insegnamento(crossmedia_articolazione_delle_scritture_multimediali,                 taddeo,      20).
insegnamento(grafica_3d,                                                            gribaudo,    20).
insegnamento(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I,  pozzato,     10).
insegnamento(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_II, schifanella, 10).
insegnamento(la_gestione_delle_risorse_umane,                                       lombardo,    10).
insegnamento(i_vincoli_giuridici_del_progetto_diritto_dei_media,                    travostino,  10).
% VR 4: il calendario deve prevedere almeno 6 blocchi liberi di 2 ore ciascuno
% per eventuali recuperi di lezioni annullate o rinviate
insegnamento(recupero,                                                              nessun_docente, 12).
        

% CALENDARIO LEZIONI
% V2: durata ammissibile per ogni lezione
durata_lezione(2..4).

% lezione(Settimana, Giorno, NumeroOre, NomeInsegnamento, Docente)
% rappresenta la lezione fissata in calendario

%  in astratto, vediamo le lezioni come il prodotto cartesiano di date, insegnamenti e durate possibili;
%  ciascun elemento del prodotto cartesiano può costituire un fatto oppure no (una ipotetica lezione può essere fissata oppure no)
0 {lezione(S, G, NumOre, NomeInsegnamento, Docente)} 1 :- insegnamento(NomeInsegnamento,Docente,_), settimana(S), giorno(G), durata_lezione(NumOre), ore(S, G, OreDisponibili), NumOre <= OreDisponibili.

%   Le lezioni di un giorno devono rispettare il numero massimo di ore disponibili
:- settimana(S), giorno(G), ore(S, G, OreMassime), 
    #sum{NumOre, NomeInsegnamento : lezione(S, G, NumOre, NomeInsegnamento, _)} > OreMassime.

%   Per ogni insegnamento deve essere fissato esattamente il numero previsto di ore di lezione
:- insegnamento(NomeInsegnamento,_, OreTotali), 
    OreTotali != #sum{NumOre, S, G : lezione(S, G, NumOre, NomeInsegnamento, _)}.


% V1: stesso docente non può svolgere più di 4 ore di lezione di un giorno (max 4 ore/giorno)
:- docente(Docente), Docente != nessun_docente, settimana(S), giorno(G), #sum{ Ore, NomeInsegnamento : lezione(S, G, Ore, NomeInsegnamento, Docente)} > max_ore_docente_pgiorno.



% V3: presentazione master prime 2 ore settimana 1, == venerdì
lezione(1,venerdi,2,presentazione_master,nessun_docente).

% V4: il calendario deve prevedere almeno 6 blocchi liberi da 2 ore ciascuno per recuperi
% :- insegnamento(recupero, _, OreRecupero), OreRecupero != #sum{NumOre, S, G : lezione(S, G, NumOre, recupero, _)}.
:- lezione(S,G,O,recupero,_),O != 2.
:- #count{ S,G : lezione(S,G,2,recupero,_)} != 6.

% V5: project management deve finire entro settimana 7 == prima settimana full time
:- lezione(S,_,_,project_management,_), S > 7.


% V6: accessibilità deve iniziare prima che finisca linguaggi di markup
% ultima_lezione trova ultima occorrenza della lezione linguaggi di markup e la prima di accessibilità 
ultima_lezione_markup(SUlt, GUlt) :- 
    lezione(SUlt, GUlt, _, linguaggi_di_markup, _),
    not lezione(S, G, _, linguaggi_di_markup, _) : precede(SUlt, GUlt, S, G).

:- lezione(SAcc, GAcc, _, accessibilita_e_usabilita_nella_progettazione_multimediale, _),
    ultima_lezione_markup(SMarkup, GMarkup),
    precede(SMarkup, GMarkup, SAcc, GAcc).


%V7: la distanza tra la prima e l'ultima lezione di ciascun insegnamento non deve superare le 8 settimane
% NEED TESTING NON SO SE SI POSSA FARE LA DIFFERENZA TRA VARIABILI IN CLINGO 
:- insegnamento(Nome, _, _),
    lezione(S1, _, _, Nome, _), lezione(S2, _, _, Nome, _),
    S2 - S1 > 8.

% V8:le ore di tecnologie server side  devono essre organizzate in 5 blocchi da 4 ore ciascuno
:- lezione(S,G,O,tecnologie_server_side_per_il_web,_),O != 4.
:- #count{ S,G : lezione(S,G,4,tecnologie_server_side_per_il_web,_)} != 5.

% V9: le prime lezione degli insegnamenti "Crossmedia articolazione delle scritture multimediali" e "Introduzione al social media management" devono essere collocate nella seconda settimana full tme 
:- lezione(S, _, _, crossmedia_articolazione_delle_scritture_multimediali, _), S != 16.
:- lezione(S, _, _, introduzione_al_social_media_management, _), S != 16.

% V10: rispetta propedeuticità tra insegnamenti
% Propedeuticità tra insegnamenti: propedeutico(Insegnamento_precedente, Insegnamento_successivo)
propedeutico(fondamenti_di_ICT_e_paradigmi_di_programmazione, ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web).
propedeutico(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web,
 progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I).
propedeutico(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I,
             progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_II).
propedeutico(progettazione_di_basi_di_dati, tecnologie_server_side_per_il_web).
propedeutico(linguaggi_di_markup, ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web).
propedeutico(project_management, marketing_digitale).
propedeutico(marketing_digitale, tecniche_e_strumenti_di_marketing_digitale).
propedeutico(project_management, strumenti_e_metodi_di_interazione_nei_social_media).
propedeutico(project_management, progettazione_grafica_e_design_di_interfacce).
propedeutico(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, elementi_di_fotografia_digitale).
propedeutico(elementi_di_fotografia_digitale, acquisizione_ed_elaborazione_di_sequenze_di_immagini_digitali).
propedeutico(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, grafica_3d).


%   Vincolo di propedeuticità: la prima lezione del corso successivo deve essere dopo l'ultima del corso precedente
:- propedeutico(CorsoPrec, CorsoSucc),
    ultima_lezione(CorsoPrec, SPrec, GPrec),
    prima_lezione(CorsoSucc, SSucc, GSucc),
    not precede(SPrec, GPrec, SSucc, GSucc).

%   Funzioni di supporto per prima e ultima lezione
prima_lezione(Corso, S, G) :- 
    lezione(S, G, _, Corso, _),
    not lezione(S2, G2, _, Corso, _) : precede(S2, G2, S, G).

ultima_lezione(Corso, S, G) :- 
    lezione(S, G, _, Corso, _),
    not lezione(S2, G2, _, Corso, _) : precede(S, G, S2, G2).

% #show giorno_master/3.
#show lezione/5.