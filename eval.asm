; Master Eval routines.

:EVAL ; (AST, env) -> AST
ife a, empty_list
  ret              ; Empty list just gets returned.
not_list_type [a]
  tc eval_ast      ; If not a list, call eval_ast on it.

; It's a list, so this is the tricky bit.
jsr eval_ast ; Evaluate the parts of the list.

; Now the first cell should be a function and the rest its arguments.
set b, [a]   ; Function cell in B.
set a, [a+1] ; Arg list in A.

ifn [b], type_native
  brk -1 ; Can't support anything else right now.

tc [b+1] ; Tail call into our function.



; Checks if the AST is a list or symbol.
; It does nested evaluation on a list, and looks up symbols.
:eval_ast ; (AST, env) -> AST
ife [a], type_symbol
  set pc, eval_ast_symbol

; If it's a memory address, it's a list.
list_type [a]
  set pc, eval_ast_list

; For everything else (numbers, strings) they simply get returned.
ret

:eval_ast_symbol ; Looks up our symbol in the environment.
set c, b
set b, a
set a, c  ; Herp derp gotta swap them round.
jsr env_lookup

ifn b, 0
  ret ; Found our symbol, so we return its value.

; Otherwise, we failed to find it, so emit an error.
brk -1 ; TODO Better error messages everywhere.


; Calls EVAL on each member of the list, returning a new list.
; This section is called recursively!
; We need to make sure to evaluate left-to-right, so they call the nested EVAL
; on this element first, then the recursive eval_ast_list.
:eval_ast_list
ife a, empty_list
  ret

pushXY
set x, a
set y, b

jsr alloc_cell
set push, a

set a, [x]
set b, y
jsr EVAL ; A is the returned value.
set push, a

set a, [x+1] ; CDR into A.
set b, y
jsr eval_ast_list ; Tail of the new list in A now.
set b, pop ; Evaluated element.
set c, pop ; New cell
set [c], b   ; CAR is the evaluated value.
set [c+1], a ; Tail is the rest of the list.
set a, c ; Return the new cell.
retXY

