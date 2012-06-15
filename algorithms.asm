; =========================================================
;  Various algorithms
; =========================================================

.proc
get_random: SET A, [_seed]
            MUL A, 31421
            ADD A, 6927
            SET [_seed], A

            SET C, [_seed+1]
            SHR C, 1
            IFN EX, 0
                XOR C, 0xB400
            SET [_seed+1], C
            XOR A, C
            RET

_seed:     .data 0xDEAD, 0xFACE
.endproc
