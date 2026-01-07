;; ================================================================
;; AGENTE STRATEGICO - Battaglia Navale
;; Distinzione tra NAVI CERTE e IPOTESI:
;; - CERTA = scoperta via FIRE o forzata (adiacente a LEFT/RIGHT/TOP/BOT)
;; - IPOTESI = guess probabilistico (puo essere sbagliata)
;; Completamento riga/colonna conta SOLO navi certe!
;; ================================================================

(defmodule AGENT (import MAIN ?ALL) (import ENV ?ALL) (export ?ALL))

;; ================================================================
;; TEMPLATE MEMORIA AGENTE
;; ================================================================

;; r-cell con slot certain: yes = certa, no = ipotesi
(deftemplate r-cell 
    (slot x) 
    (slot y) 
    (slot content)
    (slot certain (default no))
)

(deftemplate my-guess (slot x) (slot y))
(deftemplate my-fire (slot x) (slot y))
(deftemplate initialized (slot done))

;; Traccia righe e colonne sature (trovate tutte le navi CERTE)
(deftemplate row-complete (slot row))
(deftemplate col-complete (slot col))

;; ================================================================
;; FUNZIONI HELPER
;; ================================================================

;; Conta SOLO navi CERTE in una riga
(deffunction count-certain-ships-in-row (?row)
    (bind ?count 0)
    (do-for-all-facts ((?r r-cell)) 
        (and (eq ?r:x ?row) (neq ?r:content water) (eq ?r:certain yes))
        (bind ?count (+ ?count 1))
    )
    ?count
)

;; Conta SOLO navi CERTE in una colonna
(deffunction count-certain-ships-in-col (?col)
    (bind ?count 0)
    (do-for-all-facts ((?r r-cell)) 
        (and (eq ?r:y ?col) (neq ?r:content water) (eq ?r:certain yes))
        (bind ?count (+ ?count 1))
    )
    ?count
)

;; Conta celle VERAMENTE SCONOSCIUTE in una riga
;; Celle senza r-cell (anche se c'e' my-guess, conta come unknown per la forzatura)
(deffunction count-unknown-in-row (?row)
    (bind ?count 0)
    (loop-for-count (?col 0 9)
        (if (not (any-factp ((?r r-cell)) (and (eq ?r:x ?row) (eq ?r:y ?col))))
            then (bind ?count (+ ?count 1))
        )
    )
    ?count
)

;; Conta celle VERAMENTE SCONOSCIUTE in una colonna
;; Celle senza r-cell (anche se c'e' my-guess, conta come unknown per la forzatura)
(deffunction count-unknown-in-col (?col)
    (bind ?count 0)
    (loop-for-count (?row 0 9)
        (if (not (any-factp ((?r r-cell)) (and (eq ?r:x ?row) (eq ?r:y ?col))))
            then (bind ?count (+ ?count 1))
        )
    )
    ?count
)

;; Navi rimanenti da trovare in una riga
(deffunction remaining-ships-in-row (?row ?expected)
    (- ?expected (count-certain-ships-in-row ?row))
)

;; Navi rimanenti da trovare in una colonna
(deffunction remaining-ships-in-col (?col ?expected)
    (- ?expected (count-certain-ships-in-col ?col))
)



;; Verifica se una cella e' diagonale a qualsiasi nave certa
;; Restituisce TRUE se c'e' una nave certa in una delle 4 diagonali
(deffunction is-diagonal-to-certain-ship (?x ?y)
    (or
        ;; Diagonale in alto a sinistra
        (any-factp ((?r r-cell)) 
            (and (eq ?r:x (- ?x 1)) (eq ?r:y (- ?y 1)) 
                 (neq ?r:content water) (eq ?r:certain yes)))
        ;; Diagonale in alto a destra  
        (any-factp ((?r r-cell)) 
            (and (eq ?r:x (- ?x 1)) (eq ?r:y (+ ?y 1)) 
                 (neq ?r:content water) (eq ?r:certain yes)))
        ;; Diagonale in basso a sinistra
        (any-factp ((?r r-cell)) 
            (and (eq ?r:x (+ ?x 1)) (eq ?r:y (- ?y 1)) 
                 (neq ?r:content water) (eq ?r:certain yes)))
        ;; Diagonale in basso a destra
        (any-factp ((?r r-cell)) 
            (and (eq ?r:x (+ ?x 1)) (eq ?r:y (+ ?y 1)) 
                 (neq ?r:content water) (eq ?r:certain yes)))
    )
)

