; Main file. This one includes the others in a sane order.
set pc, main ; First instruction.

.include "util.asm"
.include "input.asm"
.include "memory.asm"
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
.def type_char, 1 ; FIXME

:hw_serial .dat 0 ; FIXME
