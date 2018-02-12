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


; Finds the length of the given list as a raw number.
:list_length ; (list) -> length
set b, a
set a, 0

ife b, empty_list
  ret

:list_length_loop
add a, 1
set b, [b+1]
ifn b, empty_list
  set pc, list_length_loop

ret


:cons ; (elem, list) -> list
set push, a
set push, b
jsr alloc_cell
set [a+1], pop
set [a], pop
ret


:equals ; (a, b) -> lisp_boolean
; We switch on the type of the first argument.
ife a, empty_list
  set pc, equals_empty_list

not_list_type [a]
  set pc, equals_basic_type

; If we're still here, then they're lists.
; It's faster to check length in advance, even though that's nontrivial cost.
pushXY
set x, a
set y, b

jsr list_length
set push, a
set a, y
jsr list_length
ifn a, pop
  set pc, equals_list_mismatch

; If we're still here, their lengths match, so we recursively check the elements
; for equality.
:equals_list_loop
set a, [x]
set b, [y]
jsr equals
ife a, false
  set pc, equals_list_mismatch

set x, [x+1]
set y, [y+1]
ifn x, empty_list
  set pc, equals_list_loop

; If we got down here without bailing, the lists match.
set a, true
set pc, equals_list_match

:equals_list_mismatch
set a, false
:equals_list_match
retXY

:equals_empty_list
set a, false
ife b, empty_list
  set a, true
ret

; Compares two values of basic types found in A, B.
:equals_basic_type

; First, the types must match.
ifn [a], [b]
  set pc, equals_basic_type_fail

set c, [a]
shr c, 1 ; This is now an index into the table below.
set pc, [c + equals_basic_type_checkers]


:equals_basic_type_checkers
.dat 0 ; Dummy; the lowest type is 2.
.dat equals_basic_type_check_cdr  ; Numbers: compare CDR fields
.dat equals_basic_type_check_cdr  ; Characters: compare CDR fields
.dat equals_basic_type_check_list ; Strings: compare CDRs as lists
.dat equals_basic_type_check_list ; Symbols: compare CDRs as lists
.dat equals_basic_type_fail       ; Assocs: always false for now.
.dat equals_basic_type_check_cdr  ; Native: pointer equality
.dat equals_basic_type_check_cdr  ; Closures: pointer equality
.dat equals_basic_type_pointer    ; Booleans: top-level equality
.dat equals_basic_type_pointer    ; Nil: top-level equality

:equals_basic_type_check_cdr
set c, false
ife [a+1], [b+1]
  set c, true
set a, c
ret

:equals_basic_type_check_list
set a, [a+1]
set b, [b+1]
tc equals

:equals_basic_type_fail
set a, false
ret

:equals_basic_type_pointer
set c, false
ife a, b
  set c, true
set a, c
ret




; Basic copying function.
:move ; (src, dst, len)
set push, i
set push, j
set i, a
set j, b

:move_loop
ife c, 0
  set pc, move_done

sti [j], [i]
sub c, 1
set pc, move_loop

:move_done
set j, pop
set i, pop
ret

