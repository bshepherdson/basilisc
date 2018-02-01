; Main file. This one includes the others in a sane order.
set pc, main ; First instruction.

.include "util.asm"
.include "input.asm"
.include "reader.asm"
.include "memory.asm"
.include "printer.asm"
.include "output.asm"
.include "repl.asm"
.include "strings.asm"
.include "types.asm"

:main
jsr free_all
jsr serial_init
jsr run_repl

.def mem, 0x4000
.def mem_top, 0xff00

.def empty_list, 0 ; FIXME

; Types need to be even, since the low bit is used for garbage collection.
; Lists are the default, and don't have a type. Literal values like numbers are
; a cell, where the car portion is a type and the cdr is the literal value.
.def type_number, 2
.def type_char, 4
.def type_string, 6
.def type_symbol, 8

:hw_serial .dat 0 ; FIXME
