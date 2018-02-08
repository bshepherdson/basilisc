; Built-in functions.

:repl_env .dat 0

.def last_builtin, 0

; Setting up the builtin macro.
; We're building a linked list of (next, string, length, code) blobs for each
; builtin.
; Each builtin has the following parts:
; - foo_name - raw string.
; - foo_record - the (next, string, length, code) blob.
; - foo_symbol - pointer to the actual symbol, useful for runtime checks.
; Call this macro like:
; builtin "name", name_length, label
; code...
.macro builtin=:%2_name .dat %0 %n :%2_record .dat last_builtin, %2_name, %1, %2 %n .def last_builtin, %2_record %n :%2_symbol .dat 0 %n :%2




; Builtin definitions go here.
; All builtins expect a single argument in A, the list of arguments.

; TODO I've written these for compactness rather than speed using a helper
; function. Basic operations like arithmetic could be done a lot faster with
; direct implementation, but that's tedious and takes more space, which I think
; is the more constrained resource.

; Plus works over 0 or more arguments.
builtin "+", 1, plus
set b, 0
set c, plus_inner
jsr foldr
tc as_number

:plus_inner
ifn [b], type_number
  brk -1
add a, [b+1]
ret


; Minus works over exactly 2 arguments.
builtin "-", 1, minus
jsr binop_numbers ; A is the LHS, B the RHS.
sub a, b
tc as_number

; Times works over 0 or more arguments.
builtin "*", 1, times
set b, 1
set c, times_inner
jsr foldr
tc as_number

:times_inner
ifn [b], type_number
  brk -1
mul a, [b+1]
ret


; Division works over exactly 2 arguments.
builtin "/", 1, divide
jsr binop_numbers
dvi a, b
tc as_number

; Modulus is binary too.
builtin "%", 1, modulo
jsr binop_numbers
mdi a, b
tc as_number



; Printing and output
:prn_buffer .reserve 128

; All four of the printer types have the same structure: call pr_str on the
; arguments with readable set or clear, separated by some character.
; I extract that flow into this function.

; Separator can be 0 or a raw character. 0 is not printed.
:print_helper ; (args, separator, readable) -> buf, len
ife a, empty_list
  set pc, print_helper_empty

pushXYZ
set x, a
set y, b
set z, c

set c, [cursor]
set push, c
set [cursor], prn_buffer

:print_helper_loop
set a, [x]
set b, z
jsr pr_str_inner

set x, [x+1]
ife x, empty_list
  set pc, print_helper_done

; Emit the separator, if any.
ife y, 0
  set pc, print_helper_loop

set b, [cursor]
set [b], y
add [cursor], 1

set pc, print_helper_loop


:print_helper_done
set a, prn_buffer
set b, [cursor]
sub b, a
set [cursor], pop
retXYZ


:print_helper_empty
set a, prn_buffer
set b, 0
ret


builtin "pr-str", 6, lisp_pr_str
set b, 0x20 ; space
set c, 1    ; readable
jsr print_helper ; A is the buffer, B the length.
; Convert it to a new Lisp string.
set c, 0 ; No backslashing
tc str_to_string


builtin "str", 3, list_str
set b, 0 ; no separator
set c, 0 ; !readable
jsr print_helper
set c, 0 ; No backslashing.
tc str_to_string

:prn_tail
set b, 0x20 ; space
jsr print_helper
jsr print_raw_str
jsr print_newline
set a, nil
ret

builtin "prn", 3, prn
set c, 1    ; readable
tc prn_tail

builtin "println", 7, println
set c, 0    ; !readable
tc prn_tail


; List functions
builtin "list", 4, list
ret ; The parameters are already a list.

builtin "list?", 5, list_q
set b, [a]
set a, true
ifn b, empty_list
  not_list_type [b]
    set a, false
ret

builtin "empty?", 6, empty
set b, [a]
set a, false
ife b, empty_list
  set a, true
ret

builtin "count", 5, count
ife [a], nil
  set pc, count_nil
set a, [a]
jsr list_length
tc as_number

:count_nil
set a, 0
tc as_number



; Conditionals

; We return true if the two arguments are the same type and have the same value.
; Lists are compared recursively.
builtin "=", 1, lisp_equals
set c, [a]
set a, [a+1]
set b, [a]
set a, c
tc equals


builtin "<", 1, lisp_lt
jsr binop_numbers
set c, false
ifu a, b
  set c, true
set a, c
ret

builtin ">", 1, lisp_gt
jsr binop_numbers
set c, false
ifa a, b
  set c, true
set a, c
ret

builtin "<=", 2, list_le
jsr binop_numbers
set c, true
ifa a, b
  set c, false
set a, c
ret

builtin ">=", 2, list_ge
jsr binop_numbers
set c, true
ifu a, b
  set c, false
set a, c
ret

; This was supposed to be written in BSL itself, but this is faster.
builtin "not", 3, lisp_not
set b, [a]
set a, false

ife b, nil
  set a, true
ife b, false
  set a, true
ret



; TODO Unsigned comparisons.


; Placeholders for the special forms.
builtin "def!", 4, def
brk -3 ; Can't happen; it's never called for real.
builtin "let*", 4, let
brk -3 ; Can't happen, it's never called for real.
builtin "do", 2, do
brk -3 ; Can't happen, it's never called for real.
builtin "if", 2, if
brk -3 ; Can't happen, it's never called for real.
builtin "fn*", 3, fn
brk -3 ; Can't happen, it's never called for real.


:init_repl_env ; () ->
pushX
set a, empty_list
jsr build_env
set [repl_env], a

; Now work our way through the linked list of builtins, adding them to the
; environment.
set x, last_builtin

:init_repl_env_loop
jsr alloc_cell ; New cell for the function.
set [a], type_native
set [a+1], [x+3] ; The code pointer.
set push, a ; Save this cell for later.

set a, [x+1] ; The string pointer.
set b, [x+2] ; The length
jsr str_to_symbol ; Now we have a symbol for it.

set b, [x+3] ; Put the code pointer into B.
set [b-1], a ; Store the symbol into the slot before it, [foo_symbol].

set b, a ; Move the symbol itself to B.
set a, [repl_env] ; repl_env in A.
set c, pop ; Grab the code cell as well.
jsr env_insert ; Loaded into the environment.

set x, [x] ; Chain through to the next builtin.
ifn x, 0
  set pc, init_repl_env_loop

; Done processing the builtins.
retX

