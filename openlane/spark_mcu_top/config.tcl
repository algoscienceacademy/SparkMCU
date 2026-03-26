# ============================================================================
# SparkMCU - OpenLane Configuration
# ============================================================================
# Target: SkyWater 130nm (sky130A)
# Design: AVR-Compatible 8-bit Microcontroller
# ============================================================================

# ----- Design -----
set ::env(DESIGN_NAME) "tt_um_spark_mcu_top"
set ::env(DESIGN_IS_CORE) 1

# ----- Source Files -----
set ::env(VERILOG_FILES) [glob \
    $::env(DESIGN_DIR)/../../rtl/core/spark_pkg.v \
    $::env(DESIGN_DIR)/../../rtl/core/spark_alu.v \
    $::env(DESIGN_DIR)/../../rtl/core/spark_regfile.v \
    $::env(DESIGN_DIR)/../../rtl/core/spark_decoder.v \
    $::env(DESIGN_DIR)/../../rtl/core/spark_cpu.v \
    $::env(DESIGN_DIR)/../../rtl/memory/spark_pmem.v \
    $::env(DESIGN_DIR)/../../rtl/memory/spark_dmem.v \
    $::env(DESIGN_DIR)/../../rtl/memory/spark_bus_ctrl.v \
    $::env(DESIGN_DIR)/../../rtl/memory/spark_flash_rom.v \
    $::env(DESIGN_DIR)/../../rtl/peripherals/spark_gpio.v \
    $::env(DESIGN_DIR)/../../rtl/peripherals/spark_uart.v \
    $::env(DESIGN_DIR)/../../rtl/peripherals/spark_spi.v \
    $::env(DESIGN_DIR)/../../rtl/peripherals/spark_timer0.v \
    $::env(DESIGN_DIR)/../../rtl/peripherals/spark_intctrl.v \
    $::env(DESIGN_DIR)/../../rtl/spark_mcu_top.v \
]

# ----- Include Paths -----
set ::env(VERILOG_INCLUDE_DIRS) "$::env(DESIGN_DIR)/../../rtl/core/"

# ----- Clock -----
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "62.5"
# 16 MHz target clock for AVR compatibility

set ::env(CLOCK_NET) "clk"

# ----- PDK -----
set ::env(PDK) "sky130A"
set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"
set ::env(STD_CELL_LIBRARY_OPT) "sky130_fd_sc_hd"

# ----- Die Area -----
# Let OpenLane auto-size the floorplan based on FP_CORE_UTIL
set ::env(FP_SIZING) "relative"

# ----- Pin Configuration -----
set ::env(FP_PIN_ORDER_CFG) "$::env(DESIGN_DIR)/pin_order.cfg"

# ----- Utilization -----
set ::env(FP_CORE_UTIL) 35
set ::env(PL_TARGET_DENSITY) 0.40
set ::env(CELL_PAD) 6

# ----- Power -----
set ::env(VDD_NETS) [list "vccd1"]
set ::env(GND_NETS) [list "vssd1"]
set ::env(FP_PDN_CORE_RING) 1
set ::env(FP_PDN_VPITCH) 100
set ::env(FP_PDN_HPITCH) 100
set ::env(RUN_TAP_DECAP_INSERTION) 1
set ::env(FP_TAPCELL_DIST) 14

# ----- Routing -----
set ::env(ROUTING_CORES) 4
set ::env(GRT_ADJUSTMENT) 0.15
set ::env(GRT_OVERFLOW_ITERS) 150

# ----- Diode Insertion -----
set ::env(DIODE_INSERTION_STRATEGY) 4
set ::env(GRT_MAX_DIODE_INS_ITERS) 5

# ----- Synthesis -----
set ::env(SYNTH_STRATEGY) "AREA 0"
set ::env(SYNTH_MAX_FANOUT) 8
set ::env(SYNTH_BUFFERING) 1
set ::env(SYNTH_SIZING) 1
set ::env(SYNTH_NO_FLAT) 0
set ::env(SYNTH_READ_BLACKBOX_LIB) 1

# ----- STA (Static Timing Analysis) -----
set ::env(STA_REPORT_POWER) 1
set ::env(STA_WRITE_LIB) 1

# ----- CTS (Clock Tree Synthesis) -----
set ::env(CTS_TOLERANCE) 100
set ::env(CTS_SINK_CLUSTERING_SIZE) 25
set ::env(CTS_SINK_CLUSTERING_MAX_DIAMETER) 50
set ::env(CTS_CLK_BUFFER_LIST) "sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_16"
set ::env(CTS_ROOT_BUFFER) "sky130_fd_sc_hd__clkbuf_16"

# ----- Placement -----
set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_HOLD_SLACK_MARGIN) 0.05
# Keep default/auto max wire length.
# A very small value (e.g. 500um) forces excessive buffering and can make
# resizer runtime explode on larger floorplans.
set ::env(PL_RESIZER_MAX_WIRE_LENGTH) 0

# ----- Global Routing -----
set ::env(GRT_ALLOW_CONGESTION) 1

# ----- DRC -----
set ::env(MAGIC_DRC_USE_GDS) 1
set ::env(QUIT_ON_MAGIC_DRC) 0
set ::env(RUN_DRC) 1
set ::env(RUN_LVS) 1
set ::env(RUN_CVC) 1

# ----- Antenna -----
set ::env(RUN_ANTENNA_CHECK) 1

# ----- Output -----
set ::env(TAKE_LAYOUT_SCROT) 0
