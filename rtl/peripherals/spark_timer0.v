// ============================================================================
// SparkMCU - Timer/Counter 0 (ATmega328P compatible)
// ============================================================================
// 8-bit Timer/Counter with:
//   - Normal, CTC, Fast PWM, Phase Correct PWM modes
//   - Two Output Compare units (OC0A, OC0B)
//   - Prescaler: 1, 8, 64, 256, 1024, ext falling/rising
//   - Overflow, Compare Match A/B interrupts
// ============================================================================
// Register Map (I/O space):
//   TCCR0A (0x24) : Timer Control Register A
//   TCCR0B (0x25) : Timer Control Register B
//   TCNT0  (0x26) : Timer Counter Value
//   OCR0A  (0x27) : Output Compare Register A
//   OCR0B  (0x28) : Output Compare Register B
//   TIFR0  (0x15) : Timer Interrupt Flag Register
//   TIMSK0 (0x6E) : Timer Interrupt Mask Register (extended I/O)
// ============================================================================

module spark_timer0 (
    input  wire        clk,
    input  wire        rst_n,

    // I/O bus interface
    input  wire [5:0]  io_addr,
    input  wire [7:0]  io_wdata,
    output reg  [7:0]  io_rdata,
    input  wire        io_rd,
    input  wire        io_wr,

    // External clock input
    input  wire        t0_pin,

    // Output compare pins
    output reg         oc0a,
    output reg         oc0b,

    // Interrupt outputs
    output wire        irq_ov,      // Timer overflow interrupt
    output wire        irq_compa,   // Compare match A interrupt
    output wire        irq_compb    // Compare match B interrupt
);

    // -----------------------------------------------------------------------
    // Registers
    // -----------------------------------------------------------------------

    // TCCR0A: [COM0A1:COM0A0, COM0B1:COM0B0, -, -, WGM01:WGM00]
    reg [1:0]  com0a;    // Compare Output Mode for OC0A
    reg [1:0]  com0b;    // Compare Output Mode for OC0B
    reg [1:0]  wgm_lo;   // Waveform Generation Mode bits [1:0]

    // TCCR0B: [FOC0A, FOC0B, -, -, WGM02, CS02:CS01:CS00]
    reg        wgm_hi;   // WGM bit [2]
    reg [2:0]  cs;        // Clock Select

    // Timer registers
    reg [7:0]  tcnt;      // Counter value
    reg [7:0]  ocr0a;     // Output Compare A
    reg [7:0]  ocr0b;     // Output Compare B

    // TIFR0: [-, -, -, -, -, OCF0B, OCF0A, TOV0]
    reg        tov0;      // Timer Overflow Flag
    reg        ocf0a;     // Output Compare A Flag
    reg        ocf0b;     // Output Compare B Flag

    // TIMSK0: [-, -, -, -, -, OCIE0B, OCIE0A, TOIE0]
    reg        toie0;     // Timer Overflow Interrupt Enable
    reg        ocie0a;    // Output Compare A Interrupt Enable
    reg        ocie0b;    // Output Compare B Interrupt Enable

    // WGM combined
    wire [2:0] wgm;
    assign wgm = {wgm_hi, wgm_lo};

    // Interrupt outputs
    assign irq_ov    = tov0  & toie0;
    assign irq_compa = ocf0a & ocie0a;
    assign irq_compb = ocf0b & ocie0b;

    // -----------------------------------------------------------------------
    // Prescaler
    // -----------------------------------------------------------------------
    reg [9:0]  prescaler_cnt;
    reg        timer_tick;
    reg        t0_sync, t0_prev;

    // T0 pin synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t0_sync <= 1'b0;
            t0_prev <= 1'b0;
        end else begin
            t0_sync <= t0_pin;
            t0_prev <= t0_sync;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescaler_cnt <= 10'd0;
            timer_tick <= 1'b0;
        end else begin
            timer_tick <= 1'b0;
            case (cs)
                3'b000: timer_tick <= 1'b0;  // Stopped
                3'b001: timer_tick <= 1'b1;  // clk/1
                3'b010: begin
                    prescaler_cnt <= prescaler_cnt + 10'd1;
                    if (prescaler_cnt[2:0] == 3'b111) begin
                        timer_tick <= 1'b1;
                        prescaler_cnt <= 10'd0;
                    end
                end
                3'b011: begin
                    prescaler_cnt <= prescaler_cnt + 10'd1;
                    if (prescaler_cnt[5:0] == 6'b111111) begin
                        timer_tick <= 1'b1;
                        prescaler_cnt <= 10'd0;
                    end
                end
                3'b100: begin
                    prescaler_cnt <= prescaler_cnt + 10'd1;
                    if (prescaler_cnt[7:0] == 8'hFF) begin
                        timer_tick <= 1'b1;
                        prescaler_cnt <= 10'd0;
                    end
                end
                3'b101: begin
                    prescaler_cnt <= prescaler_cnt + 10'd1;
                    if (prescaler_cnt[9:0] == 10'h3FF) begin
                        timer_tick <= 1'b1;
                        prescaler_cnt <= 10'd0;
                    end
                end
                3'b110: begin
                    // External clock, falling edge
                    timer_tick <= t0_prev & ~t0_sync;
                end
                3'b111: begin
                    // External clock, rising edge
                    timer_tick <= ~t0_prev & t0_sync;
                end
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // Timer counting logic + Register write (MERGED for synthesis)
    // -----------------------------------------------------------------------
    reg        count_dir;   // 0=up, 1=down (for Phase Correct PWM)
    wire [7:0] top_value;

    // TOP depends on WGM mode
    assign top_value = (wgm == 3'b010) ? ocr0a :  // CTC
                       (wgm == 3'b101) ? ocr0a :  // Phase Correct PWM, TOP=OCR0A
                       (wgm == 3'b111) ? ocr0a :  // Fast PWM, TOP=OCR0A
                       8'hFF;                       // Normal / Fast PWM 0xFF

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tcnt      <= 8'h00;
            count_dir <= 1'b0;
            tov0      <= 1'b0;
            ocf0a     <= 1'b0;
            ocf0b     <= 1'b0;
            oc0a      <= 1'b0;
            oc0b      <= 1'b0;
            com0a     <= 2'b00;
            com0b     <= 2'b00;
            wgm_lo    <= 2'b00;
            wgm_hi    <= 1'b0;
            cs        <= 3'b000;
            ocr0a     <= 8'h00;
            ocr0b     <= 8'h00;
            toie0     <= 1'b0;
            ocie0a    <= 1'b0;
            ocie0b    <= 1'b0;
        end else begin
            // --- Timer hardware counting ---
            if (timer_tick) begin
                case (wgm)
                    // Normal mode
                    3'b000: begin
                        tcnt <= tcnt + 8'd1;
                        if (tcnt == 8'hFF) begin
                            tov0 <= 1'b1;
                        end
                        if (tcnt == ocr0a) begin
                            ocf0a <= 1'b1;
                            case (com0a)
                                2'b01: oc0a <= ~oc0a;
                                2'b10: oc0a <= 1'b0;
                                2'b11: oc0a <= 1'b1;
                                default: ;
                            endcase
                        end
                        if (tcnt == ocr0b) begin
                            ocf0b <= 1'b1;
                            case (com0b)
                                2'b01: oc0b <= ~oc0b;
                                2'b10: oc0b <= 1'b0;
                                2'b11: oc0b <= 1'b1;
                                default: ;
                            endcase
                        end
                    end

                    // CTC (Clear Timer on Compare Match)
                    3'b010: begin
                        if (tcnt >= ocr0a) begin
                            tcnt <= 8'h00;
                            ocf0a <= 1'b1;
                            case (com0a)
                                2'b01: oc0a <= ~oc0a;
                                2'b10: oc0a <= 1'b0;
                                2'b11: oc0a <= 1'b1;
                                default: ;
                            endcase
                        end else begin
                            tcnt <= tcnt + 8'd1;
                        end
                        if (tcnt == ocr0b) begin
                            ocf0b <= 1'b1;
                        end
                    end

                    // Fast PWM (TOP=0xFF)
                    3'b011: begin
                        if (tcnt == 8'hFF) begin
                            tcnt <= 8'h00;
                            tov0 <= 1'b1;
                            if (com0a == 2'b10) oc0a <= 1'b1;
                            if (com0a == 2'b11) oc0a <= 1'b0;
                            if (com0b == 2'b10) oc0b <= 1'b1;
                            if (com0b == 2'b11) oc0b <= 1'b0;
                        end else begin
                            tcnt <= tcnt + 8'd1;
                        end
                        if (tcnt == ocr0a) begin
                            ocf0a <= 1'b1;
                            if (com0a == 2'b10) oc0a <= 1'b0;
                            if (com0a == 2'b11) oc0a <= 1'b1;
                        end
                        if (tcnt == ocr0b) begin
                            ocf0b <= 1'b1;
                            if (com0b == 2'b10) oc0b <= 1'b0;
                            if (com0b == 2'b11) oc0b <= 1'b1;
                        end
                    end

                    // Phase Correct PWM (TOP=0xFF)
                    3'b001: begin
                        if (!count_dir) begin
                            if (tcnt == 8'hFF) begin
                                count_dir <= 1'b1;
                                tov0 <= 1'b0;
                            end else begin
                                tcnt <= tcnt + 8'd1;
                            end
                        end else begin
                            if (tcnt == 8'h00) begin
                                count_dir <= 1'b0;
                                tov0 <= 1'b1;
                            end else begin
                                tcnt <= tcnt - 8'd1;
                            end
                        end
                        if (tcnt == ocr0a) begin
                            ocf0a <= 1'b1;
                            if (!count_dir) begin
                                if (com0a == 2'b10) oc0a <= 1'b0;
                                if (com0a == 2'b11) oc0a <= 1'b1;
                            end else begin
                                if (com0a == 2'b10) oc0a <= 1'b1;
                                if (com0a == 2'b11) oc0a <= 1'b0;
                            end
                        end
                        if (tcnt == ocr0b) begin
                            ocf0b <= 1'b1;
                            if (!count_dir) begin
                                if (com0b == 2'b10) oc0b <= 1'b0;
                                if (com0b == 2'b11) oc0b <= 1'b1;
                            end else begin
                                if (com0b == 2'b10) oc0b <= 1'b1;
                                if (com0b == 2'b11) oc0b <= 1'b0;
                            end
                        end
                    end

                    // Fast PWM (TOP=OCR0A)
                    3'b111: begin
                        if (tcnt >= ocr0a) begin
                            tcnt <= 8'h00;
                            tov0 <= 1'b1;
                            ocf0a <= 1'b1;
                        end else begin
                            tcnt <= tcnt + 8'd1;
                        end
                        if (tcnt == ocr0b) begin
                            ocf0b <= 1'b1;
                            if (com0b == 2'b10) oc0b <= 1'b0;
                            if (com0b == 2'b11) oc0b <= 1'b1;
                        end
                    end

                    // Phase Correct PWM (TOP=OCR0A)
                    3'b101: begin
                        if (!count_dir) begin
                            if (tcnt >= ocr0a) begin
                                count_dir <= 1'b1;
                            end else begin
                                tcnt <= tcnt + 8'd1;
                            end
                        end else begin
                            if (tcnt == 8'h00) begin
                                count_dir <= 1'b0;
                                tov0 <= 1'b1;
                            end else begin
                                tcnt <= tcnt - 8'd1;
                            end
                        end
                    end

                    default: begin
                        tcnt <= tcnt + 8'd1;
                    end
                endcase
            end

            // --- Register writes (software access, takes priority for shared signals) ---
            if (io_wr) begin
                case (io_addr)
                    6'h24: begin  // TCCR0A
                        com0a  <= io_wdata[7:6];
                        com0b  <= io_wdata[5:4];
                        wgm_lo <= io_wdata[1:0];
                    end
                    6'h25: begin  // TCCR0B
                        // FOC0A (bit 7) and FOC0B (bit 6) are strobe bits
                        if (io_wdata[7] && wgm[1:0] != 2'b01 && wgm[1:0] != 2'b11) begin
                            case (com0a)
                                2'b01: oc0a <= ~oc0a;
                                2'b10: oc0a <= 1'b0;
                                2'b11: oc0a <= 1'b1;
                                default: ;
                            endcase
                        end
                        if (io_wdata[6] && wgm[1:0] != 2'b01 && wgm[1:0] != 2'b11) begin
                            case (com0b)
                                2'b01: oc0b <= ~oc0b;
                                2'b10: oc0b <= 1'b0;
                                2'b11: oc0b <= 1'b1;
                                default: ;
                            endcase
                        end
                        wgm_hi <= io_wdata[3];
                        cs     <= io_wdata[2:0];
                    end
                    6'h26: begin  // TCNT0 (direct write overrides counter)
                        tcnt <= io_wdata;
                    end
                    6'h27: begin  // OCR0A
                        ocr0a <= io_wdata;
                    end
                    6'h28: begin  // OCR0B
                        ocr0b <= io_wdata;
                    end
                    6'h15: begin  // TIFR0 (write 1 to clear)
                        if (io_wdata[0]) tov0  <= 1'b0;
                        if (io_wdata[1]) ocf0a <= 1'b0;
                        if (io_wdata[2]) ocf0b <= 1'b0;
                    end
                    6'h2E: begin  // TIMSK0 (ext I/O 0x6E mapped here)
                        toie0  <= io_wdata[0];
                        ocie0a <= io_wdata[1];
                        ocie0b <= io_wdata[2];
                    end
                    default: ;
                endcase
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
                6'h24: io_rdata = {com0a, com0b, 2'b00, wgm_lo};         // TCCR0A
                6'h25: io_rdata = {2'b00, 2'b00, wgm_hi, cs};            // TCCR0B
                6'h26: io_rdata = tcnt;                                    // TCNT0
                6'h27: io_rdata = ocr0a;                                   // OCR0A
                6'h28: io_rdata = ocr0b;                                   // OCR0B
                6'h15: io_rdata = {5'b00000, ocf0b, ocf0a, tov0};        // TIFR0
                6'h2E: io_rdata = {5'b00000, ocie0b, ocie0a, toie0};     // TIMSK0
                default: io_rdata = 8'h00;
            endcase
        end
    end

endmodule
