; Utility functions for turning working with native DCPU strings and Lisp
; strings.
; Lisp strings are represented as lists of characters.


; Converts a raw string in buffer to a list string, stored as a list.
:str_to_lisp ; (buf, len) -> lisp_str
pushXYZ
set x, a
set y, b
add y, a ; Y holds the end position.
set z, empty_list ; Z is the empty list.

:str_to_lisp_loop
sub y, 1
jsr alloc_cell ; A is now a cell address. We make it our symbol.
set [a], type_char
set [a+1], [y] ; Character, set to the character from the string.
set push, a ; Save the value.

jsr alloc_cell ; A is our next list cell.
set [a], pop
set [a+1], z
set z, a

ifl x, y
  set pc, str_to_lisp_loop

; Reached the beginning of the string.
set a, z
retXYZ


:str_to_symbol ; (buf, len) -> lisp_symbol
jsr str_to_lisp
set push, a
jsr alloc_cell
set [a], type_symbol
set [a+1], pop
ret


; NB: Uses the input buffer!
:lisp_to_str ; (str) -> buf, len
pushX
set b, [cursor]
set x, b ; Save the initial position.

:lisp_to_str_loop
ife a, empty_list
  set pc, lisp_to_str_done

set c, [a] ; Read the car, the character cell.
set [b], [c+1] ; Its cdr is the literal character.
set a, [a+1]
add b, 1
set pc, lisp_to_str_loop

:lisp_to_str_done
set a, [cursor]
set [cursor], b
sub b, x
retX


