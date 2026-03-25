# ============================================================================
# SparkMCU - Makefile
# ============================================================================
# Build targets:
#   make sim         - Run Icarus Verilog simulation
#   make wave        - Open waveform viewer (GTKWave)
#   make synth       - Run Yosys synthesis (standalone check)
#   make openlane    - Run full OpenLane ASIC flow
#   make clean       - Clean build artifacts
#   make lint        - Run Verilator lint check
# ============================================================================

# Project settings
TOP_MODULE  = tt_um_spark_mcu_top
TB_MODULE   = spark_mcu_tb
PROJECT     = SparkMCU

# Directories
RTL_DIR     = rtl
CORE_DIR    = $(RTL_DIR)/core
MEM_DIR     = $(RTL_DIR)/memory
PERI_DIR    = $(RTL_DIR)/peripherals
TB_DIR      = testbench
BUILD_DIR   = build
OL_DIR      = openlane/$(TOP_MODULE)

# Source files
RTL_SRCS = \
    $(CORE_DIR)/spark_pkg.v \
    $(CORE_DIR)/spark_alu.v \
    $(CORE_DIR)/spark_regfile.v \
    $(CORE_DIR)/spark_decoder.v \
    $(CORE_DIR)/spark_cpu.v \
    $(MEM_DIR)/spark_pmem.v \
    $(MEM_DIR)/spark_dmem.v \
    $(MEM_DIR)/spark_bus_ctrl.v \
    $(PERI_DIR)/spark_gpio.v \
    $(PERI_DIR)/spark_uart.v \
    $(PERI_DIR)/spark_spi.v \
    $(PERI_DIR)/spark_timer0.v \
    $(PERI_DIR)/spark_intctrl.v \
    $(RTL_DIR)/spark_mcu_top.v

TB_SRCS = $(TB_DIR)/spark_mcu_tb.v

# Tools
IVERILOG   = iverilog
VVP        = vvp
GTKWAVE    = gtkwave
YOSYS      = yosys
VERILATOR  = verilator

# OpenLane paths (adjust to your installation)
OPENLANE_ROOT ?= $(HOME)/OpenLane
PDK_ROOT     ?= $(HOME)/pdk
PDK          ?= sky130A

# ============================================================================
# Targets
# ============================================================================

.PHONY: all sim wave synth lint openlane openlane-docker mount clean help

all: sim

help:
	@echo "============================================"
	@echo "  $(PROJECT) - Build System"
	@echo "============================================"
	@echo "  make sim       - Run simulation (Icarus Verilog)"
	@echo "  make wave      - Open waveform (GTKWave)"
	@echo "  make synth     - Yosys synthesis check"
	@echo "  make lint      - Verilator lint check"
	@echo "  make mount     - Enter OpenLane Docker (from host)"
	@echo "  make openlane  - Full OpenLane ASIC flow"
	@echo "  make clean     - Clean build artifacts"
	@echo "============================================"

# ---- Enter OpenLane Docker from project dir ----
mount:
	@if [ -f /.dockerenv ]; then \
		echo "Already inside OpenLane container. Run: ./flow.tcl -design SparkMCU/openlane/spark_mcu_top"; \
		exit 0; \
	fi
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "ERROR: docker is not installed on host."; \
		exit 1; \
	fi
	cd $(HOME)/OpenLane && $(MAKE) mount

# ---- Build directory ----
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# ---- Simulation with Icarus Verilog ----
sim: $(BUILD_DIR)
	@echo "=========================================="
	@echo "  Running Icarus Verilog Simulation"
	@echo "=========================================="
	cd $(BUILD_DIR) && $(IVERILOG) -g2012 \
		-I ../$(RTL_DIR) \
		-I .. \
		-o $(TB_MODULE).vvp \
		$(addprefix ../,$(RTL_SRCS)) \
		$(addprefix ../,$(TB_SRCS))
	cd $(BUILD_DIR) && $(VVP) $(TB_MODULE).vvp

# ---- Waveform viewer ----
wave: $(BUILD_DIR)/spark_mcu_tb.vcd
	$(GTKWAVE) $(BUILD_DIR)/spark_mcu_tb.vcd &

$(BUILD_DIR)/spark_mcu_tb.vcd: sim

# ---- Verilator lint ----
lint:
	@echo "=========================================="
	@echo "  Running Verilator Lint"
	@echo "=========================================="
	$(VERILATOR) --lint-only -Wall \
		-I$(RTL_DIR) -I. \
		$(RTL_SRCS) \
		--top-module $(TOP_MODULE) \
		2>&1 | tee $(BUILD_DIR)/lint.log || true
	@echo "Lint complete. Check $(BUILD_DIR)/lint.log"

# ---- Yosys synthesis (standalone check) ----
synth: $(BUILD_DIR)
	@echo "=========================================="
	@echo "  Running Yosys Synthesis"
	@echo "=========================================="
	$(YOSYS) -p " \
		read_verilog -I$(RTL_DIR) -I. $(RTL_SRCS); \
		hierarchy -check -top $(TOP_MODULE); \
		proc; opt; fsm; opt; memory; opt; \
		techmap; opt; \
		synth -top $(TOP_MODULE); \
		stat; \
		write_verilog $(BUILD_DIR)/$(TOP_MODULE)_synth.v" \
		2>&1 | tee $(BUILD_DIR)/synth.log
	@echo "Synthesis complete. Check $(BUILD_DIR)/synth.log"

# ---- OpenLane ASIC Flow ----
openlane:
	@echo "=========================================="
	@echo "  Running OpenLane ASIC Flow"
	@echo "  Target: SkyWater 130nm ($(PDK))"
	@echo "=========================================="
	@if [ ! -d "$(OPENLANE_ROOT)" ]; then \
		echo "ERROR: OpenLane not found at $(OPENLANE_ROOT)"; \
		echo "Set OPENLANE_ROOT to your OpenLane installation path"; \
		exit 1; \
	fi
	cd $(OPENLANE_ROOT) && \
		./flow.tcl -design $(CURDIR)/openlane/$(TOP_MODULE) \
		-tag spark_mcu_run \
		-overwrite

# OpenLane with Docker
openlane-docker:
	@echo "=========================================="
	@echo "  Running OpenLane via Docker"
	@echo "=========================================="
	docker run --rm \
		-v $(OPENLANE_ROOT):/openlane \
		-v $(PDK_ROOT):$(PDK_ROOT) \
		-v $(CURDIR):/work \
		-e PDK_ROOT=$(PDK_ROOT) \
		-e PDK=$(PDK) \
		efabless/openlane:latest \
		/bin/bash -c "cd /openlane && ./flow.tcl -design /work/openlane/$(TOP_MODULE) -tag spark_mcu_run -overwrite"

# ---- Clean ----
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -f *.vcd *.vvp
	@echo "Clean complete."

clean-all: clean
	rm -rf openlane/$(TOP_MODULE)/runs
