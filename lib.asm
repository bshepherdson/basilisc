; Library functionality written in the language itself.

:library
.dat lib_gensym_counter
.dat lib_gensym
.dat lib_or
.dat lib_cond
:library_end

:init_lib ; () ->
pushX
set x, library

:init_lib_loop
set a, [x]
set b, [a]
add a, 1   ; (buf, len)
jsr rep

add x, 1
ifl x, library_end
  set pc, init_lib_loop

retX



; Use like: lib foo, "Lisp code here"
; Defines a lib_foo label that points at the string length, followed by the
; string itself.
; You need to add libraries to the :library list above, as well.
.macro lib=:lib_%0 .dat lib_end_%0 - lib_%0 - 1 %n .dat %1 %n :lib_end_%0

lib gensym_counter,"(def! -gensym-counter- (atom 0))"

; Expanding by hand since I can't escape quotes in the assembler.
:lib_gensym .dat lib_end_gensym - lib_gensym - 1
.dat "(def! gensym (fn* () (symbol (str "
.dat 0x22
.dat "G__"
.dat 0x22
.dat " (swap! -gensym-counter- (fn* (x) (+ 1 x)))))))"
:lib_end_gensym


; TODO This should work with gensym, but I can't figure out why it's busted.
;lib or,"(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) (let* (condvar (gensym)) `(let* (or_FIXME ~(first xs)) (if or_FIXME or_FIXME (or ~@(rest xs)))))))))"
lib or,"(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) `(let* (or_FIXME ~(first xs)) (if or_FIXME or_FIXME (or ~@(rest xs))))))))"

; Expanding by hand since I can't escape quotes in the assembler.
:lib_cond .dat lib_end_cond - lib_cond - 1
.dat "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw "
.dat 0x22
.dat "odd number of forms to cond"
.dat 0x22
.dat ")) (cons 'cond (rest (rest xs)))))))"
:lib_end_cond

;(let* (condvar (gensym)) `(let* (~condvar 7) (if ~condvar ~condvar 8)))
