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
.equ illegal 0
_0op_inst:      .data zm_rtrue      ; 0x00
                .data zm_rfalse     ; 0x01
                .data zm_print      ; 0x02
                .data zm_printret   ; 0x03
                .data step_mach     ; 0x04
                .data 0             ; 0x05 * Will not implement
                .data 0             ; 0x06 * Will not implement
                .data 0             ; 0x07 * Will not implement
                .data zm_retpop     ; 0x08
                .data zm_voidpop    ; 0x09
                .data zm_quit       ; 0x0A
                .data zm_newline    ; 0x0B
                .data 0             ; 0x0C
                .data 0             ; 0x0D
                .data illegal       ; 0x0E
                .data illegal       ; 0x0F
_1op_inst:      .data 0             ; 0x00
                .data 0             ; 0x01
                .data 0             ; 0x02
                .data 0             ; 0x03
                .data 0             ; 0x04
                .data zm_inc        ; 0x05
                .data zm_dec        ; 0x06
                .data zm_printaddr  ; 0x07
                .data zm_call       ; 0x08
                .data 0             ; 0x09
                .data 0             ; 0x0A
                .data zm_ret        ; 0x0B
                .data zm_jump       ; 0x0C
                .data zm_printpaddr ; 0x0D
                .data zm_load       ; 0x0E
                .data zm_not        ; 0x0F
_2op_inst:      .data illegal       ; 0x00
                .data zm_je         ; 0x01
                .data zm_jl         ; 0x02
                .data zm_jg         ; 0x03
                .data zm_decchk     ; 0x04
                .data zm_incchk     ; 0x05
                .data 0             ; 0x06
                .data zm_test       ; 0x07
                .data zm_or         ; 0x08
                .data zm_and        ; 0x09
                .data 0             ; 0x0A
                .data 0             ; 0x0B
                .data 0             ; 0x0C
                .data zm_store      ; 0x0D
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
                .data illegal       ; 0x19
                .data illegal       ; 0x1A
                .data illegal       ; 0x1B
                .data illegal       ; 0x1C
                .data illegal       ; 0x1D
                .data illegal       ; 0x1E
                .data illegal       ; 0x1F
_var_inst:      .data zm_call       ; 0x00
                .data zm_storew     ; 0x01
                .data zm_storeb     ; 0x02
                .data 0             ; 0x03
                .data 0             ; 0x04
                .data zm_printchar  ; 0x05
                .data zm_printnum   ; 0x06
                .data zm_random     ; 0x07
                .data zm_push       ; 0x08
                .data zm_pop        ; 0x09
                .data 0             ; 0x0A
                .data 0             ; 0x0B
                .data illegal       ; 0x0C
                .data illegal       ; 0x0D
                .data illegal       ; 0x0E
                .data illegal       ; 0x0F
                .data illegal       ; 0x10
                .data illegal       ; 0x11
                .data illegal       ; 0x12
                .data 0             ; 0x13
                .data 0             ; 0x14
                .data 0             ; 0x15
                .data illegal       ; 0x16
                .data illegal       ; 0x17
                .data illegal       ; 0x18
                .data illegal       ; 0x19
                .data illegal       ; 0x1A
                .data illegal       ; 0x1B
                .data illegal       ; 0x1C
                .data illegal       ; 0x1D
                .data illegal       ; 0x1E
                .data illegal       ; 0x1F


.endproc

.proc
zm_objaddr:     SUB A, 1
                MUL A, 9
                ADD A, 64
                ADD A, [STORY_OBJ_TBL]
                RET
.endproc

.proc
zm_branch:      SET X, A            ; X = Condition
                JSR read_b_pc

                IFC A, 0x80
                    JMP _no_invert
                ; Invert Condition conditional
                IFE X, 0
                    SET X, 1
                IFN X, 0
                    SET X, 0
                AND A, 0x7F

_no_invert:     SET Y, A
                AND Y, 0x3F
                IFB A, 0x40
                    JMP _single_byte

                SHL Y, 8
                IFB Y, 0x20
                    BOR Y, 0xC0     ; Sign extend
                JSR read_b_pc
                BOR Y, A

_single_byte:   IFN X, 0            ; No branch
                    JMP step_mach
                IFE Y, 0            ; Return false
                    JMP zm_rfalse
                IFE Y, 1            ; Return true
                    JMP zm_rtrue
                SUB Y, 2            ; Y = offset
                
                ASR Y, 1            ; Relative jump
                ADD [even_flag], EX 
                ADX [current_pc], Y
                JMP step_mach

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
zm_test:        SET C, [inst_argv]
                SET B, [inst_argv+1]
                AND C, B
                SET A, 0
                IFE C, B
                    SET A, 1
                JMP zm_branch
