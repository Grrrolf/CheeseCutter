PREFIX ?= /usr/local
DESTDIR ?=
EXAMPLESDIR ?= $(PREFIX)/share/examples/ccutter
VERSION := $(shell cat Version 2>/dev/null || echo "unknown")
UNAME_S := $(shell uname)
ifeq ($(UNAME_S),Darwin)
DLIBS=-L-ldl -L-lstdc++ -L-lSDL2 -L-L/opt/homebrew/lib -L-L/usr/local/lib
else
DLIBS=-L-ldl -L-lstdc++ -L-lSDL2
endif
DFLAGS=-d-version=DerelictSDL2_Static -I./src -J./src/c64 -J./src/font
CFLAGS=-O2 -std=c99
CXXFLAGS=-O2 -I./src
COMPILE.d = $(DC) $(DFLAGS) -c
DC=ldc2
TARGET=ccutter

include Makefile.objects.mk

BUILD_DIR = build
DIST_DIR = dist

BUILD_OBJS = $(addprefix $(BUILD_DIR)/, $(OBJS))
BUILD_CXX_OBJS = $(addprefix $(BUILD_DIR)/, $(CXX_OBJS))
BUILD_C_OBJS = $(addprefix $(BUILD_DIR)/, $(C_OBJS))
BUILD_UTILOBJS = $(addprefix $(BUILD_DIR)/, $(UTILOBJS))

DIST_FILES = \
	./ChangeLog \
	./LICENSE.md \
	./README.md \
	$(DIST_DIR)/ccutter \
	$(DIST_DIR)/ct2util \
	./tunes/*

.PHONY: help install release dist clean dclean tar ccutter ct2util test

help:
	@echo "Available targets:"
	@echo "  all          - Build ccutter and ct2util (default)"
	@echo "  ccutter      - Build ccutter"
	@echo "  ct2util      - Build ct2util"
	@echo "  test         - Run basic smoke tests"
	@echo "  release      - Build release version (optimized and stripped)"
	@echo "  dist         - Create Linux distribution tarball"
	@echo "  dist-mac     - Create macOS distribution DMG (calls Makefile.mac)"
	@echo "  clean        - Remove build objects"
	@echo "  dclean       - Remove build and dist directories"

$(BUILD_DIR)/%.o: %.d
	@mkdir -p $(dir $@)
	$(DC) $(DFLAGS) -c -of=$@ $<

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c -o $@ $<

all: $(DIST_DIR)/ct2util $(DIST_DIR)/ccutter

ccutter: $(DIST_DIR)/ccutter
ct2util: $(DIST_DIR)/ct2util

$(DIST_DIR)/ccutter: $(C64OBJS) $(BUILD_OBJS) $(BUILD_CXX_OBJS)
	@mkdir -p $(DIST_DIR)
	$(DC) -of=$@ $(BUILD_OBJS) $(BUILD_CXX_OBJS) $(DLIBS)

ct: $(C64OBJS) $(CTOBJS)

$(DIST_DIR)/ct2util: $(C64OBJS) $(BUILD_UTILOBJS)
	@mkdir -p $(DIST_DIR)
	$(DC) -of=$@ $(BUILD_UTILOBJS)

c64: $(C64OBJS)

install: all
	strip $(DIST_DIR)/ccutter
	strip $(DIST_DIR)/ct2util
	install -D -m 755 $(DIST_DIR)/ccutter $(DESTDIR)$(PREFIX)/bin/ccutter
	install -D -m 755 $(DIST_DIR)/ct2util $(DESTDIR)$(PREFIX)/bin/ct2util
	install -d $(DESTDIR)$(EXAMPLESDIR)/example_tunes
	cp -r tunes/* $(DESTDIR)$(EXAMPLESDIR)/example_tunes/

# release version with additional optimizations
release: DFLAGS += -frelease -fno-bounds-check
release: all
	strip $(DIST_DIR)/ccutter
	strip $(DIST_DIR)/ct2util

# tarred release
dist:	release
	tar --transform 's,^\.,cheesecutter-$(VERSION),' -czf $(DIST_DIR)/cheesecutter-$(VERSION)-linux-x86.tar.gz $(DIST_FILES)

dist-mac:
	$(MAKE) -f Makefile.mac dist

test: all
	@echo "Running smoke tests..."
	$(DIST_DIR)/ccutter -h > /dev/null
	$(DIST_DIR)/ct2util > /dev/null
	@echo "Smoke tests passed!"

clean:
	rm -rf $(BUILD_DIR)
	rm -f *~ src/*~ src/*/*~

dclean: clean
	rm -rf $(DIST_DIR)

# tarred source from master
tar:
	@mkdir -p $(DIST_DIR)
	git archive master --prefix=cheesecutter-$(VERSION)/ | bzip2 > $(DIST_DIR)/cheesecutter-$(VERSION)-src.tar.bz2
# --------------------------------------------------------------------------------

src/c64/player.bin: src/c64/player_v4.acme
	acme -f cbm -Wno-old-for --outfile $@ $<

$(BUILD_DIR)/src/ct/base.o: src/c64/player.bin
$(BUILD_DIR)/src/ui/ui.o: $(BUILD_DIR)/src/ui/help.o
