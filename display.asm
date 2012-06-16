; =========================================================
;  Display Logic
; =========================================================

.equ LINE_CHARS     32
.equ LINE_HEIGHT    12
.equ SCREEN_SIZE    (LINE_CHARS*LINE_HEIGHT)

; Display configuration
.equ SCR_CURSOR     0
.equ SCR_COLOR      1
.equ SCR_FLAGS      2
.equ SCR_START      3
.equ SCR_END        4
.equ SCR_REM_CHAR   5
.equ SCR_LINES_FED  6
.equ SCR_LINES_HOLD 7

; Display flags
.equ SCR_NONE       0   ; No flags selected
.equ SCR_SCROLL     1   ; Allow automatic scrolling
.equ SCR_WRAP       2   ; Allow word wrap
.equ SCR_MORE       4   ; Prompt when scrolling too much

lem_device:         .data 0xFFFF
active_display:     .data display_status

display_status:     .data lem_display
                    .data 0xF100
                    .data SCR_NONE
                    .data lem_display
                    .data lem_display+LINE_CHARS
                    .data LINE_CHARS
                    .data 0, 1

display_game:       .data lem_display+LINE_CHARS*2          ; Keep one line blank
                    .data 0xF000
                    .data SCR_SCROLL | SCR_WRAP | SCR_MORE
                    .data lem_display+LINE_CHARS 
                    .data lem_display+SCREEN_SIZE
                    .data LINE_CHARS
                    .data 0, LINE_HEIGHT - 2

; =========================================================
; Hook up display to device
; =========================================================
init_term:      SET [lem_device], I
                SET A, 0
                SET B, lem_display
                HWI I
                RET

; =========================================================
; Set border color
; =========================================================
set_border:     SET B, A
                SET A, 3
                HWI [lem_device]
                RET

; =========================================================
; Set active display
; =========================================================
set_display:    SET [active_display], A
                RET

; =========================================================
; Set display color of active display
; =========================================================
set_color:      SET I, [active_display]
                SET [I+SCR_COLOR], A
                RET

; =========================================================
; Clear active display
; =========================================================
.proc
clear_display:  PUSH I
                SET C, [active_display]
                SET B, [C+SCR_START]
                SET [C+SCR_LINES_FED], 0
                SET [C+SCR_CURSOR], B
                SET I, [C+SCR_COLOR]
                BOR I, ' '
_clear_loop:    SET [B], I
                ADD B, 1
                IFL B, [C+SCR_END]
                    SET PC, _clear_loop
                POP I
                RET
.endproc

; =========================================================
; Reset "more" feed
; =========================================================
clear_more:     SET B, [active_display]
                SET [B+SCR_LINES_FED], 0
                RET

; =========================================================
; Read a line of characters
; =========================================================
.proc
read_line:      PUSH Z                      ; Insert mode?
                PUSH Y                      ; Cursor location
                PUSH X                      ; End of string location
                PUSH I
                PUSH J
                JSR clear_keys

                SET Z, 0
                SET B, [active_display]
                SET Y, [B+SCR_CURSOR]
                SET X, Y

_read_loop:     JSR _draw_cursor
                JSR read_key

                ; --- Clear cursor ----------
                IFN Y, X
                    AND [Y], 0xFF
                IFE Y, X
                    SET [Y], ' '
                BOR [Y], [B+SCR_COLOR]
                
                IFE A, 0x10                 ; Backspace
                    JMP _backspace_key
                IFE A, 0x11                 ; Return
                    JMP _return
                IFE A, 0x12                 ; Insert
                    JMP _insert_key
                IFE A, 0x13                 ; Delete
                    JMP _delete_key
                IFE A, 0x82                 ; Left
                    JMP _left_key
                IFE A, 0x83                 ; Right
                    JMP _right_key
                IFG A, 0x7F                 ; Not-ascii
                    JMP _read_loop
                
                IFL Y, X                    ; Cursor mid-string
                IFE Z, 0                    ; Insert mode
                    JSR _shift_forward

                SET [Y], A
                BOR [Y], [B+SCR_COLOR]
                SET A, [B+SCR_END]
                SUB A, 1

                ADD Y, 1
                IFG Y, X
                    SET X, Y

                ; Clamp values to prevent writting outside of display
                SET A, [B+SCR_END]
                IFG X, A
                    SET X, A
                SUB A, 1
                IFG Y, A
                    SET Y, A
                JMP _read_loop
                

_shift_forward: SET I, X
                IFE I, [B+SCR_END]
                    SUB I, 1
_sf_loop:       IFE I, Y
                    JMP _sf_return
                SET [I], [I-1]
                SUB I, 1
                JMP _sf_loop
_sf_return:     ADD X, 1
                RET

_shift_back:    SET I, Y
_sb_loop:       IFE I, X
                    JMP _sb_return
                SET [I], [I+1]
                ADD I, 1
                JMP _sb_loop
_sb_return:     SUB X, 1
                SET [X], ' '
                BOR [X], [B+SCR_COLOR]
                RET

_backspace_key: IFE Y, [B+SCR_CURSOR]
                    JMP _read_loop
                SUB Y, 1                    ; Delete previous character
                JSR _shift_back
                JMP _read_loop
