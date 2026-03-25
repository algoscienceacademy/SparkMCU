// ============================================================================
// SparkMCU - AVR Register File
// ============================================================================
// 32 x 8-bit general purpose registers (R0-R31)
// Dual-port read, single-port write
// Word access for R26:R27 (X), R28:R29 (Y), R30:R31 (Z)
// ============================================================================

module spark_regfile (
    input  wire        clk,
    input  wire        rst_n,

    // Read port A (Rd)
    input  wire [4:0]  rd_addr_a,
    output wire [7:0]  rd_data_a,

    // Read port B (Rr)
    input  wire [4:0]  rd_addr_b,
    output wire [7:0]  rd_data_b,

    // Write port
    input  wire        wr_en,
    input  wire [4:0]  wr_addr,
    input  wire [7:0]  wr_data,

    // Word write port (for MOVW, ADIW, SBIW, MUL result)
    input  wire        wr_word_en,
    input  wire [4:0]  wr_word_addr,   // Even register address
    input  wire [15:0] wr_word_data,

    // Word read ports for X, Y, Z pointer registers
    output wire [15:0] reg_x,   // R27:R26
    output wire [15:0] reg_y,   // R29:R28
    output wire [15:0] reg_z,   // R31:R30

    // Direct register access for I/O mapped reads (R0-R31 at 0x00-0x1F)
    input  wire [4:0]  io_rd_addr,
    output wire [7:0]  io_rd_data,
    input  wire        io_wr_en,
    input  wire [4:0]  io_wr_addr,
    input  wire [7:0]  io_wr_data
);

    // Register file storage
    reg [7:0] registers [0:31];
    integer i;

    // Read ports - combinational
    assign rd_data_a = registers[rd_addr_a];
    assign rd_data_b = registers[rd_addr_b];

    // I/O mapped read
    assign io_rd_data = registers[io_rd_addr];

    // Pointer register outputs
    assign reg_x = {registers[27], registers[26]};
    assign reg_y = {registers[29], registers[28]};
    assign reg_z = {registers[31], registers[30]};

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 8'h00;
            end
        end else begin
            // Priority: word write > single write > io write
            if (wr_word_en) begin
                registers[wr_word_addr]     <= wr_word_data[7:0];
                registers[wr_word_addr + 1] <= wr_word_data[15:8];
            end else if (wr_en) begin
                registers[wr_addr] <= wr_data;
            end else if (io_wr_en) begin
                registers[io_wr_addr] <= io_wr_data;
            end
        end
    end

endmodule
