; =========================================================
; CRT0 startup code
; =========================================================
.proc
reset:          SET SP, 0
                HWN I
_init_loop:     IFE I, 0
                    JMP entry
                SUB I, 1
                HWQ I

                ; Keyboard (generic)
                IFE A, 0x7406
                IFE B, 0x30cf
                    JSR init_keys

                ; LEM-1802
                IFE A, 0xf615
                IFE B, 0x7349
                    JSR init_term
                
                JMP _init_loop
.endproc
