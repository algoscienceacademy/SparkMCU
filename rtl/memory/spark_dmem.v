// ============================================================================
// SparkMCU - Data Memory (SRAM)
// ============================================================================
// 2KB SRAM (0x0100 - 0x08FF)
// Single-port read/write with byte access
// Targets sky130_sram_2kbyte_1rw1r_32x512_8
// ============================================================================

module spark_dmem #(
    parameter DEPTH = 256,      // 256B - reduced for synthesis
    parameter AW    = 8         // Address width = log2(DEPTH)
)(
    input  wire           clk,
    input  wire           rst_n,

    // CPU data port
    input  wire [15:0]    addr,      // Full 16-bit address
    input  wire [7:0]     wdata,
    output reg  [7:0]     rdata,
    input  wire           rd_en,
    input  wire           wr_en
);

    // Memory array
    reg [7:0] mem [0:DEPTH-1];

    // Address translation: SRAM starts at 0x0100
    wire [AW-1:0] local_addr;
    wire           addr_valid;

    assign local_addr = addr[AW-1:0];
    assign addr_valid = (addr >= 16'h0100) && (addr < 16'h0100 + DEPTH);

    // Initialize to zero
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 8'h00;
    end

    // Synchronous read/write
    always @(posedge clk) begin
        if (addr_valid) begin
            if (wr_en)
                mem[local_addr] <= wdata;
            if (rd_en)
                rdata <= mem[local_addr];
        end else begin
            rdata <= 8'h00;
        end
    end

endmodule
