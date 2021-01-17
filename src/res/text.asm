
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
	charmap " ", 1


frame: MACRO
	static_assert STRLEN(\1) <= NB_TEXT_SPRITES, "First line too long!"
	static_assert STRLEN(\2) + STRLEN(\3) <= NB_TEXT_SPRITES_2, "2nd+3rd line too long!"

	db \1, 0, \2, 0, \3, 0
ENDM

SECTION "Text", ROM0[0]

	frame "AYCE", "PRESENTS", "..."
	frame "0123456789", "QUARTET", ""
	db 0 ; Terminator
