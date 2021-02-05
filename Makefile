
ASFLAGS := -p 0xFF -Wall -Wextra -EhL -i src/
LDFLAGS := -d -t
FIXFLAGS:= -v

RGBDS   ?=
RGBASM  ?= $(RGBDS)rgbasm
RGBLINK ?= $(RGBDS)rgblink
RGBFIX  ?= $(RGBDS)rgbfix
RGBGFX  ?= $(RGBDS)rgbgfx


BINDIR := bin
OBJDIR := obj
RESDIR := res
DEPDIR := dep


VPATH := src

SRCS := $(wildcard src/*.asm)
OBJS := $(patsubst src/%.asm,$(OBJDIR)/%.o,$(SRCS))
DEPS := $(patsubst src/%.asm,$(DEPDIR)/%.mk,$(SRCS))

.SECONDEXPANSION:


all: $(BINDIR)/quartet.gb
.PHONY: all

clean:
	rm -rf $(BINDIR) $(OBJDIR) $(RESDIR) $(DEPDIR)
	make -C tools/propack clean
.PHONY: clean

# We rely on `quartet.gb` being first, and thus being passed to `-O`
# For some reason, RGBLINK outputs too many bytes?
$(BINDIR)/quartet.gb $(BINDIR)/quartet.sym $(BINDIR)/quartet.map: quartet.gb $(OBJS)
	@mkdir -p $(@D)
	$(RGBLINK) $(LDFLAGS) -o $(BINDIR)/quartet_tmp.gb -n $(BINDIR)/quartet_tmp.sym -m $(BINDIR)/quartet.map -O $^
	dd bs=32768 count=1 if=$(BINDIR)/quartet_tmp.gb of=$(BINDIR)/quartet.gb
	$(RGBFIX) $(FIXFLAGS) $(BINDIR)/quartet.gb
	sed 's/ / Q_/' quartet.sym | cat $(BINDIR)/quartet_tmp.sym - > $(BINDIR)/quartet.sym
	rm -f $(BINDIR)/quartet_tmp.gb $(BINDIR)/quartet_tmp.sym

$(OBJDIR)/%.o $(DEPDIR)/%.mk: src/%.asm
	@mkdir -p $(OBJDIR)/$(*D) $(DEPDIR)/$(*D)
	$(RGBASM) $(ASFLAGS) -M $(DEPDIR)/$*.mk -MG -MP -MQ $(OBJDIR)/$*.o -MQ $(DEPDIR)/$*.mk -o $(OBJDIR)/$*.o $<

$(RESDIR)/syms.asm: tools/syms.sh quartet.sym
	@mkdir -p $(RESDIR)
	$^ > $@

ifeq ($(filter clean,$(MAKECMDGOALS)),)
-include $(DEPS)
endif


## ASSET PROCESSING


$(RESDIR)/%.ofs.tilemap: tools/apply_ofs.py $(RESDIR)/$$(basename $$*).tilemap
	@mkdir -p $(@D)
	$^ $@

%.uniq.2bpp %.uniq.1bpp %.uniq.tilemap: GFXFLAGS += -u
%.vert.2bpp %.vert.1bpp %.vert.tilemap: GFXFLAGS += -h
$(RESDIR)/%.2bpp $(RESDIR)/%.tilemap: $(RESDIR)/%.png
	@mkdir -p $(RESDIR)/$(@*)
	$(RGBGFX) $(GFXFLAGS) -d 2 -o $(RESDIR)/$*.2bpp -t $(RESDIR)/$*.tilemap $<
$(RESDIR)/%.1bpp $(RESDIR)/%.tilemap: $(RESDIR)/%.png
	@mkdir -p $(RESDIR)/$(@*)
	$(RGBGFX) $(GFXFLAGS) -d 1 -o $(RESDIR)/$*.1bpp -t $(RESDIR)/$*.tilemap $<


$(RESDIR)/%.bin $(RESDIR)/%.inc: $(RESDIR)/%.asm
	$(RGBASM) $(ASFLAGS) -o $(RESDIR)/$*.o $< > $(RESDIR)/$*.inc
	$(RGBLINK) $(LDFLAGS) -x -o $(RESDIR)/$*.bin $(RESDIR)/$*.o
# Additional INCBIN'd dep
$(RESDIR)/winx.bin $(RESDIR)/winx.inc: $(RESDIR)/gb_light.vert.1bpp
$(RESDIR)/sgb_border.bin: $(RESDIR)/sgb_border_tiles.4bpp
$(RESDIR)/mus_data.bin: $(RESDIR)/musicdata.bin
# 0x700 = 1792
$(RESDIR)/mus_data.bin: ASFLAGS += -DDATA="`xxd -p -c 256 -l 256 -s 1792 src/$(RESDIR)/musicdata.bin`"
$(RESDIR)/sou_trn.bin: $(RESDIR)/sou_trn_data.bin


tools/propack/rnc64: tools/propack/main.c
	make -C $(@D) rnc64

# Dalton's decruncher skips the 18-byte header (not useful at runtime)
$(RESDIR)/%.rnc: $(RESDIR)/% tools/propack/rnc64
	tools/propack/rnc64 p $< $@.tmp -m 2 && dd if=$@.tmp of=$@ bs=1 skip=18 && rm $@.tmp


SUPERFAMICONV := tools/superfamiconv/bin/superfamiconv

# TODO: how to reuse its Makefile's dependencies?
# This is currently OK, but only for our purposes...
$(SUPERFAMICONV):
	make -C tools/superfamiconv bin/superfamiconv

$(RESDIR)/sgb_border_tiles.4bpp: $(RESDIR)/sgb_border_tiles.png $(SUPERFAMICONV)
	$(SUPERFAMICONV) tiles -M snes -W 8 -H 8 -R -B 4 -o $(RESDIR)/out.png -i $< -d $@
# $(RESDIR)/sgb_border.%: SFCFLAGS := -M snes -W 8 -H 8
# # Intentional restriction to 2bpp to save space, we don't need more colors
# $(RESDIR)/sgb_border.pal: $(RESDIR)/sgb_border.png $(SUPERFAMICONV)
# 	$(SUPERFAMICONV) palette $(SFCFLAGS) -P 3 -C 4 -0 '#ffffff' -i $< -d $@
# $(RESDIR)/sgb_border.1bpp: $(RESDIR)/sgb_border.png $(RESDIR)/sgb_border.pal $(SUPERFAMICONV)
# 	$(SUPERFAMICONV) tiles -v $(SFCFLAGS) -B 1 -o $(RESDIR)/out.png -i $< -p $(RESDIR)/sgb_border.pal -d $@
# $(RESDIR)/sgb_border.tilemap: $(RESDIR)/sgb_border.png $(RESDIR)/sgb_border.pal $(RESDIR)/sgb_border.2bpp $(SUPERFAMICONV)
# 	$(SUPERFAMICONV) map $(SFCFLAGS) -B 2 -i $< -p $(RESDIR)/sgb_border.pal -t $(RESDIR)/sgb_border.2bpp -d $@


# Useful to know how large a file will be when decompressed
$(RESDIR)/%.size: $(RESDIR)/%
	printf 'SIZE = %u' $$(wc -c $< | cut -d ' ' -f 1) > $@


$(RESDIR)/tiles.2bpp: $(RESDIR)/console_tiles.vert.2bpp $(RESDIR)/light_tiles.vert.2bpp $(RESDIR)/font.vert.2bpp $(RESDIR)/draft.uniq.2bpp
	cat $^ > $@

$(RESDIR)/data.bin: $(RESDIR)/text.bin $(RESDIR)/winx.bin
	cat $^ > $@
