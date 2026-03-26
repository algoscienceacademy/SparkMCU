#!/bin/bash
# ============================================================================
# SparkMCU Firmware Build Script
# ============================================================================
# Compiles C firmware to .hex file for simulation
# Usage: ./build_firmware.sh [target]
# ============================================================================

set -e

# Configuration
MCU="atmega328p"
F_CPU="16000000UL"
OPTIMIZATION="-Os"
BUILD_DIR="./firmware/build"
SRC_DIR="./firmware/src"
INC_DIR="./firmware/include"
LIB_DIR="./firmware/lib"

# Target to build (default: test_suite_main)
TARGET="${1:-test_suite_main}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}[BUILD] SparkMCU Firmware ($TARGET)${NC}"

# Create build directory
mkdir -p "$BUILD_DIR"

# Check if avr-gcc is available
if ! command -v avr-gcc &> /dev/null; then
    echo -e "${RED}[ERROR] avr-gcc not found. Install AVR-GCC toolchain.${NC}"
    exit 1
fi

# Compile C source file
echo -e "${YELLOW}[COMPILE] $TARGET.c${NC}"
avr-gcc \
    -mmcu="$MCU" \
    -DF_CPU="$F_CPU" \
    -I"$INC_DIR" \
    -L"$LIB_DIR" \
    $OPTIMIZATION \
    -Wall \
    -Wextra \
    -std=gnu99 \
    -c "$SRC_DIR/$TARGET.c" \
    -o "$BUILD_DIR/$TARGET.o"

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Compilation failed${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Compilation successful${NC}"

# Link object files
echo -e "${YELLOW}[LINK] Creating ELF file${NC}"
avr-gcc \
    -mmcu="$MCU" \
    -L"$LIB_DIR" \
    $OPTIMIZATION \
    -Wall \
    "$BUILD_DIR/$TARGET.o" \
    -o "$BUILD_DIR/$TARGET.elf"

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Linking failed${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Linking successful${NC}"

# Generate hex file
echo -e "${YELLOW}[HEX] Converting to Intel HEX format${NC}"
avr-objcopy \
    -O ihex \
    "$BUILD_DIR/$TARGET.elf" \
    "$BUILD_DIR/$TARGET.hex"

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Hex conversion failed${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Hex conversion successful${NC}"

# Display statistics
echo -e "${YELLOW}[STATS]${NC}"
echo "ELF file: $BUILD_DIR/$TARGET.elf"
echo "HEX file: $BUILD_DIR/$TARGET.hex"

# Get ELF size
SIZE=$(avr-size "$BUILD_DIR/$TARGET.elf" | tail -n 1)
echo "Size: $SIZE"

echo -e "${GREEN}[SUCCESS] Build complete!${NC}"
echo -e "Hex file ready at: ${YELLOW}$BUILD_DIR/$TARGET.hex${NC}"
