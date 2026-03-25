# ============================================================================
# SparkMCU - SDC Timing Constraints
# ============================================================================
# Target: SkyWater 130nm @ 16 MHz
# ============================================================================

# Clock definition
create_clock -name clk -period 62.5 [get_ports clk]

# Clock uncertainty (jitter + skew)
set_clock_uncertainty 0.5 [get_clocks clk]

# Clock transition
set_clock_transition 0.15 [get_clocks clk]

# Input delays (relative to clock)
set_input_delay  -clock clk -max 10.0 [get_ports {portb_in[*]}]
set_input_delay  -clock clk -min 2.0  [get_ports {portb_in[*]}]
set_input_delay  -clock clk -max 10.0 [get_ports {portc_in[*]}]
set_input_delay  -clock clk -min 2.0  [get_ports {portc_in[*]}]
set_input_delay  -clock clk -max 10.0 [get_ports {portd_in[*]}]
set_input_delay  -clock clk -min 2.0  [get_ports {portd_in[*]}]

set_input_delay  -clock clk -max 10.0 [get_ports uart_rxd]
set_input_delay  -clock clk -min 2.0  [get_ports uart_rxd]

set_input_delay  -clock clk -max 10.0 [get_ports spi_miso]
set_input_delay  -clock clk -min 2.0  [get_ports spi_miso]

set_input_delay  -clock clk -max 10.0 [get_ports t0_pin]
set_input_delay  -clock clk -min 2.0  [get_ports t0_pin]

set_input_delay  -clock clk -max 10.0 [get_ports int0_pin]
set_input_delay  -clock clk -min 2.0  [get_ports int0_pin]

set_input_delay  -clock clk -max 10.0 [get_ports int1_pin]
set_input_delay  -clock clk -min 2.0  [get_ports int1_pin]

set_input_delay  -clock clk -max 10.0 [get_ports {prog_addr[*]}]
set_input_delay  -clock clk -min 2.0  [get_ports {prog_addr[*]}]
set_input_delay  -clock clk -max 10.0 [get_ports {prog_data[*]}]
set_input_delay  -clock clk -min 2.0  [get_ports {prog_data[*]}]
set_input_delay  -clock clk -max 10.0 [get_ports prog_wr]
set_input_delay  -clock clk -min 2.0  [get_ports prog_wr]

set_input_delay  -clock clk -max 5.0  [get_ports rst_n]
set_input_delay  -clock clk -min 1.0  [get_ports rst_n]

# Output delays
set_output_delay -clock clk -max 10.0 [get_ports {portb_out[*]}]
set_output_delay -clock clk -min 2.0  [get_ports {portb_out[*]}]
set_output_delay -clock clk -max 10.0 [get_ports {portb_dir[*]}]
set_output_delay -clock clk -min 2.0  [get_ports {portb_dir[*]}]

set_output_delay -clock clk -max 10.0 [get_ports {portc_out[*]}]
set_output_delay -clock clk -min 2.0  [get_ports {portc_out[*]}]
set_output_delay -clock clk -max 10.0 [get_ports {portc_dir[*]}]
set_output_delay -clock clk -min 2.0  [get_ports {portc_dir[*]}]

set_output_delay -clock clk -max 10.0 [get_ports {portd_out[*]}]
set_output_delay -clock clk -min 2.0  [get_ports {portd_out[*]}]
set_output_delay -clock clk -max 10.0 [get_ports {portd_dir[*]}]
set_output_delay -clock clk -min 2.0  [get_ports {portd_dir[*]}]

set_output_delay -clock clk -max 10.0 [get_ports uart_txd]
set_output_delay -clock clk -min 2.0  [get_ports uart_txd]

set_output_delay -clock clk -max 10.0 [get_ports spi_sck]
set_output_delay -clock clk -min 2.0  [get_ports spi_sck]
set_output_delay -clock clk -max 10.0 [get_ports spi_mosi]
set_output_delay -clock clk -min 2.0  [get_ports spi_mosi]
set_output_delay -clock clk -max 10.0 [get_ports spi_ss_n]
set_output_delay -clock clk -min 2.0  [get_ports spi_ss_n]

set_output_delay -clock clk -max 10.0 [get_ports oc0a_pin]
set_output_delay -clock clk -min 2.0  [get_ports oc0a_pin]
set_output_delay -clock clk -max 10.0 [get_ports oc0b_pin]
set_output_delay -clock clk -min 2.0  [get_ports oc0b_pin]

set_output_delay -clock clk -max 10.0 [get_ports {debug_pc[*]}]
set_output_delay -clock clk -min 2.0  [get_ports {debug_pc[*]}]
set_output_delay -clock clk -max 10.0 [get_ports {debug_sreg[*]}]
set_output_delay -clock clk -min 2.0  [get_ports {debug_sreg[*]}]
set_output_delay -clock clk -max 10.0 [get_ports {debug_state[*]}]
set_output_delay -clock clk -min 2.0  [get_ports {debug_state[*]}]

# Driving cell for inputs
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y [all_inputs]

# Output load
set_load 0.05 [all_outputs]

# Max transition
set_max_transition 1.5 [current_design]

# Max fanout
set_max_fanout 16 [current_design]

# False paths for asynchronous inputs
set_false_path -from [get_ports rst_n]

# Multicycle paths for memory (SRAM has 1 cycle latency)
# set_multicycle_path 2 -setup -from [get_pins u_dmem/mem_reg*/Q]
# set_multicycle_path 1 -hold  -from [get_pins u_dmem/mem_reg*/Q]
