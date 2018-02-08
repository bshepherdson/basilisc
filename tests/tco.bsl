;; Testing recursive tail-call function

(def! sum2 (fn* (n acc) (if (= n 0) acc (sum2 (- n 1) (+ n acc)))))

(sum2 10 0)
;=>55

(def! res2 nil)
;=>nil
(def! res2 (sum2 200 0))
res2
;=>20100


;; Test mutually recursive tail-call functions
(def! foo (fn* (n) (if (= n 0) 0 (bar (- n 1)))))
(def! bar (fn* (n) (if (= n 0) 0 (foo (- n 1)))))

(foo 1000)
;=>0