;; ================================================================
;; DEBUG (solo all'inizio)
;; ================================================================

(defrule debug-print-visible-facts
    (declare (salience 2000))
    (not (initialized (done yes)))
=>
    (assert (initialized (done yes)))
    (printout t "=== AGENTE STRATEGICO ===" crlf)
    (do-for-all-facts ((?f k-per-row)) TRUE
        (printout t "  Row " ?f:row " = " ?f:num crlf)
    )
    (do-for-all-facts ((?f k-per-col)) TRUE
        (printout t "  Col " ?f:col " = " ?f:num crlf)
    )
    (printout t "k-cell note:" crlf)
    (do-for-all-facts ((?f k-cell)) TRUE
        (printout t "  [" ?f:x "," ?f:y "] = " ?f:content crlf)
    )
    (printout t "============================" crlf)
)

;; ================================================================
;; FASE 0: COPIA K-CELL IN R-CELL (CERTE!)
;; ================================================================

;; CONTINUOUS LEARNING: copia k-cell appena appaiono (anche dopo FIRE)
(defrule learn-kcell-continuously
    (declare (salience 1000))
    (k-cell (x ?x) (y ?y) (content ?c))
    (not (r-cell (x ?x) (y ?y)))
=>
    (assert (r-cell (x ?x) (y ?y) (content ?c) (certain yes)))
    (printout t ">>> CERTA: [" ?x "," ?y "] = " ?c crlf)
)

;; ================================================================
;; FASE 1: DEDUZIONI ACQUA (tutte CERTE)
;; ================================================================

(defrule deduce-row-zero
    (declare (salience 500))
    (k-per-row (row ?x) (num 0))
    (cell (x ?x) (y ?y))
    (not (r-cell (x ?x) (y ?y)))
=>
    (assert (r-cell (x ?x) (y ?y) (content water) (certain yes)))
    (printout t "  DEDUCE: row=0 -> [" ?x "," ?y "]=water" crlf)
)

(defrule deduce-col-zero
    (declare (salience 500))
    (k-per-col (col ?y) (num 0))
    (cell (x ?x) (y ?y))
    (not (r-cell (x ?x) (y ?y)))
=>
    (assert (r-cell (x ?x) (y ?y) (content water) (certain yes)))
    (printout t "  DEDUCE: col=0 -> [" ?x "," ?y "]=water" crlf)
)

(defrule deduce-water-around-sub
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content sub) (certain yes))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)
               (>= ?nx (- ?x 1)) (<= ?nx (+ ?x 1))
               (>= ?ny (- ?y 1)) (<= ?ny (+ ?y 1))
               (not (and (eq ?nx ?x) (eq ?ny ?y)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water) (certain yes)))
    (printout t "  DEDUCE: attorno SUB[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

(defrule deduce-water-around-left
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content left) (certain yes))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)))
    (test (or (and (eq ?nx (- ?x 1)) (eq ?ny ?y))
              (and (eq ?nx (+ ?x 1)) (eq ?ny ?y))
              (and (eq ?nx ?x) (eq ?ny (- ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (+ ?y 1)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water) (certain yes)))
    (printout t "  DEDUCE: attorno LEFT[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

(defrule deduce-water-around-right
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content right) (certain yes))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)))
    (test (or (and (eq ?nx (- ?x 1)) (eq ?ny ?y))
              (and (eq ?nx (+ ?x 1)) (eq ?ny ?y))
              (and (eq ?nx ?x) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (- ?y 1)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water) (certain yes)))
    (printout t "  DEDUCE: attorno RIGHT[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

(defrule deduce-water-around-top
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content top) (certain yes))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)))
    (test (or (and (eq ?nx ?x) (eq ?ny (- ?y 1)))
              (and (eq ?nx ?x) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny ?y))
              (and (eq ?nx (- ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny (+ ?y 1)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water) (certain yes)))
    (printout t "  DEDUCE: attorno TOP[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

(defrule deduce-water-around-bot
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content bot) (certain yes))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)))
    (test (or (and (eq ?nx ?x) (eq ?ny (- ?y 1)))
              (and (eq ?nx ?x) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny ?y))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (+ ?y 1)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water) (certain yes)))
    (printout t "  DEDUCE: attorno BOT[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

(defrule deduce-water-around-middle
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content middle) (certain yes))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)))
    (test (or (and (eq ?nx (- ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (+ ?y 1)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water) (certain yes)))
    (printout t "  DEDUCE: attorno MID[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

;; Deduzione diagonali per BOAT generico (da GUESS CERTO)
;; Sappiamo per certo che le diagonali di qualsiasi pezzo nave = water
(defrule deduce-water-diagonals-boat
    (declare (salience 390))
    (r-cell (x ?x) (y ?y) (content boat) (certain yes))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)))
    (test (or (and (eq ?nx (- ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (+ ?y 1)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water) (certain yes)))
    (printout t "  DEDUCE: diagonale BOAT[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

;; DEDUCE water attorno a BOAT generico (creato da guess adiacenti)
(defrule deduce-water-around-boat
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content boat) (certain yes))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)))
    ;; Solo diagonali per boat generico
    (test (or (and (eq ?nx (- ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (+ ?y 1)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water) (certain yes)))
    (printout t "  DEDUCE: diagonale BOAT[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)



;; ================================================================
;; FASE 1.5: CHECK RIGA/COLONNA SATURA (SOLO NAVI CERTE!)
;; La regola scatta quando esiste almeno una nave certa nella riga
;; e il conteggio raggiunge il target
;; ================================================================

;; K=0 rows/cols are automatically complete
(defrule check-row-complete-zero
    (declare (salience 301))
    (k-per-row (row ?x) (num 0))
    (not (row-complete (row ?x)))
=>
    (assert (row-complete (row ?x)))
    (printout t "*** RIGA " ?x " COMPLETA (K=0) ***" crlf)
)

(defrule check-col-complete-zero
    (declare (salience 301))
    (k-per-col (col ?y) (num 0))
    (not (col-complete (col ?y)))
=>
    (assert (col-complete (col ?y)))
    (printout t "*** COLONNA " ?y " COMPLETA (K=0) ***" crlf)
)

(defrule check-row-complete
    (declare (salience 300))
    (k-per-row (row ?x) (num ?expected&:(> ?expected 0)))
    (not (row-complete (row ?x)))
    ;; Trigger: deve esistere almeno una nave certa in questa riga
    (r-cell (x ?x) (content ?c&~water) (certain yes))
    ;; Test: il conteggio delle navi certe >= target
    (test (>= (count-certain-ships-in-row ?x) ?expected))
=>
    (assert (row-complete (row ?x)))
    (printout t "*** RIGA " ?x " SATURA! (" (count-certain-ships-in-row ?x) "/" ?expected " navi CERTE) ***" crlf)
)

(defrule check-col-complete
    (declare (salience 300))
    (k-per-col (col ?y) (num ?expected&:(> ?expected 0)))
    (not (col-complete (col ?y)))
    ;; Trigger: deve esistere almeno una nave certa in questa colonna
    (r-cell (y ?y) (content ?c&~water) (certain yes))
    ;; Test: il conteggio delle navi certe >= target
    (test (>= (count-certain-ships-in-col ?y) ?expected))
=>
    (assert (col-complete (col ?y)))
    (printout t "*** COLONNA " ?y " SATURA! (" (count-certain-ships-in-col ?y) "/" ?expected " navi CERTE) ***" crlf)
)

;; ================================================================
;; FASE 1.6: DEDUZIONE CELLE FORZATE
;; Se righe/colonne hanno esattamente N celle sconosciute e N navi mancanti,
;; quelle celle DEVONO essere navi (GUESS CERTO)
;; ================================================================

;; Deduzione cella forzata in RIGA
;; Se remaining_ships == unknown_cells, le celle sconosciute DEVONO essere navi
;; NOTA: Funziona anche se c'è già un guess ipotetico (lo rendiamo certo)
;; Deduzione cella forzata in RIGA
;; Salience 280: deve girare DOPO deduce-water-row/col-complete (290)
(defrule deduce-forced-ship-row
    (declare (salience 280))
    (status (step ?s) (currently running))
    (k-per-row (row ?x) (num ?expected&:(> ?expected 0)))
    (not (row-complete (row ?x)))
    (k-per-col (col ?y))
    (not (r-cell (x ?x) (y ?y)))
    ;; Verifica: navi rimanenti == celle sconosciute
    (test (= (remaining-ships-in-row ?x ?expected) (count-unknown-in-row ?x)))
    (test (> (count-unknown-in-row ?x) 0))
=>
    (assert (r-cell (x ?x) (y ?y) (content boat) (certain yes)))
    (printout t "  DEDUCE FORZATO: riga " ?x " ha " (count-unknown-in-row ?x) " celle = " (remaining-ships-in-row ?x ?expected) " navi -> [" ?x "," ?y "]=nave" crlf)
)

;; Deduzione cella forzata in COLONNA
(defrule deduce-forced-ship-col
    (declare (salience 280))
    (status (step ?s) (currently running))
    (k-per-col (col ?y) (num ?expected&:(> ?expected 0)))
    (not (col-complete (col ?y)))
    (k-per-row (row ?x))
    (not (r-cell (x ?x) (y ?y)))
    ;; Verifica: navi rimanenti == celle sconosciute
    (test (= (remaining-ships-in-col ?y ?expected) (count-unknown-in-col ?y)))
    (test (> (count-unknown-in-col ?y) 0))
=>
    (assert (r-cell (x ?x) (y ?y) (content boat) (certain yes)))
    (printout t "  DEDUCE FORZATO: col " ?y " ha " (count-unknown-in-col ?y) " celle = " (remaining-ships-in-col ?y ?expected) " navi -> [" ?x "," ?y "]=nave" crlf)
)
;; FASE 1.6: DEDUZIONE ACQUA IN RIGHE/COLONNE SATURE
;; ================================================================

(defrule deduce-water-row-complete
    (declare (salience 290))
    (row-complete (row ?x))
    (cell (x ?x) (y ?y))
    (not (r-cell (x ?x) (y ?y)))
=>
    (assert (r-cell (x ?x) (y ?y) (content water) (certain yes)))
    (printout t "  DEDUCE: riga " ?x " satura -> [" ?x "," ?y "]=water" crlf)
)

(defrule deduce-water-col-complete
    (declare (salience 290))
    (col-complete (col ?y))
    (cell (x ?x) (y ?y))
    (not (r-cell (x ?x) (y ?y)))
=>
    (assert (r-cell (x ?x) (y ?y) (content water) (certain yes)))
    (printout t "  DEDUCE: col " ?y " satura -> [" ?x "," ?y "]=water" crlf)
)

;; ================================================================
;; FASE 1.7: UNGUESS IPOTESI IN RIGHE/COLONNE SATURE
;; ================================================================

(defrule unguess-hypothesis-row-saturated
    (declare (salience 285))
    (status (step ?s) (currently running))
    (row-complete (row ?x))
    ?mg <- (my-guess (x ?x) (y ?y))
    (not (r-cell (x ?x) (y ?y) (certain yes)))
=>
    (assert (exec (step ?s) (action unguess) (x ?x) (y ?y)))
    (retract ?mg)
    (assert (r-cell (x ?x) (y ?y) (content water) (certain yes)))
    (printout t "Step " ?s ": UNGUESS IPOTESI [" ?x "," ?y "] - riga " ?x " satura!" crlf)
    (pop-focus)
)

(defrule unguess-hypothesis-col-saturated
    (declare (salience 285))
    (status (step ?s) (currently running))
    (col-complete (col ?y))
    ?mg <- (my-guess (x ?x) (y ?y))
    (not (r-cell (x ?x) (y ?y) (certain yes)))
=>
    (assert (exec (step ?s) (action unguess) (x ?x) (y ?y)))
    (retract ?mg)
    (assert (r-cell (x ?x) (y ?y) (content water) (certain yes)))
    (printout t "Step " ?s ": UNGUESS IPOTESI [" ?x "," ?y "] - col " ?y " satura!" crlf)
    (pop-focus)
)




;; UNGUESS standard (scoperto water via FIRE)
(defrule unguess-on-water-discovered
    (declare (salience 250))
    (status (step ?s) (currently running))
    ?mg <- (my-guess (x ?x) (y ?y))
    (r-cell (x ?x) (y ?y) (content water))
=>
    (assert (exec (step ?s) (action unguess) (x ?x) (y ?y)))
    (retract ?mg)
    (printout t "Step " ?s ": UNGUESS [" ?x "," ?y "] - scoperto water!" crlf)
    (pop-focus)
)

;; ================================================================
;; FASE 2: AZIONI
;; ================================================================

;; GUESS su navi note (gia in r-cell) - PRIORITÀ ALTA
(defrule action-guess-known
    (declare (salience 70))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content ?c&~water) (certain yes))
    (not (my-guess (x ?x) (y ?y)))
=>
    (assert (exec (step ?s) (action guess) (x ?x) (y ?y)))
    (assert (my-guess (x ?x) (y ?y)))
    (printout t "Step " ?s ": GUESS nave nota [" ?x "," ?y "] = " ?c crlf)
    (pop-focus)
)

;; FIRE su celle ad alta probabilita - dopo GUESS noti
(defrule action-fire-high-priority
    (declare (salience 60))
    (status (step ?s) (currently running))
    (moves (fires ?f&:(> ?f 0)))
    (k-per-row (row ?x) (num ?rn&:(>= ?rn 3)))
    (k-per-col (col ?y) (num ?cn&:(>= ?cn 3)))
    (not (row-complete (row ?x)))
    (not (col-complete (col ?y)))
    (not (r-cell (x ?x) (y ?y)))
    (not (my-fire (x ?x) (y ?y)))
=>
    (assert (exec (step ?s) (action fire) (x ?x) (y ?y)))
    (assert (my-fire (x ?x) (y ?y)))
    (printout t "Step " ?s ": FIRE [" ?x "," ?y "] (row=" ?rn " col=" ?cn ")" crlf)
    (pop-focus)
)

;; GUESS adiacente a LEFT - CERTO!
(defrule action-guess-adjacent-left
    (declare (salience 55))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content left) (certain yes))
    (test (< (+ ?y 1) 10))
    (not (r-cell (x ?x) (y =(+ ?y 1))))
    (not (my-guess (x ?x) (y =(+ ?y 1))))
