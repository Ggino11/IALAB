# 🧠 IALAB - Intelligenza Artificiale e Laboratorio

Progetto d'esame per il corso di **Intelligenza Artificiale e Laboratorio** dell'Università di Torino.

Repository contenente implementazioni di algoritmi di ricerca in Prolog e soluzioni di scheduling con Answer Set Programming (Clingo/ASP).

---

## 📂 Struttura del Progetto

| Cartella | Descrizione | Tecnologia |
|----------|-------------|------------|
| [`Labirinto/`](./Labirinto/) | Risoluzione di labirinti con A* e IDA* | Prolog |
| [`Puzzle_8/`](./Puzzle_8/) | Risoluzione del puzzle dell'8 con A* e IDA* | Prolog |
| [`CalendarioMaster/`](./CalendarioMaster/) | Generazione calendario Master in Comunicazione Digitale | Clingo/ASP |
| [`CalendatrioSport/`](./CalendatrioSport/) | Generazione calendario competizione sportiva | Clingo/ASP |
| [`battle-2025/`](./battle-2025/) | Agente per battaglia navale | CLIPS |

---

## 🎯 Attività 1: Prolog - Algoritmi di Ricerca

Implementazione e confronto delle strategie **A*** e **IDA*** sui seguenti domini:

### 🧩 Labirinto

Labirinto con almeno due uscite (non necessariamente raggiungibili).

#### Risultati Sperimentali

| Labirinto | A* (passi/tempo) | IDA* (passi/tempo) | Note |
|-----------|------------------|---------------------|------|
| 10×10 | 9 / 0.013s | 9 / 0.138s | ✅ Percorso ottimale |
| 20×20 | 36 / 0.015s | 36 / 0.022s | ✅ Percorso ottimale |
| 30×30 | — | — | ⚠️ Uscite non raggiungibili |
| 50×50 | 37 / 0.036s | 37 / 0.111s | ✅ Percorso ottimale |
| 100×100 | 103 / 0.247s | 103 / 1.031s | ✅ Percorso ottimale |

📖 **[Documentazione completa →](./Labirinto/README.md)**

### 🔢 Puzzle dell'8

Puzzle 3×3 con 8 tessere numerate e una casella vuota.

#### Risultati Sperimentali

| Algoritmo | Mosse | Tempo |
|-----------|-------|-------|
| IDA* | 20 | 0.302s |
| A* | 20 | 2.298s |

> **Nota**: Per il Puzzle-8, IDA* risulta più veloce di A* grazie al minor overhead di gestione della memoria.

---

## 🎯 Attività 2: Clingo/ASP - Scheduling

### 🏆 Calendario Sportivo

Generazione del calendario del primo turno di una competizione sportiva con:
- 32 squadre divise in 6 zone continentali
- 8 gironi da 4 squadre
- Vincoli su fasce (teste di serie, prima fascia, seconda fascia, underdog)
- Almeno 3 zone continentali per girone

### 📚 Calendario Master

Generazione del calendario del "Master in Progettazione della Comunicazione Digitale" con:
- 24 settimane di lezioni (venerdì e sabato)
- 2 settimane full-time (7ª e 16ª)
- 24 insegnamenti con vincoli di propedeuticità
- Vincoli su docenti (max 4 ore/giorno)

---

## 🚀 Come Eseguire

### Prerequisiti

- [SWI-Prolog](https://www.swi-prolog.org/) per i progetti Prolog
- [Clingo](https://potassco.org/clingo/) per i progetti ASP
- [CLIPS](http://www.clipsrules.net/) per la battaglia navale
- Python 3.x per il generatore di labirinti

### Esempio: Labirinto

```bash
cd Labirinto
swipl -g "[labirinto10x10], [azioni], [heuristic], [ida_star], [a_star], [main], main, halt."
```

### Esempio: Puzzle 8

```bash
cd Puzzle_8
swipl -g "[main], main."
```
---

## 🎯 Attività 3: CLIPS - Battaglia Navale

Progetto di un agente intelligente per il gioco della battaglia navale.

### Strategie Implementate

1.  **Agente Semplice (`Agent_Simple.clp`)**: Approccio greedy che spara nelle zone a più alta probabilità e utilizza deduzioni base (acqua intorno alle navi colpite).
2.  **Agente Strategico (`Agent_strategic.clp`)**: Sistema esperto a fasi con:
    *   Ragionamento su certezze vs ipotesi
    *   Regole di "chiusura" per righe e colonne sature
    *   Deduzioni forzate (celle ignote = navi mancanti)
    *   Backtracking logico (`unguess`)

### Esempio Esecuzione

```bash
cd battle-2025
# Esecuzione Agente Strategico dentro clips
(load 0_Main.clp)
(load 1_Env.clp)
(load mapEnviroment.clp) ; Carica scenario
(load Agent_strategic.clp)
(reset)
(run)
```

---

## 👥 Autore

Simone Amitrano,
Progetto sviluppato per il corso IALAB - Università di Torino

---

## 📝 Licenza

Progetto a scopo didattico.