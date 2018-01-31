; Input handling for the Lisp interpreter.
; Receives a line of input from the user over the keyboard.

:key_buffer .reserve 256
:cursor .dat key_buffer

; Reads a string from the keyboard, with backspace but no line-editing.
; Returns the address of the string and its length.
:kb_read_raw ; () -> str, len
set [cursor], key_buffer

:kb_read_loop
set a, 1 ; GET_NEXT
;hwi [hw_keyboard] TODO FIXME
ife c, 0
  set pc, kb_read_loop

ife c, 0x10 ; Backspace
  set pc, kb_read_backspace

ife c, 0x11 ; Return
  set pc, kb_read_done

ifg c, 0x7f ; Too high: arrows
  set pc, kb_read_loop ; Do nothing, read again.
ifl c, 0x20 ; Too low: not supported
  set pc, kb_read_loop

; Found a printable character, record it.
set a, [cursor]
set [a], c
add [cursor], 1
set pc, kb_read_loop


:kb_read_backspace
sub [cursor], 1
ifl [cursor], key_buffer
  set [cursor], key_buffer
set pc, kb_read_loop

:kb_read_done ; We have our string.
set a, key_buffer
set b, [cursor]
sub b, a ; Length in B.
ret


; Reads a complete line from the serial link.
:serial_read_raw ; () -> str, len
set [cursor], key_buffer

:serial_read_raw_loop
set a, 2 ; Receive
hwi [hw_serial] ; B:A holds the data; but we're using only 8 bits so it's in A.
; C holds the error status.
ife c, 3 ; "No data"
  set pc, serial_read_raw_loop
ifn c, 0 ; Other errors
  brk 1

; Read a block successfully.
and a, 0xff
ife a, 0x10 ; Backspace
  set pc, serial_read_raw_backspace

ife a, 0x11 ; Return
  set pc, serial_read_raw_done

ifg a, 0x7f ; Too high: arrows
  set pc, serial_read_raw_loop ; Do nothing, read again.
ifl a, 0x20 ; Too low: not supported
  set pc, serial_read_raw_loop


set b, [cursor]
set [b], a
add [cursor], 1
set pc, serial_read_raw_loop


:serial_read_raw_backspace
sub [cursor], 1
ifl [cursor], key_buffer
  set [cursor], key_buffer
set pc, serial_read_raw_loop

:serial_read_raw_done ; We have our string.
set a, key_buffer
set b, [cursor]
sub b, a ; Length in B.
ret



; Configures the serial link for our purposes:
; single bytes, no interrupts.
:serial_init ; () ->
set a, 1
set b, 0
set c, 0xff
hwi [hw_serial]
ret




