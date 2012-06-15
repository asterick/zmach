key_device:     .data   0xFFFF      ; Keep device private

; =========================================================
; Keyboard device
; =========================================================

init_keys:      SET [key_device], I
                RET

; =========================================================
; Clear the keyboard buffer
; =========================================================
clear_keys:     SET A, 0            ; Clear queue
                HWI [key_device]
                RET

; =========================================================
; C = Keyboard press (Waits for input)
; =========================================================
.proc
read_key:       JSR get_random      ; Feed our RNG
                SET A, 1            ; Read from queue
_read_loop:     HWI [key_device]
                IFE C, 0            ; Wait for key code
                    JMP _read_loop
                SET A, C            ; A = keycode
                RET
.endproc

