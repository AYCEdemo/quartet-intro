
INCLUDE "hardware.inc/hardware.inc"


SECTION "Data", ROM0[0]

WXVAL_LEN = 0 ; Length of dest buffer
CUR_FRAME = 0
; win_x <nb scanlines>, <nb pixels to show>
win_x: MACRO
	IF ISCONST(LOOP_FRAME)
		IF CUR_FRAME == LOOP_FRAME
START_OFS equ WXVAL_LEN ; Offset to start at in the uncompressed table
START_CNT equ CUR_FRAME * 8 ; Initial value of frame counter, to sync with START_OFS
		ENDC
	ENDC

	IF (\1) == 0 ; Copy
		db (_NARG - 1) * 2 | 1
WXVAL_LEN = WXVAL_LEN + _NARG - 1
		REPT _NARG - 1
			SHIFT
			assert WARN, (\1) != 1, "WX = 166 is bugged!"
			db (SCRN_X + 7) - \1

			IF (\1) == 0
CUR_FRAME = CUR_FRAME + 1
			ENDC
		ENDR

	ELSE ; RLE
		db (\1) * 2, (SCRN_X + 7) - (\2)
WXVAL_LEN = WXVAL_LEN + (\1)

		IF (\2) == 0
CUR_FRAME = CUR_FRAME + (\1)
		ENDC
	ENDC
ENDM
	; TODO: make these frames
	win_x  0, 0
	win_x  0, 0
	win_x  0, 0
	win_x  0, 0
	win_x  0, 0
	win_x  0, 0
LOOP_FRAME equ 6

	; Downtime
	win_x 18, 0

	; No window light
	win_x  3, 0

	win_x  5, $0A
	win_x 11, $09
	win_x 10, $08
	win_x  8, $07
	win_x  6, $06
	win_x  3, $05
	win_x  4, $04
	win_x  3, $03
	win_x  0, $02, 0

	win_x  6, $14
	win_x  6, $13
	win_x  6, $12
	win_x  4, $11
	win_x  5, $10
	win_x  5, $0F
	win_x  6, $0E
	win_x  4, $0D
	win_x  4, $0C
	win_x  4, $0B
	win_x  3, $0A
	win_x  0, $09, $09, $08, $08, $07, $07, $06, $06, $05, $04, $03, $02, 0

	win_x  2, $24
	win_x  8, $23
	win_x  6, $22
	win_x  6, $21
	win_x  6, $20
	win_x  6, $1F
	win_x  4, $1E
	win_x  2, $1D
	win_x  3, $1C
	win_x  3, $1B
	win_x  4, $1A
	win_x  3, $19
	win_x  0, $18, $18, $17, $17, $16, $16, $15, $15, $14, $13, $13, $12, $11, $10, $0F, $0E, $0D, $0C, $0A, $09, $07, $06, $04, $03, $02, 0

	win_x  2, $31
	win_x  8, $30
	win_x 10, $2F
	win_x 11, $2E
	win_x  7, $2D
	win_x  4, $2C
	win_x  3, $2B
	win_x  4, $2A
	win_x  3, $29
	win_x  2, $28
	win_x  2, $27
	win_x  2, $26
	win_x  2, $25
	win_x  2, $24
	win_x  0, $23, $22, $21, $21, $20, $1F, $1E, $1E, $1D, $1C, $1C, $1B, $1B, $1A, $16, $10, $0C, $05, 0

	win_x  2, $48
	win_x  8, $47
	win_x  7, $46
	win_x  6, $45
	win_x  7, $44
	win_x  9, $43
	win_x  6, $42
	win_x  4, $41
	win_x  3, $40
	win_x  3, $3F
	win_x  2, $3E
	win_x  3, $3D
	win_x  4, $3C
	win_x  0, $3B, $39, $36, $34, $32, $2F, $2B, $27, $24, $21, $1E, $1C, $16, $10, $0C, $05, 0

	static_assert CUR_FRAME == 32, "32 window frames, not {d:CUR_FRAME}"
	db 1 ; Terminator


	PRINTT "START_OFS equ {START_OFS}\n"
	PRINTT "START_CNT equ {START_CNT}\n"
	PRINTT "WXVAL_LEN equ {WXVAL_LEN}\n"
	PRINTT "LOOP_FRAME equ {LOOP_FRAME}\n"
