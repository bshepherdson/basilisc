; Master Eval routines.

:EVAL ; (AST, env) -> AST
ife a, empty_list
  ret              ; Empty list just gets returned.
not_list_type [a]
  tc eval_ast      ; If not a list, call eval_ast on it.

; It's a list, so this is the tricky bit.
; First, perform any macro expansion.
set push, b ; Save the environment (hur hur)
jsr macroexpand
set b, pop

; Double-check that it's still a nonempty list.
ife a, empty_list
  ret
not_list_type [a]
  tc eval_ast

; It's still a list, so we continue by checking for special forms.
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

:eval_call ; (args, func)
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



; Returns raw true/false depending on whether the AST is a list calling a macro.
:is_macro_call ; (AST, env) -> macro?
set c, a
set a, 0 ; False is common.
ife c, empty_list
  ret

not_list_type [c]
  ret ; Not a list.

; It's a list, at least, so check what the first value is.
set a, b ; Move the env to A.
set b, [c]
ifn [b], type_symbol
  set pc, is_macro_call_fail

; Look up our symbol in the environment.
jsr env_lookup ; A is the found value.
ife b, 0
  set pc, is_macro_call_fail

; Check if the value is a macro.
set b, 0
ife [a], type_macro
  set b, 1
set a, b
ret

; Not a symbol, so bail.
:is_macro_call_fail
set a, 0
ret


; Recursively expands macros until what remains is a vanilla call.
:macroexpand ; (AST, env) -> AST
pushXY
set x, a
set y, b

:macroexpand_loop
set a, x
set b, y
jsr is_macro_call
ife a, 0
  set pc, macroexpand_bail

; If we're still here, this is a macro function call.
; So we look up the macro and call it.
set b, [x] ; Initial symbol.
set a, y   ; Our environment.
jsr env_lookup

; Now we call through to EVAL_closure
set b, a ; The function itself.
set a, [x+1] ; The arg list.
jsr EVAL_closure ; A is the result of the call, on which we loop.

set x, a
set pc, macroexpand_loop

:macroexpand_bail
set a, x ; The latest iteration of the AST.
retXY




; Table of special forms. Each record is (symbol, code).
; The code has type (AST, env) -> AST, env, continue?
; If the continue flag is set, EVAL keeps expanding this form, tail-calling.
; If it is clear, then we're done and AST should be returned.
:special_forms
.dat def_symbol, sf_def
.dat defmacro_symbol, sf_defmacro
.dat let_symbol, sf_let
.dat do_symbol, sf_do
.dat if_symbol, sf_if
.dat fn_symbol, sf_fn
.dat quote_symbol, sf_quote
.dat quasiquote_symbol, sf_quasiquote
.dat lisp_macroexpand_symbol, sf_macroexpand
.dat try_symbol, sf_try
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



; Helper function for def! and defmacro! that does the basic building of the
; closure triple
:def_helper ; (AST, env) -> AST
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
retXY



; Special form for def!
; Defines a new symbol in the environment.
; Expects the first parameter to be a symbol and the second to be the value.
; The second parameter gets evaluated and returned, in addition to being added
; to the environment.
:sf_def ; (AST, env) -> AST, env, continue?
jsr def_helper
set b, 0
set c, 0 ; No continue, it's handled.
ret


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
set b, y
set a, pop  ; Our trailing expression.
popXY
set ex, pop ; Drop our return address.
tc EVAL



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
set c, 0 ; No continue, just return nil.
retXY

:sf_do_last_one
popXY
set ex, pop ; Drop the return value; we're never coming back to it.
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

; NB: Parameter lists are not quite lists.
; They can be just a symbol (for (& rest)), or the tail of the list can be a
; symbol rather than a list (for (a b & rest))
:sf_fn
pushXY
set x, [a+1] ; Points at the parameter list.
set y, b     ; Our containing envirnonment.

