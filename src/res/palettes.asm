
rgb: MACRO
RED = (\1) >> 3
GREEN = (\2) >> 3
BLUE = (\3) >> 3
	dw RED | GREEN << 5 | BLUE << 10
ENDM

SECTION "Palettes", ROM0[0]

; BG0
	rgb 255, 255, 255 ; Light
	rgb 122,  35, 105 ; Character skin
	rgb  51,  44,  80 ; Window frame
	rgb   0,   0,   0 ; Outside dark
; BG1
	rgb 255, 255, 255 ; Light
	rgb 122,  35, 105 ; Character skin
	rgb  51,  44,  80 ; Window frame
	rgb  16,  18,  85 ; Car interior
; BG2
	rgb 255, 255, 255 ; Light
	rgb 122,  35, 105 ; Character skin
	rgb  68,  40,  91 ; Character "edges" & clothes
	rgb  16,  18,  85 ; Car interior
; BG3
	rgb 255, 255, 255 ; Light
	rgb 122,  35, 105 ; Character skin
	rgb  68,  40,  91 ; Character "edges" & clothes
	rgb   0,   0,   0 ; Outside dark
; BG4
	rgb 255, 255, 255 ; Light
	rgb 122,  35, 105 ; Character skin
	rgb  68,  40,  91 ; Character "edges" & clothes
	rgb  18,  25,  87 ; Eye
; BG5
	rgb 255, 255, 255 ; Light (unused)
	rgb 108, 108, 108 ; Cartridge
	rgb 140, 140, 140 ; Cartridge edges
	rgb   0,   0,   0 ; Unused
; BG6-7
	ds 2 * 4 * 2, 0

; OBJ0
	dw 0 ; Unused
	rgb   8, 128, 128 ; GB shell (flashing on DMG)
	rgb  68,  40,  91 ; GB shell "edges"
	rgb 255, 255, 255 ; GB light & text
