
INCLUDE "hardware.inc/hardware.inc"
INCLUDE "res/syms.asm"

INCLUDE "res/winx.inc"


lb: MACRO
	assert (\2) < 256
	assert (\3) < 256
	ld \1, (\2) << 8 | (\3)
ENDM


SECTION "Entry point", ROM0[Q_EntryPoint]

EntryPoint: ; Only jump here during actual boot-up!!
	; `call Q_Memcpy` will write to $5C7F + $5C7E, but these'll get ignored
	; This will abort the init process, jumping into our patch
	ld sp, Retpoline + 2

	cp BOOTUP_A_CGB
	ld a, 0
	jr nz, .notColor
	rr b
	adc a, 2
.notColor
	ldh [Q_hConsoleType], a

	ld hl, Q_OAMDMA
	ld de, Q_hOAMDMA
	ld bc, 8
	call Q_Memcpy
Init: ; Jump here to re-perform initialization
	sub a
	ld bc, $1FFE
	ld hl, $C000
	call Q_Memset
	sub a
	ld bc, $3E
	ld hl, $FFC0
	call Q_Memset
	ld a, $C0
	call Q_hOAMDMA
	jp Q_Init


SECTION "Patch", ROM0[$5C7C]

Retpoline:
	dw Intro


Intro:
	ld sp, $E000

	; Init interrupts
	ld hl, StatHandler
	lb bc, hStatHandler.end - hStatHandler, LOW(hStatHandler)
.copyHandler
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, .copyHandler
	; ld hl, IntTrampolines
	lb bc, IntTrampolinesEnd - IntTrampolines, LOW(Q_hSTATTrampoline)
.copyTrampolines
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, .copyTrampolines

	ld a, IEF_VBLANK | IEF_LCDC
	ldh [rIE], a
	xor a
	ldh [rIF], a
	ei
	ldh [Q_hVBlankFlag], a

	; Turn LCD off for gfx init
	rst Q_WaitVBlank
	xor a
	ldh [rLCDC], a

	ldh a, [Q_hConsoleType]
	and a
	jr nz, .notSGB
	call Q_DetectSGB
	; DO NOT SET CONSOLE TYPE TO SGB
	; The game only performs SGB detection **and init** only if DMG is initially detected!!
	ldh [hIsSGB], a
	jr z, .notSGB
	; TODO: perform SGB init, including border transfer
	; Also, disable changing the border! (ICON_EN)
	; Don't forget to turn the LCD off again!
.notSGB

	;; VRAM init
	; Performed after SGB check because of the VRAM transfers

	; Copy secondary tilemap
	ld hl, .tilemap
	ld de, $9DCC
	ld bc, SecondaryMapCopySpecs
.writeSecondaryMapRow
	ld a, [bc] ; Read count
	inc bc
	ldh [hPreludeCopyCnt], a
.copyPrelude
	ld a, [hli]
	ld [de], a
	inc e ; inc de
	ldh a, [hPreludeCopyCnt]
	add a, $10
	ldh [hPreludeCopyCnt], a
	jr nc, .copyPrelude
.copyTrailing
	ld a, [hli] ; Advance read ptr
	ld a, [bc] ; Read tile
	inc bc
	ld [de], a
	inc e ; inc de
	; Only reason that this jump works is that the stars align. Don't try at home, kids
	jr z, .secondaryMapDone
	ldh a, [hPreludeCopyCnt]
	dec a
	ldh [hPreludeCopyCnt], a
	jr nz, .copyTrailing
	ld a, $80
.writeTrailing
	inc hl
	ld [de], a
	inc de
	bit 4, e
	jr nz, .writeTrailing
	ld a, e
	or $0C
	ld e, a
	jr .writeSecondaryMapRow
