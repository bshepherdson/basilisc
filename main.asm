; Main file. This one includes the others in a sane order.
set pc, main ; First instruction.

; Some high-level definitions.
.def mem, 0x4000
.def pre_mem, mem-1
.def mem_top, 0xff00

.macro list_type=ifg %0, pre_mem
.macro not_list_type=ifl %0, mem

.def empty_list, 0 ; FIXME
.def nil, 0

; Types need to be even, since the low bit is used for garbage collection.
; Lists are the default, and don't have a type. Literal values like numbers are
; a cell, where the car portion is a type and the cdr is the literal value.
.def type_number, 2
.def type_char, 4
.def type_string, 6
.def type_symbol, 8
.def type_assoc, 10
.def type_native, 12
.def type_closure, 14


.include "util.asm"
.include "input.asm"
.include "reader.asm"
.include "memory.asm"
.include "printer.asm"
.include "output.asm"

.include "env.asm"
.include "helpers.asm"
.include "builtins.asm"
.include "eval.asm"

.include "repl.asm"
.include "strings.asm"
.include "types.asm"

:main
jsr init_mem
jsr init_repl_env
jsr serial_init
; set a, [repl_env]
; set a, [a] ; Grab the assoc and print it.
; jsr PRINT
; jsr print_raw_str
; jsr print_newline
jsr run_repl

:hw_serial .dat 0 ; FIXME
