; Error messages and error handling.

; There are two types of errors:
; - Those raised by the "throw" function from Lisp code, and
; - Those triggered by internal error-checking.

; Lisp errors are represented as a Lisp value passed to (throw ...).
; Internal error messages are represented as (length, str....) pairs.

; The entry points set the state flag in [error] as well as error_msg.

; Both kinds of errors have the same workflow: if error_handler has a nonzero
; value, set sp, [error_handler] and jump to try_handle_error.
; If error_handler is nonzero, we either emit the native string or print the
; Lisp payload.


.def error_none, 0
.def error_internal, 1
.def error_lisp, 2

:error         .dat error_none ; The error flag, holds one of the above values.
:error_msg     .dat 0          ; Pointer to an error block.
:error_payload .dat nil        ; Optional Lisp value payload.

; This is set by the innermost try*: it's the SP for the frame.
:error_handler .dat 0

.macro mkerror=:err_%0 .dat err_end_%0 - err_%0 - 1 %n .dat %1 %n :err_end_%0 %n :%0 %n set a, err_%0 %n tc abort

; NB: For obscure reasons, no space can exist after the comma for these to work.
mkerror not_found_,"' not found"
mkerror not_enough_arguments,"too few args"
mkerror expected_atom,"expected atom"
mkerror expected_number,"expected number"
mkerror nth_exhausted,"nth: out of range"
mkerror need_rest_param,"param req'd after &"
mkerror bad_try_catch,"bad try*/catch*"

; Called to set an internal error.
:abort ; (error_block) ->
set [error], error_internal
set [error_msg], a

ifn [error_handler], 0
  set pc, abort_try_set

; There's no try-catch block, so just print the message.
set b, [a] ; The length
add a, 1   ; Move forward to the string pointer.
jsr print_raw_str
jsr print_newline

; Now we strip the stack and return to the master repl loop.
set sp, -1 ; Just the topmost value.
tc run_repl


:abort_try_set
; Convert our raw error into a Lisp string first.
set b, [a]
add a, 1
set c, 0 ; No backslashing.
jsr str_to_string
set [error_payload], a
set [error], error_lisp ; We effectively has a Lisp error now.

set sp, [error_handler]
tc try_handle_error



; Helper function for symbol lookup failure.
:not_found ; (sym) ->
set [not_found_buf], 0x27 ; '

set a, [a+1] ; Grab the string portion only.
set b, 0 ; Not readable.

set push, [cursor]
set [cursor], not_found_buf+1
jsr lisp_to_str ; (buf, len)
set [cursor], pop

set a, not_found_buf+1
add a, b ; Add the returned length.

set c, [err_not_found_]

set [not_found_len], b
set b, a
set a, err_not_found_+1
add [not_found_len], c
add [not_found_len], 1 ; One extra for the starting quote.
jsr move

set a, not_found_len
tc abort


:not_found_len .dat 0
:not_found_buf .reserve 64

