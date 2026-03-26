// ============================================================================
// SparkMCU - Flash ROM (Program Memory) with $readmemh Support
// ============================================================================
// 32KB program memory that can load firmware from .hex files
// Supports synchronous read and optional programming interface
// ============================================================================

module spark_flash_rom #(
    parameter DEPTH   = 16384,      // 16K x 16-bit words (32KB)
    parameter AW      = 14,         // Address width = log2(16384)
    parameter HEX_FILE = ""         // Hex file path for $readmemh
)(
    input  wire            clk,
    input  wire            rst_n,

    // CPU fetch port (read-only)
    input  wire [AW-1:0]   fetch_addr,
    output wire [15:0]     fetch_data,
    input  wire            fetch_en,

    // Debug/monitoring port
    output wire [15:0]     monitor_data,
    input  wire [AW-1:0]   monitor_addr,
    input  wire            monitor_en,

    // Programming interface (for simulation or bootloader)
    input  wire [AW-1:0]   prog_addr,
    input  wire [15:0]     prog_data,
    input  wire            prog_we
);

    // -----------------------------------------------------------------------
    // Memory Array
    // -----------------------------------------------------------------------
    reg [15:0] mem [0:DEPTH-1];

    // -----------------------------------------------------------------------
    // Initialization
    // -----------------------------------------------------------------------
    initial begin
        // Zero-initialize memory
        integer i;
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 16'h0000;

        // Load from hex file if provided
        if (HEX_FILE != "")
            $readmemh(HEX_FILE, mem);
    end

    // -----------------------------------------------------------------------
    // Synchronous Read (Fetch Port)
    // -----------------------------------------------------------------------
    reg [15:0] fetch_data_r;
    assign fetch_data = fetch_data_r;

    always @(posedge clk) begin
        if (fetch_en)
            fetch_data_r <= mem[fetch_addr];
    end

    // -----------------------------------------------------------------------
    // Debug/Monitor Read
    // -----------------------------------------------------------------------
    reg [15:0] monitor_data_r;
    assign monitor_data = monitor_data_r;

    always @(posedge clk) begin
        if (monitor_en)
            monitor_data_r <= mem[monitor_addr];
    end

    // -----------------------------------------------------------------------
    // Programming Write (Synchronous)
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Nothing to do on reset
        end else if (prog_we) begin
            mem[prog_addr] <= prog_data;
        end
    end

endmodule
