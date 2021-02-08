
SECTION "SGB border", ROM0[0]

; The border tiles are hand-crafted to use 3 bitplanes layered on top of each-other
; This allows displaying different patterns depending on the applied palette,
; but has been done by hand.
INCBIN "res/sgb_border_tiles.4bpp"

COVER_BASE_ID equ @ / 32
INCLUDE "res/screen_cover.2bpp.size"
; Include screen-covering (2bpp) tiles, expanding them to 4bpp
; Skip the first tile (assuming it's the transparent one), as $00 is already that.
I = 16
	REPT SIZE / 16 - 1
		INCBIN "res/screen_cover.2bpp", I, 16
		ds 16, 0
I = I + 16
	ENDR

	; Pad up to 128 4bpp tiles
	ds 128 * 32 - @, 0


; The tilemap is made a bit weirdly...
; XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX
; XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX
; XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX
; XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX
; XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XX.. .... .... .... .... ..XX XXXX
; XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX
; XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX
; XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX
; XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX
; XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX
; The "X"s are the border, the "."s are the screen "cover"
; The border tiles are essentially 1bpp, so to save space, up to 3 tiles are "packed" into one,
; selecting which one of the 3 to display using the palette.
; (The 4th bitplane is not used, as one of its colors is transparent, plus we need room in the palettes for the cover.)
; This process was done by hand, so they're stored separately.
; However, the screen cover is automatically generated, and treated only as 2bpp, as it only uses 4 colors/tile.
; So, the tilemaps are a little bit heterogeneous... we reconciliate them here.
; Plus, the "cover" tilemap needs an offset (COVER_BASE_ID) applied.

I = 0
WHICH = 0
cover_entry: macro
BYTE equs STRCAT("$", STRSUB("{COVER_MAP{d:WHICH}}", I + 1, 4))
	IF HIGH(BYTE) == 0 ; If transparent tile, keep that
		dw 0
	ELSE ; Otherwise, apply offset, but preserve attr
		db HIGH(BYTE) + COVER_BASE_ID - 1, LOW(BYTE) + $10
	ENDC
	PURGE BYTE

I = I + 4
	IF I == 252
I = 0
WHICH = WHICH + 1
	ENDC
endm

; Each row is 32 tilemap entries, 2 bytes each.
INCBIN "res/sgb_border.tilemap", 0, 5 * 32 * 2
OFS = 5 * 32 * 2
REPT 18
	INCBIN "res/sgb_border.tilemap", OFS, 6 * 2
	REPT 20
		cover_entry
	ENDR
	INCBIN "res/sgb_border.tilemap", OFS + 26 * 2, 6 * 2
OFS = OFS + 32 * 2 ; Go to next row
ENDR
INCBIN "res/sgb_border.tilemap", OFS, 5 * 32 * 2


	PRINTT "; PAL = {PAL}\n"
OFS = 1
colors: macro
	REPT \1 * 2
		IF OFS <= STRLEN("{PAL}")
BYTE equs STRCAT("db $", STRSUB("{PAL}", OFS, 2))
			BYTE
			PURGE BYTE
OFS = OFS + 2
		ELSE
			db 0
		ENDC
	ENDR
endm

; BG4
	colors 4
	dw 0, 0, 0, 0
	dw     0, $34a4,     0, $34a4,     0, $34a4,     0, $34a4
; BG5
	colors 4
	dw 0, 0, 0, 0
	dw     0,     0, $34a4, $34a4,     0,     0, $34a4, $34a4
; BG6
	colors 4
	dw 0, 0, 0, 0
	dw     0,     0,     0,     0, $34a4, $34a4, $34a4, $34a4
; BG7 should not be used, the SGB BIOS uses it for the UI