.secondaryMapDone
	; Just copy the rest
	ld de, $9F0C
	lb bc, 20, 8
	ld a, 32 - 20
	call Q_CopyRows

	ld hl, $9C00
	ld a, $81
	ld bc, 10 * SCRN_VX_B
	call Q_Memset
	dec a ; ld a, $80
	ld hl, $9800
	ld bc, 10 * SCRN_VX_B
	call Q_Memset
	ld hl, .consoleTiles
	ld de, $8000
	ld bc, .tiles - .consoleTiles
	call Q_Memcpy
	ld hl, .tiles
	ld de, $8800
	ld bc, .tilemap - .tiles
	call Q_Memcpy
	; ld hl, .tilemap
	ld de, $99CC
	lb bc, 20, 18
	ld a, 32 - 20
	call Q_CopyRows

	; Write LCD params & turn it on
	ld a, $E4
	ldh [rBGP], a
	ldh [rOBP0], a
	ld a, SCRN_VX - SCRN_X
	ldh [rSCX], a
	ld a, SCRN_VY - SCRN_Y
	ldh [rSCY], a
	xor a
	ldh [rWY], a
	ld a, SCRN_X + 7
	ldh [rWX], a
	ld a, STATF_LYC
	ldh [rSTAT], a
	ld a, $2C
	ldh [rLYC], a
	ld a, LCDCF_ON | LCDCF_WINON | LCDCF_OBJ16 | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON
	ldh [rLCDC], a
	; Perform some additional setup work during the first (white) frame

	; Write sprites
	; ld hl, ConsoleSpritePos
	ld c, (ConsoleSpritePos.end - ConsoleSpritePos) / 2
	ld de, wLightOAM
.writeConsoleSprite
	ld a, [hli]
	ld [de], a
	inc e ; inc de
	ld a, [hli]
	ld [de], a
	inc e ; inc de
	ld a, e
	ld [de], a
	inc e ; inc de
	xor a
	ld [de], a
	inc e ; inc de
	dec c
	jr nz, .writeConsoleSprite
	; Clear the remaining Y positions
	ld c, 40 - (ConsoleSpritePos.end - ConsoleSpritePos) / 2
	xor a
.clearOAM
	ld [de], a
	inc e ; inc de
	inc e ; inc de
	inc e ; inc de
	inc e ; inc de
	dec c
	jr nz, .clearOAM

	; Decode that RLE
	; ld de, WindowXValues
	ld d, h
	ld e, l
	ld hl, wWindowXValues
	assert WARN, HIGH(WindowXValues.end) != HIGH(WindowXValues), "Can optimize WindowXValues reader!"
.unpackWX
	ld a, [de]
	inc de
	srl a
	ld b, a
	jr z, .done
	jr c, .copy
	ld a, [de]
	inc de
.unRLE
	ld [hli], a
	dec b
	jr nz, .unRLE
	jr .unpackWX
.copy
	ld a, [de]
	inc de
	ld [hli], a
	dec b
	jr nz, .copy
	jr .unpackWX
.done

	; Init vars
	xor a
	ldh [Q_hCurKeys], a
	ld a, START_CNT
	ldh [hFrameCounter], a
	ld de, wWindowXValues + START_OFS

	; ACTUAL FX CODE GOES HERE
.loop
	rst Q_WaitVBlank
	; On DMG, blink the Game Boy to make it gray-ish
	; The Game Boy is hidden by the border on SGB, so that's fine
	ldh a, [rOBP0]
	xor $04
	ldh [rOBP0], a
	; Set sprites to 8x8 for first text rows
	ldh a, [rLCDC]
	and ~LCDCF_OBJ16
	ldh [rLCDC], a

	ldh a, [hFrameCounter]
	inc a
	ldh [hFrameCounter], a
	ld b, a

	; Check if end of animation was reached; if so, re-swap tilemaps
	cp START_CNT
	jr z, .swapTilemaps
	; Check if counter reached 0, in which case, cycle the animation
	or b
	jr nz, .noReset
	; TODO: update text
	; Reload animation ptr
	ld hl, wWindowXValues
	; TODO: depending on value of B at this point, may not be necessary
	;       (load directly into `de` if necessary)
	; Swap tilemap behind window for 2nd part of animation
.swapTilemaps
	ldh a, [rLCDC]
	xor LCDCF_WIN9C00 | LCDCF_BG9C00
	ldh [rLCDC], a
.noReset

	; Every 8 frames, step the animation by advancing the reload point
	ld a, b
	and 7
	jr nz, .noStep
	ld d, h
	ld e, l
