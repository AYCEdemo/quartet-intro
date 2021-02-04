
SECTION "SOU_TRN data blob", ROM0[0]

Blob:
	dw .end - .start
	dw $2B00 ; Load addr

.start
INCBIN "res/sou_trn_data.bin"
.end

	dw 0 ; End code
	dw $0400 ; S-APU start addr (where for CPU to jump to)
