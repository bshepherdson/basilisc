; Utilities, like assembler macros.

.macro pushX=set push, x
.macro pushXY=pushX %n set push, y
.macro pushXYZ=pushXY %n set push, z

.macro popX=set x, pop
.macro popXY=set y, pop %n popX
.macro popXYZ=set z, pop %n popXY

.macro retX=popX %n set pc, pop
.macro retXY=popXY %n set pc, pop
.macro retXYZ=popXYZ %n set pc, pop

.macro ret=set pc, pop

; Make tail calls explicit, so they don't look accidental.
.macro tc=set pc, %0
