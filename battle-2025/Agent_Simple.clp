;; ================================================================
;; AGENTE SEMPLICE - Battaglia Navale
;; Strategia: Fire prima, deduzioni, tracciamento righe complete
;; ================================================================

(defmodule AGENT (import MAIN ?ALL) (import ENV ?ALL) (export ?ALL))

;; ================================================================
;; TEMPLATE MEMORIA AGENTE
;; ================================================================

(deftemplate r-cell (slot x) (slot y) (slot content))
(deftemplate my-guess (slot x) (slot y))
(deftemplate my-fire (slot x) (slot y))
(deftemplate initialized (slot done))

;; NUOVO: Traccia righe e colonne "complete" (trovate tutte le navi)
(deftemplate row-complete (slot row))
(deftemplate col-complete (slot col))

;; Contatori navi trovate per riga/colonna
(deftemplate ship-count-row (slot row) (slot count))
(deftemplate ship-count-col (slot col) (slot count))

;; ================================================================
;; FUNZIONI HELPER
;; ================================================================

;; Conta quante navi (r-cell != water) ci sono in una riga
(deffunction count-ships-in-row (?row)
    (bind ?count 0)
    (do-for-all-facts ((?r r-cell)) 
        (and (eq ?r:x ?row) (neq ?r:content water))
        (bind ?count (+ ?count 1))
    )
    ?count
)

;; Conta quante navi (r-cell != water) ci sono in una colonna
(deffunction count-ships-in-col (?col)
    (bind ?count 0)
    (do-for-all-facts ((?r r-cell)) 
        (and (eq ?r:y ?col) (neq ?r:content water))
        (bind ?count (+ ?count 1))
    )
    ?count
)

