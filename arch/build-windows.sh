#!/bin/bash
# build-windows.sh
set -e

# Ensure directories exist
mkdir -p build/src/asm
mkdir -p build/src/resid
mkdir -p build/src/resid-fp
mkdir -p build/src/audio/resid
mkdir -p dist

CC=clang-cl
CXX=clang-cl

echo "Checking compilers..."
which $CC || echo "$CC not found"
which ldc2 || echo "ldc2 not found"

echo "Compiling C files..."
for f in src/asm/*.c; do
    obj="build/${f%.c}.obj"
    echo "Processing $f"
    $CC -nologo -O2 -Isrc -c -Fo"$obj" "$f"
done

echo "Compiling C++ files..."
for f in src/resid/*.cpp; do
    obj="build/${f%.cpp}.obj"
    echo "Processing $f"
    $CXX -nologo -O2 -Isrc -c -EHsc -Fo"$obj" "$f"
done
for f in src/resid-fp/*.cpp; do
    obj="build/${f%.cpp}.obj"
    echo "Processing $f"
    $CXX -nologo -O2 -Isrc -c -EHsc -Fo"$obj" "$f"
done
echo "Processing src/audio/resid/residctrl.cpp"
$CXX -nologo -O2 -Isrc -c -EHsc -Fo"build/src/audio/resid/residctrl.obj" src/audio/resid/residctrl.cpp

echo "Compiling and Linking CheeseCutter..."
# Use -i to automatically compile imported modules (like Derelict loader)
ldc2 -i -Isrc -Jsrc/c64 -Jsrc/font -O -of=dist/ccutter.exe src/main.d build/src/resid/*.obj build/src/resid-fp/*.obj build/src/audio/resid/residctrl.obj

echo "Compiling and Linking ct2util..."
ldc2 -i -Isrc -Jsrc/c64 -O -of=dist/ct2util.exe src/ct2util.d build/src/asm/*.obj
