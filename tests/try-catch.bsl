;; Testing try*/catch*

(try* 123 (catch* e 456))
;=>123

(try* (abc 1 2) (catch* exc (prn "exc is:" exc)))
; "exc is:" "'abc' not found"
;=>nil

(try* (throw "my exception") (catch* exc (do (prn "exc:" exc) 7)))
; "exc:" "my exception"
;=>7

;;; Test that throw is a function:
(try* (map throw (list "my err")) (catch* exc exc))
;=>"my err"

