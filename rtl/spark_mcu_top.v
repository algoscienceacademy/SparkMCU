// ============================================================================
// SparkMCU - Top-Level SoC Integration
// ============================================================================
// AVR-Compatible 8-bit Microcontroller SoC
// Target: SkyWater 130nm (sky130A) via OpenLane
// ============================================================================
//
// Features:
//   - AVR CPU core (ATmega328P ISA compatible)
//   - 32KB Program Memory (Flash)
//   - 2KB Data SRAM
//   - 32 x 8-bit General Purpose Registers
//   - GPIO Ports B, C, D
//   - UART (USART0)
//   - SPI Master
//   - 8-bit Timer/Counter 0 with PWM
//   - External Interrupt Controller (INT0, INT1, PCINT)
//
// Pin Mapping:
//   Port B: PB[7:0] - 8 GPIO pins
//   Port C: PC[5:0] - 6 GPIO pins (PC6 = RESET)
//   Port D: PD[7:0] - 8 GPIO pins
//   UART:   RXD, TXD
//   SPI:    SCK, MOSI, MISO, SS_N
//   Timer:  T0 (external clock), OC0A, OC0B (PWM outputs)
//   Misc:   INT0, INT1 (external interrupts)
//
// ============================================================================

module spark_mcu_top (
    input  wire        clk,          // System clock
    input  wire        rst_n,        // Active-low reset

    // GPIO Port B
    input  wire [7:0]  portb_in,
    output wire [7:0]  portb_out,
    output wire [7:0]  portb_dir,

    // GPIO Port C (6 bits)
    input  wire [5:0]  portc_in,
    output wire [5:0]  portc_out,
    output wire [5:0]  portc_dir,

    // GPIO Port D
    input  wire [7:0]  portd_in,
    output wire [7:0]  portd_out,
    output wire [7:0]  portd_dir,

    // UART
    input  wire        uart_rxd,
    output wire        uart_txd,

    // SPI
    output wire        spi_sck,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        spi_ss_n,

    // Timer external
    input  wire        t0_pin,
    output wire        oc0a_pin,
    output wire        oc0b_pin,

    // External interrupts
    input  wire        int0_pin,
    input  wire        int1_pin,

    // Programming interface (for loading firmware)
    input  wire [13:0] prog_addr,
    input  wire [15:0] prog_data,
    input  wire        prog_wr,

    // Debug outputs
    output wire [15:0] debug_pc,
    output wire [7:0]  debug_sreg,
    output wire [2:0]  debug_state
);

    // -----------------------------------------------------------------------
    // Internal wires
    // -----------------------------------------------------------------------

    // CPU <-> Program Memory
    wire [15:0] pm_addr;
    wire [15:0] pm_data;
    wire        pm_rd;

    // CPU <-> Data Memory
    wire [15:0] dm_addr;
    wire [7:0]  dm_wdata;
    wire [7:0]  dm_rdata;
    wire        dm_rd;
    wire        dm_wr;

    // CPU <-> I/O Bus
    wire [5:0]  io_addr;
    wire [7:0]  io_wdata;
    wire [7:0]  io_rdata;
    wire        io_rd;
    wire        io_wr;

    // CPU <-> Extended I/O Bus
    wire [7:0]  eio_addr;
    wire [7:0]  eio_wdata;
    wire [7:0]  eio_rdata;
    wire        eio_rd;
    wire        eio_wr;

    // CPU <-> Interrupt Controller
    wire [20:0] irq_lines;
    wire        irq_ack;
    wire [4:0]  irq_ack_num;

    // Bus Controller <-> SRAM
    wire [15:0] sram_addr;
    wire [7:0]  sram_wdata;
    wire [7:0]  sram_rdata;
    wire        sram_rd;
    wire        sram_wr;

    // Bus Controller <-> GPIO B
    wire [5:0]  gpio_b_addr;
    wire [7:0]  gpio_b_wdata;
    wire [7:0]  gpio_b_rdata;
    wire        gpio_b_rd;
    wire        gpio_b_wr;

    // Bus Controller <-> GPIO C
    wire [5:0]  gpio_c_addr;
    wire [7:0]  gpio_c_wdata;
    wire [7:0]  gpio_c_rdata;
    wire        gpio_c_rd;
    wire        gpio_c_wr;

    // Bus Controller <-> GPIO D
    wire [5:0]  gpio_d_addr;
    wire [7:0]  gpio_d_wdata;
    wire [7:0]  gpio_d_rdata;
    wire        gpio_d_rd;
    wire        gpio_d_wr;

    // Bus Controller <-> Timer0
    wire [5:0]  tmr0_addr;
    wire [7:0]  tmr0_wdata;
    wire [7:0]  tmr0_rdata;
    wire        tmr0_rd;
    wire        tmr0_wr;

    // Bus Controller <-> UART
    wire [7:0]  uart_addr;
    wire [7:0]  uart_wdata;
    wire [7:0]  uart_rdata;
    wire        uart_rd;
    wire        uart_wr;

    // Bus Controller <-> SPI
    wire [5:0]  spi_addr;
    wire [7:0]  spi_wdata;
    wire [7:0]  spi_rdata;
    wire        spi_rd;
    wire        spi_wr;

    // Bus Controller <-> Interrupt Controller
    wire [5:0]  intc_addr;
    wire [7:0]  intc_wdata;
    wire [7:0]  intc_rdata;
    wire        intc_rd;
    wire        intc_wr;

    // Timer interrupt wires
    wire        tmr0_ov;
    wire        tmr0_compa;
    wire        tmr0_compb;

    // UART interrupt wires
    wire        uart_irq_rxc;
    wire        uart_irq_udre;
    wire        uart_irq_txc;

    // SPI interrupt wire
    wire        spi_irq;

    // Pin change interrupt wires
    wire        pcint_b, pcint_c, pcint_d;

    // -----------------------------------------------------------------------
    // CPU Core
    // -----------------------------------------------------------------------
    spark_cpu u_cpu (
        .clk          (clk),
        .rst_n        (rst_n),
        .pm_addr      (pm_addr),
        .pm_data      (pm_data),
        .pm_rd        (pm_rd),
        .dm_addr      (dm_addr),
        .dm_wdata     (dm_wdata),
        .dm_rdata     (dm_rdata),
        .dm_rd        (dm_rd),
        .dm_wr        (dm_wr),
        .io_addr      (io_addr),
        .io_wdata     (io_wdata),
        .io_rdata     (io_rdata),
        .io_rd        (io_rd),
        .io_wr        (io_wr),
        .eio_addr     (eio_addr),
        .eio_wdata    (eio_wdata),
        .eio_rdata    (eio_rdata),
        .eio_rd       (eio_rd),
        .eio_wr       (eio_wr),
        .irq_lines    (irq_lines),
        .irq_ack      (irq_ack),
        .irq_ack_num  (irq_ack_num),
        .debug_pc     (debug_pc),
        .debug_sreg   (debug_sreg),
        .debug_state  (debug_state)
    );

    // -----------------------------------------------------------------------
    // Program Memory (reduced size for ASIC synthesis bring-up)
    // -----------------------------------------------------------------------
    spark_pmem #(
        .DEPTH (256),
        .AW    (8)
    ) u_pmem (
        .clk       (clk),
        .rst_n     (rst_n),
        .addr      (pm_addr[7:0]),
        .rdata     (pm_data),
        .rd_en     (pm_rd),
        .prog_addr (prog_addr[7:0]),
        .prog_data (prog_data),
        .prog_wr   (prog_wr)
    );

    // -----------------------------------------------------------------------
    // Data SRAM (reduced size for ASIC synthesis bring-up)
    // -----------------------------------------------------------------------
    spark_dmem #(
        .DEPTH (128),
        .AW    (7)
    ) u_dmem (
        .clk   (clk),
        .rst_n (rst_n),
        .addr  (sram_addr),
        .wdata (sram_wdata),
        .rdata (sram_rdata),
        .rd_en (sram_rd),
        .wr_en (sram_wr)
    );

    // -----------------------------------------------------------------------
    // Bus Controller
    // -----------------------------------------------------------------------
    spark_bus_ctrl u_bus_ctrl (
        .clk           (clk),
        .rst_n         (rst_n),
        .cpu_dm_addr   (dm_addr),
        .cpu_dm_wdata  (dm_wdata),
        .cpu_dm_rdata  (dm_rdata),
        .cpu_dm_rd     (dm_rd),
        .cpu_dm_wr     (dm_wr),
        .cpu_io_addr   (io_addr),
        .cpu_io_wdata  (io_wdata),
        .cpu_io_rdata  (io_rdata),
        .cpu_io_rd     (io_rd),
        .cpu_io_wr     (io_wr),
        .cpu_eio_addr  (eio_addr),
        .cpu_eio_wdata (eio_wdata),
        .cpu_eio_rdata (eio_rdata),
        .cpu_eio_rd    (eio_rd),
        .cpu_eio_wr    (eio_wr),
        .sram_addr     (sram_addr),
        .sram_wdata    (sram_wdata),
        .sram_rdata    (sram_rdata),
        .sram_rd       (sram_rd),
        .sram_wr       (sram_wr),
        .gpio_b_addr   (gpio_b_addr),
        .gpio_b_wdata  (gpio_b_wdata),
        .gpio_b_rdata  (gpio_b_rdata),
        .gpio_b_rd     (gpio_b_rd),
        .gpio_b_wr     (gpio_b_wr),
        .gpio_c_addr   (gpio_c_addr),
        .gpio_c_wdata  (gpio_c_wdata),
        .gpio_c_rdata  (gpio_c_rdata),
        .gpio_c_rd     (gpio_c_rd),
        .gpio_c_wr     (gpio_c_wr),
        .gpio_d_addr   (gpio_d_addr),
        .gpio_d_wdata  (gpio_d_wdata),
        .gpio_d_rdata  (gpio_d_rdata),
        .gpio_d_rd     (gpio_d_rd),
        .gpio_d_wr     (gpio_d_wr),
        .tmr0_addr     (tmr0_addr),
        .tmr0_wdata    (tmr0_wdata),
        .tmr0_rdata    (tmr0_rdata),
        .tmr0_rd       (tmr0_rd),
        .tmr0_wr       (tmr0_wr),
        .uart_addr     (uart_addr),
        .uart_wdata    (uart_wdata),
        .uart_rdata    (uart_rdata),
        .uart_rd       (uart_rd),
        .uart_wr       (uart_wr),
        .spi_addr      (spi_addr),
        .spi_wdata     (spi_wdata),
        .spi_rdata     (spi_rdata),
        .spi_rd        (spi_rd),
        .spi_wr        (spi_wr),
        .intc_addr     (intc_addr),
        .intc_wdata    (intc_wdata),
        .intc_rdata    (intc_rdata),
        .intc_rd       (intc_rd),
        .intc_wr       (intc_wr)
    );

    // -----------------------------------------------------------------------
    // GPIO Port B (8-bit)
    // -----------------------------------------------------------------------
    wire [7:0] portb_out_internal;
    wire [7:0] portb_dir_internal;

    spark_gpio #(
        .PORT_WIDTH (8),
        .PIN_ADDR   (6'h03),
        .DDR_ADDR   (6'h04),
        .PORT_ADDR  (6'h05)
    ) u_gpio_b (
        .clk      (clk),
        .rst_n    (rst_n),
        .io_addr  (gpio_b_addr),
        .io_wdata (gpio_b_wdata),
        .io_rdata (gpio_b_rdata),
        .io_rd    (gpio_b_rd),
        .io_wr    (gpio_b_wr),
        .pin_in   (portb_in),
        .pin_out  (portb_out_internal),
        .pin_dir  (portb_dir_internal),
        .pcint    (pcint_b)
    );

    assign portb_out = portb_out_internal;
    assign portb_dir = portb_dir_internal;

    // -----------------------------------------------------------------------
    // GPIO Port C (6-bit)
    // -----------------------------------------------------------------------
    wire [5:0] portc_out_internal;
    wire [5:0] portc_dir_internal;

    spark_gpio #(
        .PORT_WIDTH (6),
        .PIN_ADDR   (6'h06),
        .DDR_ADDR   (6'h07),
        .PORT_ADDR  (6'h08)
    ) u_gpio_c (
        .clk      (clk),
        .rst_n    (rst_n),
        .io_addr  (gpio_c_addr),
        .io_wdata (gpio_c_wdata),
        .io_rdata (gpio_c_rdata),
        .io_rd    (gpio_c_rd),
        .io_wr    (gpio_c_wr),
        .pin_in   (portc_in),
        .pin_out  (portc_out_internal),
        .pin_dir  (portc_dir_internal),
        .pcint    (pcint_c)
    );

    assign portc_out = portc_out_internal;
    assign portc_dir = portc_dir_internal;

    // -----------------------------------------------------------------------
    // GPIO Port D (8-bit)
    // -----------------------------------------------------------------------
    wire [7:0] portd_out_internal;
    wire [7:0] portd_dir_internal;

    spark_gpio #(
        .PORT_WIDTH (8),
        .PIN_ADDR   (6'h09),
        .DDR_ADDR   (6'h0A),
        .PORT_ADDR  (6'h0B)
    ) u_gpio_d (
        .clk      (clk),
        .rst_n    (rst_n),
        .io_addr  (gpio_d_addr),
        .io_wdata (gpio_d_wdata),
        .io_rdata (gpio_d_rdata),
        .io_rd    (gpio_d_rd),
        .io_wr    (gpio_d_wr),
        .pin_in   (portd_in),
        .pin_out  (portd_out_internal),
        .pin_dir  (portd_dir_internal),
        .pcint    (pcint_d)
    );

    assign portd_out = portd_out_internal;
    assign portd_dir = portd_dir_internal;

    // -----------------------------------------------------------------------
    // UART (USART0)
    // -----------------------------------------------------------------------
    spark_uart u_uart (
        .clk       (clk),
        .rst_n     (rst_n),
        .io_addr   (uart_addr),
        .io_wdata  (uart_wdata),
        .io_rdata  (uart_rdata),
        .io_rd     (uart_rd),
        .io_wr     (uart_wr),
        .rxd       (uart_rxd),
        .txd       (uart_txd),
        .irq_rxc   (uart_irq_rxc),
        .irq_udre  (uart_irq_udre),
        .irq_txc   (uart_irq_txc)
    );

    // -----------------------------------------------------------------------
    // SPI
    // -----------------------------------------------------------------------
    spark_spi u_spi (
        .clk     (clk),
        .rst_n   (rst_n),
        .io_addr (spi_addr),
        .io_wdata(spi_wdata),
        .io_rdata(spi_rdata),
        .io_rd   (spi_rd),
        .io_wr   (spi_wr),
        .sck     (spi_sck),
        .mosi    (spi_mosi),
        .miso    (spi_miso),
        .ss_n    (spi_ss_n),
        .irq_spi (spi_irq)
    );

    // -----------------------------------------------------------------------
    // Timer/Counter 0
    // -----------------------------------------------------------------------
    spark_timer0 u_timer0 (
        .clk        (clk),
        .rst_n      (rst_n),
        .io_addr    (tmr0_addr),
        .io_wdata   (tmr0_wdata),
        .io_rdata   (tmr0_rdata),
        .io_rd      (tmr0_rd),
        .io_wr      (tmr0_wr),
        .t0_pin     (t0_pin),
        .oc0a       (oc0a_pin),
        .oc0b       (oc0b_pin),
        .irq_ov     (tmr0_ov),
        .irq_compa  (tmr0_compa),
        .irq_compb  (tmr0_compb)
    );

    // -----------------------------------------------------------------------
    // Interrupt Controller
    // -----------------------------------------------------------------------
    spark_intctrl u_intctrl (
        .clk         (clk),
        .rst_n       (rst_n),
        .io_addr     (intc_addr),
        .io_wdata    (intc_wdata),
        .io_rdata    (intc_rdata),
        .io_rd       (intc_rd),
        .io_wr       (intc_wr),
        .int0_pin    (int0_pin),
        .int1_pin    (int1_pin),
        .pcint_b     (pcint_b),
        .pcint_c     (pcint_c),
        .pcint_d     (pcint_d),
        .tmr0_ov     (tmr0_ov),
        .tmr0_compa  (tmr0_compa),
        .tmr0_compb  (tmr0_compb),
        .uart_rxc    (uart_irq_rxc),
        .uart_udre   (uart_irq_udre),
        .uart_txc    (uart_irq_txc),
        .spi_stc     (spi_irq),
        .irq_ack     (irq_ack),
        .irq_ack_num (irq_ack_num),
        .irq_lines   (irq_lines)
    );

endmodule
