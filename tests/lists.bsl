;; Testing nth, first and rest functions

(nth (list 1) 0)
;=>1
(nth (list 1 2) 1)
;=>2
(def! x "x")
(def! x (nth (list 1 2) 2))
x
;=>"x"

(first (list))
;=>nil
(first (list 6))
;=>6
(first (list 7 8 9))
;=>7

(rest (list))
;=>()
(rest (list 6))
;=>()
(rest (list 7 8 9))
;=>(8 9)
