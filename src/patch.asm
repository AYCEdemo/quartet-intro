
INCLUDE "hardware.inc/hardware.inc"
INCLUDE "res/syms.asm"

INCLUDE "res/winx.inc"


lb: MACRO
	assert (\2) < 256
	assert (\3) < 256
	ld \1, (\2) << 8 | (\3)
ENDM

NB_STREAMED_SPRITES equ 4


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
	ld hl, Tilemap
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
	ld a, BASE_TILE
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
	ld a, BASE_TILE + 1
	ld bc, 10 * SCRN_VX_B
	call Q_Memset
	dec a ; ld a, $80
	ld hl, $9800
	ld bc, 10 * SCRN_VX_B
	call Q_Memset
	xor a
	ld hl, $8000
	lb bc, vSpriteTiles - $8000, 0
	call Q_MemsetWithIncr
	; ld de, vSpriteTiles
	ld d, h
	ld e, l
	ld hl, SpriteTiles
	ld bc, Tiles.end - SpriteTiles
	call Q_Memcpy
	; ld hl, Tilemap
	ld de, $99CC
	lb bc, 20, 18
	ld a, 32 - 20
	call Q_CopyRows

	; Write LCD params & turn it on
	ld a, $E4
	ldh [rBGP], a
	xor a
	ldh [rOBP0], a
	ldh [rWY], a
	ld a, SCRN_X + 7
	ldh [rWX], a
	ld a, SCRN_VX - SCRN_X
	ldh [rSCX], a
	ld a, SCRN_VY - SCRN_Y
	ldh [rSCY], a
	ld a, STATF_LYC
	ldh [rSTAT], a
	ld a, $1C
	ldh [rLYC], a
	ld a, LCDCF_ON | LCDCF_WINON | LCDCF_OBJ16 | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON
	ldh [rLCDC], a
	; Perform some additional setup work during the first (white) frame

	; Write sprites
	; ld hl, SpritePos
	lb bc, (SpritePos.end - SpritePos.light) / 2, SpritePos.light - SpritePos
	ld de, wLightOAM.end
.writeConsoleSprite
	dec e ; dec de
	xor a
	ld [de], a
	dec e ; dec de
	ld a, c
	ld [de], a
	dec e ; dec de
	ld a, [hli]
	ld [de], a
	dec e ; dec de
	ld a, [hli]
	ld [de], a
	dec c
	dec c
	jr nz, .writeConsoleSprite
	; Write light sprite positions
.writeLightSprite
	dec e ; dec de
	xor a
	ld [de], a
	dec e ; dec de
	ld [de], a
	dec e ; dec de
	ld a, [hli]
	ld [de], a
	dec e ; dec de
	ld a, [hli]
	ld [de], a
	dec b
	jr nz, .writeLightSprite
	; Clear the remaining sprites
	xor a
.clearOAM
	dec e ; dec de
	ld [de], a
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
MainLoop:
	rst Q_WaitVBlank
	; On DMG, blink the Game Boy to make it gray-ish
	; The Game Boy is hidden by the border on SGB, so that's fine
	ldh a, [rOBP0]
	xor $04
	ldh [rOBP0], a

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
	; Copy tiles using popslide (faster), since we know we won't be interrupted
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	ld sp, hl
	ld hl, vStreamedSpriteTiles
	ld c, 16 * NB_STREAMED_SPRITES / 2
.streamTile
	pop de
	ld a, e
	ld [hli], a
	ld a, d
	ld [hli], a
	dec c
	jr nz, .streamTile
	; Restore SP and HL, and keep truckin
	ld sp, $DFFE
	pop hl
	inc hl
	; Read sprite tiles
	ld a, [hli] ; Read sentinel byte
	ld b, a
	ld de, wLightOAM.light - 4 ; First iteration will be skipped, since carry is clear
.writeLightSpriteTile
	inc e ; inc de
	inc e ; inc de
	ld a, 0
	jr nc, .clearLightSpriteTile
	ld a, [hli]
.clearLightSpriteTile
	ld [de], a
	inc e ; inc de
	inc e ; inc de
	sla b
	jr nz, .writeLightSpriteTile
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
	jr z, MainLoop


	; TODO: on SGB, clear ICON_EN
	; The ROM relies on a lot of power-on state
	di
	call Q_ClearVRAM ; Also turns LCD off and returns with A = 0
	ldh [rSCX], a
	ldh [rSCY], a
	ldh [rIE], a
	ldh [Q_hPractice], a ; This also needs to be reset
	jp Init

