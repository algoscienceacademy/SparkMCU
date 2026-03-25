// ============================================================================
// SparkMCU - SPI Master/Slave Module (ATmega328P compatible)
// ============================================================================
// Features:
//   - Master and Slave modes
//   - Configurable clock polarity (CPOL) and phase (CPHA)
//   - Configurable bit order (MSB/LSB first)
//   - 4 prescaler settings + 2x speed
//   - SPI Transfer Complete interrupt
// ============================================================================
// Register Map:
//   SPCR (0x2C) : SPI Control Register
//   SPSR (0x2D) : SPI Status Register
//   SPDR (0x2E) : SPI Data Register
// ============================================================================

module spark_spi (
    input  wire        clk,
    input  wire        rst_n,

    // I/O bus interface
    input  wire [5:0]  io_addr,
    input  wire [7:0]  io_wdata,
    output reg  [7:0]  io_rdata,
    input  wire        io_rd,
    input  wire        io_wr,

    // SPI pins
    output reg         sck,        // SPI Clock
    output reg         mosi,       // Master Out, Slave In
    input  wire        miso,       // Master In, Slave Out
    output reg         ss_n,       // Slave Select (active low)

    // Interrupt output
    output wire        irq_spi     // SPI Transfer Complete interrupt
);

    // -----------------------------------------------------------------------
    // Register definitions
    // -----------------------------------------------------------------------

    // SPCR bits
    reg        spie;     // [7] SPI Interrupt Enable
    reg        spe;      // [6] SPI Enable
    reg        dord;     // [5] Data Order (0=MSB first, 1=LSB first)
    reg        mstr;     // [4] Master/Slave Select
    reg        cpol;     // [3] Clock Polarity
    reg        cpha;     // [2] Clock Phase
    reg [1:0]  spr;      // [1:0] Clock Rate Select

    // SPSR bits
    reg        spif;     // [7] SPI Interrupt Flag
    reg        wcol;     // [6] Write Collision Flag
    reg        spi2x;   // [0] Double SPI Speed

    // Data registers
    reg [7:0]  spi_data_out;
    reg [7:0]  spi_data_in;
    reg [7:0]  shift_reg;

    // Interrupt
    assign irq_spi = spif & spie;

    // -----------------------------------------------------------------------
    // Clock divider
    // -----------------------------------------------------------------------
    reg [6:0]  clk_divider;
    reg [6:0]  clk_count;
    reg        spi_clk;
    reg        spi_clk_prev;

    always @(*) begin
        case ({spi2x, spr})
            3'b000: clk_divider = 7'd1;   // /4
            3'b001: clk_divider = 7'd7;   // /16
            3'b010: clk_divider = 7'd31;  // /64
            3'b011: clk_divider = 7'd63;  // /128
            3'b100: clk_divider = 7'd0;   // /2
            3'b101: clk_divider = 7'd3;   // /8
            3'b110: clk_divider = 7'd15;  // /32
            3'b111: clk_divider = 7'd31;  // /64
        endcase
    end

    // -----------------------------------------------------------------------
    // SPI Master State Machine
    // -----------------------------------------------------------------------
    reg [3:0]  bit_count;
    reg        spi_active;
    reg        transfer_start;
    reg        leading_edge;
    reg        trailing_edge;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_count    <= 7'd0;
            spi_clk      <= 1'b0;
            spi_clk_prev <= 1'b0;
            leading_edge <= 1'b0;
            trailing_edge <= 1'b0;
        end else if (spe && spi_active) begin
            spi_clk_prev <= spi_clk;
            if (clk_count >= clk_divider) begin
                clk_count <= 7'd0;
                spi_clk   <= ~spi_clk;
            end else begin
                clk_count <= clk_count + 7'd1;
            end
            leading_edge  <= (~spi_clk_prev & spi_clk);
            trailing_edge <= (spi_clk_prev & ~spi_clk);
        end else begin
            clk_count    <= 7'd0;
            spi_clk      <= cpol;  // Idle state
            spi_clk_prev <= cpol;
            leading_edge <= 1'b0;
            trailing_edge <= 1'b0;
        end
    end

    // Master transfer logic + Register write (MERGED for synthesis)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg      <= 8'h00;
            spi_data_in    <= 8'h00;
            bit_count      <= 4'd0;
            spi_active     <= 1'b0;
            transfer_start <= 1'b0;
            spif           <= 1'b0;
            wcol           <= 1'b0;
            mosi           <= 1'b0;
            sck            <= 1'b0;
            ss_n           <= 1'b1;
            spie           <= 1'b0;
            spe            <= 1'b0;
            dord           <= 1'b0;
            mstr           <= 1'b0;
            cpol           <= 1'b0;
            cpha           <= 1'b0;
            spr            <= 2'b00;
            spi2x          <= 1'b0;
            spi_data_out   <= 8'h00;
        end else begin
            // --- SPI hardware transfer FSM ---
            if (spe && mstr) begin
                sck  <= spi_clk ^ cpol;
                ss_n <= ~spi_active;

                if (transfer_start) begin
                    transfer_start <= 1'b0;
                    spi_active <= 1'b1;
                    shift_reg <= spi_data_out;
                    bit_count <= 4'd0;
                    if (dord)
                        mosi <= spi_data_out[0];
                    else
                        mosi <= spi_data_out[7];
                end else if (spi_active) begin
                    if (!cpha) begin
                        if (leading_edge) begin
                            if (dord)
                                shift_reg <= {miso, shift_reg[7:1]};
                            else
                                shift_reg <= {shift_reg[6:0], miso};
                        end
                        if (trailing_edge) begin
                            bit_count <= bit_count + 4'd1;
                            if (bit_count >= 4'd7) begin
                                spi_active <= 1'b0;
                                spi_data_in <= shift_reg;
                                spif <= 1'b1;
                            end else begin
                                if (dord)
                                    mosi <= shift_reg[0];
                                else
                                    mosi <= shift_reg[7];
                            end
                        end
                    end else begin
                        if (leading_edge) begin
                            if (dord)
                                mosi <= shift_reg[0];
                            else
                                mosi <= shift_reg[7];
                        end
                        if (trailing_edge) begin
                            if (dord)
                                shift_reg <= {miso, shift_reg[7:1]};
                            else
                                shift_reg <= {shift_reg[6:0], miso};
                            bit_count <= bit_count + 4'd1;
                            if (bit_count >= 4'd7) begin
                                spi_active <= 1'b0;
                                spi_data_in <= shift_reg;
                                spif <= 1'b1;
                            end
                        end
                    end
                end
            end else begin
                sck  <= cpol;
                ss_n <= 1'b1;
            end

            // --- Register writes (software access) ---
            if (io_wr) begin
                case (io_addr)
                    6'h2C: begin  // SPCR
                        spie <= io_wdata[7];
                        spe  <= io_wdata[6];
                        dord <= io_wdata[5];
                        mstr <= io_wdata[4];
                        cpol <= io_wdata[3];
                        cpha <= io_wdata[2];
                        spr  <= io_wdata[1:0];
                    end
                    6'h2D: begin  // SPSR
                        spi2x <= io_wdata[0];
                    end
                    6'h2E: begin  // SPDR (write starts transfer)
                        spi_data_out <= io_wdata;
                        if (!spi_active)
                            transfer_start <= 1'b1;
                        else
                            wcol <= 1'b1;
                    end
                    default: ;
                endcase
            end

            // Clear SPIF when SPSR is read followed by SPDR access
            if (io_rd && io_addr == 6'h2D)
                spif <= 1'b0;
        end
    end

    // -----------------------------------------------------------------------
    // Register read
    // -----------------------------------------------------------------------
    always @(*) begin
        io_rdata = 8'h00;
        if (io_rd) begin
            case (io_addr)
                6'h2C: io_rdata = {spie, spe, dord, mstr, cpol, cpha, spr};  // SPCR
                6'h2D: io_rdata = {spif, wcol, 5'b0, spi2x};                  // SPSR
                6'h2E: io_rdata = spi_data_in;                                 // SPDR
                default: io_rdata = 8'h00;
            endcase
        end
    end

endmodule
