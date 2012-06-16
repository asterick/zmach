.macro PUSH data
        SET PUSH, data
.endmacro

.macro POP data
        SET data, POP
.endmacro

.macro BRK
        .DATA 0x0040    ; Breakpoint for 0x10co.de
.endmacro

.macro RET
        SET PC, POP
.endmacro

.macro JMP data
        SET PC, data
.endmacro

.macro DEC_IJ
        STD A, A
.endmacro

.macro INC_IJ
        STI A, A
.endmacro