=>
    (bind ?ny (+ ?y 1))
    (assert (exec (step ?s) (action guess) (x ?x) (y ?ny)))
    (assert (my-guess (x ?x) (y ?ny)))
    (assert (r-cell (x ?x) (y ?ny) (content boat) (certain yes)))
    (printout t "Step " ?s ": GUESS CERTO dx LEFT [" ?x "," ?ny "]" crlf)
    (pop-focus)
)

;; GUESS adiacente a RIGHT - CERTO!
(defrule action-guess-adjacent-right
    (declare (salience 55))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content right) (certain yes))
    (test (>= (- ?y 1) 0))
    (not (r-cell (x ?x) (y =(- ?y 1))))
    (not (my-guess (x ?x) (y =(- ?y 1))))
=>
    (bind ?ny (- ?y 1))
    (assert (exec (step ?s) (action guess) (x ?x) (y ?ny)))
    (assert (my-guess (x ?x) (y ?ny)))
    (assert (r-cell (x ?x) (y ?ny) (content boat) (certain yes)))
    (printout t "Step " ?s ": GUESS CERTO sx RIGHT [" ?x "," ?ny "]" crlf)
    (pop-focus)
)

;; GUESS adiacente a TOP - CERTO!
(defrule action-guess-adjacent-top
    (declare (salience 55))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content top) (certain yes))
    (test (< (+ ?x 1) 10))
    (not (r-cell (x =(+ ?x 1)) (y ?y)))
    (not (my-guess (x =(+ ?x 1)) (y ?y)))
