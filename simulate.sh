#!/bin/bash
# ============================================================================
# SparkMCU RTL Simulation Script
# ============================================================================
# Runs testbench with compiled firmware hex file
# Supports iverilog, VCS, Vivado, ModelSim, etc.
# Usage: ./simulate.sh [simulator] [test_name]
# ============================================================================

set -e

# Configuration
SIMULATOR="${1:-iverilog}"  # Default: iverilog
TEST_NAME="${2:-test_suite_main}"
BUILD_DIR="./firmware/build"
TESTBENCH_DIR="./testbench"
RTL_DIR="./rtl"
HEX_FILE="$BUILD_DIR/$TEST_NAME.hex"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}[SIM] SparkMCU RTL Test: $TEST_NAME${NC}"
echo -e "${BLUE}[SIM] Simulator: $SIMULATOR${NC}"

# Check that hex file exists
if [ ! -f "$HEX_FILE" ]; then
    echo -e "${RED}[ERROR] Hex file not found: $HEX_FILE${NC}"
    echo -e "${YELLOW}[HINT] Build firmware first: ./build_firmware.sh $TEST_NAME${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Hex file found: $HEX_FILE${NC}"

# RTL source files
RTL_FILES=(
    "$RTL_DIR/spark_mcu_top.v"
    "$RTL_DIR/core/spark_cpu.v"
    "$RTL_DIR/core/spark_alu.v"
    "$RTL_DIR/core/spark_decoder.v"
    "$RTL_DIR/core/spark_regfile.v"
    "$RTL_DIR/core/spark_pkg.v"
    "$RTL_DIR/memory/spark_pmem.v"
    "$RTL_DIR/memory/spark_dmem.v"
    "$RTL_DIR/memory/spark_bus_ctrl.v"
    "$RTL_DIR/memory/spark_flash_rom.v"
    "$RTL_DIR/peripherals/spark_gpio.v"
    "$RTL_DIR/peripherals/spark_uart.v"
    "$RTL_DIR/peripherals/spark_timer0.v"
    "$RTL_DIR/peripherals/spark_intctrl.v"
    "$RTL_DIR/peripherals/spark_spi.v"
    "$TESTBENCH_DIR/spark_mcu_test_tb.v"
)

# Run simulation based on selected simulator
case "$SIMULATOR" in
    iverilog|icarus)
        echo -e "${YELLOW}[SIM] Using iVerilog/Icarus Verilog${NC}"
        
        if ! command -v iverilog &> /dev/null; then
            echo -e "${RED}[ERROR] iverilog not found. Install via: apt-get install iverilog${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}[COMPILE] Compiling design${NC}"
        iverilog \
            -g2009 \
            -I"$RTL_DIR/core" \
            -o "$BUILD_DIR/sparkmc_TB.vvp" \
            -DHEX_FILE="\"$HEX_FILE\"" \
            "${RTL_FILES[@]}"
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}[ERROR] iVerilog compilation failed${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}[OK] iVerilog compilation successful${NC}"
        
        echo -e "${YELLOW}[RUN] Running simulation${NC}"
        vvp "$BUILD_DIR/sparkmc_TB.vvp" \
            -lxt2 \
            -o "$BUILD_DIR/spark_mcu_test.lxt"
        
        SIM_EXIT_CODE=$?
        ;;
        
    vivado)
        echo -e "${YELLOW}[SIM] Using Vivado Simulator${NC}"
        
        if ! command -v xsim &> /dev/null; then
            echo -e "${RED}[ERROR] xsim (Vivado) not found${NC}"
            exit 1
        fi
        
        # Vivado simulation setup (would need proper project structure)
        echo -e "${RED}[ERROR] Vivado simulation not yet implemented${NC}"
        exit 1
        ;;
        
    modelsim|vsim)
        echo -e "${YELLOW}[SIM] Using ModelSim${NC}"
        
        if ! command -v vlog &> /dev/null; then
            echo -e "${RED}[ERROR] vlog (ModelSim) not found${NC}"
            exit 1
        fi
        
        echo -e "${RED}[ERROR] ModelSim simulation not yet implemented${NC}"
        exit 1
        ;;
        
    vcs)
        echo -e "${YELLOW}[SIM] Using VCS${NC}"
        
        if ! command -v vcs &> /dev/null; then
            echo -e "${RED}[ERROR] vcs (VCS) not found${NC}"
            exit 1
        fi
        
        echo -e "${RED}[ERROR] VCS simulation not yet implemented${NC}"
        exit 1
        ;;
        
    *)
        echo -e "${RED}[ERROR] Unknown simulator: $SIMULATOR${NC}"
        echo "Supported simulators: iverilog, vivado, modelsim, vcs"
        exit 1
        ;;
esac

# Check simulation result
if [ $SIM_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS] Simulation completed successfully${NC}"
    echo -e "${BLUE}[INFO] Results: $BUILD_DIR/${TEST_NAME}.lxt${NC}"
else
    echo -e "${RED}[ERROR] Simulation exited with code $SIM_EXIT_CODE${NC}"
    exit $SIM_EXIT_CODE
fi