.endproc

.proc
zm_je:          SET I, 1
                SET A, 0    ; Don't branch
_check:         IFE I, [inst_argc]
                IFG I, [inst_argc]
                    JMP zm_branch
                IFE [inst_argv], [inst_argv+I]
                    SET A, 1
                JMP _check
.endproc

.proc
zm_jl:          SET A, 0
                IFU [inst_argv], [inst_argv+1]
                    SET A, 1
                JMP zm_branch
.endproc

.proc
zm_jg:          SET A, 0
                IFA [inst_argv], [inst_argv+1]
                    SET A, 1
                JMP zm_branch
.endproc

.proc
zm_jump:        SET A, [inst_argv]
                ASR A, 1
                ADD [even_flag], EX 
                ADX [current_pc], A
                JMP step_mach
.endproc

.proc
zm_quit:        JMP zm_quit
.endproc

.proc
zm_newline:     SET A, '\r'
                JSR print_char
                RET
.endproc

.proc
zm_retpop:      SET A, 0
                JSR read_var
                SET [return_value], A
                RET
.endproc

.proc
zm_voidpop:     SET A, 0
                JSR read_var
                JMP step_mach
.endproc

.proc
zm_rfalse:      SET [return_value], 0
                RET
.endproc

.proc
zm_rtrue:       SET [return_value], 1
                RET
.endproc

.proc
zm_push:        SET B, [inst_argv]
                SET A, 0
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_pop:         SET A, 0
                JSR read_var
                SET B, A
                SET A, [inst_argv]
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_random:      SET A, [inst_argv]
                IFB A, 1
                    JMP _random_seed
                JSR get_random
                MOD A, [inst_argv]
                ADD A, 1
                SET X, A
                JSR read_b_pc
                SET B, X
                JSR write_var
                JMP step_mach

_random_seed:   JSR seed_random
                JSR read_b_pc
                SET B, 0
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_not:         JSR read_b_pc
                SET B, [inst_argv]
                XOR B, 0xFFFF
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_and:         JSR read_b_pc
                SET B, [inst_argv]
                AND B, [inst_argv+1]
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_or:          JSR read_b_pc
                SET B, [inst_argv]
                BOR B, [inst_argv+1]
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_inc:         SET A, [inst_argv]
                JSR read_var
                SET B, A
                ADD B, 1
                SET A, [inst_argv]
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_incchk:      SET A, [inst_argv]
                JSR read_var
                SET B, A
                ADD B, 1
                SET X, 0
                IFA B, [inst_argv+1]
                    SET X, 1
                SET A, [inst_argv]
                JSR write_var
                JMP zm_branch
.endproc

.proc
zm_dec:         SET A, [inst_argv]
                JSR read_var
                SET B, A
                SUB B, 1
                SET A, [inst_argv]
                JSR write_var
                JMP zm_branch
.endproc

.proc
zm_decchk:      SET A, [inst_argv]
                JSR read_var
                SET B, A
                SUB B, 1
                SET X, 0
                IFU B, [inst_argv+1]
                    SET X, 1
                SET A, [inst_argv]
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_load:        SET A, [inst_argv]
                JSR read_var
                SET X, A
                JSR read_b_pc
                SET B, X
                JSR write_var
                JMP step_mach
.endproc

.proc
zm_store:       SET A, [inst_argv]
                SET B, [inst_argv+1]
                JSR write_var
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

.proc
zm_printaddr:   SET A, [inst_argv]
                JSR print_addr
                JMP step_mach
.endproc

.proc
zm_printpaddr:  SET A, [inst_argv]
                JSR print_paddr
                JMP step_mach
.endproc

.proc
zm_print:       JSR print_addr
                JMP step_mach
.endproc

.proc
zm_printret:    JSR print_addr
                SET [return_value], 1   ; Return true
                RET
.endproc

.proc
zm_ret:         SET [return_value], [inst_argv]
                RET
.endproc

.proc
zm_printchar:   SET A, [inst_argv]
                IFN A, '\r'
                IFL A, 0x20
                    JMP step_mach
                IFL A, 0x80             ; Print only ascii characters
                    JSR print_char
                JMP step_mach

.endproc

.proc
zm_printnum:    SET A, [inst_argv]
                JSR print_num
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

