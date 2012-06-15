; =========================================================
;  Story memory IO
; =========================================================

.equ STORY_FLAGS1   (story_data+0x00)
.equ STORY_HIGH_MEM (story_data+0x02)
.equ STORY_INIT_PC  (story_data+0x03)
.equ STORY_DICT_LOC (story_data+0x04)
.equ STORY_OBJ_TBL  (story_data+0x05)
.equ STORY_GLOBALS  (story_data+0x06)
.equ STORY_STATIC   (story_data+0x07)
.equ STORY_FLAGS2   (story_data+0x08)
.equ STORY_ABR_TBL  (story_data+0x0C)
.equ STORY_INT_VER  (story_data+0x0F)
.equ STORY_STD_REV  (story_data+0x19)

current_pc:     .data story_data    ; Absolute location of current program data
even_flag:      .data 0             ; Non-zero when reading on an odd boundary
output_stream:  .data print_char    ; Default to screen

; =========================================================
; =========================================================
.proc
_alpha_dict0:    .data "abcdefghijklmnopqrstuvwxyz"
_alpha_dict1:    .data "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
_alpha_dict2:    .data " \r0123456789.,!?_#'\"/\\-:()"
_alphabet:       .data _alpha_dict0

print_paddr:    SET PUSH, [current_pc]
                SET PUSH, [even_flag]
                JSR set_pc_paddr
                JSR print_zstring
                SET [even_flag], POP
                SET [current_pc], POP
                RET

print_zstring:  SET PUSH, X ; Shifter
                SET PUSH, Y ; Break bit
                SET PUSH, Z ; ZSCII remaining
                SET [_alphabet], _alpha_dict0

                JSR _next_zscii         ; Read first ZSCII char
_zscii_loop:    SET B, EX
                SET A, [_alphabet]       ; A = ZSCII CHAR
                
                SUB A, 6
                ADD A, B

                IFE A, _alpha_dict2      ; If currently selected dict letter is A2:0
                    JMP _zscii_full

                SET A, [A]

                IFE B, 0               ; Print space
                    SET A, ' '
                IFN B, 0
                IFL B, 4               ; If EX = 1..3 (abbrev)
                    JMP _zscii_abbr
                IFN B, 0
                IFL B, 6               ; If EX = 4..5 (dict)
                    JMP _zscii_alpha

                JSR print_char
_reset_step:    SET [_alphabet], _alpha_dict0
_next_step:     JSR _read_zscii
                JMP _zscii_loop

_zscii_full:    JSR _read_zscii
                SET A, EX
                SHL A, 5
                SET PUSH, A
                JSR _read_zscii
                SET A, POP
                BOR A, EX
                JSR print_char
                JMP _reset_step
                
_zscii_alpha:   IFE B, 4
                    SET [_alphabet], _alpha_dict1
                IFE B, 5
                    SET [_alphabet], _alpha_dict2
                JMP _next_step
                
_zscii_abbr:    JSR _read_zscii
                SET A, B                ; A = 1..3
                SUB A, 1                ; A = 0..2 (abbr entry)
                SHL A, 5                ; A = 0, 32, 64
                ADD A, EX               ; A = 0...95
                SHL A, 1                ; (Multiply by 2)
                ADD A, [STORY_ABR_TBL]  ; Look up packed addr
                JSR read_w_addr
                JSR print_paddr
                JMP _reset_step


_read_zscii:    IFG Z, 0            ; We have at least one zscii code
                    JMP _shift_out
                IFN Y, 0            ; Is the done bit set?
                    JMP _zscii_done
_next_zscii:    JSR read_w_pc       ; Get the next zscii
                SET X, A
                SHL X, 1            ; EX = break bit
                SET Y, EX           ; Z = break
                SET Z, 3            ; We have 3 characters left
_shift_out:     SUB Z, 1        
                SHL X, 5            ; EX = next zscii char
                RET

_zscii_done:    SET X, POP  ; Strip off the last PC
                SET Z, POP
                SET Y, POP
                SET X, POP
                RET
.endproc

; =========================================================
; =========================================================

; =========================================================
; Jump to new program (packed) address (A = target)
; =========================================================
set_pc_paddr:   SET [current_pc], A
                SET [even_flag], 0
                ADD [current_pc], story_data
                RET

; =========================================================
; Jump to new program (byte) address (A = target)
; =========================================================
set_pc_addr:    SHR A, 1
                SET [current_pc], A
                SET [even_flag], EX
                ADD [current_pc], story_data
                RET

; =========================================================
; Read story/program word (A = byte address, A = result)
; =========================================================
.proc
read_w_addr:    SHR A, 1
                SET C, EX
                ADD A, story_data
                SET EX, C
                JMP _read_word

read_w_pc:      SET A, [current_pc]
                ADD [current_pc], 1
                SET EX, [even_flag]

_read_word:     SET C, [A+1]
                SET A, [A]
                IFE EX, 0
                    RET             ; A already contains word
                SHL A, 8
                SHR C, 8
                BOR A, C
                RET
.endproc


; =========================================================
; Read program byte (a = result)
; =========================================================
read_b_pc:      SET A, [current_pc]
                SET A, [A]
                ADD [even_flag], 0x8000
                ADD [current_pc], EX
                IFE [even_flag], 0
                    AND A, 0xFF             ; Odd bytes are stored in the lower half
                IFN [even_flag], 0
                    SHR A, 8                ; Even bytes are stored in the upper half
                RET

; =========================================================
; Read story byte (a = byte address)
; =========================================================
read_b_addr:    SHR A, 1
                SET A, [A+story_data]
                IFN EX, 0
                    AND A, 0xFF ; We use the lower half
                IFE EX, 0
                    SHR A, 8    ; We use the upper half
                RET

; =========================================================
; Write story byte (a = byte address, b = data)
; WARNING: DOES NOT VALIDATE STATIC DATA BOUNDARY
; =========================================================
.proc
write_b_addr:   SHR A, 1
                IFN EX, 0
                    JMP _wb_odd
                IFE EX, 0
                AND [A+story_data], 0x00FF
                SHL B, 8
                BOR [A+story_data], B
                RET
_wb_odd:        AND [A+story_data], 0xFF00
                AND B, 0xFF
                BOR [A+story_data], B
                RET
.endproc

; =========================================================
; Write story word (a = byte address, b = data)
; WARNING: DOES NOT VALIDATE STATIC DATA BOUNDARY
; =========================================================
.proc
write_w_addr:   SHR A, 1
                IFN EX, 0
                    JMP _ww_odd
                SET [A+story_data], B
                RET
_ww_odd:        ADD A, story_data
                AND [A], 0xFF00
                AND [A+1], 0x00FF
                SHR B, 8
                BOR [A], B
                BOR [A+1], EX
                RET
.endproc