.noStep

	ld h, d
	ld l, e
	; Now, perform WXzardry, changing WX on each scanline
	; Stop when the window has been hidden
	; This will get interrupted by the OAM DMA, but this is made to be lenient,
	; at worst a couple scanlines will get duplicated.
.waitNotVBlank
	ldh a, [rLY]
	cp SCRN_Y
	jr nc, .waitNotVBlank
	ld c, 0
.stepWindow
	ldh a, [rLY]
	cp c
	jr c, .stepWindow
	ld a, [hli]
	ldh [rWX], a
	inc c
	sub SCRN_X + 7
	jr nz, .stepWindow

	call Q_PollKeys
	jr z, .loop


	; TODO: on SGB, clear ICON_EN
	; The ROM relies on a lot of power-on state
	di
	call Q_ClearVRAM ; Also turns LCD off and returns with A = 0
	ldh [rSCX], a
	ldh [rSCY], a
	ldh [rIE], a
	ldh [Q_hPractice], a ; This also needs to be reset
	jp Init

.consoleTiles
NB_CONSOLE_SPRITES equ 16
assert (ConsoleSpritePos.end - ConsoleSpritePos) / 2 == NB_CONSOLE_SPRITES
OFS = 0
REPT NB_CONSOLE_SPRITES
	ds 32 ; TODO: put something interesting here
	INCBIN "res/console_tiles.vert.2bpp",OFS,32
OFS = OFS + 32
ENDR
; Expected to be contiguous
.tiles
INCBIN "res/draft.uniq.2bpp"
; Expected to be contiguous
.tilemap
INCBIN "res/draft.uniq.tilemap.bit7", 20
; Expected to be contiguous
ConsoleSpritePos:
	db  72 + 16, 111 + 8
	db  73 + 16, 103 + 8
	db  75 + 16,  95 + 8
	db  78 + 16,  88 + 8
	db  94 + 16,  88 + 8
	db  86 + 16, 115 + 8
	db  91 + 16, 107 + 8
	db  95 + 16, 101 + 8
	db  96 + 16,  96 + 8
	db 102 + 16, 115 + 8
	db 107 + 16, 107 + 8
	db 111 + 16, 100 + 8
	db 110 + 16,  94 + 8
	db 118 + 16, 114 + 8
	db 118 + 16, 107 + 8
	db 127 + 16, 103 + 8
.end
; Expected to be contiguous
WindowXValues:
INCBIN "res/winx.bin"
.end

SecondaryMapCopySpecs:
	db $81, $82
	db $81, $83
	db $81, $84
	db $81, $84
	db $82, $85, $86
	db $71, $87
	db $61, $88
	db $62, $89, $8A
	db $44, $8B, $8C, $8D, $8E
	db $15, $8B, $8F, $90, $91, $92

StatHandler:
	LOAD "STAT handler", HRAM[$FF80]
hStatHandler:
	ld a, HIGH(wLightOAM)
	ldh [rDMA], a
	; Leverage some of the cycles writing to LCDC as wait time for OAM DMA to complete
	ldh a, [rLCDC]
	or LCDCF_OBJ16
	ldh [rLCDC], a
	ld a, 40 - 2
.wait
	dec a
	jr nz, .wait
	pop af
	reti
.end
	ENDL

IntTrampolines:
	LOAD "Int trampolines", HRAM[Q_hSTATTrampoline]
	push af
	jr hStatHandler

assert @ == Q_hVBlankTrampoline
	jp Q_DefaultVBlankHandler
	ENDL
IntTrampolinesEnd:



SECTION "Shadow OAM", WRAM0[$C000]

wLightOAM:
	ds $A0

wWindowXValues:
	ds WXVAL_LEN
.end::


SECTION "HRAM", HRAM[$FF91]

hIsSGB:
	db
hPreludeCopyCnt:
hFrameCounter:
	db

SECTION "OAM DMA", HRAM[Q_hOAMDMA - 2]

	ds 8 ; Original OAM DMA

SECTION "VBlank flag", HRAM[Q_hVBlankFlag]

	db
