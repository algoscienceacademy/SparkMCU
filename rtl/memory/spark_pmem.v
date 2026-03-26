// ============================================================================
// SparkMCU - Program Memory (Flash) - Synchronous ROM
// ============================================================================
// 16K x 16-bit (32KB) program memory
// Single-port read for instruction fetch
// Synthesizable as block RAM on SkyWater 130nm using OpenRAM or sky130 SRAM
// ============================================================================

module spark_pmem #(
    parameter DEPTH = 256,      // 256 words (512B) - reduced for synthesis
    parameter AW    = 8,        // Address width = log2(DEPTH)
    parameter HEX_FILE = ""     // Optional: load from hex file
)(
    input  wire            clk,
    input  wire            rst_n,

    // CPU fetch port
    input  wire [AW-1:0]   addr,
    output reg  [15:0]     rdata,
    input  wire            rd_en,

    // Programming interface (for loading firmware)
    input  wire [AW-1:0]   prog_addr,
    input  wire [15:0]     prog_data,
    input  wire            prog_wr
);

    // Memory array
    reg [15:0] mem [0:DEPTH-1];

    // Initialize to NOP (0x0000) or load from hex file
    integer i;
    initial begin
        // First, initialize all to NOP
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 16'h0000;
        
        // Then, if HEX_FILE is provided, load it
        if (HEX_FILE != "") begin
            $readmemh(HEX_FILE, mem);
        end
    end

    // Synchronous read
    always @(posedge clk) begin
        if (rd_en)
            rdata <= mem[addr];
    end

    // Programming write port
    always @(posedge clk) begin
        if (prog_wr)
            mem[prog_addr] <= prog_data;
    end

endmodule
