// ============================================================================
// SparkMCU - Data Bus Controller / Memory Mapper
// ============================================================================
// Routes data memory accesses to the correct target:
//   0x0000 - 0x001F : Register File (handled by CPU internally)
//   0x0020 - 0x005F : I/O Registers
//   0x0060 - 0x00FF : Extended I/O Registers
//   0x0100 - 0x08FF : SRAM (2KB)
// ============================================================================

module spark_bus_ctrl (
    input  wire        clk,
    input  wire        rst_n,

    // CPU data memory interface
    input  wire [15:0] cpu_dm_addr,
    input  wire [7:0]  cpu_dm_wdata,
    output reg  [7:0]  cpu_dm_rdata,
    input  wire        cpu_dm_rd,
    input  wire        cpu_dm_wr,

    // CPU I/O interface
    input  wire [5:0]  cpu_io_addr,
    input  wire [7:0]  cpu_io_wdata,
    output reg  [7:0]  cpu_io_rdata,
    input  wire        cpu_io_rd,
    input  wire        cpu_io_wr,

    // CPU Extended I/O interface
    input  wire [7:0]  cpu_eio_addr,
    input  wire [7:0]  cpu_eio_wdata,
    output reg  [7:0]  cpu_eio_rdata,
    input  wire        cpu_eio_rd,
    input  wire        cpu_eio_wr,

    // SRAM interface
    output wire [15:0] sram_addr,
    output wire [7:0]  sram_wdata,
    input  wire [7:0]  sram_rdata,
    output wire        sram_rd,
    output wire        sram_wr,

    // GPIO Port B
    output reg  [5:0]  gpio_b_addr,
    output reg  [7:0]  gpio_b_wdata,
    input  wire [7:0]  gpio_b_rdata,
    output reg         gpio_b_rd,
    output reg         gpio_b_wr,

    // GPIO Port C
    output reg  [5:0]  gpio_c_addr,
    output reg  [7:0]  gpio_c_wdata,
    input  wire [7:0]  gpio_c_rdata,
    output reg         gpio_c_rd,
    output reg         gpio_c_wr,

    // GPIO Port D
    output reg  [5:0]  gpio_d_addr,
    output reg  [7:0]  gpio_d_wdata,
    input  wire [7:0]  gpio_d_rdata,
    output reg         gpio_d_rd,
    output reg         gpio_d_wr,

    // Timer0
    output reg  [5:0]  tmr0_addr,
    output reg  [7:0]  tmr0_wdata,
    input  wire [7:0]  tmr0_rdata,
    output reg         tmr0_rd,
    output reg         tmr0_wr,

    // UART
    output reg  [7:0]  uart_addr,
    output reg  [7:0]  uart_wdata,
    input  wire [7:0]  uart_rdata,
    output reg         uart_rd,
    output reg         uart_wr,

    // SPI
    output reg  [5:0]  spi_addr,
    output reg  [7:0]  spi_wdata,
    input  wire [7:0]  spi_rdata,
    output reg         spi_rd,
    output reg         spi_wr,

    // Interrupt control
    output reg  [5:0]  intc_addr,
    output reg  [7:0]  intc_wdata,
    input  wire [7:0]  intc_rdata,
    output reg         intc_rd,
    output reg         intc_wr
);

    // Internal decode signals for Timer0 from standard I/O and extended I/O
    reg [5:0] tmr0_addr_io;
    reg [7:0] tmr0_wdata_io;
    reg       tmr0_rd_io;
    reg       tmr0_wr_io;

    reg [5:0] tmr0_addr_eio;
    reg [7:0] tmr0_wdata_eio;
    reg       tmr0_rd_eio;
    reg       tmr0_wr_eio;

    // SRAM direct connections
    assign sram_addr  = cpu_dm_addr;
    assign sram_wdata = cpu_dm_wdata;
    assign sram_rd    = cpu_dm_rd && (cpu_dm_addr >= 16'h0100);
    assign sram_wr    = cpu_dm_wr && (cpu_dm_addr >= 16'h0100);

    // I/O address decode for standard I/O space (0x00-0x3F via io_addr)
    always @(*) begin
        // Default
        gpio_b_addr = 6'h00; gpio_b_wdata = 8'h00; gpio_b_rd = 1'b0; gpio_b_wr = 1'b0;
        gpio_c_addr = 6'h00; gpio_c_wdata = 8'h00; gpio_c_rd = 1'b0; gpio_c_wr = 1'b0;
        gpio_d_addr = 6'h00; gpio_d_wdata = 8'h00; gpio_d_rd = 1'b0; gpio_d_wr = 1'b0;
        tmr0_addr_io = 6'h00; tmr0_wdata_io = 8'h00; tmr0_rd_io = 1'b0; tmr0_wr_io = 1'b0;
        spi_addr    = 6'h00; spi_wdata    = 8'h00; spi_rd    = 1'b0; spi_wr    = 1'b0;
        intc_addr   = 6'h00; intc_wdata   = 8'h00; intc_rd   = 1'b0; intc_wr   = 1'b0;

        cpu_io_rdata = 8'h00;

        if (cpu_io_rd || cpu_io_wr) begin
            case (cpu_io_addr)
                // Port B (PINB=0x03, DDRB=0x04, PORTB=0x05)
                6'h03, 6'h04, 6'h05: begin
                    gpio_b_addr  = cpu_io_addr;
                    gpio_b_wdata = cpu_io_wdata;
                    gpio_b_rd    = cpu_io_rd;
                    gpio_b_wr    = cpu_io_wr;
                    cpu_io_rdata = gpio_b_rdata;
                end

                // Port C (PINC=0x06, DDRC=0x07, PORTC=0x08)
                6'h06, 6'h07, 6'h08: begin
                    gpio_c_addr  = cpu_io_addr;
                    gpio_c_wdata = cpu_io_wdata;
                    gpio_c_rd    = cpu_io_rd;
                    gpio_c_wr    = cpu_io_wr;
                    cpu_io_rdata = gpio_c_rdata;
                end

                // Port D (PIND=0x09, DDRD=0x0A, PORTD=0x0B)
                6'h09, 6'h0A, 6'h0B: begin
                    gpio_d_addr  = cpu_io_addr;
                    gpio_d_wdata = cpu_io_wdata;
                    gpio_d_rd    = cpu_io_rd;
                    gpio_d_wr    = cpu_io_wr;
                    cpu_io_rdata = gpio_d_rdata;
                end

                // Timer0 (TIFR0=0x15, TCCR0A=0x24, TCCR0B=0x25, TCNT0=0x26, OCR0A=0x27, OCR0B=0x28)
                6'h15, 6'h24, 6'h25, 6'h26, 6'h27, 6'h28: begin
                    tmr0_addr_io  = cpu_io_addr;
                    tmr0_wdata_io = cpu_io_wdata;
                    tmr0_rd_io    = cpu_io_rd;
                    tmr0_wr_io    = cpu_io_wr;
                    cpu_io_rdata = tmr0_rdata;
                end

                // SPI (SPCR=0x2C, SPSR=0x2D, SPDR=0x2E)
                6'h2C, 6'h2D, 6'h2E: begin
                    spi_addr   = cpu_io_addr;
                    spi_wdata  = cpu_io_wdata;
                    spi_rd     = cpu_io_rd;
                    spi_wr     = cpu_io_wr;
                    cpu_io_rdata = spi_rdata;
                end

                // Interrupt flags/masks (PCIFR=0x1B, EIFR=0x1C, EIMSK=0x1D)
                6'h1B, 6'h1C, 6'h1D: begin
                    intc_addr  = cpu_io_addr;
                    intc_wdata = cpu_io_wdata;
                    intc_rd    = cpu_io_rd;
                    intc_wr    = cpu_io_wr;
                    cpu_io_rdata = intc_rdata;
                end

                default: begin
                    cpu_io_rdata = 8'h00;
                end
            endcase
        end
    end

    // Extended I/O address decode (UART at 0xC0-0xC6, TIMSK at 0x6E-0x70)
    always @(*) begin
        uart_addr   = 8'h00; uart_wdata  = 8'h00; uart_rd   = 1'b0; uart_wr   = 1'b0;
        tmr0_addr_eio = 6'h00; tmr0_wdata_eio = 8'h00; tmr0_rd_eio = 1'b0; tmr0_wr_eio = 1'b0;
        cpu_eio_rdata = 8'h00;

        if (cpu_eio_rd || cpu_eio_wr) begin
            // UART registers (absolute 0xC0-0xC6)
            if (cpu_eio_addr >= 8'h80 && cpu_eio_addr <= 8'h86) begin
                uart_addr  = cpu_eio_addr;
                uart_wdata = cpu_eio_wdata;
                uart_rd    = cpu_eio_rd;
                uart_wr    = cpu_eio_wr;
                cpu_eio_rdata = uart_rdata;
            end
            // Timer masks (TIMSK0=0x6E, TIMSK1=0x6F, TIMSK2=0x70)
            else if (cpu_eio_addr >= 8'h6E && cpu_eio_addr <= 8'h70) begin
                tmr0_addr_eio  = cpu_eio_addr[5:0];
                tmr0_wdata_eio = cpu_eio_wdata;
                tmr0_rd_eio    = cpu_eio_rd;
                tmr0_wr_eio    = cpu_eio_wr;
                cpu_eio_rdata = tmr0_rdata;
            end
        end
    end

    // Timer0 output mux (single driver)
    always @(*) begin
        tmr0_addr  = tmr0_addr_io;
        tmr0_wdata = tmr0_wdata_io;
        tmr0_rd    = tmr0_rd_io;
        tmr0_wr    = tmr0_wr_io;

        if (tmr0_rd_eio || tmr0_wr_eio) begin
            tmr0_addr  = tmr0_addr_eio;
            tmr0_wdata = tmr0_wdata_eio;
            tmr0_rd    = tmr0_rd_eio;
            tmr0_wr    = tmr0_wr_eio;
        end
    end

    // Data memory read mux
    always @(*) begin
        if (cpu_dm_addr >= 16'h0100)
            cpu_dm_rdata = sram_rdata;
        else if (cpu_dm_addr >= 16'h0060)
            cpu_dm_rdata = cpu_eio_rdata;
        else if (cpu_dm_addr >= 16'h0020)
            cpu_dm_rdata = cpu_io_rdata;
        else
            cpu_dm_rdata = 8'h00; // Register file handled internally
    end

endmodule
