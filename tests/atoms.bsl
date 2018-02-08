;; Testing atoms

(def! inc3 (fn* (a) (+ 3 a)))

(def! a (atom 2))
;=>(atom 2)

(atom? a)
;=>true

(atom? 1)
;=>false

(deref a)
;=>2

(reset! a 3)
;=>3

(swap! a inc3)
;=>6

(deref a)
;=>6

(swap! a (fn* (a) a))
;=>6

(swap! a (fn* (a) (* 2 a)))
;=>12

(swap! a (fn* (a b) (* a b)) 10)
;=>120

(swap! a + 3)
;=>123


;; Testing swap!/closure interaction
(def! inc-it (fn* (a) (+ 1 a)))
(def! atm (atom 7))
(def! f (fn* () (swap! atm inc-it)))
(f)
;=>8
(f)
;=>9
