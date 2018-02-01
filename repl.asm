; Core REPL functions for the interpreter.

:READ ; (buf, len) -> AST
jsr read_string
set pc, pop

:EVAL ; (AST) -> AST
set pc, pop

:PRINT ; (AST) -> buf, len
jsr pr_str
set a, reader_buffer
set b, [cursor]
sub b, a
ret


:rep ; (buf, len) -> string
jsr READ
jsr EVAL
jsr PRINT
set pc, pop

; Main loop function.
; (It's really jacked because of all the REPs it does.)
:run_repl ; () ->
jsr print_prompt
jsr serial_read_raw ; buf, len
;jsr str_to_lisp
jsr rep             ; buf, len
jsr print_raw_str
jsr print_newline
set pc, run_repl

