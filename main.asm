.include        "system.inc"        ; macros for ease of use

; Global definition table
.org            bss_section
local_var:      .bss 1
data_stack:     .bss 1
return_value:   .bss 1
inst_argc:      .bss 1
inst_argv:      .bss 4
key_device:     .bss 1
lem_device:     .bss 1
lem_display:    .bss 0x180          ; Frame buffer

heap:                               ; Unused heap space

.org            0x0000
.include        "crt0.asm"          ; Startup code
.include        "memory.asm"        ; Z-Machine memory I/O calls
.include        "interpreter.asm"   ; Actual runtime code
.include        "display.asm"       ; Display driver
.include        "keyboard.asm"      ; Keyboard driver
.include        "algorithms.asm"    ; Various algorithms

story_data:     .incbig "stories/ZORK1.DAT"

; =========================================================
; Post initialization main function
; =========================================================

reset:          SET A, 1
                JSR set_border

                SET A, display_status
                JSR set_display
                JSR clear_display

                SET A, display_game
                JSR set_display
                JSR clear_display

                JSR mach_start
                JMP reset

bss_section:    