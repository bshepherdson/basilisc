;; Testing trivial macros
(defmacro! one (fn* () 1))
(one)
;=>1
(defmacro! two (fn* () 2))
(two)
;=>2

;; Testing unless macros
(defmacro! unless (fn* (pred a b) `(if ~pred ~b ~a)))
(unless false 7 8)
;=>7
(unless true 7 8)
;=>8
(defmacro! unless2 (fn* (pred a b) `(if (not ~pred) ~a ~b)))
(unless2 false 7 8)
;=>7
(unless2 true 7 8)
;=>8

;; Testing macroexpand
(macroexpand (unless2 2 3 4))
;=>(if (not 2) 3 4)

;; Testing evaluation of macro result
(defmacro! identity (fn* (x) x))
(let* (a 123) (identity a))
;=>123

;; Testing non-macro function
(not (= 1 1))
;=>false
(not (= 1 2))
;=>true


