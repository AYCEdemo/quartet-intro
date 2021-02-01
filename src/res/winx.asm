
INCLUDE "hardware.inc/hardware.inc"


SECTION "Data", ROM0[0]

LOAD "Decompressed data", WRAM0[$C22A]

WXVAL_LEN = 0 ; Length of dest buffer
CUR_FRAME = 0
; win_x <nb scanlines>, <nb pixels to show>
win_x: MACRO
	IF (\1) == 0 ; Copy
		db (_NARG - 1) * 2 | 1
		REPT _NARG - 1
			SHIFT

			db \1
WXVAL_LEN = WXVAL_LEN + 1

			IF STRIN("\1", "%")
				IF CUR_FRAME == LOOP_FRAME
					; We need to begin *after* the header
START_OFS equ WXVAL_LEN ; Offset to start at in the uncompressed table (start @ first window val)
					assert (\1) == %00000010 ; If tiles follow the first mask, we need a more complex check
START_CNT equ CUR_FRAME * 8 ; Initial value of frame counter, to sync with START_OFS
				ENDC
CUR_FRAME = CUR_FRAME + 1
			ELSE
				assert (\1) != 1, "WX = 166 is bugged!"
			ENDC
		ENDR

	ELSE ; RLE
		assert (\2) != 0, "Didn't you forget about the sprite header?"
		db (\1) * 2, (\2)
WXVAL_LEN = WXVAL_LEN + (\1)
	ENDC
ENDM


BASE_TILE equ $2A
t equ BASE_TILE ; Shorter alias
LOOP_FRAME equ 6
BLANK_TILES equ $7ED0

s EQUS "* 16 + StreamedTiles"

