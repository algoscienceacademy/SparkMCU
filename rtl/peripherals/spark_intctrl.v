// ============================================================================
// SparkMCU - Interrupt Controller (ATmega328P compatible)
// ============================================================================
// Manages external interrupts (INT0, INT1) and pin change interrupts
// Provides interrupt flag and mask registers
// Aggregates all peripheral interrupt sources
// ============================================================================

module spark_intctrl (
    input  wire        clk,
    input  wire        rst_n,

    // I/O bus interface
    input  wire [5:0]  io_addr,
    input  wire [7:0]  io_wdata,
    output reg  [7:0]  io_rdata,
    input  wire        io_rd,
    input  wire        io_wr,

    // External interrupt pins
    input  wire        int0_pin,
    input  wire        int1_pin,

    // Pin change interrupt inputs (from GPIO)
    input  wire        pcint_b,     // Port B pin change
    input  wire        pcint_c,     // Port C pin change
    input  wire        pcint_d,     // Port D pin change

    // Timer interrupts
    input  wire        tmr0_ov,
    input  wire        tmr0_compa,
    input  wire        tmr0_compb,

    // UART interrupts
    input  wire        uart_rxc,
    input  wire        uart_udre,
    input  wire        uart_txc,

    // SPI interrupt
    input  wire        spi_stc,

    // CPU interrupt acknowledge
    input  wire        irq_ack,
    input  wire [4:0]  irq_ack_num,

    // Aggregated interrupt output to CPU
    output wire [20:0] irq_lines
);

    // -----------------------------------------------------------------------
    // External Interrupt Control
    // -----------------------------------------------------------------------

    // EIMSK: [-, -, -, -, -, -, INT1, INT0]
    reg        int0_en;
    reg        int1_en;

    // EIFR: [-, -, -, -, -, -, INTF1, INTF0]
    reg        intf0;
    reg        intf1;

    // EICRA: [-, -, -, -, ISC11, ISC10, ISC01, ISC00]  (extended I/O, simplified)
    reg [1:0]  isc0;     // INT0 sense control
    reg [1:0]  isc1;     // INT1 sense control

    // PCIFR: [-, -, -, -, -, PCIF2, PCIF1, PCIF0]
    reg        pcif0, pcif1, pcif2;

    // PCICR: [-, -, -, -, -, PCIE2, PCIE1, PCIE0]
    reg        pcie0, pcie1, pcie2;

    // INT0/INT1 synchronizers
    reg        int0_sync1, int0_sync2, int0_prev;
    reg        int1_sync1, int1_sync2, int1_prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int0_sync1 <= 1'b0; int0_sync2 <= 1'b0; int0_prev <= 1'b0;
            int1_sync1 <= 1'b0; int1_sync2 <= 1'b0; int1_prev <= 1'b0;
        end else begin
            int0_sync1 <= int0_pin; int0_sync2 <= int0_sync1;
            int1_sync1 <= int1_pin; int1_sync2 <= int1_sync1;
            int0_prev <= int0_sync2;
            int1_prev <= int1_sync2;
        end
    end

    // Edge/level detection for INT0
    wire int0_trigger;
    assign int0_trigger = (isc0 == 2'b00) ? 1'b0 :              // Low level (not edge)
                          (isc0 == 2'b01) ? (int0_sync2 ^ int0_prev) :  // Any edge
                          (isc0 == 2'b10) ? (int0_prev & ~int0_sync2) :  // Falling edge
                          (~int0_prev & int0_sync2);                      // Rising edge

    wire int1_trigger;
    assign int1_trigger = (isc1 == 2'b00) ? 1'b0 :
                          (isc1 == 2'b01) ? (int1_sync2 ^ int1_prev) :
                          (isc1 == 2'b10) ? (int1_prev & ~int1_sync2) :
                          (~int1_prev & int1_sync2);

    // Level interrupt for ISC=00
    wire int0_level = (isc0 == 2'b00) & ~int0_sync2;
    wire int1_level = (isc1 == 2'b00) & ~int1_sync2;

    // Flag management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intf0 <= 1'b0;
            intf1 <= 1'b0;
            pcif0 <= 1'b0;
            pcif1 <= 1'b0;
            pcif2 <= 1'b0;
        end else begin
            // Set flags on trigger
            if (int0_trigger) intf0 <= 1'b1;
            if (int1_trigger) intf1 <= 1'b1;
            if (pcint_b)      pcif0 <= 1'b1;
            if (pcint_c)      pcif1 <= 1'b1;
            if (pcint_d)      pcif2 <= 1'b1;

            // Clear on acknowledge
            if (irq_ack) begin
                case (irq_ack_num)
                    5'd1: intf0 <= 1'b0;
                    5'd2: intf1 <= 1'b0;
                    5'd3: pcif0 <= 1'b0;
                    5'd4: pcif1 <= 1'b0;
                    5'd5: pcif2 <= 1'b0;
                endcase
            end

            // Clear on write-1
            if (io_wr && io_addr == 6'h1C) begin
                if (io_wdata[0]) intf0 <= 1'b0;
                if (io_wdata[1]) intf1 <= 1'b0;
            end
            if (io_wr && io_addr == 6'h1B) begin
                if (io_wdata[0]) pcif0 <= 1'b0;
                if (io_wdata[1]) pcif1 <= 1'b0;
                if (io_wdata[2]) pcif2 <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Interrupt line aggregation
    // -----------------------------------------------------------------------
    // AVR interrupt vector order (0-based index in irq_lines):
    //  0: INT0      1: INT1      2: PCINT0    3: PCINT1    4: PCINT2
    //  5: WDT       6: TIMER2_COMPA  7: TIMER2_COMPB  8: TIMER2_OVF
    //  9: TIMER1_CAPT  10: TIMER1_COMPA  11: TIMER1_COMPB  12: TIMER1_OVF
    // 13: TIMER0_COMPA  14: TIMER0_COMPB  15: TIMER0_OVF
    // 16: SPI_STC   17: USART_RXC   18: USART_UDRE   19: USART_TXC
    // 20: Reserved

    assign irq_lines[0]  = (intf0 & int0_en) | (int0_level & int0_en);
    assign irq_lines[1]  = (intf1 & int1_en) | (int1_level & int1_en);
    assign irq_lines[2]  = pcif0 & pcie0;
    assign irq_lines[3]  = pcif1 & pcie1;
    assign irq_lines[4]  = pcif2 & pcie2;
    assign irq_lines[5]  = 1'b0;            // WDT (not implemented)
    assign irq_lines[6]  = 1'b0;            // TIMER2_COMPA (not implemented)
    assign irq_lines[7]  = 1'b0;            // TIMER2_COMPB
    assign irq_lines[8]  = 1'b0;            // TIMER2_OVF
    assign irq_lines[9]  = 1'b0;            // TIMER1_CAPT
    assign irq_lines[10] = 1'b0;            // TIMER1_COMPA
    assign irq_lines[11] = 1'b0;            // TIMER1_COMPB
    assign irq_lines[12] = 1'b0;            // TIMER1_OVF
    assign irq_lines[13] = tmr0_compa;
    assign irq_lines[14] = tmr0_compb;
    assign irq_lines[15] = tmr0_ov;
    assign irq_lines[16] = spi_stc;
    assign irq_lines[17] = uart_rxc;
    assign irq_lines[18] = uart_udre;
    assign irq_lines[19] = uart_txc;
    assign irq_lines[20] = 1'b0;

    // -----------------------------------------------------------------------
    // Register read
    // -----------------------------------------------------------------------
    always @(*) begin
        io_rdata = 8'h00;
        if (io_rd) begin
            case (io_addr)
                6'h1B: io_rdata = {5'b0, pcif2, pcif1, pcif0};   // PCIFR
                6'h1C: io_rdata = {6'b0, intf1, intf0};           // EIFR
                6'h1D: io_rdata = {6'b0, int1_en, int0_en};      // EIMSK
                default: io_rdata = 8'h00;
            endcase
        end
    end

    // Register write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int0_en <= 1'b0;
            int1_en <= 1'b0;
            isc0    <= 2'b00;
            isc1    <= 2'b00;
            pcie0   <= 1'b0;
            pcie1   <= 1'b0;
            pcie2   <= 1'b0;
        end else if (io_wr) begin
            case (io_addr)
                6'h1D: begin  // EIMSK
                    int0_en <= io_wdata[0];
                    int1_en <= io_wdata[1];
                end
                // PCICR would be at extended I/O, simplified here
                6'h1B: begin
                    pcie0 <= io_wdata[0];
                    pcie1 <= io_wdata[1];
                    pcie2 <= io_wdata[2];
                end
            endcase
        end
    end

endmodule
