.include        "system.inc"        ; macros for ease of use

.org            bss_section
lem_display:    .bss 0x180          ; Frame buffer
game_stack:                         ; Unused heap space

.org            0x0000
.include        "crt0.asm"          ; Startup code
;.include        "interpreter.asm"   ; Actual runtime code
;.include        "memory.asm"        ; Z-Machine memory I/O calls
.include        "display.asm"       ; Display driver
.include        "keyboard.asm"      ; Keyboard driver
.include        "algorithms.asm"    ; Various algorithms

story_data:     ;.incbig "stories/ZORK1.DAT"

; =========================================================
; Post initialization main function
; =========================================================

entry:          SET A, 1
                JSR set_border

                SET A, display_status
                JSR set_display
                JSR clear_display

                SET A, display_game
                JSR set_display
                JSR clear_display

                JSR read_line
crash:          JMP crash

bss_section:    