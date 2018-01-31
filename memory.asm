; Memory handling functions.

:free_list .dat mem

; Called at startup to build a free list containing every cell.
:free_all ; () -> void
set a, mem
set c, mem_top

:free_all_loop
set b, a
add b, 2
set [a], b
add a, 2
ifl a, c
  set pc, free_all_loop

set [free_list], mem



; Returns the address of a fresh cell.
:alloc_cell ; () -> cell
set a, [free_list]
set [free_list], [a]
ret

; Returns a known-free cell to the free list.
:free ; (cell) -> void
set [a], [free_list]
set [free_list], a
ret

