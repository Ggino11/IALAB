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

%Definizione regole per docenti,e ore per insegnamento (estratti automaticamente dagli insegnamenti)
docente(D) :- insegnamento(_, D, _).
tot_ore_insegnamento(I, O) :- insegnamento(I, _, O).

% un giorno del master è definito da una settimana, un giorno della settimana e un numero di ore
giorno_master(S, G, O) :- settimana(S), not settimana_full_time(S), giorno_settimana(G), ore_giorno(G, O).
giorno_master(S, G, O) :- settimana_full_time(S), giorno_settimana_full_time(G), ore_giorno(G, O).

% durata ammissibile per ogni lezione, primo vincolo
durata_lezione(2..4).

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
insegnamento(introduzione_al_social_media_management,                                suppini,     14).
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

% Propedeuticità tra insegnamenti: propedeutico(Insegnamento_precedente, Insegnamento_successivo)

propedeutico(fondamenti_di_ICT_e_paradigmi_di_programmazione, ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web).

propedeutico(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web,
 progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobili_I).
propedeutico(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobili_I,
             progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobili_II).
propedeutico(progettazione_di_basi_di_dati, tecnologie_server_side_per_il_web).
propedeutico(linguaggi_di_markup, ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web).
propedeutico(project_management, marketing_digitale).
propedeutico(marketing_digitale, tecniche_e_strumenti_di_marketing_digitale).
propedeutico(project_management, strumenti_e_metodi_di_interazione_nei_social_media).
propedeutico(project_management, progettazione_grafica_e_design_di_interfacce).
propedeutico(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, elementi_di_fotografia_digitale).
propedeutico(elementi_di_fotografia_digitale, acquisizione_ed_elaborazione_di_sequenze_di_immagini_digitali).
propedeutico(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, grafica_3d).

% lezione(Settimana, Giorno, Ore, Insegnamento, Docente)
0 { lezione(S,G,O,I,D) : durata(O), insegnamento(I,D,_) } 1 :- giorno_master(S,G,_).

% non superare le ore disponibili del giorno
:- giorno_master(S,G,Omax), #sum{Ore,I,D : lezione(S,G,Ore,I,D)} > Omax.

% ogni insegnamento deve coprire esattamente le ore totali
:- insegnamento(I,_,OreTot), OreTot != #sum{Ore,S,G : lezione(S,G,Ore,I,_)}.

%secondo vincolo
% Vincolo stesso docente non può svolgere più di 4 ore di lezione di un giorno (max 4 ore/giorno)
:- giorno_master(S, G, _), docente(D), 
   #sum{ Ore, I : lezione(S, G, Ore,I, Docente)} > max_ore_docente_pgiorno.

% vincolo presentazione master prime 2 ore settimana 1, == venerdì
lezione(1,venerdi,2,presentazione_master,nessun_docente).

% vincolo: project management deve finire entro settimana 7 == prima settimana full time
:- lezione(S,_,_,project_management,_), S > 7.

% prima e ultima lezione di un corso per gestire propedeuticità
prima_lezione(I,S,G) :- lezione(S,G,_,I,_), not (lezione(S2,G2,_,I,_), precede(S2,G2,S,G)).
ultima_lezione(I,S,G) :- lezione(S,G,_,I,_), not (lezione(S2,G2,_,I,_), precede(S,G,S2,G2)).

% accessibilità deve iniziare prima che finisca linguaggi di markup
:- ultima_lezione(linguaggi_di_markup,S1,G1),
   prima_lezione(accessibilita_e_usabilita_nella_progettazione_multimediale,S2,G2),
   precede(S1,G1,S2,G2).

% not working i dont know why    
