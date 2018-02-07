; Environment functions

; An environment is a list of association lists, searched front to back.
; An association list has a type tag, and a list of pairs.
; Each pair is cell whose car points to a symbol, and whose cdr points to its
; value.

:build_env ; (parent) -> env
set push, a
jsr assoc_new ; A is a new, empty association list.
set push, a
jsr alloc_cell
set [a], pop
set [a+1], pop
ret


; Convenience for building an environment with eg. function parameters set.
; It expects a list of parameter names as binds, and a list of values as exprs.
:build_env_with ; (parent, binds, exprs) -> env
pushXY
set x, b
set y, c
jsr build_env
set push, a ; Keep the environment on the stack.

; There's an interesting special case here: if the value in X is ever a symbol
; instead of a list containing symbols, then the entire remaining parameter list
; is bound to it; this is the "rest" parameters.
:build_env_with_loop
ife x, empty_list
  set pc, build_env_with_done
ife [x], type_symbol
  set pc, build_env_with_rest

; Otherwise, [x] is a symbol for the next value.
ifn y, empty_list
  set pc, build_env_with_loop_legit

; Error! We ran out of values before names.
set a, err_not_enough_arguments
tc abort

:build_env_with_loop_legit ; Continue by binding a single pair.
set a, peek ; The environment.
set b, [x]  ; The symbol.
set c, [y]  ; The value.
jsr env_insert

set x, [x+1]
set y, [y+1]
set pc, build_env_with_loop

:build_env_with_rest
set a, peek
set b, x  ; The final symbol
set c, y  ; The entire remaining list (maybe empty)
jsr env_insert
; Fall through

:build_env_with_done
set a, pop ; Our augmented environment.
retXY




; Inserts a new value for the given into the top-most environment.
:env_insert ; (env, symbol, value) ->
set a, [a]
tc assoc_insert

; Looks up a symbol in an environment.
; Tries each layer in turn, and aborts if we reach the end without finding the
; target. Returns a flag indicating whether the value was found.
:env_lookup ; (env, symbol) -> value, found?
pushXY
set x, a
set y, b

:env_lookup_loop
ife x, empty_list
  set pc, env_lookup_fail

set a, [x] ; Grab the assoc in the car.
set b, y
jsr assoc_find ; Returns value, found? as well.
ifn b, 0
  set pc, env_lookup_ret

set x, [x+1]
set pc, env_lookup_loop

:env_lookup_fail
set a, nil
set b, 0
; Fall through to ret below

:env_lookup_ret
retXY


; Returns a new, empty association list.
:assoc_new ; () -> assoc_list
jsr alloc_cell
set [a], type_assoc
set [a+1], empty_list
ret


; Inserts a new value with the given symbol key into the associaton list.
:assoc_insert ; (assoc, key, value) ->
set push, a
set push, b
set push, c

jsr alloc_cell ; A is a new cell, we're going to use it as our pair.
set [a+1], pop ; Value in the right
set [a], pop   ; Key in the left

set push, a
jsr alloc_cell ; Another new cell.
set [a], pop   ; The pair from above goes in its left slot

set b, pop   ; B is the assoc, whose left side is the list.
set [a+1], [b+1]  ; Make the old assoc list the tail of our new list cell.
set [b+1], a      ; And make the new cell the assoc's inner list.
ret


:assoc_find ; (assoc, key) -> value, found?
pushXY
set x, [a+1] ; Grab the cdr, the actual list.
set y, b     ; Save the key as well.

:assoc_find_loop
ife x, empty_list
  set pc, assoc_find_failure

set a, [x] ; A is the cell pair.
set a, [a] ; Now the key, a symbol.
ifn [a], type_symbol
  brk -1 ; Can't happen, key is not a symbol.

; Now we've got symbols (with type tags on) in A and Y.
set b, y
jsr symbol_eq
ifn a, 0 ; Match!
  set pc, assoc_find_success

; No match, keep searching.
set x, [x+1]
set pc, assoc_find_loop


:assoc_find_success
; X holds the list cell, its cadr is the returned value.
set a, [x]
set a, [a+1]
set b, 1
set pc, assoc_find_done

:assoc_find_failure
set b, 0
set a, nil
set pc, assoc_find_done

:assoc_find_done
retXY


; Expects two symbols, with their type tags still on.
; Returns whether they are equal. Case sensitive!
:symbol_eq ; (a, b)
set c, a
set a, 1
ife c, b
  ret ; Shortcut: return true instantly if they're identical pointers.

; Otherwise we have work to do. We leave 0 in A so we can instant-fail.
set a, 0
set b, [b+1] ; Strip off the type tags.
set c, [c+1] ; Strip off the type tags.

:symbol_eq_loop
ife b, empty_list
  ife c, empty_list
    set pc, symbol_eq_success

ife b, empty_list
  ret
ife c, empty_list
  ret

set push, b
set push, c
set b, [b]
set c, [c]
ife [b+1], [c+1] ; Characters match.
  set pc, symbol_eq_loop_continue

; No match!
add sp, 2 ; Drop the saves values.
ret

:symbol_eq_loop_continue
set c, pop
set c, [c+1] ; Move the list along.
set b, pop
set b, [b+1] ; Move the list along.
set pc, symbol_eq_loop

:symbol_eq_success
set a, 1
ret

