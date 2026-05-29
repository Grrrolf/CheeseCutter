#!/bin/bash
# build-windows.sh
set -e

# Ensure directories exist
mkdir -p build/src/asm
mkdir -p build/src/resid
mkdir -p build/src/resid-fp
mkdir -p build/src/audio/resid
mkdir -p dist

echo "Compiling C files..."
for f in src/asm/*.c; do
    cl /nologo /O2 /Isrc /c /Fo"build/${f%.c}.obj" "$f"
done

echo "Compiling C++ files..."
for f in src/resid/*.cpp; do
    cl /nologo /O2 /Isrc /c /EHsc /Fo"build/${f%.cpp}.obj" "$f"
done
for f in src/resid-fp/*.cpp; do
    cl /nologo /O2 /Isrc /c /EHsc /Fo"build/${f%.cpp}.obj" "$f"
done
cl /nologo /O2 /Isrc /c /EHsc /Fo"build/src/audio/resid/residctrl.obj" src/audio/resid/residctrl.cpp

echo "Compiling and Linking CheeseCutter..."
# Collect D files excluding ct2util related if we want to be precise, or just all D files
# Actually, the main targets have overlapping files.
# Using the lists from Makefile.objects.mk but adapted for ldc2 command line.

D_FILES="src/derelict/sdl2/internal/sdl_types.d \
	src/audio/audio.d \
	src/audio/player.d \
	src/audio/timer.d \
	src/audio/callback.d \
	src/ct/purge.d \
	src/ct/base.d \
	src/com/fb.d \
	src/com/cpu.d \
	src/com/kbd.d \
	src/com/session.d \
	src/com/util.d \
	src/main.d \
	src/ui/tables.d \
	src/ui/dialogs.d \
	src/ui/ui.d \
	src/ui/input.d \
	src/ui/help.d \
	src/seq/seqtable.d \
	src/seq/tracktable.d \
	src/seq/trackmap.d \
	src/seq/fplay.d \
	src/seq/sequencer.d \
	src/audio/resid/filter.d"

ldc2 -Isrc -Jsrc/c64 -Jsrc/font -O -of=dist/ccutter.exe $D_FILES build/src/asm/*.obj build/src/resid/*.obj build/src/resid-fp/*.obj build/src/audio/resid/residctrl.obj

echo "Compiling and Linking ct2util..."
UTIL_D_FILES="src/ct2util.d \
	src/ct/base.d \
	src/com/cpu.d \
	src/com/util.d \
	src/ct/purge.d \
	src/ct/dump.d \
	src/ct/build.d"

ldc2 -Isrc -Jsrc/c64 -O -of=dist/ct2util.exe $UTIL_D_FILES build/src/asm/*.obj
