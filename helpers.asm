; Helper functions for the builtin implementations and elsewhere.
; Working with lists, etc.

; Takes a raw number and returns a number cell.
:as_number
set b, type_number
tc as_typed_cell


:as_typed_cell ; (value, type) -> cell
set push, a
set push, b
jsr alloc_cell
set [a], pop ; The type in the car
set [a+1], pop ; The value in the cdr
ret


; Folds a user-supplied function over each pair of values in this list.
; The user function is passed (running_total, list_value).
; So if the list contains number cells and the running total is a raw number,
; that's what it'll get passed.
:foldr ; (list, initial, f) -> final_value
pushXY
set x, a
set y, c
set a, b ; Initial value in A.

:foldr_loop
ife x, empty_list
  set pc, foldr_done

set b, [x]
jsr y      ; A now holds the new running value.
set x, [x+1]
set pc, foldr_loop

:foldr_done
retXY


; Many binary operations get argument lists but really just want two arguments.
; This returns them as whole cells in A and B.
:binop ; (arg_list) -> lhs, rhs
set c, [a]
set b, [a+1]
set b, [b]
set a, c
ret

; Specializing further, many binops require two numbers. This consolidates them.
; The numbers are returned as raw numbers, having been checked.
:binop_numbers ; (arg_list) -> lhs, rhs
jsr binop
ifn [a], type_number
  brk -1
ifn [b], type_number
  brk -1
set a, [a+1]
set b, [b+1]
ret