WinX:
	win_x  0, /* 10 */ LOW(34s), HIGH(34s), %11011010, t+$3E, t+$40, t+$16, t+$42
	win_x  5, $9C
	win_x  8, $9B
	win_x 11, $9A
	win_x 11, $99
	win_x 10, $98
	win_x  6, $97
	win_x  5, $96
	win_x  3, $95
	win_x  0, $94, $94, $93, $93, $92, $92, $91, $91, $90, $90, $8F, $8E, $8E, $8D, $8D, $8C, $A7, \
              /* 11 */ LOW(38s), HIGH(38s), %01011110, t+$44, t+$16, t+$46, t+$48

	win_x  4, $86
	win_x  8, $85
	win_x  7, $84
	win_x  6, $83
	win_x  8, $82
	win_x  7, $81
	win_x  4, $80
	win_x  4, $7F
	win_x  5, $7E
	win_x  0, $7D, $7D, $7C, $7C, $7B, $7B, $7A, $79, $78, $78, $77, $76, $75, $75, $74, $75, $78, $7C, $80, $83, $86, $89, $8B, $A7, \
              /* 12 */ LOW(42s), HIGH(42s), %01011110, t+$4A, t+$4C, t+$4E, t+$48

	win_x  3, $74
	win_x  3, $73
	win_x  4, $72
	win_x  5, $71
	win_x  5, $70
	win_x  6, $6F
	win_x  7, $6E
	win_x  7, $6D
	win_x  5, $6C
	win_x  2, $6B
	win_x  2, $6A
	win_x  4, $69
	win_x  0, $68, $68, $67, $67, $66, $65, $64, $64, $63, $64, $67, $6B, $6E, $71, $73, $75, $78, $7C, $80, $83, $86, $89, $8B, $A7, \
              /* 13 */ LOW(0s), HIGH(0s), %01011110, t+$50, t+$52, t+$54, t+$48

	win_x  4, $62
	win_x  8, $61
	win_x  9, $60
	win_x  7, $5F
	win_x  4, $5E
	win_x  5, $5D
	win_x  4, $5C
	win_x  0, $5B, $5A, $5A, $59, $58, $57, $57, $58, $59
	win_x  3, $5A
	win_x  3, $5B
	win_x  4, $5C
	win_x  0, $5E, $61, $64, $67, $6B, $6E, $71, $73, $75, $78, $7C, $80, $83, $86, $89, $8B, $A7, \
              /* 14 */ LOW(3s), HIGH(3s), %00011010, t+$56, t+$58

	win_x  4, $5A
	win_x  6, $59
	win_x  5, $58
	win_x  5, $57
	win_x  4, $56
	win_x  3, $55
	win_x  4, $54
	win_x  0, $53, $53, $52, $52, $51, $50, $50, $4F, $51, $52, $53, $54, $54, $55, $56, $57, $57, $58, $59
	win_x  3, $5A
	win_x  3, $5B
	win_x  4, $5C
	win_x  0, $5E, $61, $64, $67, $6B, $6E, $71, $73, $75, $78, $7C, $80, $83, $86, $89, $8B, $A7, \
	          /* 15 */ LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010

	win_x  6, $52
	win_x  7, $51
	win_x  4, $50
	win_x  4, $4F
	win_x  4, $4E
	win_x  7, $4D
	win_x  5, $4C
	win_x  0, $4E, $4F, $51, $52, $53, $54, $54, $55, $56, $57, $57, $58, $59
	win_x  3, $5A
	win_x  3, $5B
	win_x  4, $5C
	win_x  0, $5E, $61, $64, $67, $6B, $6E, $71, $73, $75, $78, $7C, $80, $83, $86, $89, $8B, $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \ ; Downtime w/ no sprites
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              LOW(BLANK_TILES), HIGH(BLANK_TILES), %00000010,  $A7, \
              /*  2 */ LOW(6s), HIGH(6s), %11011010, t+$00, t+$02, t+$04, t+$06,  $A7, \ ; No window light during these
	          /*  3 */ LOW(10s), HIGH(10s), %11011010, t+$08, t+$0A, t+$0C, t+$0E,  $A7, \
	          /*  4 */ LOW(14s), HIGH(14s), %11111110, t+$10, t+$12, t+$14, t+$16, t+$18, t+$1A,  $A7, \
	          /*  5 */ LOW(18s), HIGH(18s), %11111110, t+$1C, t+$1E, t+$20, t+$16, t+$22, t+$24

	win_x  5, $9D
	win_x 11, $9E
	win_x 10, $9F
	win_x  8, $A0
	win_x  6, $A1
	win_x  3, $A2
	win_x  4, $A3
	win_x  3, $A4
	win_x  0, $A5, $A7, \
	          /*  6 */ LOW(18s), HIGH(18s), %11111110, t+$1C, t+$1E, t+$20, t+$16, t+$22, t+$24

	win_x  6, $93
	win_x  6, $94
	win_x  6, $95
	win_x  4, $96
	win_x  5, $97
	win_x  5, $98
	win_x  6, $99
	win_x  4, $9A
	win_x  4, $9B
	win_x  4, $9C
	win_x  3, $9D
	win_x  0, $9E, $9E, $9F, $9F, $A0, $A0, $A1, $A1, $A2, $A3, $A4, $A5, $A7, \
	          /*  7 */ LOW(22s), HIGH(22s), %11111110, t+$26, t+$1E, t+$28, t+$16, t+$22, t+$2A

	win_x  2, $83
	win_x  8, $84
	win_x  6, $85
	win_x  6, $86
	win_x  6, $87
	win_x  6, $88
	win_x  4, $89
	win_x  2, $8A
	win_x  3, $8B
	win_x  3, $8C
	win_x  4, $8D
	win_x  3, $8E
	win_x  0, $8F, $8F, $90, $90, $91, $91, $92, $92, $93, $94, $94, $95, $96, $97, $98, $99, $9A, $9B, $9D, $9E, $A0, $A1, $A3, $A4, $A5, $A7, \
	          /*  8 */ LOW(26s), HIGH(26s), %11111110, t+$2C, t+$2E, t+$30, t+$16, t+$32, t+$34

	win_x  2, $76
	win_x  8, $77
	win_x 10, $78
	win_x 11, $79
	win_x  7, $7A
	win_x  4, $7B
	win_x  3, $7C
	win_x  4, $7D
	win_x  3, $7E
	win_x  2, $7F
	win_x  2, $80
	win_x  2, $81
	win_x  2, $82
	win_x  2, $83
	win_x  0, $84, $85, $86, $86, $87, $88, $89, $89, $8A, $8B, $8B, $8C, $8C, $8D, $91, $97, $9B, $A2, $A7, \
	          /*  9 */ LOW(30s), HIGH(30s), %11111110, t+$36, t+$38, t+$3A, t+$16, t+$32, t+$3C

	win_x  2, $5F
	win_x  8, $60
	win_x  7, $61
	win_x  6, $62
	win_x  7, $63
	win_x  9, $64
	win_x  6, $65
	win_x  4, $66
	win_x  3, $67
	win_x  3, $68
	win_x  2, $69
	win_x  3, $6A
	win_x  4, $6B
	win_x  0, $6C, $6E, $71, $73, $75, $78, $7C, $80, $83, $86, $89, $8B, $91, $97, $9B, $A2, $A7

	static_assert CUR_FRAME == 32, "32 window frames, t+$no {d:CUR_FRAME}"
	db 1 ; Terminator

STREAMED_TILES_BASE equ @
StreamedTiles:
INCBIN "res/gb_light.vert.1bpp"

NB_STREAMED_TILES equ (@ - StreamedTiles) / 16


	PRINTT "START_OFS equ {START_OFS}\n"
	PRINTT "START_CNT equ {START_CNT}\n"
	PRINTT "WXVAL_LEN equ {WXVAL_LEN}\n"
	PRINTT "LOOP_FRAME equ {LOOP_FRAME}\n"
	PRINTT "BASE_LIGHT_TILE equ {BASE_TILE}\n"
	PRINTT "STREAMED_TILES_BASE equ {STREAMED_TILES_BASE}\n"
	PRINTT "NB_STREAMED_TILES equ {NB_STREAMED_TILES}\n"

ENDL
