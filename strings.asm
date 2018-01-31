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


