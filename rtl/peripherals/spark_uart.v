// ============================================================================
// SparkMCU - UART (USART0) Module (ATmega328P compatible)
// ============================================================================
// Features:
//   - Full-duplex asynchronous serial communication
//   - Configurable baud rate (UBRR0)
//   - 5/6/7/8/9 data bits
//   - 1 or 2 stop bits
//   - Even/odd/no parity
//   - RX Complete, TX Complete, Data Register Empty interrupts
// ============================================================================
// Register Map (absolute addresses):
//   0xC0 : UCSR0A - Control/Status Register A
//   0xC1 : UCSR0B - Control/Status Register B
//   0xC2 : UCSR0C - Control/Status Register C
//   0xC4 : UBRR0L - Baud Rate Register Low
//   0xC5 : UBRR0H - Baud Rate Register High
//   0xC6 : UDR0   - Data Register
// ============================================================================

module spark_uart (
    input  wire        clk,
    input  wire        rst_n,

    // I/O bus interface (extended I/O)
    input  wire [7:0]  io_addr,     // Address (offset from 0x60)
    input  wire [7:0]  io_wdata,
    output reg  [7:0]  io_rdata,
    input  wire        io_rd,
    input  wire        io_wr,

    // UART pins
    input  wire        rxd,         // UART receive pin
    output reg         txd,         // UART transmit pin

    // Interrupt outputs
    output wire        irq_rxc,     // RX complete interrupt
    output wire        irq_udre,    // Data register empty interrupt
    output wire        irq_txc      // TX complete interrupt
);

    // -----------------------------------------------------------------------
    // Register definitions
    // -----------------------------------------------------------------------

    // UCSR0A bits
    reg        rxc;      // [7] RX Complete
    reg        txc;      // [6] TX Complete
    reg        udre;     // [5] Data Register Empty
    reg        fe;       // [4] Frame Error
    reg        dor;      // [3] Data OverRun
    reg        upe;      // [2] Parity Error
    reg        u2x;      // [1] Double TX Speed
    reg        mpcm;     // [0] Multi-processor Comm Mode

    // UCSR0B bits
    reg        rxcie;    // [7] RX Complete Interrupt Enable
    reg        txcie;    // [6] TX Complete Interrupt Enable
    reg        udrie;    // [5] Data Register Empty Interrupt Enable
    reg        rxen;     // [4] Receiver Enable
    reg        txen;     // [3] Transmitter Enable
    reg        ucsz2;   // [2] Character Size bit 2
    reg        rxb8;     // [1] RX Data Bit 8
    reg        txb8;     // [0] TX Data Bit 8

    // UCSR0C bits
    reg [1:0]  umsel;    // [7:6] Mode Select
    reg [1:0]  upm;      // [5:4] Parity Mode
    reg        usbs;     // [3] Stop Bit Select
    reg [1:0]  ucsz;     // [2:1] Character Size
    reg        ucpol;    // [0] Clock Polarity

    // UBRR0
    reg [11:0] ubrr;     // Baud rate register

    // Data registers
    reg [7:0]  tx_data;
    reg [7:0]  rx_data;
    reg [7:0]  rx_buffer;

    // Interrupt outputs
    assign irq_rxc  = rxc & rxcie;
    assign irq_udre = udre & udrie;
    assign irq_txc  = txc & txcie;

    // -----------------------------------------------------------------------
    // Baud rate generator
    // -----------------------------------------------------------------------
    reg [15:0] baud_counter;
    reg        baud_tick;
    reg [15:0] baud_divisor;

    always @(*) begin
        if (u2x)
            baud_divisor = {4'b0, ubrr} + 16'd1;  // (UBRR+1) for 2x
        else
            baud_divisor = ({4'b0, ubrr} + 16'd1) << 1;  // 2*(UBRR+1) for normal
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 16'd0;
            baud_tick <= 1'b0;
        end else begin
            if (baud_counter >= baud_divisor - 16'd1) begin
                baud_counter <= 16'd0;
                baud_tick <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 16'd1;
                baud_tick <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Transmitter + Receiver + Register write (MERGED for synthesis)
    // -----------------------------------------------------------------------
    reg [3:0]  tx_state;
    reg [3:0]  tx_bit_count;
    reg [9:0]  tx_shift_reg;
    reg [3:0]  tx_baud_div;
    reg        tx_busy;

    localparam TX_IDLE     = 4'd0;
    localparam TX_START    = 4'd1;
    localparam TX_DATA     = 4'd2;
    localparam TX_PARITY   = 4'd3;
    localparam TX_STOP1    = 4'd4;
    localparam TX_STOP2    = 4'd5;

    reg [3:0]  rx_state;
    reg [3:0]  rx_bit_count;
    reg [9:0]  rx_shift_reg;
    reg [3:0]  rx_baud_div;
    reg [1:0]  rxd_sync;

    localparam RX_IDLE     = 4'd0;
    localparam RX_START    = 4'd1;
    localparam RX_DATA     = 4'd2;
    localparam RX_PARITY   = 4'd3;
    localparam RX_STOP     = 4'd4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // TX reset
            tx_state     <= TX_IDLE;
            tx_shift_reg <= 10'h3FF;
            tx_bit_count <= 4'd0;
            tx_baud_div  <= 4'd0;
            tx_busy      <= 1'b0;
            txd          <= 1'b1;
            txc          <= 1'b0;
            udre         <= 1'b1;
            // RX reset
            rxd_sync     <= 2'b11;
            rx_state     <= RX_IDLE;
            rx_shift_reg <= 10'h000;
            rx_bit_count <= 4'd0;
            rx_baud_div  <= 4'd0;
            rxc          <= 1'b0;
            fe           <= 1'b0;
            dor          <= 1'b0;
            upe          <= 1'b0;
            rx_data      <= 8'h00;
            rx_buffer    <= 8'h00;
            rxb8         <= 1'b0;
            // Config reset
            u2x   <= 1'b0;
            mpcm  <= 1'b0;
            rxcie <= 1'b0;
            txcie <= 1'b0;
            udrie <= 1'b0;
            rxen  <= 1'b0;
            txen  <= 1'b0;
            ucsz2 <= 1'b0;
            txb8  <= 1'b0;
            umsel <= 2'b00;
            upm   <= 2'b00;
            usbs  <= 1'b0;
            ucsz  <= 2'b11;
            ucpol <= 1'b0;
            ubrr  <= 12'h000;
            tx_data <= 8'h00;
        end else begin
            // === RXD synchronizer ===
            rxd_sync <= {rxd_sync[0], rxd};

            // === TX FSM ===
            case (tx_state)
                TX_IDLE: begin
                    txd <= 1'b1;
                    if (!udre && txen) begin
                        tx_shift_reg <= {txb8, tx_data, 1'b0};
                        tx_state <= TX_START;
                        tx_busy <= 1'b1;
                        tx_baud_div <= 4'd0;
                        udre <= 1'b1;
                    end
                end

                TX_START: begin
                    if (baud_tick) begin
                        txd <= 1'b0;
                        if (tx_baud_div >= 4'd15) begin
                            tx_baud_div <= 4'd0;
                            tx_bit_count <= 4'd0;
                            tx_state <= TX_DATA;
                        end else begin
                            tx_baud_div <= tx_baud_div + 4'd1;
                        end
                    end
                end

                TX_DATA: begin
                    if (baud_tick) begin
                        if (tx_baud_div >= 4'd15) begin
                            tx_baud_div <= 4'd0;
                            txd <= tx_shift_reg[0];
                            tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
                            if (tx_bit_count >= ({1'b0, ucsz} + 4'd5 + {3'b0, ucsz2})) begin
                                if (upm != 2'b00)
                                    tx_state <= TX_PARITY;
                                else
                                    tx_state <= TX_STOP1;
                            end else begin
                                tx_bit_count <= tx_bit_count + 4'd1;
                            end
                        end else begin
                            tx_baud_div <= tx_baud_div + 4'd1;
                        end
                    end
                end

                TX_PARITY: begin
                    if (baud_tick) begin
                        if (tx_baud_div >= 4'd15) begin
                            tx_baud_div <= 4'd0;
                            txd <= (upm[0]) ? ~(^tx_data) : (^tx_data);
                            tx_state <= TX_STOP1;
                        end else begin
                            tx_baud_div <= tx_baud_div + 4'd1;
                        end
                    end
                end

                TX_STOP1: begin
                    if (baud_tick) begin
                        txd <= 1'b1;
                        if (tx_baud_div >= 4'd15) begin
                            tx_baud_div <= 4'd0;
                            if (usbs)
                                tx_state <= TX_STOP2;
                            else begin
                                tx_state <= TX_IDLE;
                                tx_busy <= 1'b0;
                                txc <= 1'b1;
                            end
                        end else begin
                            tx_baud_div <= tx_baud_div + 4'd1;
                        end
                    end
                end

                TX_STOP2: begin
                    if (baud_tick) begin
                        txd <= 1'b1;
                        if (tx_baud_div >= 4'd15) begin
                            tx_baud_div <= 4'd0;
                            tx_state <= TX_IDLE;
                            tx_busy <= 1'b0;
                            txc <= 1'b1;
                        end else begin
                            tx_baud_div <= tx_baud_div + 4'd1;
                        end
                    end
                end

                default: tx_state <= TX_IDLE;
            endcase

            // === RX FSM ===
            case (rx_state)
                RX_IDLE: begin
                    if (rxen && !rxd_sync[1]) begin
                        rx_state <= RX_START;
                        rx_baud_div <= 4'd0;
                    end
                end

                RX_START: begin
                    if (baud_tick) begin
                        if (rx_baud_div == 4'd7) begin
                            if (!rxd_sync[1]) begin
                                rx_baud_div <= 4'd0;
                                rx_bit_count <= 4'd0;
                                rx_state <= RX_DATA;
                            end else begin
                                rx_state <= RX_IDLE;
                            end
                        end else begin
                            rx_baud_div <= rx_baud_div + 4'd1;
                        end
                    end
                end

                RX_DATA: begin
                    if (baud_tick) begin
                        if (rx_baud_div >= 4'd15) begin
                            rx_baud_div <= 4'd0;
                            rx_shift_reg <= {rxd_sync[1], rx_shift_reg[9:1]};
                            if (rx_bit_count >= ({1'b0, ucsz} + 4'd4 + {3'b0, ucsz2})) begin
                                if (upm != 2'b00)
                                    rx_state <= RX_PARITY;
                                else
                                    rx_state <= RX_STOP;
                            end else begin
                                rx_bit_count <= rx_bit_count + 4'd1;
                            end
                        end else begin
                            rx_baud_div <= rx_baud_div + 4'd1;
                        end
                    end
                end

                RX_PARITY: begin
                    if (baud_tick) begin
                        if (rx_baud_div >= 4'd15) begin
                            rx_baud_div <= 4'd0;
                            if (upm[0])
                                upe <= ~(^rx_shift_reg[7:0]) ^ rxd_sync[1];
                            else
                                upe <= (^rx_shift_reg[7:0]) ^ rxd_sync[1];
                            rx_state <= RX_STOP;
                        end else begin
                            rx_baud_div <= rx_baud_div + 4'd1;
                        end
                    end
                end

                RX_STOP: begin
                    if (baud_tick) begin
                        if (rx_baud_div >= 4'd15) begin
                            rx_baud_div <= 4'd0;
                            fe <= ~rxd_sync[1];
                            if (rxc)
                                dor <= 1'b1;
                            else
                                dor <= 1'b0;
                            rx_buffer <= rx_shift_reg[7:0];
                            rxb8 <= rx_shift_reg[8];
                            rxc <= 1'b1;
                            rx_state <= RX_IDLE;
                        end else begin
                            rx_baud_div <= rx_baud_div + 4'd1;
                        end
                    end
                end

                default: rx_state <= RX_IDLE;
            endcase

            // === Register writes (software, takes priority for shared signals) ===
            if (io_wr) begin
                case (io_addr)
                    8'h80: begin  // UCSR0A
                        if (io_wdata[6]) txc <= 1'b0;
                        u2x  <= io_wdata[1];
                        mpcm <= io_wdata[0];
                    end
                    8'h81: begin  // UCSR0B
                        rxcie <= io_wdata[7];
                        txcie <= io_wdata[6];
                        udrie <= io_wdata[5];
                        rxen  <= io_wdata[4];
                        txen  <= io_wdata[3];
                        ucsz2 <= io_wdata[2];
                        txb8  <= io_wdata[0];
                    end
                    8'h82: begin  // UCSR0C
                        umsel <= io_wdata[7:6];
                        upm   <= io_wdata[5:4];
                        usbs  <= io_wdata[3];
                        ucsz  <= io_wdata[2:1];
                        ucpol <= io_wdata[0];
                    end
                    8'h84: begin  // UBRR0L
                        ubrr[7:0] <= io_wdata;
                    end
                    8'h85: begin  // UBRR0H
                        ubrr[11:8] <= io_wdata[3:0];
                    end
                    8'h86: begin  // UDR0 (write = TX data)
                        tx_data <= io_wdata;
                        udre <= 1'b0;
                    end
                    default: ;
                endcase
            end

            // Clear RXC when UDR is read
            if (io_rd && io_addr == 8'h86) begin
                rxc <= 1'b0;
                rx_data <= rx_buffer;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Register read
    // -----------------------------------------------------------------------
    always @(*) begin
        io_rdata = 8'h00;
        if (io_rd) begin
            case (io_addr)
                8'h80: io_rdata = {rxc, txc, udre, fe, dor, upe, u2x, mpcm};  // UCSR0A
                8'h81: io_rdata = {rxcie, txcie, udrie, rxen, txen, ucsz2, rxb8, txb8}; // UCSR0B
                8'h82: io_rdata = {umsel, upm, usbs, ucsz, ucpol};            // UCSR0C
                8'h84: io_rdata = ubrr[7:0];                                   // UBRR0L
                8'h85: io_rdata = {4'h0, ubrr[11:8]};                          // UBRR0H
                8'h86: io_rdata = rx_buffer;                                    // UDR0
                default: io_rdata = 8'h00;
            endcase
        end
    end

endmodule
