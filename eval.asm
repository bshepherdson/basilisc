; Master Eval routines.

:EVAL ; (AST, env) -> AST
ife a, empty_list
  ret              ; Empty list just gets returned.
not_list_type [a]
  tc eval_ast      ; If not a list, call eval_ast on it.

; It's a list, so this is the tricky bit.
; First, check for special forms.
jsr special_forms_check ; returns AST, env, continue?
ife c, 0
  ret ; Bail if it's already been handled.

; If we're still here, double-check the type before continuing.
ife a, empty_list
  ret
not_list_type [a]
  tc eval_ast

jsr eval_ast ; Evaluate the parts of the list.

; Now the first cell should be a function and the rest its arguments.
set b, [a]   ; Function cell in B.
set a, [a+1] ; Arg list in A.

ife [b], type_closure
  set pc, EVAL_closure
ifn [b], type_native
  brk -1 ; Can't support anything else right now.

tc [b+1] ; Tail call into our function.



; Arg list is in A, function in B.
:EVAL_closure
pushX
set x, [b+1] ; The (env, params, body) list.

; First, construct our function env.
set c, a   ; List of evaluated args goes in C.
set a, [x] ; The parent env is the first value from the list.
set x, [x+1] ; Advance X to the params.
set b, [x]   ; B holds the parameter list.
jsr build_env_with ; A holds the final env.

set b, a
set a, [x+1]
set a, [a] ; Grab the body.
popX

; TODO Remove this debugging hook eventually, it costs several cycles.
ifl sp, 0xff00
  brk -4 ; Catch runaway nesting.
tc EVAL ; Nested EVAL of the body in the new env.


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

:last_symbol .dat 0

:eval_ast_symbol ; Looks up our symbol in the environment.
set c, b
set b, a
set a, c  ; Herp derp gotta swap them round.
set [last_symbol], b ; Save the symbol into the variable.
jsr env_lookup

ifn b, 0
  ret ; Found our symbol, so we return its value.

; Otherwise, we failed to find it, so emit an error.
set a, [last_symbol]
tc not_found


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



; Table of special forms. Each record is (symbol, code).
; The code has type (AST, env) -> AST, env, continue?
; If the continue flag is set, EVAL keeps expanding this form, tail-calling.
; If it is clear, then we're done and AST should be returned.
:special_forms
.dat def_symbol, sf_def
.dat let_symbol, sf_let
.dat do_symbol, sf_do
.dat if_symbol, sf_if
.dat fn_symbol, sf_fn
:special_forms_end

; Checks each special form record in turn, until one matches.
:special_forms_check ; (AST, env) -> AST, env, continue?

; First, if the first element isn't a symbol, bail with continue set.
set c, [a] ; C is the first element.
ifn [c], type_symbol
  ret ; C is nonzero, so that's a continue.

; If we're still here, we have real work to do.
pushXYZ
; C is still the symbol, which we stash.
set push, c
set x, a
set y, b
set z, special_forms

:special_forms_check_loop
set a, peek
set b, [z] ; B is now a pointer to a symbol
set b, [b] ; B is now the symbol proper.
jsr symbol_eq
ifn a, 0 ; We found a match, so implement it.
  set pc, special_forms_found

; Otherwise, advance Z and loop.
add z, 2
ifl z, special_forms_end
  set pc, special_forms_check_loop

; All done, no match.
set a, pop ; Pop the symbol.
set a, x   ; Overwrite it with the AST.
set b, y   ; And the environment.
set c, 1   ; Signal continuing evaluation.
retXYZ


:special_forms_found
; First we put ourselves in order, then we tail-call the handler.
set a, pop ; Drop the symbol.
set a, x   ; AST
set b, y   ; Env
set c, [z+1]
popXYZ
tc c




; Special form for def!
; Defines a new symbol in the environment.
; Expects the first parameter to be a symbol and the second to be the value.
; The second parameter gets evaluated and returned, in addition to being added
; to the environment.
:sf_def ; (AST, env) -> AST, env, continue?
pushXY
set x, [a+1] ; We can drop the "def!" symbol.
set y, b

; Check that we have exactly two values.
ife x, empty_list ; List is not empty.
  brk -1
set c, [x+1]
ife c, empty_list ; Nor is it 1-element
  brk -1
ifn [c+1], empty_list ; Nor is it longer than 2.
  brk -1

; Next, check the type of the symbol.
set a, [x]
ifn [a], type_symbol
  brk -1

