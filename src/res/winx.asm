
INCLUDE "hardware.inc/hardware.inc"


SECTION "Data", ROM0[0]

LOOP_FRAME equ 6

WXVAL_LEN = 0 ; Length of dest buffer
CUR_FRAME = 0
; win_x <nb scanlines>, <nb pixels to show>
win_x: MACRO
	IF (\1) == 0 ; Copy
		db (_NARG - 1) * 2 | 1
		REPT _NARG - 1
			SHIFT

			db \1
			IF STRIN("\1", "%")
				IF CUR_FRAME == LOOP_FRAME
					; We need to begin *after* the header
					assert (\1) == 0 ; If tiles follow it, we need a more complex check
START_OFS equ WXVAL_LEN + 2 ; Offset to start at in the uncompressed table
START_CNT equ CUR_FRAME * 8 ; Initial value of frame counter, to sync with START_OFS
				ENDC
CUR_FRAME = CUR_FRAME + 1
			ELSE
				assert (\1) != 1, "WX = 166 is bugged!"
			ENDC
WXVAL_LEN = WXVAL_LEN + 1
		ENDR

	ELSE ; RLE
		assert (\2) != 0, "Didn't you forget about the sprite header?"
		db (\1) * 2, (\2)
WXVAL_LEN = WXVAL_LEN + (\1)
	ENDC
ENDM

	win_x  0, /* 10 */ %11011000, $60, $62, $38, $64, 0
	win_x  5, $9C
	win_x  8, $9B
	win_x 11, $9A
	win_x 11, $99
	win_x 10, $98
	win_x  6, $97
	win_x  5, $96
	win_x  3, $95
	win_x  0, $94, $94, $93, $93, $92, $92, $91, $91, $90, $90, $8F, $8E, $8E, $8D, $8D, $8C, $A7, \
              /* 11 */ %01011100, $66, $38, $68, $6A, 0

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
              /* 12 */ %01011100, $6C, $6E, $70, $6A, 0

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
              /* 13 */ %01011100, $72, $74, $76, $6A, 0

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
              /* 14 */ %00011000, $78, $7A, 0

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
	          /* 15 */ %00000000, 0

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
              %00000000, 0,  $A7, \ ; Downtime w/ no sprites
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              %00000000, 0,  $A7, \
              /*  2 */ %11011000, $22, $24, $26, $28, $7D,  $A7, \ ; No window light during these
	          /*  3 */ %11011010, $2A, $2C, $2E, $30, $80, $83,  $A7, \
	          /*  4 */ %11111110, $32, $34, $36, $38, $3A, $3C, $86, $89,  $A7, \
	          /*  5 */ %11111100, $3E, $40, $42, $38, $44, $46, 0

	win_x  5, $9D
	win_x 11, $9E
	win_x 10, $9F
	win_x  8, $A0
	win_x  6, $A1
	win_x  3, $A2
	win_x  4, $A3
	win_x  3, $A4
	win_x  0, $A5, $A7, \
	          /*  6 */ %11111100, $3E, $40, $42, $38, $44, $46, 0

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
	          /*  7 */ %11111100, $48, $40, $4A, $38, $44, $4C, 0

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
	          /*  8 */ %11111100, $4E, $50, $52, $38, $54, $56, 0

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
	          /*  9 */ %11111100, $58, $5A, $5C, $38, $54, $5E, 0

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

	static_assert CUR_FRAME == 32, "32 window frames, not {d:CUR_FRAME}"
	db 1 ; Terminator


	PRINTT "START_OFS equ {START_OFS}\n"
	PRINTT "START_CNT equ {START_CNT}\n"
	PRINTT "WXVAL_LEN equ {WXVAL_LEN}\n"
	PRINTT "LOOP_FRAME equ {LOOP_FRAME}\n"
