
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
.PHONY: clean

# We rely on `quartet.gb` being first, and thus being passed to `-O`
# For some reason, RGBLINK outputs too many bytes?
$(BINDIR)/quartet.gb $(BINDIR)/quartet.sym $(BINDIR)/quartet.map: quartet.gb $(OBJS)
	@mkdir -p $(@D)
	$(RGBLINK) $(LDFLAGS) -o $(BINDIR)/quartet_tmp.gb -n $(BINDIR)/quartet_tmp.sym -m $(BINDIR)/quartet.map -O $^
	dd bs=32768 count=1 if=$(BINDIR)/quartet_tmp.gb of=$(BINDIR)/quartet.gb
	$(RGBFIX) $(FIXFLAGS) $(BINDIR)/quartet.gb
	sed 's/ / Q_/' quartet.sym | cat $(BINDIR)/quartet_tmp.sym - > $(BINDIR)/quartet.sym
	rm -f quartet_tmp.gb quartet_tmp.sym

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

%.uniq.2bpp %.uniq.tilemap: GFXFLAGS += -u
%.vert.2bpp %.vert.tilemap: GFXFLAGS += -h
$(RESDIR)/%.2bpp $(RESDIR)/%.tilemap: $(RESDIR)/%.png
	@mkdir -p $(RESDIR)/$(@*)
	$(RGBGFX) $(GFXFLAGS) -o $(RESDIR)/$*.2bpp -t $(RESDIR)/$*.tilemap $<

$(RESDIR)/winx.bin $(RESDIR)/winx.inc: $(RESDIR)/winx.asm
	$(RGBASM) $(ASFLAGS) -o $(RESDIR)/winx.o $< > $(RESDIR)/winx.inc
	$(RGBLINK) -x -o $(RESDIR)/winx.bin $(RESDIR)/winx.o
