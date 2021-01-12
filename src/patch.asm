
INCLUDE "hardware.inc/hardware.inc"
INCLUDE "res/syms.asm"


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
	ld a, $d9 ; reti
	ldh [Q_hSTATTrampoline], a
	ld de, Q_DefaultVBlankHandler
	ld hl, Q_hVBlankTrampoline
	call Q_WriteTrampoline

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
	; The game only performs SGB detection **and init** if DMG is initially detected!!
	ldh [hIsSGB], a
	jr z, .notSGB
	; TODO: perform SGB init, including border transfer
	; Also, disable changing the border! (ICON_EN)
.notSGB

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
	ld a, LCDCF_ON | LCDCF_OBJ16 | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON
	ldh [rLCDC], a

	; Write sprites
	; ld hl, ConsoleSpritePos
	ld c, (ConsoleSpritePos.end - ConsoleSpritePos) / 2
	ld de, wShadowOAM
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
	ld a, HIGH(wShadowOAM)
	call Q_hOAMDMA

	; Init vars
	xor a
	ldh [Q_hCurKeys], a
	ldh [hFrameCounter], a

	; ACTUAL FX CODE GOES HERE
.loop
	rst Q_WaitVBlank
	; On DMG, blink the Game Boy to make it gray-ish
	; The Game Boy is hidden by the border on SGB, so that's fine
	ldh a, [rOBP0]
	xor $04
	ldh [rOBP0], a

	ldh a, [hFrameCounter]
	dec a
	ldh [hFrameCounter], a

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
INCBIN "res/console_tiles.vert.2bpp"
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


SECTION "Shadow OAM", WRAM0[$C000]

wShadowOAM:
	ds $A0


SECTION "HRAM", HRAM[$FF80]

hIsSGB:
	db
hFrameCounter:
	db

assert @ <= Q_hOAMDMA
