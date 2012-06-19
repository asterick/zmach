; --- TOP OF DATA STACK
; [variables 0...E]
; [data stack]

; =========================================================
; Z-Machine entry point (operations table included)
; =========================================================

.proc

mach_start:     SET [local_var], heap           ; Reset to top of stack
                SET [data_stack], heap          ; Entry point has no locals
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
                    JMP [_0op_inst+X]
                JMP [_1op_inst+X]

; --- Jump tables --------------------------
_0op_inst:      .data 0             ; 0x00
                .data 0             ; 0x01
                .data 0             ; 0x02
                .data 0             ; 0x03
                .data 0             ; 0x04
                .data 0             ; 0x05
                .data 0             ; 0x06
                .data 0             ; 0x07
                .data 0             ; 0x08
                .data 0             ; 0x09
                .data 0             ; 0x0A
                .data 0             ; 0x0B
                .data 0             ; 0x0C
                .data 0             ; 0x0D
                .data 0             ; 0x0E *
                .data 0             ; 0x0F *
_1op_inst:      .data 0             ; 0x00
                .data 0             ; 0x01
                .data 0             ; 0x02
                .data 0             ; 0x03
                .data 0             ; 0x04
                .data 0             ; 0x05
                .data 0             ; 0x06
                .data 0             ; 0x07
                .data zm_call       ; 0x08
                .data 0             ; 0x09
                .data 0             ; 0x0A
                .data 0             ; 0x0B
                .data 0             ; 0x0C
                .data 0             ; 0x0D
                .data 0             ; 0x0E
                .data 0             ; 0x0F
_2op_inst:      .data 0             ; 0x00
                .data 0             ; 0x01
                .data 0             ; 0x02
                .data 0             ; 0x03
                .data 0             ; 0x04
                .data 0             ; 0x05
                .data 0             ; 0x06
                .data 0             ; 0x07
                .data 0             ; 0x08
                .data 0             ; 0x09
                .data 0             ; 0x0A
                .data 0             ; 0x0B
                .data 0             ; 0x0C
                .data 0             ; 0x0D
                .data 0             ; 0x0E
                .data zm_loadw      ; 0x0F
                .data zm_loadb      ; 0x10
                .data 0             ; 0x11
                .data 0             ; 0x12
                .data 0             ; 0x13
                .data zm_add        ; 0x14
                .data zm_sub        ; 0x15
                .data zm_mul        ; 0x16
                .data zm_div        ; 0x17
                .data zm_mod        ; 0x18
                .data 0             ; 0x19 *
                .data 0             ; 0x1A *
                .data 0             ; 0x1B *
                .data 0             ; 0x1C *
                .data 0             ; 0x1D *
                .data 0             ; 0x1E *
                .data 0             ; 0x1F *
_var_inst:      .data zm_call       ; 0x00
                .data zm_storew     ; 0x01
                .data zm_storeb     ; 0x02
                .data 0             ; 0x03
                .data 0             ; 0x04
                .data 0             ; 0x05
                .data 0             ; 0x06
                .data 0             ; 0x07
                .data 0             ; 0x08
                .data 0             ; 0x09
                .data 0             ; 0x0A
                .data 0             ; 0x0B
                .data 0             ; 0x0C
                .data 0             ; 0x0D
                .data 0             ; 0x0E
                .data 0             ; 0x0F
                .data 0             ; 0x10
                .data 0             ; 0x11
                .data 0             ; 0x12
                .data 0             ; 0x13
                .data 0             ; 0x14
                .data 0             ; 0x15
                .data 0             ; 0x16 *
                .data 0             ; 0x17 *
                .data 0             ; 0x18 *
                .data 0             ; 0x19 *
                .data 0             ; 0x1A *
                .data 0             ; 0x1B *
                .data 0             ; 0x1C *
                .data 0             ; 0x1D *
                .data 0             ; 0x1E *
                .data 0             ; 0x1F *


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
                
                SET A, [inst_argv]  ; Argument 0 is always the routine
                JSR set_pc_paddr    ; Jump to the packed address

                JSR read_b_pc                   ; Get local argument count

                SET J, [data_stack]             ; Shift call frame (allocate A locals)
                SET [local_var], J
                ADD [data_stack], A

                SET I, [inst_argc]              ; Current argument count
                SUB I, 1                        ; Last argument index
                ADD J, I                        ; J = locals[I]
_arg_loop:      IFA I, 0                        ; Copy down (ignore routine address)
                    JMP _call_start
                STD [J-1], [inst_argv+I]        ; J is one too high
                JMP _arg_loop

_call_start:    JSR step_mach
                SET A, [return_value]           ; Reserve return value
                JSR write_var
                POP [data_stack]
                POP [local_var]
                POP [even_flag]
                POP [current_pc]
                POP C
                POP B
                JMP step_mach
.endproc

.proc
zm_add:         JSR read_b_pc
                SET B, [inst_argv]
                ADD B, [inst_argv+1]
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_sub:         JSR read_b_pc
                SET B, [inst_argv]
                SUB B, [inst_argv+1]
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_mul:         JSR read_b_pc
                SET B, [inst_argv]
                MLI B, [inst_argv+1]
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_div:         JSR read_b_pc
                SET B, [inst_argv]
                DVI B, [inst_argv+1]
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_mod:         JSR read_b_pc
                SET B, [inst_argv]
                MDI B, [inst_argv+1]
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_loadw:       SET A, [inst_argv+1]
                SHL A, 1
                ADD A, [inst_argv]
                JSR read_w_addr         ; A = Word
                SET X, A
                JSR read_b_pc
                SET B, X
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_loadb:       SET A, [inst_argv+1]
                ADD A, [inst_argv]
                JSR read_b_addr         ; A = Byte
                SET X, A
                JSR read_b_pc
                SET B, X
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_storew:      SET A, [inst_argv+1]
                SHL A, 1
                ADD A, [inst_argv]
                SET B, [inst_argv+2]
                JSR write_w_addr
                JMP step_mach
.endproc

.proc
zm_storeb:      SET A, [inst_argv+1]
                ADD A, [inst_argv]
                SET B, [inst_argv+2]
                JSR write_b_addr
                JMP step_mach
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

