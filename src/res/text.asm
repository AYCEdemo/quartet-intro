
FONT_BASE_TILE equ $84
	PRINTT "FONT_BASE_TILE equ {FONT_BASE_TILE}\n"
NB_TEXT_SPRITES equ 10
	PRINTT "NB_TEXT_SPRITES equ {NB_TEXT_SPRITES}\n"
NB_TEXT_SPRITES_2 equ 14
	PRINTT "NB_TEXT_SPRITES_2 equ {NB_TEXT_SPRITES_2}\n"

CHARS equs "?!\"#$&'()*+,-./0123456789<=>ABCDEFGHIJKLMNOPQRSTUVWXYZ:;"
X = 0
REPT STRLEN("{CHARS}")
	charmap STRSUB("{CHARS}", X + 1, 1), X * 2 + FONT_BASE_TILE
X = X + 1
ENDR
	charmap " ", 0


; On-screen X position of the leftmost sprite in each line, if it was 10 chars long
LINE1_X equ 77
LINE2_X equ 77
LINE3_X equ 77


line: MACRO
LEN = STRLEN(\2)
	db LINE\1_X + (10 - LEN) * 4, \2, 1

I = 0
	REPT LEN
I = I + 1
		IF !STRCMP(STRSUB(\2, I, 1), " ")
LEN = LEN - 1
		ENDC
	ENDR
ENDM

frame: MACRO

	line 1, \1
	static_assert LEN <= NB_TEXT_SPRITES, "1st line too long! ({d:LEN} > 10)"
	line 2, \2
	static_assert LEN <= 8, "2nd line too long! ({d:LEN} > 8)" ; 2 light sprites on same scanline
LINE2_LEN = LEN
	line 3, \3
	static_assert LEN <= 8, "3rd line too long! ({d:LEN} > 8)" ; Technically 3, but it always overlaps with another, so OK
LEN = LINE2_LEN + LEN
	static_assert LEN <= NB_TEXT_SPRITES_2, "2nd+3rd line too long! ({d:LEN} > {d:NB_TEXT_SPRITES_2})"
ENDM

SECTION "Text", ROM0[0]

	frame "AYCE", "PRESENTS", "..."
	frame "", "QUARTET", ""
	frame "CODE", "", "ISSOTM"
	frame "GFX", "", "DOCTOR"
	frame "MUSIC", "", "DEVED"
	frame "PRESS ANY", "BTN FOR", "THE GAME"
	frame "SCROLLER", "LOOPS NOW", "..."
	db 0 ; Terminator