; We start by assembling the last cell: (body '())
set b, empty_list
set a, [x+1]
set a, [a] ; The body AST
jsr cons

set push, a ; Save the list so far.
set a, [x]  ; Parameter list.
jsr massage_parameters ; Looks for a & symbol and converts it.

set b, pop  ; The beginnings of the closure we saved above.
jsr cons

set b, a
set a, y ; Our parent environment.
jsr cons

set b, type_closure
jsr as_typed_cell

set b, nil
set c, 0 ; No continue, that's the final value.
retXY


; Special handling for parameter lists.
; Calls itself recursively; if it finds the symbol "&" then the next symbol is
; treated as the trailing one.
:massage_parameters ; (list) -> param_list
ife a, empty_list
  ret

set push, a ; Save the original list.
set b, [a]
ifn [b], type_symbol
  brk -1 ; Internal error.

set b, [b+1] ; The symbol list.
set c, [b] ; The first symbol.
ife [c+1], 0x26 ; &
  ife [b+1], empty_list
    set pc, massage_parameters_found_amp

; It's something else, so recurse.
set a, [a+1]
jsr massage_parameters

; Now, if the saved one's cdr matches the return value, return the saved one.
set b, peek
ife [b+1], a
  set pc, massage_parameters_no_change

; They're different! So we cons our saved list's car onto the returned value.
set b, a
set a, pop
set a, [a]
tc cons

:massage_parameters_no_change
set a, pop
ret

:massage_parameters_found_amp
; We found the ampersand, so the next symbol is the one we want.
set a, pop
set a, [a+1]
ife a, empty_list
  tc need_rest_param

set a, [a] ; The final symbol
ret ; We return it whole.



; Quote simply returns its unevaluated first argument.
:sf_quote ; (AST, env) -> AST, env, continue?
set a, [a+1]
set a, [a]
set c, 0 ; All done.
ret


:sf_quasiquote ; (AST, env) -> AST, env, continue?
set a, [a+1] ; Drop the "quasiquote" symbol itself.
set a, [a]
set push, b
jsr qq
set b, pop
set ex, pop ; Drop the old return address; I'm never returning normally.
tc EVAL



:qq ; (AST) -> AST
ife a, empty_list
  ret
not_list_type [a]
  set pc, qq_just_quote ; Simple, non-list values are simply quoted.

; If it is a list, we check whether the car is the symbol "unquote".
set push, a
set a, [a]
ifn [a], type_symbol
  set pc, qq_main

set b, [unquote_symbol]
jsr symbol_eq
ife a, 0
  set pc, qq_main


:qq_unquote ; Found an unquote; return its first value for evaluation.
set a, pop ; The list in question.
set a, [a+1]
set a, [a] ; Grab the first argument.
ret ; And return it.


:qq_main
; Next, check for splice-unquote nested inside an inner block.
set a, pop ; Grab my list.
set b, [a] ; B is the first element.
not_list_type [b]
  set pc, qq_base

set c, [b] ; C is the first element of that element.
ifn [c], type_symbol
  set pc, qq_base

set push, a ; Save the main list for later again.
set b, c
set a, [splice_unquote_symbol]
jsr symbol_eq

ifn a, 0
  set pc, qq_splice_unquote

set a, pop

:qq_base ; The base case (iv): return a list (cons (qq ast[0]) (qq ast[1..]))
set push, a ; Save our list.
set a, [a] ; First element in A.
jsr qq     ; Recurse into it.
set b, pop
set push, a ; Save the first element for later.
set a, [b+1] ; Grab the tail too
jsr qq      ; Recurse onto it too.

set b, empty_list
jsr cons ; A is now (tail, ())

set b, a
set a, pop ; The saved first part
jsr cons

set b, a
set a, [lisp_cons_symbol]
tc cons   ; Our complete cons call is our return value.


; case (iii) from the guide.
; Return a new list (concat ast[0][1] (quasiquote ast[1..]))
:qq_splice_unquote
set a, peek ; Grab the main list.
set a, [a+1] ; Now it's ast[1..]
jsr qq       ; I've got the last argument now.

set b, empty_list
jsr cons     ; Last element of the list now.
set b, a

set a, pop   ; The master list.
set a, [a]   ; ast[0]
set a, [a+1] ; ast [0][1..]
set a, [a]   ; ast[0][1]
jsr cons     ; Got the latter two elements now.

set b, a
set a, [concat_symbol]
tc cons ; Returns our final list.


; Simple case (i): just return (quote ast)
:qq_just_quote
set b, empty_list
jsr cons
set b, a
set a, [quote_symbol]
tc cons


:sf_defmacro ; (AST, env) -> AST, env, continue?
jsr def_helper
; We expect A to be a fn* triple with type_closure, which we adjust.
ifn [a], type_closure
  brk -1
set [a], type_macro
set b, 0
set c, 0 ; No continue
ret


:sf_macroexpand ; (AST, env) -> AST, env, continue?
set a, [a+1] ; Drop the symbol.
set a, [a]   ; Take instead the first argument.
jsr macroexpand ; Run the expansion into an AST.
set c, 0 ; No continue, just return.
ret


; Tries to evaluate the first value after setting itself up as the error
; handler.
; If it returns safely, great. If not, try_handle_error gets called and we
; move into the call handler.
; Our AST here is (try* A (catch* B C))
; If A errors out, we bind the error payload to B and tail-call C.
:sf_try ; (AST, env) -> AST, env, continue?
set a, [a+1] ; Skip over the try* symbol itself.

set push, a
set push, b
set push, [error_handler]
set [error_handler], sp

set a, [a]    ; That's the main code, the one that might fail.
jsr EVAL

; If that returned to here, then everything is good.
set [error_handler], pop
add sp, 2 ; Dump my saved values.
set c, 0 ; No continue.
ret


; If an error fired, we land here. The stack should already have been adjusted
; to where it was saved above.
:try_handle_error
set [error_handler], pop ; Restore the old, saved value; allows nested try.
set b, pop  ; Env
set a, pop  ; Original AST.

pushXY
set x, a
set y, b

set x, [x+1] ; Points to second arg, the (catch* b c) list.
set x, [x]   ; Reaches in, now points at catch*.
set a, [x]
set b, [catch_symbol]
jsr symbol_eq
ife a, 0
  tc bad_try_catch

; Successful match, so move along.
set a, y
jsr build_env
set y, a

set x, [x+1] ; Points at the symbol's element.
set b, [x]   ; The symbol itself.
set c, [error_payload]
jsr env_insert

; Our new environment is ready, now it's time to tail-call EVAL.
set a, [x+1]
set a, [a]   ; The AST for the catch body.
set b, y     ; Our new environment.

popXY
set [error_payload], nil ; Empty that out; it's a GC root.
add sp, 1 ; Drop my own return address; sf_try doesn't return in this case.
tc EVAL