=>
    (bind ?nx (+ ?x 1))
    (assert (exec (step ?s) (action guess) (x ?nx) (y ?y)))
    (assert (my-guess (x ?nx) (y ?y)))
    (assert (r-cell (x ?nx) (y ?y) (content boat) (certain yes)))
    (printout t "Step " ?s ": GUESS CERTO sotto TOP [" ?nx "," ?y "]" crlf)
    (pop-focus)
)

;; GUESS adiacente a BOT - CERTO!
(defrule action-guess-adjacent-bot
    (declare (salience 55))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content bot) (certain yes))
    (test (>= (- ?x 1) 0))
    (not (r-cell (x =(- ?x 1)) (y ?y)))
    (not (my-guess (x =(- ?x 1)) (y ?y)))
=>
    (bind ?nx (- ?x 1))
    (assert (exec (step ?s) (action guess) (x ?nx) (y ?y)))
    (assert (my-guess (x ?nx) (y ?y)))
    (assert (r-cell (x ?nx) (y ?y) (content boat) (certain yes)))
    (printout t "Step " ?s ": GUESS CERTO sopra BOT [" ?nx "," ?y "]" crlf)
    (pop-focus)
)

;; GUESS adiacente a MIDDLE - CERTO!
(defrule action-guess-adjacent-middle
    (declare (salience 54))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content middle) (certain yes))
    (test (< (+ ?x 1) 10))
    (not (r-cell (x =(+ ?x 1)) (y ?y)))
    (not (my-guess (x =(+ ?x 1)) (y ?y)))
