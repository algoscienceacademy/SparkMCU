// ============================================================================
// SparkMCU - GPIO Port Module (ATmega328P compatible)
// ============================================================================
// Each port has 8 pins with:
//   - PINx  : Input pin value (read) / Toggle (write 1)
//   - DDRx  : Data direction (0=input, 1=output)
//   - PORTx : Output data / pull-up enable
// ============================================================================

module spark_gpio #(
    parameter PORT_WIDTH = 8,
    parameter PIN_ADDR   = 6'h03,   // I/O address for PINx
    parameter DDR_ADDR   = 6'h04,   // I/O address for DDRx
    parameter PORT_ADDR  = 6'h05    // I/O address for PORTx
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // I/O bus interface
    input  wire [5:0]              io_addr,
    input  wire [7:0]              io_wdata,
    output reg  [7:0]              io_rdata,
    input  wire                    io_rd,
    input  wire                    io_wr,

    // External pin interface
    input  wire [PORT_WIDTH-1:0]   pin_in,     // Pin input values
    output wire [PORT_WIDTH-1:0]   pin_out,    // Pin output values
    output wire [PORT_WIDTH-1:0]   pin_dir,    // Pin direction (1=output)

    // Pin change interrupt output
    output wire                    pcint       // Pin change interrupt flag
);

    // Registers
    reg [PORT_WIDTH-1:0] port_reg;    // PORTx
    reg [PORT_WIDTH-1:0] ddr_reg;     // DDRx
    reg [PORT_WIDTH-1:0] pin_sync;    // Synchronized pin input
    reg [PORT_WIDTH-1:0] pin_prev;    // Previous pin state for change detect

    // Output assignments
    assign pin_out = port_reg;
    assign pin_dir = ddr_reg;

    // Pin change detection
    assign pcint = |(pin_sync ^ pin_prev);

    // Pin input synchronizer (2-stage for metastability)
    reg [PORT_WIDTH-1:0] pin_sync1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pin_sync1 <= {PORT_WIDTH{1'b0}};
            pin_sync  <= {PORT_WIDTH{1'b0}};
            pin_prev  <= {PORT_WIDTH{1'b0}};
        end else begin
            pin_sync1 <= pin_in;
            pin_sync  <= pin_sync1;
            pin_prev  <= pin_sync;
        end
    end

    // Register read
    always @(*) begin
        io_rdata = 8'h00;
        if (io_rd) begin
            case (io_addr)
                PIN_ADDR:  io_rdata = {{(8-PORT_WIDTH){1'b0}}, pin_sync};
                DDR_ADDR:  io_rdata = {{(8-PORT_WIDTH){1'b0}}, ddr_reg};
                PORT_ADDR: io_rdata = {{(8-PORT_WIDTH){1'b0}}, port_reg};
                default:   io_rdata = 8'h00;
            endcase
        end
    end

    // Register write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            port_reg <= {PORT_WIDTH{1'b0}};
            ddr_reg  <= {PORT_WIDTH{1'b0}};
        end else if (io_wr) begin
            case (io_addr)
                PIN_ADDR: begin
                    // Writing to PINx toggles PORTx bits (ATmega328P feature)
                    port_reg <= port_reg ^ io_wdata[PORT_WIDTH-1:0];
                end
                DDR_ADDR: begin
                    ddr_reg <= io_wdata[PORT_WIDTH-1:0];
                end
                PORT_ADDR: begin
                    port_reg <= io_wdata[PORT_WIDTH-1:0];
                end
            endcase
        end
    end

endmodule
