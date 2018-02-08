; Utility functions for turning working with native DCPU strings and Lisp
; strings.
; Lisp strings are represented as lists of characters.




:backslashing .dat 0

; Converts a raw string in a buffer to a Lisp string, stored as a list.
; Honours backslash escaping when the flag is set.
:str_to_list ; (buf, len, backslashing?) -> lisp_str
ife b, 0
  set pc, str_to_list_empty

pushXYZ
set [backslashing], c

set x, a
set y, b

; Non-empty, so we put the first cell into Z.
jsr alloc_cell
set push, a ; Save the first cell.
set z, a

:str_to_list_loop
set a, [x]

ifn a, 0x5c ; \\
  set pc, str_to_list_loop_regular
ife [backslashing], 0
  set pc, str_to_list_loop_regular

; Found a slash with backslashing enabled.
add x, 1
sub y, 1
set a, [x] ; Move to the next character.

ife a, 0x6e ; n
  set a, 0x11 ; Newline

; Otherwise, it's a ", \ or otherwise, so we put it straight in.

:str_to_list_loop_regular
set b, type_char
jsr as_typed_cell
set [z], a

sub y, 1
add x, 1
ife y, 0
  set pc, str_to_list_done

jsr alloc_cell
set [z+1], a
set z, a
set pc, str_to_list_loop

:str_to_list_done
set [z+1], empty_list
set a, pop ; A is the original cell.
retXYZ

:str_to_list_empty
set a, empty_list
ret


:str_to_string ; (buf, len) -> list_string
jsr str_to_list
set b, type_string
tc as_typed_cell

:str_to_symbol ; (buf, len) -> lisp_symbol
jsr str_to_list
set b, type_symbol
tc as_typed_cell


; NB: Uses the input buffer!
:lisp_to_str ; (str, readable) -> buf, len
pushXYZ
set z, b ; Save the "readable" flag into Z.
set b, [cursor]
set x, b ; Save the initial position.

:lisp_to_str_loop
ife a, empty_list
  set pc, lisp_to_str_done

set c, [a] ; Read the car, the character cell.
set y, [c+1]   ; Read the character.

ife z, 0
  set pc, lisp_to_str_loop_not_special

; Handle special characters, if any.
ifn y, 0x22     ; "
  ifn y, 0x11   ; \n
    ifn y, 0x5c ; \\
      set pc, lisp_to_str_loop_not_special

; Emit a backslash first.
set [b], 0x5c
add b, 1

; If the next character is a newline, convert it to an n.
ife y, 0x11   ; newline
  set y, 0x6e ; n

:lisp_to_str_loop_not_special
set [b], y ; Its cdr is the literal character.
set a, [a+1]
add b, 1
set pc, lisp_to_str_loop

:lisp_to_str_done
set a, [cursor]
set [cursor], b
sub b, x
retXYZ


