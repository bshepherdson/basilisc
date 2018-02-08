; Printing routines for Lisp ASTs.

; Populates text into the input buffer.
; TODO Confirm it's safe to use the same one; the operations don't overlap.
:pr_str ; (AST, readable) -> buf, len
set [cursor], reader_buffer

; Recursion-safe inner point that doesn't reset cursor.
:pr_str_inner ; (AST, readable) -> buf, len
ife a, empty_list ; Special case for empty list, since it's not a valid cell.
  set pc, pr_str_empty_list
ife [a], type_symbol
  set pc, pr_str_symbol
ife [a], type_string
  set pc, pr_str_string
ife [a], type_number
  set pc, pr_str_number
ife [a], type_assoc
  set pc, pr_str_assoc
ife [a], type_native
  set pc, pr_str_native
ife [a], type_closure
  set pc, pr_str_native ; Same as a closure for now.
ife [a], type_boolean
  set pc, pr_str_boolean
ife [a], type_nil
  set pc, pr_str_nil

; Default case: a list of other values.
pushX
set c, [cursor]
set push, c ; Save the initial position for later.
set x, a    ; X holds the list.

; First, write a ( to the buffer.
set [c], 0x28 ; (
add [cursor], 1 ; B is ignored from here.

; Special case: skip to the end for empty lists.
ife x, empty_list
  set pc, pr_str_list_done

set push, b ; Save the readability flag.

:pr_str_list_loop
set a, [x] ; Car into A.
set b, peek
jsr pr_str_inner ; Recursively output it.
set x, [x+1] ; Cdr into X.

ife x, empty_list
  set pc, pr_str_list_done

; There's more, so emit a space and loop.
set c, [cursor]
set [c], 0x20 ; space
add [cursor], 1

set pc, pr_str_list_loop ; And loop

:pr_str_list_done
set ex, pop ; Drop the readable flag.
set b, [cursor]
set [b], 0x29 ; )
add [cursor], 1
add b, 1
set a, pop ; Pop our original position.
sub b, a   ; Length in B.
retX



:pr_str_string
set push, b
ife b, 0
  set pc, pr_str_string_after_quote_1

set c, [cursor]
set [c], 0x22 ; "
add [cursor], 1

:pr_str_string_after_quote_1
set a, [a+1]
jsr lisp_to_str ; buf, len

set c, pop ; The saved readable flag.
ife c, 0
  set pc, pr_str_string_after_quote_2

set c, [cursor]
set [c], 0x22 ; "
add [cursor], 1

:pr_str_string_after_quote_2
sub a, 1
add b, 2 ; Adjust for the quotes.
ret



:pr_str_symbol
set a, [a+1]
tc lisp_to_str ; buf, len

:pr_str_number
; We use a to hold the number, b for the negative flag, and C to hold the count
; of digits.
; Digit values go on the stack and then get drained into the buffer in reverse
; order. We use signed numbers by default.
pushX
set a, [a+1] ; A is the number itself.
set b, 0
set c, 0
ife a, 0  ; Special case to print 0 properly.
  set pc, pr_str_number_zero
ifl a, 0x8000 ; Positive value
  set pc, pr_str_number_positive

; Handle negatives:
; Special case of 0x8000, which has no positive counterpart.
ife a, 0x8000
  set pc, pr_str_number_max_neg

set b, 1
xor a, -1
add a, 1 ; A is now the positive counterpart.

:pr_str_number_positive
set push, a
mod peek, 10 ; Put the next digit on the stack.
add c, 1
div a, 10

ifn a, 0
  set pc, pr_str_number_positive

; Done, C holds the number of digits.
; Handle the negative flag first.
set a, [cursor]
set x, a

ife b, 0 ; Positive, so skip printing the negative sign
  set pc, pr_str_number_post_negative_sign

; Print a negative sign.
set [a], 0x2d ; -
add a, 1

:pr_str_number_post_negative_sign
set [a], pop
add [a], 0x30 ; '0' - Adjust from raw digits to characters.
add a, 1
sub c, 1
ifg c, 0
  set pc, pr_str_number_post_negative_sign

set b, a
set a, x ; The original location.
sub b, a ; The length.
add [cursor], b
retX


:pr_str_number_zero ; Handles 0 as a special case.
set a, [cursor]
set [a], 0x30 ; '0'
add [cursor], 1
set b, 1
retX


:pr_str_number_max_neg ; Handles 0x8000 by printing it directly.
set a, [cursor]
set [a], 0x2d ; -
set [a+1], 0x33
set [a+2], 0x32
set [a+3], 0x37
set [a+4], 0x36
set [a+5], 0x38
add [cursor], 6
set b, 6
retX


:pr_str_empty_list ; Handles empty list as a special case.
set a, [cursor]
set [a], 0x28 ; (
set [a+1], 0x29 ; )
add [cursor], 2
set b, 2
ret

:pr_str_assoc ; Prints an association list.
set push, [cursor] ; Save the current position for the end.
set push, [a+1] ; A list of pairs, saved for later.

set b, [cursor]
set [b], 0x7b ; '{'
add [cursor], 1

:pr_str_assoc_loop
; First, print the key.
set a, peek
set a, [a] ; A is the cell.
set a, [a] ; A is the key, a symbol.
jsr pr_str_inner

set a, [cursor]
set [a], 0x3a ; ':'
set [a+1], 0x20 ; space
add [cursor], 2

set a, peek
set a, [a] ; A is the cell again.
set a, [a+1] ; A is the value, so print it.
jsr pr_str_inner

; Advance the list pointer to the next cell.
set a, pop
set a, [a+1] ; Grab the next list cell.
ife a, empty_list
  set pc, pr_str_assoc_done

set push, a ; Save the list item for the next iteration.

; Still going, so print the comma space.
set a, [cursor]
set [a], 0x2c ; ','
set [a+1], 0x20 ; space
add [cursor], 2
set pc, pr_str_assoc_loop


:pr_str_assoc_done
; Print the final }
set a, [cursor]
set [a], 0x7d ; '}'
add [cursor], 1

set a, pop ; Grab the saved start position.
set b, [cursor] ; And the current.
sub b, a ; Length acquired.
ret


:print_to_cursor  ; (str+len pointer) ->
set push, I
set push, J
set b, [a]
add a, 1
set i, a
set j, [cursor]

:print_to_cursor_loop
sti [j], [i]
sub b, 1
ifg b, 0
  set pc, print_to_cursor_loop

set [cursor], j
set j, pop
set i, pop
ret



:str_false .dat 5
.dat "false"
:str_true  .dat 4
.dat "true"
:str_nil   .dat 3
.dat "nil"
:str_fn_native .dat 3
.dat "$fn"

:pr_str_native
set a, str_fn_native
tc print_to_cursor

:pr_str_boolean
set c, str_false
ife a, true
  set c, str_true

set a, c
tc print_to_cursor

:pr_str_nil
set a, str_nil
tc print_to_cursor