=>
    (bind ?nx (+ ?x 1))
    (assert (exec (step ?s) (action guess) (x ?nx) (y ?y)))
    (assert (my-guess (x ?nx) (y ?y)))
    (assert (r-cell (x ?nx) (y ?y) (content boat) (certain yes)))
    (printout t "Step " ?s ": GUESS CERTO sotto MID [" ?nx "," ?y "]" crlf)
    (pop-focus)
)

;; GUESS a DESTRA di MIDDLE orizzontale - CERTO!
(defrule action-guess-adjacent-middle-right
    (declare (salience 54))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content middle) (certain yes))
    (test (< (+ ?y 1) 10))
    (not (r-cell (x ?x) (y =(+ ?y 1))))
    (not (my-guess (x ?x) (y =(+ ?y 1))))
=>
    (bind ?ny (+ ?y 1))
    (assert (exec (step ?s) (action guess) (x ?x) (y ?ny)))
    (assert (my-guess (x ?x) (y ?ny)))
    (assert (r-cell (x ?x) (y ?ny) (content boat) (certain yes)))
    (printout t "Step " ?s ": GUESS CERTO dx MID [" ?x "," ?ny "]" crlf)
    (pop-focus)
)

;; GUESS a SINISTRA di MIDDLE orizzontale - CERTO!
(defrule action-guess-adjacent-middle-left
    (declare (salience 54))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content middle) (certain yes))
    (test (>= (- ?y 1) 0))
    (not (r-cell (x ?x) (y =(- ?y 1))))
    (not (my-guess (x ?x) (y =(- ?y 1))))
