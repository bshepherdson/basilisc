; Output handlers for the Lisp system.
; Temporarily a hack that uses the serial link, later using the LEM.

:print_char ; (raw_char) ->
set b, a ; Move the character into B.
set a, 3 ; Transmit
hwi [hw_serial]
ifn c, 0 ; Error occurred
  brk 5
ret

:print_lisp_str ; (str) ->
pushX
set x, a

:print_lisp_str_loop
ife x, empty_list
  set pc, print_lisp_str_done

; Expect the car slot to be a character.
; TODO Check that, rather than assuming.
set b, [x]
set a, [b+1]
jsr print_char
set x, [x+1]
set pc, print_lisp_str_loop

:print_lisp_str_done
retX



:print_raw_str ; (buf, len) ->
ife b, 0
  ret

pushXY
set x, a
set y, b

:print_raw_str_loop
set a, [x]
jsr print_char
add x, 1
sub y, 1
ifg y, 0
  set pc, print_raw_str_loop
retXY


:print_newline
set a, 0x11
tc print_char

:print_prompt
set a, 0x75 ; u
jsr print_char
set a, 0x73 ; s
jsr print_char
set a, 0x65 ; e
jsr print_char
set a, 0x72 ; r
jsr print_char
set a, 0x3e ; >
jsr print_char
set a, 0x20 ; space
jsr print_char
ret


