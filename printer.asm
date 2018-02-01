; Printing routines for Lisp ASTs.

; Populates text into the input buffer.
; TODO Confirm it's safe to use the same one; the operations don't overlap.
:pr_str ; (AST) -> buf, len
set [cursor], reader_buffer

; Recursion-safe inner point that doesn't reset cursor.
:pr_str_inner ; (AST) -> buf, len
ife a, empty_list ; Special case for empty list, since it's not a valid cell.
  set pc, pr_str_empty_list
ife [a], type_symbol
  set pc, pr_str_symbol
ife [a], type_string
  set pc, pr_str_string
ife [a], type_number
  set pc, pr_str_number

; Default case: a list of other values.
pushX
set b, [cursor]
set push, b ; Save the initial position for later.
set x, a    ; X holds the list.

; First, write a ( to the buffer.
set [b], 0x28 ; (
add [cursor], 1 ; B is ignored from here.

; Special case: skip to the end for empty lists.
ife x, empty_list
  set pc, pr_str_list_done


:pr_str_list_loop
set a, [x] ; Car into A.
jsr pr_str_inner ; Recursively output it.
set x, [x+1] ; Cdr into X.

ife x, empty_list
  set pc, pr_str_list_done

; There's more, so emit a space and loop.
set b, [cursor]
set [b], 0x20 ; space
add [cursor], 1

set pc, pr_str_list_loop ; And loop

:pr_str_list_done
set b, [cursor]
set [b], 0x29 ; )
add [cursor], 1
add b, 1
set a, pop ; Pop our original position.
sub b, a   ; Length in B.
retX



:pr_str_string
set b, [cursor]
set [b], 0x22 ; "
add [cursor], 1

set a, [a+1]
jsr lisp_to_str ; buf, len

set c, [cursor]
set [c], 0x22 ; "
add [cursor], 1

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
