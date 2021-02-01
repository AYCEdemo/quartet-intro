
; The export stores instrument data ($700 bytes), then the pattern table ($100 bytes), then the patterns

SECTION "Music data", ROM0[0]

wPatternData equ $CC00
	PRINTT "wPatternData equ {wPatternData}\n"

LOAD "Music data runtime", WRAM0[wPatternData]

; Pattern data first
INCBIN "res/musicdata.bin", $800


; Extract and convert pattern table from `DATA`
wPatternTable:
	PRINTT "wPatternTable equ {wPatternTable}\n"

static_assert LOW(wPatternData) == 0

LEN = STRLEN("{DATA}")
STATE = 0
	REPT LEN / 2
		IF STATE < 2 ; Stop after reading $00 twice
LEN = LEN - 2
BYTE equs STRCAT("$", STRSUB("{DATA}", 1, 2))
REST equs STRSUB("{DATA}", 3, LEN)
			PURGE DATA
DATA equs "{REST}"
			PURGE REST

			IF BYTE == 0
STATE = STATE + 1
				db 0
			ELSE
STATE = 0
				db BYTE - $50 + HIGH(wPatternData)
			ENDC

			PURGE BYTE
		ENDC
	ENDR

	ds $C0 - LOW(@) ; Unused...

	PRINTT "wPulseInstrPanningTable equ {@}\n"
; 01:D7C0 wPulseInstrPanningTable
	ds 16, $11
; 01:D7D0 wWaveInstrPanningTable
	ds 16, $11
; 01:D7E0 wNoiseInstrPanningTable
	ds 16, $11
; 01:D7F0 ???
	ds 16, $11


; Finally, instrument data (should land where Quartet's Carillon expects it)
INCBIN "res/musicdata.bin", 0, $700

ENDL
