#!/bin/bash
cd /home/shahrear/OpenLane/designs/SparkMCU

# Compile firmware
make -f Makefile.fw clean
make -f Makefile.fw build-fw

# Compile and run simulation with increased timeout
iverilog -g2009 -I rtl/core -o sim.vvp \
  testbench/spark_mcu_test_tb.v \
  rtl/spark_mcu_top.v \
  rtl/core/spark_cpu.v \
  rtl/core/spark_alu.v \
  rtl/core/spark_decoder.v \
  rtl/core/spark_regfile.v \
  rtl/core/spark_pkg.v \
  rtl/memory/spark_dmem.v \
  rtl/memory/spark_pmem.v \
  rtl/memory/spark_bus_ctrl.v \
  rtl/peripherals/spark_uart.v \
  rtl/peripherals/spark_gpio.v \
  rtl/peripherals/spark_timer0.v \
  rtl/peripherals/spark_spi.v \
  rtl/peripherals/spark_intctrl.v && \
  echo "[COMPILE SUCCESS]" || echo "[COMPILE FAILED]"

# Run with 500ms timeout instead of 100ms
vvp sim.vvp 2>&1 | head -200
