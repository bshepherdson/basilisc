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

