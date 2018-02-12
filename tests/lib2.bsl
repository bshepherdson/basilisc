;; Testing map function
(def! nums (list 1 2 3))
(def! double (fn* (a) (* 2 a)))
(double 3)
;=>6
(map double nums)
;=>(2 4 6)

;; Testing builtin functions
(symbol? 'abc)
;=>true
(symbol? "abc")
;=>false

(nil? nil)
;=>true
(nil? true)
;=>false

(true? true)
;=>true
(true? false)
;=>false
(true? true?)
;=>false

(false? false)
;=>true
(false? true)
;=>false

;; Testing apply function with core functions
(apply + (list 2 3))
;=>5
(apply + 4 (list 5))
;=>9
(apply prn (list 1 2 "3" (list)))
; 1 2 "3" ()
;=>nil
(apply prn 1 2 (list "3" (list)))
; 1 2 "3" ()
;=>nil
(apply list (list))
;=>()
(apply symbol? (list (quote two)))
;=>true


;; Testing apply function with user functions
(apply (fn* (a b) (+ a b)) (list 2 3))
;=>5
(apply (fn* (a b) (+ a b)) 4 (list 5))
;=>9

