; Core REPL functions for the interpreter.

:READ ; (str) -> str
set pc, pop

:EVAL ; (str) -> str
set pc, pop

:PRINT ; (str) -> str
set pc, pop


:rep ; (str) -> str
jsr READ
jsr EVAL
jsr PRINT
set pc, pop

; Main loop function.
; It's really jacked because of all the REPs it does.
:run_repl ; () ->
jsr print_prompt
jsr serial_read_raw
jsr str_to_lisp
jsr rep
jsr print_lisp_str
jsr print_newline
set pc, run_repl

