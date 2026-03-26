// ============================================================================
// SparkMCU - Enhanced Testbench with UART Monitor
// ============================================================================
// Features:
//   - Loads firmware from .hex file
//   - Monitors UART output (pure Verilog compatible)
//   - Captures PASS/FAIL test results
//   - Generates test report
// ============================================================================

`timescale 1ns / 1ps

module spark_mcu_test_tb;

    // -----------------------------------------------------------------------
    // Simulation Parameters
    // -----------------------------------------------------------------------
    parameter CLK_PERIOD = 62.5;        // 16 MHz clock
    parameter UART_BAUD  = 9600;
    parameter UART_PERIOD = 1000000000 / UART_BAUD;  // in ns
    parameter HEX_FILE   = "firmware/build/test.hex";
    parameter SIM_TIME   = 10000000000;   // 10 seconds max simulation

    // -----------------------------------------------------------------------
    // Testbench Signals
    // -----------------------------------------------------------------------
    reg         clk;
    reg         rst_n;

    // GPIO Ports
    reg  [7:0]  portb_in;
    wire [7:0]  portb_out;
    wire [7:0]  portb_dir;

    reg  [5:0]  portc_in;
    wire [5:0]  portc_out;
    wire [5:0]  portc_dir;

    reg  [7:0]  portd_in;
    wire [7:0]  portd_out;
    wire [7:0]  portd_dir;

    // UART
    reg         uart_rxd;
    wire        uart_txd;

    // SPI
    wire        spi_sck;
    wire        spi_mosi;
    reg         spi_miso;
    wire        spi_ss_n;

    // Timer
    reg         t0_pin;
    wire        oc0a_pin;
    wire        oc0b_pin;

    // External Interrupts
    reg         int0_pin;
    reg         int1_pin;

    // Debug signals
    wire [15:0] debug_pc;
    wire [7:0]  debug_sreg;
    wire [2:0]  debug_state;

    // -----------------------------------------------------------------------
    // UART Monitor Signals (Pure Verilog)
    // -----------------------------------------------------------------------
    reg  [7:0]  uart_rx_byte;
    reg         uart_rx_valid;
    integer     uart_char_count;
    
    // Test results
    integer     test_pass_count;
    integer     test_fail_count;
    integer     test_total_count;
    
    // Output buffer (Verilog-compatible byte array)
    reg [7:0] output_buffer [0:255];
    integer output_index;

    // -----------------------------------------------------------------------
    // DUT Instantiation
    // -----------------------------------------------------------------------
    tt_um_spark_mcu_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .portb_in   (portb_in),
        .portb_out  (portb_out),
        .portb_dir  (portb_dir),
        .portc_in   (portc_in),
        .portc_out  (portc_out),
        .portc_dir  (portc_dir),
        .portd_in   (portd_in),
        .portd_out  (portd_out),
        .portd_dir  (portd_dir),
        .uart_rxd   (uart_rxd),
        .uart_txd   (uart_txd),
        .spi_sck    (spi_sck),
        .spi_mosi   (spi_mosi),
        .spi_miso   (spi_miso),
        .spi_ss_n   (spi_ss_n),
        .t0_pin     (t0_pin),
        .oc0a_pin   (oc0a_pin),
        .oc0b_pin   (oc0b_pin),
        .int0_pin   (int0_pin),
        .int1_pin   (int1_pin),
        .prog_addr  (),
        .prog_data  (),
        .prog_wr    (),
        .debug_pc   (debug_pc),
        .debug_sreg (debug_sreg),
        .debug_state(debug_state)
    );

    // -----------------------------------------------------------------------
    // Clock Generation (16 MHz)
    // -----------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // -----------------------------------------------------------------------
    // Test Stimulation
    // -----------------------------------------------------------------------
    initial begin
        // Initialize signals
        rst_n       = 0;
        portb_in    = 8'h00;
        portc_in    = 6'h00;
        portd_in    = 8'h00;
        uart_rxd    = 1;           // UART idle state
        spi_miso    = 0;
        t0_pin      = 0;
        int0_pin    = 0;
        int1_pin    = 0;
        
        uart_char_count = 0;
        test_pass_count = 0;
        test_fail_count = 0;
        test_total_count = 0;
        output_index = 0;

        // Reset sequence
        #100 rst_n = 1;
        $display("[TB] System initialized, running tests...");
        $display("[TB] Time: %t", $time);
        $display("[TB] Initial PC: 0x%04h", debug_pc);

        // Monitor PC every 1ms
        fork
            // PC monitor process
            begin
                repeat (10000) begin
                    #1000000;  // 1ms in simulation
                    $display("[TB] PC @ %t: 0x%04h | UART chars: %d | PASS: %d | FAIL: %d", $time, debug_pc, uart_char_count, test_pass_count, test_fail_count);
                end
            end
            
            // Timeout process
            begin
                #SIM_TIME begin
                    if (test_fail_count > 0) begin
                        $display("\n[TB] ===== TEST RESULTS =====");
                        $display("[TB] PASS: %d", test_pass_count);
                        $display("[TB] FAIL: %d", test_fail_count);
                        $display("[TB] TOTAL: %d", test_total_count);
                        $display("[TB] TEST: FAILED");
                        $finish(1);
                    end else begin
                        $display("\n[TB] ===== TEST RESULTS =====");
                        $display("[TB] PASS: %d", test_pass_count);
                        $display("[TB] FAIL: %d", test_fail_count);
                        $display("[TB] TOTAL: %d", test_total_count);
                        $display("[TB] TEST: PASSED");
                        $finish(0);
                    end
                end
            end
        join
    end

    // -----------------------------------------------------------------------
    // UART Monitor (RX from DUT perspective, so TXD is our input)
    // -----------------------------------------------------------------------
    // Simple synchronous UART receiver
    reg uart_rxd_d1, uart_rxd_d2, uart_rxd_d3;
    reg [9:0] uart_shift_reg;
    reg [3:0] uart_bit_count;
    integer   uart_bit_timer;
    reg       uart_receiving;

    always @(posedge clk) begin
        // Synchronize uart_txd (3-stage pipeline)
        uart_rxd_d1 <= uart_txd;
        uart_rxd_d2 <= uart_rxd_d1;
        uart_rxd_d3 <= uart_rxd_d2;

        if (!uart_receiving) begin
            // Look for start bit (falling edge)
            if (uart_rxd_d3 && !uart_rxd_d2) begin
                uart_receiving <= 1;
                uart_bit_count <= 0;
                uart_bit_timer <= 0;
            end
        end else begin
            uart_bit_timer <= uart_bit_timer + 1;

            // Sample at baud period (approximately)
            // At 16 MHz: UART_PERIOD / CLK_PERIOD ≈ 1667 clocks per bit
            if (uart_bit_timer >= (UART_PERIOD / CLK_PERIOD) - 1) begin
                uart_bit_timer <= 0;
                uart_shift_reg[uart_bit_count] <= uart_rxd_d2;
                uart_bit_count <= uart_bit_count + 1;

                // Reception complete (start + 8 data bits + stop)
                if (uart_bit_count == 9) begin
                    uart_receiving <= 0;
                    uart_rx_byte <= uart_shift_reg[8:1];  // Extract 8 data bits
                    uart_rx_valid <= 1;

                    // DEBUG: Print all received bytes
                    if (uart_shift_reg[8:1] >= 32 && uart_shift_reg[8:1] < 127) begin
                        $write("%c", uart_shift_reg[8:1]);
                    end else if (uart_shift_reg[8:1] == 8'h0A) begin
                        $write("\n");
                    end else if (uart_shift_reg[8:1] == 8'h0D) begin
                        $write("\r");
                    end else begin
                        $display("[UART] Received byte: 0x%02h (dec %d)", uart_shift_reg[8:1], uart_shift_reg[8:1]);
                    end

                    process_uart_char(uart_shift_reg[8:1]);

                    uart_char_count <= uart_char_count + 1;
                end
            end
        end
    end

    // -----------------------------------------------------------------------
    // Process received character and detect test keywords
    // -----------------------------------------------------------------------
    task process_uart_char(input [7:0] char);
        begin
            // Printable ASCII range
            if (char >= 32 && char < 127) begin
                $write("%c", char);
                if (output_index < 256) begin
                    output_buffer[output_index] <= char;
                    output_index <= output_index + 1;
                end
            end else begin
                // Special characters
                case (char)
                    8'h0A: begin  // Line feed
                        parse_output_line();
                        output_index <= 0;
                        $write("\n");
                    end
                    8'h0D: $write("");  // Carriage return (suppress)
                    8'h09: $write("    ");  // Tab
                    default: ;
                endcase
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Parse output line for PASS/FAIL keywords (Pure Verilog)
    // -----------------------------------------------------------------------
    task parse_output_line();
        integer i, j;
        reg found_pass;
        reg found_fail;
        begin
            found_pass = 0;
            found_fail = 0;

            // Check for "PASS" substring (P=80, A=65, S=83)
            for (i = 0; i <= output_index - 4; i = i + 1) begin
                if (output_buffer[i] == 8'h50 && output_buffer[i+1] == 8'h41 &&
                    output_buffer[i+2] == 8'h53 && output_buffer[i+3] == 8'h53) begin
                    found_pass = 1;
                end
            end

            // Check for "FAIL" substring (F=70, A=65, I=73, L=76)
            for (i = 0; i <= output_index - 4; i = i + 1) begin
                if (output_buffer[i] == 8'h46 && output_buffer[i+1] == 8'h41 &&
                    output_buffer[i+2] == 8'h49 && output_buffer[i+3] == 8'h4C) begin
                    found_fail = 1;
                end
            end

            // Update counters
            if (found_pass && !found_fail) begin
                test_pass_count <= test_pass_count + 1;
                test_total_count <= test_total_count + 1;
                $display(" [PASS]");
            end else if (found_fail) begin
                test_fail_count <= test_fail_count + 1;
                test_total_count <= test_total_count + 1;
                $display(" [FAIL]");
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // GPIO Monitoring (for debug)
    // -----------------------------------------------------------------------
    initial begin
        forever begin
            @(posedge clk);
            // Optional: Add GPIO assertions here
        end
    end

    // -----------------------------------------------------------------------
    // Waveform Dumping (for debugging)
    // -----------------------------------------------------------------------
    initial begin
        // Uncomment to generate VCD file for waveform viewing
        // $dumpfile("spark_mcu_test.vcd");
        // $dumpvars(0, spark_mcu_test_tb);
    end

    // -----------------------------------------------------------------------
    // Timeout Monitor
    // -----------------------------------------------------------------------
    initial begin
        #SIM_TIME begin
            $display("[TB] ERROR: Simulation timeout - test did not complete");
            $finish(1);
        end
    end

endmodule
