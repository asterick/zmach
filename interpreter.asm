; --- TOP OF DATA STACK
; [variables 0...E]
; [data stack]

; =========================================================
; Z-Machine entry point (operations table included)
; =========================================================

.proc
; --- Instruction lookup tables
_0op_inst:      .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
_1op_inst:      .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
_2op_inst:      .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
_var_inst:      .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3
                .data 0, 1, 2, 3

mach_start:     SET [local_var], heap           ; Reset to top of stack
                SET [data_stack], heap + 15     ; Allocate 15 local variables
                SET A, [STORY_INIT_PC]          ; Jump to start PC
                JSR set_pc_addr

step_mach:      JSR read_b_pc
                SET X, A
                IFC X, 0x80                     ; 2OP (long form)
                    JMP _long_op
                IFC X, 0x40
                    JMP _short_op               ; 0OP/1OP (short form)
                
                ; 11aooooo  ; 0 = 2OP, 1 = VAR_OP
                JSR read_b_pc
                JSR _var_map
                AND X, 0x3F
                JMP [_2op_inst+X]               ; VAR instructions are just after 2OP

_var_map:       SET [inst_argc], 0              ; Clear argument count
                SET Y, A                        ; Y = Variable map
                SHL Y, 8                        ; ... in the upper 8 bits (for shifting)
                SET I, 4                        ; I = 4 scan slots
_vm_loop:       IFE I, 0                        ; Return when scan is complete
                    RET
                SUB I, 1
                SHL Y, 2                        ; EX = Variable type
                IFE EX, 0           ; Large     ; 0 = large constant
                    JMP _vm_large
                IFE EX, 1           ; Small     ; 1 = small constant
                    JMP _vm_small
                IFN EX, 2                       ; 3 = omitted
                    JMP _vm_loop
_vm_var:        JSR read_b_pc                   ; A = variable index
                JSR read_var                    ; Read the variable
                JMP _vm_store
_vm_large:      JSR read_w_pc                   ; A = Word data
                JMP _vm_store
_vm_small:      JSR read_b_pc                   ; A = Byte data
_vm_store:      SET B, [inst_argc]              ; Stuff it in argument list
                SET [B+inst_argv], A
                ADD [inst_argc], 1
                JMP _vm_loop


                ; 0abooooo  ; 0 = small, 1 = variable (2op)
_long_op:       SET [inst_argc], 2              ; Always two op
                JSR read_b_pc
                IFB X, 0x40                     ; Read arg 1
                    JSR read_var
                SET [inst_argv], A
                JSR read_b_pc                   ; Read arg 2
                IFB X, 0x20
                    JSR read_var
                SET [inst_argv+1], A
                AND X, 0x1F
                JMP [_2op_inst+X]
                    

                ; 10aaoooo  ; 00 = large, 01 = small, 10 = var, 11 = omit (0op/1op)
_short_op:      SET A, X
                BOR A, 0b11001111   ; 
                JSR _var_map
                AND X, 0xF
                IFE [inst_argc], 0
                    m [_0op_inst+X]
                JMP [_1op_inst+X]



.endproc

; =========================================================
; Preserve z-machine call frame, and restore with call
; =========================================================
.proc
zm_call:        PUSH B
                PUSH C
                PUSH [current_pc]
                PUSH [even_flag]
                PUSH [local_var]
                PUSH [data_stack]
                JSR A
                POP [data_stack]
                POP [local_var]
                POP [even_flag]
                POP [current_pc]
                POP C
                POP B
                RET
.endproc

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