=>
    (bind ?ny (- ?y 1))
    (assert (exec (step ?s) (action guess) (x ?x) (y ?ny)))
    (assert (my-guess (x ?x) (y ?ny)))
    (assert (r-cell (x ?x) (y ?ny) (content boat) (certain yes)))
    (printout t "Step " ?s ": GUESS CERTO sx MID [" ?x "," ?ny "]" crlf)
    (pop-focus)
)


;; GUESS IPOTESI - Alta probabilita (row+col >= 6)
(defrule action-guess-high-probability
    (declare (salience 45))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (k-per-row (row ?x) (num ?rn&:(> ?rn 0)))
    (k-per-col (col ?y) (num ?cn&:(> ?cn 0)))
    (test (>= (+ ?rn ?cn) 6))
    (not (row-complete (row ?x)))
    (not (col-complete (col ?y)))
    (not (r-cell (x ?x) (y ?y)))
    (not (my-guess (x ?x) (y ?y)))
    ;; NON guessare su celle diagonali a navi certe!
    (test (not (is-diagonal-to-certain-ship ?x ?y)))
=>
    (assert (exec (step ?s) (action guess) (x ?x) (y ?y)))
    (assert (my-guess (x ?x) (y ?y)))
    ;; NON creo r-cell - e' solo IPOTESI!
    (printout t "Step " ?s ": GUESS ipotesi [" ?x "," ?y "] (row=" ?rn " col=" ?cn ")" crlf)
    (pop-focus)
)

