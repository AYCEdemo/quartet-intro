
# quartet-intro

A cracktro for *Quartet*, courtesy of AYCE :)

Careful when cloning that this repo uses `hardware.inc`, `superfamiconv` and `rnc_propack_source` as submodules.

## Building

You need `quartet.gb` at the root of the repo (not provided) and RGBDS installed.
Be careful that \~3 different revisions of *Quartet* were released; SHA256 of the ROM we used: `dcf0199e5fbc40cdf06131c376f821f275c3d518608de04ce1cfbe4d47c472aa`.

Then run `make`.

## Notes

All symbols RE'd from the ROM (see `quartet.sym`) are available in the code, prefixed with `Q_`, and with dots replaced with `_`.

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
