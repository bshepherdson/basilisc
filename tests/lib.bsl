;; Testing or macro
(or)
;=>nil
(or 1)
;=>1
(or 1 2 3 4)
;=>1
(or false 2)
;=>2
(or false nil 3)
;=>3
(or false nil false false nil 4)
;=>4
(or false nil 3 false nil 4)
;=>3
(or (or false 4))
;=>4

;; Testing cond macro
(cond)
;=>nil
(cond true 7)
;=>7
(cond true 7 true 8)
;=>7
(cond false 7 true 8)
;=>8
(cond false 7 false 8 "else" 9)
;=>9
(cond false 7 (= 2 2) 8 "else" 9)
;=>8
(cond false 7 false 8 false 9)
;=>nil
