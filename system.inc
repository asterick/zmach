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