;; GUESS IPOTESI - Media probabilita (row+col >= 4)
(defrule action-guess-medium-probability
    (declare (salience 42))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (k-per-row (row ?x) (num ?rn&:(> ?rn 0)))
    (k-per-col (col ?y) (num ?cn&:(> ?cn 0)))
    (test (>= (+ ?rn ?cn) 4))
    (test (< (+ ?rn ?cn) 6))
    (not (row-complete (row ?x)))
    (not (col-complete (col ?y)))
    (not (r-cell (x ?x) (y ?y)))
    (not (my-guess (x ?x) (y ?y)))
    ;; NON guessare su celle diagonali a navi certe!
    (test (not (is-diagonal-to-certain-ship ?x ?y)))
=>
    (assert (exec (step ?s) (action guess) (x ?x) (y ?y)))
    (assert (my-guess (x ?x) (y ?y)))
    (printout t "Step " ?s ": GUESS ipotesi [" ?x "," ?y "] (row=" ?rn " col=" ?cn ")" crlf)
    (pop-focus)
)

;; GUESS IPOTESI - Bassa probabilita (row+col >= 2)
(defrule action-guess-low-probability
    (declare (salience 40))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (k-per-row (row ?x) (num ?rn&:(> ?rn 0)))
    (k-per-col (col ?y) (num ?cn&:(> ?cn 0)))
    (test (>= (+ ?rn ?cn) 2))
    (test (< (+ ?rn ?cn) 4))
    (not (row-complete (row ?x)))
    (not (col-complete (col ?y)))
    (not (r-cell (x ?x) (y ?y)))
    (not (my-guess (x ?x) (y ?y)))
    ;; NON guessare su celle diagonali a navi certe!
    (test (not (is-diagonal-to-certain-ship ?x ?y)))
=>
    (assert (exec (step ?s) (action guess) (x ?x) (y ?y)))
    (assert (my-guess (x ?x) (y ?y)))
    (printout t "Step " ?s ": GUESS ipotesi [" ?x "," ?y "] (row=" ?rn " col=" ?cn ")" crlf)
    (pop-focus)
)

;; ================================================================
;; CHIUSURA
;; ================================================================

(defrule action-solve-no-guesses
    (declare (salience 5))
    (status (step ?s) (currently running))
    (moves (guesses 0))
=>
    (assert (exec (step ?s) (action solve)))
    (printout t "Step " ?s ": SOLVE - guesses esaurite" crlf)
    (pop-focus)
)

(defrule action-solve-fallback
    (declare (salience 1))
    (status (step ?s) (currently running))
=>
    (assert (exec (step ?s) (action solve)))
    (printout t "Step " ?s ": SOLVE - fallback" crlf)
    (pop-focus)
)