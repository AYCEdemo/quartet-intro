
rgb: MACRO
RED = (\1) >> 3
GREEN = (\2) >> 3
BLUE = (\3) >> 3
	dw RED | GREEN << 5 | BLUE << 10
ENDM

SECTION "Palettes", ROM0[0]

; BG0
	rgb 255, 255, 255
	rgb  64,  98, 155
	rgb  51,  44,  80
	rgb   0,   0,   0
; BG1
	rgb 255, 255, 255
	rgb  64,  98, 155
	rgb  51,  44,  80
	rgb   0,   0,   0
; BG2-7
	ds 6 * 4 * 2

; OBJ0
	db 0 ; Ignored
	rgb  70, 135, 143
	rgb 255, 255, 255
	rgb 255, 255, 255
	db 0

PRINTT "NB_OBJ_PALS equ 1\n"
