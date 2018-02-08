;; Testing list functions
(list)
;=>()
(list? (list))
;=>true
(empty? (list))
;=>true
(empty? (list 1))
;=>false
(list 1 2 3)
;=>(1 2 3)
(count (list 1 2 3))
;=>3
(count (list))
;=>0
(count nil)
;=>0
(if (> (count (list 1 2 3)) 3) "yes" "no")
;=>"no"
(if (>= (count (list 1 2 3)) 3) "yes" "no")
;=>"yes"


;; Testing if form
(if true 7 8)
;=>7
(if false 7 8)
;=>8
(if true (+ 1 7) (+ 1 8))
;=>8
(if false (+ 1 7) (+ 1 8))
;=>9
(if nil 7 8)
;=>8
(if 0 7 8)
;=>7
(if "" 7 8)
;=>7
(if (list) 7 8)
;=>7
(if (list 1 2 3) 7 8)
;=>7
(= (list) nil)
;=>false

;; Testing 1-way if form
(if false (+ 1 7))
;=>nil
(if nil 8 7)
;=>7
(if true (+ 1 7))
;=>8


;; Testing basic conditionals
(= 2 1)
;=>false
(= 1 1)
;=>true
(= 1 2)
;=>false
(= 1 (+ 1 1))
;=>false
(= 2 (+ 1 1))
;=>true
(= nil 1)
;=>false
(= nil nil)
;=>true

(> 2 1)
;=>true
(> 1 1)
;=>false
(> 1 2)
;=>false

(>= 2 1)
;=>true
(>= 1 1)
;=>true
(>= 1 2)
;=>false

(< 2 1)
;=>false
(< 1 1)
;=>false
(< 1 2)
;=>true

(<= 2 1)
;=>false
(<= 1 1)
;=>true
(<= 1 2)
;=>true

;; Testing equality
(= 1 1)
;=>true
(= 0 0)
;=>true
(= 1 0)
;=>false
(= "" "")
;=>true
(= "abc" "abc")
;=>true
(= "abc" "")
;=>false
(= "" "abc")
;=>false
(= "abc" "def")
;=>false
(= "abc" "ABC")
;=>false
(= true true)
;=>true
(= false false)
;=>true
(= nil nil)
;=>true

(= (list) (list))
;=>true
(= (list 1 2) (list 1 2))
;=>true
(= (list 1) (list))
;=>false
(= (list) (list 1))
;=>false
(= 0 (list))
;=>false
(= (list) 0)
;=>false
(= (list) "")
;=>false
(= "" (list))
;=>false


;; Testing builtin and user defined functions
(+ 1 2)
;=>3
( (fn* (a b) (+ b a)) 3 4)
;=>7
( (fn* () 4) )
;=>4

( (fn* (f x) (f x)) (fn* (a) (+ 1 a)) 7)
;=>8


;; Testing closures
( ( (fn* (a) (fn* (b) (+ a b))) 5) 7)
;=>12

(def! gen-plus5 (fn* () (fn* (b) (+ 5 b))))
(def! plus5 (gen-plus5))
(plus5 7)
;=>12

(def! gen-plusX (fn* (x) (fn* (b) (+ x b))))
(def! plus7 (gen-plusX 7))
(plus7 8)
;=>15


;; Testing do form
(do (prn "prn output1"))
; "prn output1"
;=>nil
(do (prn "prn output2") 7)
; "prn output2"
;=>7
(do (prn "prn output1") (prn "prn output2") (+ 1 2))
; "prn output1"
; "prn output2"
;=>3

(do (def! a 6) 7 (+ a 8))
;=>14
a
;=>6

(def! DO (fn* (a) 7))
(DO 3)
;=>7


;; Testing recursive sumdown function
(def! sumdown (fn* (N) (if (> N 0) (+ N (sumdown (- N 1))) 0)))
(sumdown 1)
;=>1
(sumdown 2)
;=>3
(sumdown 6)
;=>21

;; Testing recursive Fibonacci function
(def! fib (fn* (N) (if (= N 0) 1 (if (= N 1) 1 (+ (fib (- N 1)) (fib (- N 2)))))))
(fib 1)
;=>1
(fib 2)
;=>2
(fib 4)
;=>5
(fib 6)
;=>13

