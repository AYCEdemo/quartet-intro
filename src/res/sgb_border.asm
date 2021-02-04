
SECTION "SGB border", ROM0[0]

; The border tiles are hand-crafted to use 3 bitplanes layered on top of each-other
; This allows displaying different patterns depending on the applied palette,
; but has been done by hand.
INCBIN "res/sgb_border_tiles.4bpp"

	; Pad up to 128 4bpp tiles
	ds 128 * 32 - @, $FF

; TODO: include tilemap for screen cover
INCBIN "res/sgb_border.tilemap"

; BG4
	dw 0, 0, 0, 0, 0, 0, 0, 0,     0, $34a4,     0, $34a4,     0, $34a4,     0, $34a4
; BG5
	dw 0, 0, 0, 0, 0, 0, 0, 0,     0,     0, $34a4, $34a4,     0,     0, $34a4, $34a4
; BG6
	dw 0, 0, 0, 0, 0, 0, 0, 0,     0,     0,     0,     0, $34a4, $34a4, $34a4, $34a4
; BG7 should not be used, the SGB BIOS uses it for the UI