;; ================================================================
;; DEBUG (solo all'inizio)
;; ================================================================

(defrule debug-print-visible-facts
    (declare (salience 2000))
    (not (initialized (done yes)))
=>
    (assert (initialized (done yes)))
    (printout t "=== CONOSCENZA INIZIALE ===" crlf)
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
;; FASE 0: COPIA K-CELL IN R-CELL
;; ================================================================

(defrule init-copy-kcell
    (declare (salience 1000))
    (k-cell (x ?x) (y ?y) (content ?c))
    (not (r-cell (x ?x) (y ?y)))
=>
    (assert (r-cell (x ?x) (y ?y) (content ?c)))
    (printout t ">>> Nuova conoscenza: r-cell [" ?x "," ?y "] = " ?c crlf)
)

;; ================================================================
;; FASE 1: DEDUZIONI
;; ================================================================

(defrule deduce-row-zero
    (declare (salience 500))
    (k-per-row (row ?x) (num 0))
    (cell (x ?x) (y ?y))
    (not (r-cell (x ?x) (y ?y)))
=>
    (assert (r-cell (x ?x) (y ?y) (content water)))
    (printout t "  DEDUCE: row=0 -> [" ?x "," ?y "]=water" crlf)
)

(defrule deduce-col-zero
    (declare (salience 500))
    (k-per-col (col ?y) (num 0))
    (cell (x ?x) (y ?y))
    (not (r-cell (x ?x) (y ?y)))
=>
    (assert (r-cell (x ?x) (y ?y) (content water)))
    (printout t "  DEDUCE: col=0 -> [" ?x "," ?y "]=water" crlf)
)

(defrule deduce-water-around-sub
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content sub))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)
               (>= ?nx (- ?x 1)) (<= ?nx (+ ?x 1))
               (>= ?ny (- ?y 1)) (<= ?ny (+ ?y 1))
               (not (and (eq ?nx ?x) (eq ?ny ?y)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water)))
    (printout t "  DEDUCE: attorno SUB[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

(defrule deduce-water-around-left
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content left))
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
    (assert (r-cell (x ?nx) (y ?ny) (content water)))
    (printout t "  DEDUCE: attorno LEFT[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

(defrule deduce-water-around-right
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content right))
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
    (assert (r-cell (x ?nx) (y ?ny) (content water)))
    (printout t "  DEDUCE: attorno RIGHT[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

(defrule deduce-water-around-top
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content top))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)))
    (test (or (and (eq ?nx ?x) (eq ?ny (- ?y 1)))
              (and (eq ?nx ?x) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny ?y))
              (and (eq ?nx (- ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny (+ ?y 1)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water)))
    (printout t "  DEDUCE: attorno TOP[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

(defrule deduce-water-around-bot
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content bot))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)))
    (test (or (and (eq ?nx ?x) (eq ?ny (- ?y 1)))
              (and (eq ?nx ?x) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny ?y))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (+ ?y 1)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water)))
    (printout t "  DEDUCE: attorno BOT[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

(defrule deduce-water-around-middle
    (declare (salience 400))
    (r-cell (x ?x) (y ?y) (content middle))
    (cell (x ?nx) (y ?ny))
    (test (and (>= ?nx 0) (<= ?nx 9) (>= ?ny 0) (<= ?ny 9)))
    (test (or (and (eq ?nx (- ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (- ?x 1)) (eq ?ny (+ ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (- ?y 1)))
              (and (eq ?nx (+ ?x 1)) (eq ?ny (+ ?y 1)))))
    (not (r-cell (x ?nx) (y ?ny)))
=>
    (assert (r-cell (x ?nx) (y ?ny) (content water)))
    (printout t "  DEDUCE: attorno MID[" ?x "," ?y "] -> [" ?nx "," ?ny "]=water" crlf)
)

;; ================================================================
;; FASE 1.5: CONTROLLO RIGHE/COLONNE COMPLETE
;; Se abbiamo trovato tutte le navi di una riga, marchiamola
;; ================================================================

(defrule check-row-complete
    (declare (salience 300))
    (k-per-row (row ?x) (num ?expected))
    (not (row-complete (row ?x)))
    (test (>= (count-ships-in-row ?x) ?expected))
    (test (> ?expected 0))
=>
    (assert (row-complete (row ?x)))
    (printout t "*** Riga " ?x " COMPLETA! (trovate " ?expected " navi) ***" crlf)
)

(defrule check-col-complete
    (declare (salience 300))
    (k-per-col (col ?y) (num ?expected))
    (not (col-complete (col ?y)))
    (test (>= (count-ships-in-col ?y) ?expected))
    (test (> ?expected 0))
=>
    (assert (col-complete (col ?y)))
    (printout t "*** Colonna " ?y " COMPLETA! (trovate " ?expected " navi) ***" crlf)
)

;; ================================================================
;; FASE 2: AZIONI
;; ================================================================

;; FIRE su celle ad alta probabilità
(defrule action-fire-high-priority
    (declare (salience 70))
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

;; GUESS su navi note
(defrule action-guess-known
    (declare (salience 60))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content ?c&~water))
    (not (my-guess (x ?x) (y ?y)))
=>
    (assert (exec (step ?s) (action guess) (x ?x) (y ?y)))
    (assert (my-guess (x ?x) (y ?y)))
    (printout t "Step " ?s ": GUESS nave nota [" ?x "," ?y "] = " ?c crlf)
    (pop-focus)
)

;; GUESS adiacente a LEFT
(defrule action-guess-adjacent-left
    (declare (salience 55))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content left))
    (test (< (+ ?y 1) 10))
    (not (r-cell (x ?x) (y =(+ ?y 1))))
    (not (my-guess (x ?x) (y =(+ ?y 1))))
=>
    (bind ?ny (+ ?y 1))
    (assert (exec (step ?s) (action guess) (x ?x) (y ?ny)))
    (assert (my-guess (x ?x) (y ?ny)))
    (printout t "Step " ?s ": GUESS destra di LEFT [" ?x "," ?ny "]" crlf)
    (pop-focus)
)

;; GUESS adiacente a RIGHT
(defrule action-guess-adjacent-right
    (declare (salience 55))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content right))
    (test (>= (- ?y 1) 0))
    (not (r-cell (x ?x) (y =(- ?y 1))))
    (not (my-guess (x ?x) (y =(- ?y 1))))
=>
    (bind ?ny (- ?y 1))
    (assert (exec (step ?s) (action guess) (x ?x) (y ?ny)))
    (assert (my-guess (x ?x) (y ?ny)))
    (printout t "Step " ?s ": GUESS sinistra di RIGHT [" ?x "," ?ny "]" crlf)
    (pop-focus)
)

;; GUESS adiacente a TOP
(defrule action-guess-adjacent-top
    (declare (salience 55))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content top))
    (test (< (+ ?x 1) 10))
    (not (r-cell (x =(+ ?x 1)) (y ?y)))
    (not (my-guess (x =(+ ?x 1)) (y ?y)))
=>
    (bind ?nx (+ ?x 1))
    (assert (exec (step ?s) (action guess) (x ?nx) (y ?y)))
    (assert (my-guess (x ?nx) (y ?y)))
    (printout t "Step " ?s ": GUESS sotto TOP [" ?nx "," ?y "]" crlf)
    (pop-focus)
)

