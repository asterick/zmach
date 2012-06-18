.macro PUSH data
        SET PUSH, data
.endmacro

.macro POP data
        SET data, POP
.endmacro

.macro BRK
        .data 0x0040    ; Breakpoint for 0x10co.de
.endmacro

.macro RET
        SET PC, POP
.endmacro

.macro JMP data
        SET PC, data
.endmacro

.macro NOP
        SET A, A
.endmacro

.macro DEC_IJ
        STD A, A
.endmacro

.macro INC_IJ
        STI A, A
.endmacro
