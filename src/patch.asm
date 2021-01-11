
INCLUDE "hardware.inc/hardware.inc"
INCLUDE "res/syms.asm"


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

	ld a, LCDCF_ON
	ldh [rLCDC], a

	; TODO...

	; The ROM expects the LCD to be off at power-on, and IE = 0
	rst Q_WaitVBlank
	di
	xor a
	ldh [rLCDC], a
	ldh [rIE], a
	ldh [Q_hPractice], a ; This also needs to be reset
	jp Init