;; GUESS adiacente a BOT
(defrule action-guess-adjacent-bot
    (declare (salience 55))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content bot))
    (test (>= (- ?x 1) 0))
    (not (r-cell (x =(- ?x 1)) (y ?y)))
    (not (my-guess (x =(- ?x 1)) (y ?y)))
=>
    (bind ?nx (- ?x 1))
    (assert (exec (step ?s) (action guess) (x ?nx) (y ?y)))
    (assert (my-guess (x ?nx) (y ?y)))
    (printout t "Step " ?s ": GUESS sopra BOT [" ?nx "," ?y "]" crlf)
    (pop-focus)
)

;; GUESS adiacente a MIDDLE
(defrule action-guess-adjacent-middle
    (declare (salience 54))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (r-cell (x ?x) (y ?y) (content middle))
    (test (< (+ ?x 1) 10))
    (not (r-cell (x =(+ ?x 1)) (y ?y)))
    (not (my-guess (x =(+ ?x 1)) (y ?y)))
=>
    (bind ?nx (+ ?x 1))
    (assert (exec (step ?s) (action guess) (x ?nx) (y ?y)))
    (assert (my-guess (x ?nx) (y ?y)))
    (printout t "Step " ?s ": GUESS sotto MIDDLE [" ?nx "," ?y "]" crlf)
    (pop-focus)
)

;; GUESS PRIORITIZZATI - Tier 1: Alta probabilità (row+col >= 6)
(defrule action-guess-high-probability
    (declare (salience 45))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (k-per-row (row ?x) (num ?rn&:(> ?rn 0)))
    (k-per-col (col ?y) (num ?cn&:(> ?cn 0)))
    (test (>= (+ ?rn ?cn) 6))  ; Alta probabilità: somma >= 6
    (not (row-complete (row ?x)))
    (not (col-complete (col ?y)))
    (not (r-cell (x ?x) (y ?y)))
    (not (my-guess (x ?x) (y ?y)))
=>
    (assert (exec (step ?s) (action guess) (x ?x) (y ?y)))
    (assert (my-guess (x ?x) (y ?y)))
    (printout t "Step " ?s ": GUESS alta prob [" ?x "," ?y "] (row=" ?rn " col=" ?cn " sum=" (+ ?rn ?cn) ")" crlf)
    (pop-focus)
)

;; GUESS PRIORITIZZATI - Tier 2: Media probabilità (row+col >= 4)
(defrule action-guess-medium-probability
    (declare (salience 42))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (k-per-row (row ?x) (num ?rn&:(> ?rn 0)))
    (k-per-col (col ?y) (num ?cn&:(> ?cn 0)))
    (test (>= (+ ?rn ?cn) 4))
    (test (< (+ ?rn ?cn) 6))   ; Media: 4 <= somma < 6
    (not (row-complete (row ?x)))
    (not (col-complete (col ?y)))
    (not (r-cell (x ?x) (y ?y)))
    (not (my-guess (x ?x) (y ?y)))
=>
    (assert (exec (step ?s) (action guess) (x ?x) (y ?y)))
    (assert (my-guess (x ?x) (y ?y)))
    (printout t "Step " ?s ": GUESS media prob [" ?x "," ?y "] (row=" ?rn " col=" ?cn " sum=" (+ ?rn ?cn) ")" crlf)
    (pop-focus)
)

;; GUESS PRIORITIZZATI - Tier 3: Bassa probabilità (row+col >= 2)
(defrule action-guess-low-probability
    (declare (salience 40))
    (status (step ?s) (currently running))
    (moves (guesses ?g&:(> ?g 0)))
    (k-per-row (row ?x) (num ?rn&:(> ?rn 0)))
    (k-per-col (col ?y) (num ?cn&:(> ?cn 0)))
    (test (>= (+ ?rn ?cn) 2))
    (test (< (+ ?rn ?cn) 4))   ; Bassa: 2 <= somma < 4
    (not (row-complete (row ?x)))
    (not (col-complete (col ?y)))
    (not (r-cell (x ?x) (y ?y)))
    (not (my-guess (x ?x) (y ?y)))
=>
    (assert (exec (step ?s) (action guess) (x ?x) (y ?y)))
    (assert (my-guess (x ?x) (y ?y)))
    (printout t "Step " ?s ": GUESS bassa prob [" ?x "," ?y "] (row=" ?rn " col=" ?cn " sum=" (+ ?rn ?cn) ")" crlf)
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