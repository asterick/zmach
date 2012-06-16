; --- TOP OF DATA STACK
; [variables 0...E]
; [data stack]

local_var:      .data 0xFFFF                    ; Local variables
data_stack:     .data 0xFFFF                    ; Variable stack

; =========================================================
; Read variable
; =========================================================
.proc
read_var:       IFG A, 0x0F                     ; Global variables
                    JMP _read_global
                IFN A, 0x00                     ; Read a local
                    JMP _read_local

                SUB [data_stack], 1
                SET B, [data_stack]
                SET A, [B]                      ; Data stack
                RET

_read_global:   SUB A, 0x10
                SHL A, 1                        ; Read word address
                ADD A, [STORY_GLOBALS]
                JMP read_w_addr

_read_local:    SET B, [local_var]
                ADD B, A
                SUB B, 1
                SET A, [B]
                RET
.endproc

; =========================================================
; Write variable
; =========================================================
.proc
write_var:      IFG A, 0x0F                     ; Global variables
                    JMP _write_global
                IFN A, 0x00                     ; Read a local
                    JMP _write_local
                
                SET C, [data_stack]             ; Push to stack
                SET [C], B
                ADD [data_stack], 1
                RET

_write_global:  SUB A, 0x10
                SHL A, 1
                ADD A, [STORY_GLOBALS]
                JMP write_w_addr

_write_local:   SUB A, 1
                SET C, [local_var]
                ADD C, A
                SET [C], B
                RET
.endproc

; =========================================================
; Preserve z-machine call frame, and restore with call
; =========================================================
.proc
zm_call:        SET PUSH, B
                SET PUSH, C
                SET PUSH, [current_pc]
                SET PUSH, [even_flag]
                SET PUSH, [local_var]
                SET PUSH, [data_stack]
                JSR A
                SET [data_stack], POP
                SET [local_var], POP
                SET [even_flag], POP
                SET [current_pc], POP
                SET C, POP
                SET B, POP
                RET
.endproc


.proc
zm_reset:       SET [local_var], heap           ; Reset to top of stack
                SET [data_stack], heap + 15     ; Allocate 15 local variables
                RET
.endproc