_delete_key:    IFE Y, X
                    JMP _read_loop
                JSR _shift_back             ; Delete character ahead of cursor
                JMP _read_loop
                
_insert_key:    XOR Z, 1                    ; Toggle insert mode
                JMP _read_loop

_left_key:      IFG Y, [B+SCR_CURSOR]
                    SUB Y, 1
                JMP _read_loop
                
_right_key:     IFL Y, X
                    ADD Y, 1
                JMP _read_loop

_return:        POP J
                POP I
                POP X
                POP Y
                POP Z
                RET


_draw_cursor:   IFE Y, X
                   JMP _draw_end
                AND [Y], 0xFF
                IFE Z, 0
                    BOR [Y], 0xF800
                IFN Z, 0
                    BOR [Y], 0x0F00
                RET
_draw_end:      SET [Y], [B+SCR_COLOR]
                IFE Z, 0
                    BOR [Y], '_' | 0x80     ; Blinking cursor
                IFN Z, 0
                    BOR [Y], 0x9C
                RET


.endproc

; =========================================================
; Print a number to active display
; =========================================================

.proc
print_num:      IFA A, -1
                    JMP print_unum
                SET C, A
                SET A, '-'
                JSR print_char
                SET A, C
                MLI A, -1

print_unum:     PUSH X
                PUSH Y
                SET Y, A
                SET X, 10000
_pn_size:       IFE X, Y
                    JMP _pn_loop
                IFL X, Y
                    JMP _pn_loop
                DIV X, 10
                JMP _pn_size
                
_pn_loop:       SET A, Y
                MOD Y, X
                DIV A, X
                ADD A, '0'
                JSR print_char
                DIV X, 10
                IFN X, 0
                    JMP _pn_loop
                POP Y
                POP X
                RET
.endproc

; =========================================================
; Print character to active display
; =========================================================
.proc
_more_prompt:   .data "[more]", 0
print_char:     PUSH J
                PUSH I
                SET C, [active_display]
                JSR _check_scroll           ; Do We need to scroll our text?
                IFN A, '\r'                 ; Carriage return (line break)
                IFN [C+SCR_REM_CHAR], 0     ; We need at least one character on the line
                    JMP _copy_char
                ADD [C+SCR_LINES_FED], 1    ; For the [more] break
                ADD [C+SCR_CURSOR], [C+SCR_REM_CHAR]
                SET [C+SCR_REM_CHAR], LINE_CHARS
                IFE A, ' '
                    JMP _printc_ret
                IFE A, '\r'
                    JMP _printc_ret
                JSR _check_scroll           ; Do We need to scroll our text?

                SET I, [C+SCR_CURSOR]
                SET B, 32
_find_space:    SUB B, 1
                IFU B, 0                    ; Word was too long, do not wrap
                    JMP _copy_char
                SUB I, 1
                SET J, [I]
                AND J, 0xFF
                IFN J, ' '
                    JMP _find_space

                ADD B, 1
                IFE B, LINE_CHARS
                    JMP _copy_char
                ADD I, 1
                SET [C+SCR_REM_CHAR], B
                SET J, [C+SCR_CURSOR]
_wrap_copy:     SET [J], [I]
                STI [I], [C+SCR_COLOR]
                BOR [I-1], ' '
                ADD B, 1
                IFN B, LINE_CHARS
                    JMP _wrap_copy
                SET [C+SCR_CURSOR], J
                JMP _copy_char

_copy_char:     SET B, [C+SCR_CURSOR]
                ADD B, 1
                IFG B, [C+SCR_END]
                    JMP _printc_ret
                BOR A, [C+SCR_COLOR]
                SET [B-1], A
                SET [C+SCR_CURSOR], B
                SUB [C+SCR_REM_CHAR], 1
_printc_ret:    POP I
                POP J
                RET

_check_scroll:  IFL [C+SCR_CURSOR], [C+SCR_END] ; In current display
                    JMP _check_more
                IFC [C+SCR_FLAGS], SCR_SCROLL   ; Scroll disabled
                    RET
                SET B, [C+SCR_START]
                SET I, [C+SCR_END]
                SUB I, LINE_CHARS
_scroll_loop:   SET [B], [B+LINE_CHARS]
                ADD B, 1
                IFL B, I
                    JMP _scroll_loop
_scroll_clear:  SET [B], ' '
                BOR [B], [C+SCR_COLOR]
                ADD B, 1
                IFL B, [C+SCR_END]
                    JMP _scroll_clear                
                SUB [C+SCR_CURSOR], LINE_CHARS
_check_more:    IFC [C+SCR_FLAGS], SCR_MORE
                    RET
                IFL [C+SCR_LINES_FED], [C+SCR_LINES_HOLD]
                    RET
                SET [C+SCR_LINES_FED], 0
                SET I, [C+SCR_CURSOR]
                SET J, _more_prompt
_hold_loop:     STI [I], [J]
                BOR [I-1], [C+SCR_COLOR]
                BOR [I-1], 0x80
                IFN [J], 0
                    JMP _hold_loop
                PUSH A
                PUSH C
                JSR clear_keys
                JSR read_key
                POP C
                POP A
                RET
.endproc