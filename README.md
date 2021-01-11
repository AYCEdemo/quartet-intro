
# quartet-intro

A cracktro for *Quartet*, courtesy of AYCE :)

Careful when cloning that this repo uses `hardware.inc` as a submodule.

## Building

You need `quartet.gb` at the root of the repo (not provided) and RGBDS installed.
SHA256 of ROM used: `dcf0199e5fbc40cdf06131c376f821f275c3d518608de04ce1cfbe4d47c472aa`.

Then run `make`.

## Notes

All symbols RE'd from the ROM (see `quartet.sym`) are available, prefixed with `Q_`, and with dots replaced with `.`.

### Text printing

E.g. `Q_PrintStringCentered`. Params:

- Call `Q_UnpackFont` first
- Make sure clear stack area (used as a buffer)
- Clear D700 as well
- Params:
  * `hl` = Tiles addr (tiles will be written to here)
  * `de` = Tilemap buf addr
  * `bc` = Input text
  * `a` = Row to XOR over all tiles
