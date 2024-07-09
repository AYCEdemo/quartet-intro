
ASFLAGS := -p 0xFF -Wall -Wextra -E -i src/
LDFLAGS := -d -t
FIXFLAGS:= -v

RGBDS   ?=
RGBASM  ?= $(RGBDS)rgbasm
RGBLINK ?= $(RGBDS)rgblink
RGBFIX  ?= $(RGBDS)rgbfix
RGBGFX  ?= $(RGBDS)rgbgfx


VPATH := src

SRCS := $(wildcard src/*.asm)
OBJS := $(patsubst src/%.asm,obj/%.o,$(SRCS))
DEPS := $(patsubst src/%.asm,obj/%.mk,$(SRCS))

.SECONDEXPANSION:


all: bin/quartet.gb
.PHONY: all

clean: tools/propack/Makefile
	rm -rf bin obj res
	make -C tools/propack clean
.PHONY: clean

# We rely on `quartet.gb` being first, and thus being passed to `-O`
# For some reason, RGBLINK outputs too many bytes?
bin/quartet.gb bin/quartet.sym bin/quartet.map: quartet.gb $(OBJS)
	@mkdir -p $(@D)
	$(RGBLINK) $(LDFLAGS) -o bin/quartet_tmp.gb -n bin/quartet_tmp.sym -m bin/quartet.map -O $^
	dd bs=32768 count=1 if=bin/quartet_tmp.gb of=bin/quartet.gb
	$(RGBFIX) $(FIXFLAGS) bin/quartet.gb
	sed 's/ / Q_/' quartet.sym | cat bin/quartet_tmp.sym - > bin/quartet.sym
	rm -f bin/quartet_tmp.gb bin/quartet_tmp.sym

obj/%.mk: src/%.asm
	@mkdir -p $(@D)
	$(RGBASM) $(ASFLAGS) -M obj/$*.mk -MG -MP -MQ obj/$*.o -MQ obj/$*.mk -o obj/$*.o $<
# DO NOT merge this with the rule above, otherwise Make will assume that the `.o` file is generated,
# even when it isn't!
# This causes weird issues that depend, among other things, on the version of Make.
obj/%.o: obj/%.mk
	@touch $@
res/syms.asm: tools/syms.sh quartet.sym
	@mkdir -p res
	$^ > $@

ifeq ($(filter clean,$(MAKECMDGOALS)),)
include $(DEPS)
endif


## ASSET PROCESSING


res/%.ofs.tilemap: tools/apply_ofs.py res/$$(basename $$*).tilemap
	@mkdir -p $(@D)
	$^ $@

%.uniq.2bpp %.uniq.1bpp %.uniq.tilemap: GFXFLAGS += -u
%.vert.2bpp %.vert.1bpp %.vert.tilemap: GFXFLAGS += -h
res/%.2bpp res/%.tilemap: res/%.png
	@mkdir -p res/$(@*)
	$(RGBGFX) $(GFXFLAGS) -d 2 -o res/$*.2bpp -t res/$*.tilemap $<
res/%.1bpp res/%.tilemap: res/%.png
	@mkdir -p res/$(@*)
	$(RGBGFX) $(GFXFLAGS) -d 1 -o res/$*.1bpp -t res/$*.tilemap $<
.PRECIOUS: %.2bpp %.1bpp %.tilemap


res/%.bin res/%.inc: res/%.asm
	$(RGBASM) $(ASFLAGS) -o res/$*.o $< > res/$*.inc
	$(RGBLINK) $(LDFLAGS) -x -o res/$*.bin res/$*.o
# Additional INCBIN'd dep
res/winx.bin res/winx.inc: res/gb_light.vert.1bpp
res/sgb_border.bin: res/sgb_border_tiles.4bpp res/screen_cover.pal res/screen_cover.2bpp res/screen_cover.tilemap res/screen_cover.2bpp.size
res/sgb_border.bin: ASFLAGS += -DPAL="`xxd -p -c 48 res/screen_cover.pal`"
res/sgb_border.bin: ASFLAGS += -DCOVER_MAP0="`xxd -p -l 126 -c 126 res/screen_cover.tilemap`"
res/sgb_border.bin: ASFLAGS += -DCOVER_MAP1="`xxd -p -l 126 -c 126 -s 126 res/screen_cover.tilemap`"
res/sgb_border.bin: ASFLAGS += -DCOVER_MAP2="`xxd -p -l 126 -c 126 -s 252 res/screen_cover.tilemap`"
res/sgb_border.bin: ASFLAGS += -DCOVER_MAP3="`xxd -p -l 126 -c 126 -s 378 res/screen_cover.tilemap`"
res/sgb_border.bin: ASFLAGS += -DCOVER_MAP4="`xxd -p -l 126 -c 126 -s 504 res/screen_cover.tilemap`"
res/sgb_border.bin: ASFLAGS += -DCOVER_MAP5="`xxd -p -l 126 -c 126 -s 630 res/screen_cover.tilemap`"
res/mus_data.bin: res/musicdata.bin
# 0x700 = 1792
res/mus_data.bin: ASFLAGS += -DDATA="`xxd -p -c 256 -l 256 -s 1792 src/res/musicdata.bin`"
res/sou_trn.bin: res/sou_trn_data.bin


tools/propack/rnc64: tools/propack/main.c
	make -C $(@D) rnc64

# Dalton's decruncher skips the 18-byte header (not useful at runtime)
res/%.rnc: res/% tools/propack/rnc64
	tools/propack/rnc64 p $< $@.tmp -m 2 && dd if=$@.tmp of=$@ bs=1 skip=18 && rm $@.tmp


SUPERFAMICONV := tools/superfamiconv/bin/superfamiconv

# TODO: how to reuse its Makefile's dependencies?
# This is currently OK, but only for our purposes...
$(SUPERFAMICONV): tools/superfamiconv/Makefile
	make -C tools/superfamiconv bin/superfamiconv

res/sgb_border_tiles.4bpp: res/sgb_border_tiles.png $(SUPERFAMICONV)
	$(SUPERFAMICONV) tiles -M snes -W 8 -H 8 -R -B 4 -i $< -d $@

res/screen_cover.pal: res/screen_cover.png $(SUPERFAMICONV)
	$(SUPERFAMICONV) palette -M snes -W 8 -H 8 -P 3 -C 4 -0 '#ffffff' -i $< -d $@
res/screen_cover.2bpp: res/screen_cover.png res/screen_cover.pal $(SUPERFAMICONV)
	$(SUPERFAMICONV) tiles -M snes -W 8 -H 8 -B 2 -i $< -p res/screen_cover.pal -d $@
res/screen_cover.tilemap: res/screen_cover.png res/screen_cover.2bpp res/screen_cover.pal $(SUPERFAMICONV)
	$(SUPERFAMICONV) map -M snes -W 8 -H 8 -B 2 -i $< -t res/screen_cover.2bpp -p res/screen_cover.pal -d $@


# Useful to know how large a file will be when decompressed
res/%.size: res/%
	printf 'SIZE = %u' $$(wc -c $< | cut -d ' ' -f 1) > $@


# The first row is just some window tiles, they're not part of the image proper
res/draft.%.tilemap: res/draft.uniq.%.ofs.tilemap
	dd if=$< of=$@ bs=1 skip=20
res/gfx.%.bin: res/console_tiles.vert.2bpp res/light_tiles.vert.2bpp res/font.vert.2bpp res/draft.uniq.2bpp res/palettes.bin res/draft.%.tilemap
	cat $^ > $@

res/data.bin: res/text.bin res/winx.bin
	cat $^ > $@

# By default, cloning the repo does not init submodules; if that happens, warn the user.
# Note that the real paths aren't used!
# Since RGBASM fails to find the files, it outputs the raw paths, not the actual ones.
hardware.inc/hardware.inc tools/superfamiconv/Makefile tools/propack/Makefile:
	@echo '$@ is not present; have you initialized submodules?'
	@echo 'Run `git submodule update --init`, then `make clean`, then `make` again.'
	@echo 'Tip: to avoid this, use `git clone --recursive` next time!'
	@exit 1
