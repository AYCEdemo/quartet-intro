
SECTION "SOU_TRN data blob", ROM0[0]

LOAD "SOU_TRN runtime data", VRAM[$8000]

Blob:
	dw .end - .start
	dw $2B00 ; Load addr

.start
INCBIN "res/sou_trn_data.bin"
.end

	dw 0 ; End code
	dw $0400 ; S-APU start addr (where for S-APU to jump to)

	PRINTT "SOU_TRN_SIZE equ {@} - $8000\n"


	PRINTT "SOU_TRN_DATA_SND equ {@}\n"
; These are DATA_SND packets that must be transferred before using SOU_TRN
; Don't know why, but the manual says to do so...
	db $79, $00, $09, $00, $0B, $AD, $C2, $02, $C9, $09, $D0, $1A, $A9, $01, $8D, $00
	db $79, $0B, $09, $00, $0B, $42, $AF, $DB, $FF, $00, $F0, $05, $20, $73, $C5, $80
	db $79, $16, $09, $00, $0B, $03, $20, $76, $C5, $A9, $31, $8D, $00, $42, $68, $68
	db $79, $21, $09, $00, $01, $60, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $79, $00, $08, $00, $03, $4C, $00, $09, $00, $00, $00, $00, $00, $00, $00, $00

	PRINTT "SOUNDStartPacket equ {@}\n"
; The triggering SOUND packet
	; 8 = SOUND
	db 8 << 3 | 1, 0, 0, $00, 1


; Additionally, include ATTR_TRN ATF & PAL_TRN palettes
; Each ATF is 90 bytes, each palette is 8 bytes (4× RGB555)
; To ensure most efficient packing, we'll put the ATF as close as possible to the next slot, and insert palette beforehand if possible

attr_row: macro
	REPT 5
		db (\1) << 6 | (\2) << 4 | (\3) << 2 | (\4)
		SHIFT 4
	ENDR
endm

atf: macro
ATF_NUM equ (@ - $8000) / 90
	PRINTT "ATF_NUM equ {ATF_NUM}\n"
ALGN = (@ - $8000) % 90
	static_assert ALGN == 0, "Bad align {d:ALGN}"

	attr_row  1, 1, 1, 1,  1, 1, 1, 1,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0
	attr_row  1, 1, 1, 1,  1, 1, 1, 1,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0
	attr_row  1, 1, 1, 1,  1, 1, 1, 1,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0
	attr_row  1, 1, 1, 1,  1, 1, 1, 1,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0
	attr_row  1, 1, 1, 1,  1, 1, 1, 1,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0
	attr_row  1, 1, 1, 1,  1, 1, 1, 1,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0

	attr_row  1, 1, 1, 1,  1, 1, 1, 1,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0
	attr_row  1, 1, 1, 1,  1, 1, 1, 1,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0
	attr_row  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0
	attr_row  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  3, 3, 3, 0,  0, 0, 0, 0
	attr_row  2, 0, 0, 0,  0, 0, 0, 0,  0, 0, 1, 3,  3, 3, 3, 3,  0, 0, 0, 0
	attr_row  2, 2, 0, 0,  0, 0, 0, 0,  2, 2, 2, 3,  3, 3, 3, 3,  1, 1, 1, 1

	attr_row  2, 2, 2, 2,  2, 2, 2, 2,  2, 2, 2, 3,  3, 3, 3, 1,  1, 1, 1, 1
	attr_row  2, 2, 2, 2,  2, 2, 2, 2,  2, 2, 2, 3,  3, 3, 3, 1,  1, 1, 1, 1
	attr_row  2, 2, 2, 2,  2, 2, 2, 2,  2, 2, 0, 0,  3, 3, 3, 1,  1, 1, 1, 1
	attr_row  2, 2, 2, 2,  0, 0, 0, 0,  0, 0, 0, 0,  2, 3, 2, 2,  1, 1, 1, 1
	attr_row  2, 2, 2, 2,  2, 2, 0, 0,  0, 0, 0, 0,  2, 2, 2, 2,  1, 1, 1, 1
	attr_row  2, 2, 2, 2,  2, 2, 2, 2,  2, 2, 2, 2,  2, 2, 2, 2,  2, 2, 2, 2
endm

PAL0 equs "dw $7fff, $5172, $3d4a, $0000"
PAL1 equs "dw $7fff, $5172, $3d4a, $38a5"
PAL2 equs "dw $7fff, $5172, $4d2c, $38a5"
PAL3 equs "dw $7fff, $4d2c, $5172, $4de5"
PAL_GREY equs "dw $7fff, $56b5, $6b5a, $0000"

pal: macro
PAL\1_NUM equ (@ - $8000) / 8
	PRINTT "PAL\1_NUM equ {PAL\1_NUM}\n"
ALGN = (@ - $8000) % 8
	static_assert ALGN == 0, "Bad align {d:ALGN}"

	PAL\1
endm


BYTES_TILL_ATF equs "((90 - (@ - $8000) % 90) % 90)"
PAL_ALIGN_PADDING equs "((8 - (@ - $8000) % 8) % 8)"
NUM = BYTES_TILL_ATF
	PRINTT "BYTES_TILL_ATF equ {d:NUM}\n"
NUM = PAL_ALIGN_PADDING
	PRINTT "PAL_ALIGN_PADDING equ {d:NUM}\n"

	ds BYTES_TILL_ATF
	atf
	ds PAL_ALIGN_PADDING
	pal 0
	pal 1
	pal 2
	pal 3
	pal _GREY


	; TODO: this could instead be stored between two palettes, using the latter's color #0 (since it's ignored)
	PRINTT "PAL_SETPacket equ {@}\n"
	; 10 = PAL_SET
	db 10 << 3 | 1
	dw PAL0_NUM, PAL1_NUM, PAL2_NUM, PAL3_NUM
	db ATF_NUM | $C0 ; Apply ATF ($80), unfreeze screen ($40)


ENDL
