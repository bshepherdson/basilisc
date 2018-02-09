; Error messages and error handling.

; Error messages are represented as (length, str....) pairs, with a macro.
; For now, when errors are not recoverable, abort simply jumps to the top.
; Later I'll build some kind of error unwinding.

.def error_none, 0
.def error_internal, 1
.def error_lisp, 2

:error         .dat error_none ; The error flag, holds one of the above values.
:error_msg     .dat 0          ; Pointer to an error block.
:error_payload .dat nil        ; Optional Lisp value payload.

.macro mkerror=:err_%0 .dat err_end_%0 - err_%0 - 1 %n .dat %1 %n :err_end_%0 %n :%0 %n set a, err_%0 %n tc abort

; NB: For obscure reasons, no space can exist after the comma for these to work.
mkerror not_found_,"' not found"
mkerror not_enough_arguments,"too few args"
mkerror expected_atom,"expected atom"
mkerror expected_number,"expected number"
mkerror nth_exhausted,"nth: out of range"

; Called to set an internal error.
:abort ; (error_block) ->
set [error], error_internal
set [error_msg], a

set b, [a] ; The length
add a, 1   ; Move forward to the string pointer.
jsr print_raw_str
jsr print_newline

; Now we strip the stack and return to the master repl loop.
set sp, -1 ; Just the topmost value.
tc run_repl


; Helper function for symbol lookup failure.
:not_found ; (sym) ->
set push, a
set a, 0x27 ; '
jsr print_char

set a, pop ; Our symbol.
set a, [a+1] ; Grab the string portion only.
jsr print_lisp_str

set a, err_not_found_
tc abort