SpriteTiles:
INCBIN "res/console_tiles.vert.2bpp"
.light
INCBIN "res/light_tiles.vert.2bpp"
.end
; Expected to be contiguous
FontTiles:
INCBIN "res/font.vert.2bpp"
.end
; Expected to be contiguous
Tiles:
INCBIN "res/draft.uniq.2bpp"
.end
; Expected to be contiguous
Tilemap: ; Continued after the VRAM declarations...

PUSHS
SECTION "Tiles", VRAM[$8000]
	ds 2 * 16 ; Blank tiles
vStreamedSpriteTiles:
	ds 16 * 2 * NB_STREAMED_SPRITES
vSpriteTiles:
	ds SpriteTiles.light - SpriteTiles
.light
	ds SpriteTiles.end - SpriteTiles.light
vFontTiles:
	ds FontTiles.end - FontTiles
	assert @ <= $9000, "Can't access font from OAM! ({@} > $9000)"
vBGTiles:
	ds Tiles.end - Tiles
	assert @ <= $9800, "Too many tiles! ({@} > $9800)"
POPS
BASE_TILE equ LOW(vBGTiles / 16)
LIGHT_BASE equ LOW(vSpriteTiles.light / 16)
assert LIGHT_BASE == BASE_LIGHT_TILE, "Light base predicted = {BASE_LIGHT_TILE}, real = {LIGHT_BASE}"

INCBIN "res/draft.uniq.{x:BASE_TILE}.ofs.tilemap", 20
; Expected to be contiguous
SpritePos: ; (X, Y), reversed from OAM order!
	db 111 + 8,  72 + 16
	db 103 + 8,  73 + 16
	db  95 + 8,  75 + 16
	db  88 + 8,  78 + 16
	db  88 + 8,  94 + 16
	db 115 + 8,  86 + 16
	db 107 + 8,  91 + 16
	db 101 + 8,  95 + 16
	db  96 + 8,  96 + 16
	db 115 + 8, 102 + 16
	db 107 + 8, 107 + 16
	db 100 + 8, 111 + 16
	db  94 + 8, 110 + 16
	db 114 + 8, 118 + 16
	db 107 + 8, 118 + 16
	db 103 + 8, 127 + 16
NB_CONSOLE_SPRITES equ (@ - SpritePos) / 2
	; Console
	; These four are actually light sprites, but they use streamed tiles
	db 114 + 8,  82 + 16
	db 111 + 8,  72 + 16
	db 103 + 8,  72 + 16
	db 100 + 8,  75 + 16
	assert NB_STREAMED_SPRITES == (@ - SpritePos) / 2 - NB_CONSOLE_SPRITES
.light
	; Player
	db  70 + 8,  37 + 16
	db  74 + 8,  38 + 16
	db  79 + 8,  50 + 16
	db  75 + 8,  54 + 16
	db  79 + 8,  66 + 16
	db  75 + 8,  76 + 16
NB_LIGHT_SPRITES equ (@ - SpritePos) / 2 - NB_CONSOLE_SPRITES
.end
; Expected to be contiguous
WindowXValues:
INCBIN "res/winx.bin"
.end

; Count is formatted as such:
; - High nibble is (16 - initial_copy_len)
; - Low nibble is amount of tile IDs after it to copy
spec: macro
	db \1
	REPT _NARG - 1
		SHIFT
		db LOW(BASE_TILE + (\1))
	ENDR
endm
SecondaryMapCopySpecs:
	spec $81, $02
	spec $81, $03
	spec $81, $04
	spec $81, $04
	spec $82, $05, $06
	spec $71, $07
	spec $61, $08
	spec $62, $09, $0A
	spec $44, $0B, $0C, $0D, $0E
	spec $15, $0B, $0F, $10, $11, $12

StatHandler:
	LOAD "STAT handler", HRAM[$FF80]
hStatHandler:
	ld a, HIGH(wLightOAM)
	ldh [rDMA], a
	ld a, 40
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
	ds (40 - NB_LIGHT_SPRITES - NB_CONSOLE_SPRITES) * 4
.light
	ds NB_LIGHT_SPRITES * 4
.console
	ds NB_CONSOLE_SPRITES * 4
.end

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
