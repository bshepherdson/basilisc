; Memory handling functions.


; Memory design:
; There is a large memory region of two-word cells, from mem to mem_top.
; There's a "used" subregion and a "virgin" subregion.
; The "used" subregion starts empty, and all cells are "virgin".

; When a cell is requested and there are none in the free list,
; a new block of cells is moved from the virgin to used subregions and added to
; the free list.
; If the virgin area is empty, we run the garbage collector.
; TODO: Garbage collection! Right now the gc just does brk -2

:free_list .dat 0

; Holds the first virgin cell, ie. the next one to claim.
:mem_high_water .dat mem

; Called at startup to prepare the memory system.
:init_mem ; () -> void
ret ; Nothing to do, actually.


.def chunk_size, 64

; Claims a new region of chunk_size cells from the virgin to used areas,
; putting them all in the free list.
:claim_region
set a, [mem_high_water]
set b, chunk_size
set [free_list], a

:claim_region_loop
set c, a
add c, 2
set [a], c
set a, c
sub b, 1
ifg b, 0
  set pc, claim_region_loop

set [a-2], 0 ; Set the last cell's free list pointer to 0.
set [mem_high_water], a
ret



; Returns the address of a fresh cell.
:alloc_cell ; () -> cell
ife [free_list], 0
  jsr claim_region

set a, [free_list]
set [free_list], [a]
ret

; Returns a known-free cell to the free list.
:free ; (cell) -> void
set [a], [free_list]
set [free_list], a
ret