; Now EVAL the value.
set a, [x+1] ; List cell
set a, [a]   ; It's car, the actual value.
set b, y     ; Our current environment.
jsr EVAL

; A is now the EVAL'd value.
set push, a ; Which we save for later.
set a, y   ; Env
set b, [x] ; Our symbol.
set c, peek ; The value.
jsr env_insert

; Now return the value, and signal we're done evaluating.
set a, pop
set b, 0
set c, 0 ; No continue
retXY



; Expects (let* (k1 v1 k2 v2 ...) expr).
; Builds an environment with each of the k_i referring to the evaluated v_i's,
; then evaluates expr in that environment and discards it.
; Actually this doesn't evaluate expr directly, rather it returns with expr as
; the returned AST, and the let* env as the env, which gives better tail-call
; performance.
:sf_let ; (AST, env) -> AST, env, continue
pushXY
set x, a

set a, b   ; Env is the parent for this new environment.
jsr build_env ; A is now a new environment.
set y, a      ; Y holds that new environment now.

set x, [x+1]  ; Discard the first value; that's the "let*" symbol.
set a, [x]    ; The parameter list.
set x, [x+1]  ; Push the final expression.
set push, [x]
set x, a      ; The parameter list lives in X.

:sf_let_loop
ife x, empty_list
  set pc, sf_let_loop_done

; First element is the symbol, second is the value.
; We want the value first, so we can EVAL it.
set a, [x+1]
set a, [a]
set b, y
jsr EVAL ; A is now the evaluated value.

set c, a
set b, [x] ; Our symbol
set a, y   ; The environment.
jsr env_insert ; A is the updated environment.
set x, [x+1]
set x, [x+1] ; Take the tail twice, leaving x pointing after its past self.
set pc, sf_let_loop


:sf_let_loop_done
; TODO We want this to be a tail call eventually.
set b, y
set a, pop  ; Our trailing expression.
popXY
tc EVAL
retXY



; Special form for (do exprs....).
; Evaluates each contained expression in order, returning the last.
:sf_do
pushXY
set x, [a+1] ; Put our list into X, skipping the initial do.
set y, b     ; Save our environment.

ife x, empty_list
  set pc, sf_do_nil

; There's at least one value, so proceed.
:sf_do_loop
set a, [x] ; The next value.
set b, y   ; The environment.

set x, [x+1]
ife x, empty_list
  set pc, sf_do_last_one
; If not, fall through.

jsr EVAL
set pc, sf_do_loop

:sf_do_nil
set a, nil
retXY

:sf_do_last_one
popXY
tc EVAL


; Special form for ifs. Evaluates the condition (second element).
; If it's nil or false, return the fourth value, evaluated.
; Otherwise, return the third value, evaluated.
:sf_if ; (AST, env) -> AST, env, continue?
pushXY
set x, [a+1] ; Skip over the "if" symbol.
set y, b     ; Save the env

; Evaluate the condition.
set a, [x]
set b, y
jsr EVAL ; A is the resulting value.

set x, [x+1] ; X points at the true value.

; If A is nil or false, advance to the false value.
ife a, nil
  set x, [x+1]
ife a, false
  set x, [x+1]

; Either way, evaluate [x] (unless x is empty_list)
ife x, empty_list
  set pc, sf_if_bail

set a, [x]
set b, y
popXY
set ex, pop ; Drop the return address too - we're never returning to EVAL,
            ; which called special_forms_check, which called me.
tc EVAL

:sf_if_bail
set a, nil ; Prepare to return nil if the list is too short.
retXY


; Special form for defining function closures.
; These need to capture the parent env, their parameter lists, and their body
; ASTs.
; A closure has the form: (type_closure, (env, param-list, body)).
:sf_fn
pushXY
set x, [a+1] ; Points at the parameter list.
set y, b     ; Our containing envirnonment.

; We start by assembling the last cell: (body '())
jsr alloc_cell
set [a+1], empty_list
set b, [x+1]
set [a], [b] ; The body AST

set push, a ; Save that cell for a moment.

jsr alloc_cell
set [a], [x] ; Our parameter list.
set [a+1], pop
set push, a

jsr alloc_cell
set [a], y ; Our parent environment.
set [a+1], pop ; The previous cell.
set push, a  ; Save it one last time.

jsr alloc_cell
set [a], type_closure
set [a+1], pop ; Our function closure is complete and in A.

set b, nil
set c, 0 ; No continue
retXY

