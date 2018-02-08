;; Testing string quoting

""
;=>""
"abc"
;=>"abc"
"abc   def"
;=>"abc   def"
"\""
;=>"\""

"abc\ndef\nghi"
;=>"abc\ndef\nghi"

"\\n"
;=>"\\n"


;; Testing pr-str

(pr-str)
;=>""
(pr-str "")
;=>"\"\""

(pr-str "abc")
;=>"\"abc\""

(pr-str "abc  def" "ghi jkl")
;=>"\"abc  def\" \"ghi jkl\""

(pr-str "\"")
;=>"\"\\\"\""

(pr-str (list 1 2 "abc" "\"") "def")
;=>"(1 2 \"abc\" \"\\\"\") \"def\""

(pr-str "abc\ndef\nghi")
;=>"\"abc\\ndef\\nghi\""

(pr-str "abc\\def\\ghi")
;=>"\"abc\\\\def\\\\ghi\""

(pr-str (list))
;=>"()"


;; Testing str
(str)
;=>""
(str "")
;=>""
(str "abc")
;=>"abc"
(str "\"")
;=>"\""
(str 1 "abc" 3)
;=>"1abc3"

(str "abc  def" "ghi jkl")
;=>"abc  defghi jkl"

(str "abc\ndef\nghi")
;=>"abc\ndef\nghi"
(str "abc\\def\\ghi")
;=>"abc\\def\\ghi"

(str (list 1 2 "abc" "\"") "def")
;=>"(1 2 abc \")def"

(str (list))
;=>"()"


;; Testing prn
(prn)
; 
;=>nil

(prn "")
; ""
;=>nil

(prn "abc")
; "abc"
;=>nil

(prn "abc  def" "ghi jkl")
; "abc  def" "ghi jkl"

(prn "\"")
; "\""
;=>nil

(prn "abc\ndef\nghi")
; "abc\ndef\nghi"
;=>nil

(prn "abc\\def\\ghi")
; "abc\\def\\ghi"
;=>nil

(prn (list 1 2 "abc" "\"") "def")
; (1 2 "abc" "\"") "def"
;=>nil


;; Testing println
(println)
; 
;=>nil

(println "")
; 
;=>nil

(println "abc")
; abc
;=>nil

(println "abc  def" "ghi jkl")
; abc  def ghi jkl
;=>nil

(println "\"")
; "
;=>nil

(println "abc\ndef\nghi")
; abc
; def
; ghi
;=>nil


(println "abc\\def\\ghi")
; abc\def\ghi
;=>nil

(println (list 1 2 "abc" "\"") "def")
; (1 2 abc ") def
;=>nil

