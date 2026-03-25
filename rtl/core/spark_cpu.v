// ============================================================================
// SparkMCU - AVR CPU Core
// ============================================================================
// Multi-cycle pipeline AVR CPU
// Stages: FETCH -> DECODE -> EXECUTE -> MEMORY -> WRITEBACK
// Harvard architecture with separate program and data memory buses
// ============================================================================

`include "spark_pkg.v"

module spark_cpu (
    input  wire        clk,
    input  wire        rst_n,

    // Program memory interface (Flash)
    output reg  [15:0] pm_addr,         // Program memory address (word address)
    input  wire [15:0] pm_data,         // Program memory data (instruction)
    output wire        pm_rd,           // Program memory read enable

    // Data memory interface (SRAM)
    output reg  [15:0] dm_addr,         // Data memory address
    output reg  [7:0]  dm_wdata,        // Data memory write data
    input  wire [7:0]  dm_rdata,        // Data memory read data
    output reg         dm_rd,           // Data memory read enable
    output reg         dm_wr,           // Data memory write enable

    // I/O interface
    output reg  [5:0]  io_addr,         // I/O address
    output reg  [7:0]  io_wdata,        // I/O write data
    input  wire [7:0]  io_rdata,        // I/O read data
    output reg         io_rd,           // I/O read enable
    output reg         io_wr,           // I/O write enable

    // Extended I/O interface (memory-mapped 0x60-0xFF)
    output reg  [7:0]  eio_addr,
    output reg  [7:0]  eio_wdata,
    input  wire [7:0]  eio_rdata,
    output reg         eio_rd,
    output reg         eio_wr,

    // Interrupt interface
    input  wire [20:0] irq_lines,       // Interrupt request lines
    output reg         irq_ack,         // Interrupt acknowledge
    output reg  [4:0]  irq_ack_num,     // Acknowledged interrupt number

    // Debug
    output wire [15:0] debug_pc,
    output wire [7:0]  debug_sreg,
    output wire [2:0]  debug_state
);

    // -----------------------------------------------------------------------
    // Internal state
    // -----------------------------------------------------------------------
    reg [2:0]  state, next_state;
    reg [15:0] pc, next_pc;
    reg [15:0] instruction_reg;
    reg [15:0] instruction_next_reg;
    reg [7:0]  sreg;
    reg [15:0] sp;        // Stack pointer (16-bit)
    reg        skip_next; // Skip next instruction flag
    reg        irq_pending;
    reg [4:0]  irq_num;

    // Fetch pipeline
    reg        fetch_second_word;
    reg [15:0] saved_first_word;

    // Debug outputs
    assign debug_pc    = pc;
    assign debug_sreg  = sreg;
    assign debug_state = state;
    assign pm_rd       = 1'b1;

    // -----------------------------------------------------------------------
    // Decoder outputs
    // -----------------------------------------------------------------------
    wire [4:0]  dec_rd_addr, dec_rr_addr;
    wire [7:0]  dec_imm8;
    wire [5:0]  dec_imm6;
    wire [11:0] dec_imm12;
    wire [6:0]  dec_imm7;
    wire [21:0] dec_imm22;
    wire [15:0] dec_imm16;
    wire [5:0]  dec_io_addr;
    wire [2:0]  dec_bit_idx;
    wire [3:0]  dec_alu_op;
    wire        dec_use_imm, dec_reg_write, dec_reg_word_write;
    wire        dec_mem_read, dec_mem_write;
    wire        dec_io_read, dec_io_write;
    wire        dec_push_op, dec_pop_op;
    wire        dec_branch_op, dec_jump_op, dec_call_op;
    wire        dec_ret_op, dec_reti_op;
    wire        dec_sreg_write, dec_skip_op, dec_is_32bit;
    wire        dec_indirect_read, dec_indirect_write;
    wire [1:0]  dec_ptr_sel, dec_ptr_mode;
    wire [5:0]  dec_ptr_disp;
    wire        dec_mul_op, dec_movw_op, dec_lpm_op;
    wire        dec_sleep_op, dec_wdr_op, dec_nop_op;
    wire        dec_bit_set_op, dec_bit_clr_op;
    wire        dec_bld_op, dec_bst_op;
    wire        dec_sreg_bit_set, dec_sreg_bit_clr;
    wire        dec_cp_op, dec_adiw_op, dec_sbiw_op;
    wire        dec_valid;

    spark_decoder u_decoder (
        .instruction      (instruction_reg),
        .instruction_next (instruction_next_reg),
        .rd_addr          (dec_rd_addr),
        .rr_addr          (dec_rr_addr),
        .imm8             (dec_imm8),
        .imm6             (dec_imm6),
        .imm12            (dec_imm12),
        .imm7             (dec_imm7),
        .imm22            (dec_imm22),
        .imm16            (dec_imm16),
        .io_addr          (dec_io_addr),
        .bit_idx          (dec_bit_idx),
        .alu_op           (dec_alu_op),
        .use_imm          (dec_use_imm),
        .reg_write        (dec_reg_write),
        .reg_word_write   (dec_reg_word_write),
        .mem_read         (dec_mem_read),
        .mem_write        (dec_mem_write),
        .io_read          (dec_io_read),
        .io_write         (dec_io_write),
        .push_op          (dec_push_op),
        .pop_op           (dec_pop_op),
        .branch_op        (dec_branch_op),
        .jump_op          (dec_jump_op),
        .call_op          (dec_call_op),
        .ret_op           (dec_ret_op),
        .reti_op          (dec_reti_op),
        .sreg_write       (dec_sreg_write),
        .skip_op          (dec_skip_op),
        .is_32bit         (dec_is_32bit),
        .indirect_read    (dec_indirect_read),
        .indirect_write   (dec_indirect_write),
        .ptr_sel          (dec_ptr_sel),
        .ptr_mode         (dec_ptr_mode),
        .ptr_disp         (dec_ptr_disp),
        .mul_op           (dec_mul_op),
        .movw_op          (dec_movw_op),
        .lpm_op           (dec_lpm_op),
        .sleep_op         (dec_sleep_op),
        .wdr_op           (dec_wdr_op),
        .nop_op           (dec_nop_op),
        .bit_set_op       (dec_bit_set_op),
        .bit_clr_op       (dec_bit_clr_op),
        .bld_op           (dec_bld_op),
        .bst_op           (dec_bst_op),
        .sreg_bit_set     (dec_sreg_bit_set),
        .sreg_bit_clr     (dec_sreg_bit_clr),
        .cp_op            (dec_cp_op),
        .adiw_op          (dec_adiw_op),
        .sbiw_op          (dec_sbiw_op),
        .valid            (dec_valid)
    );

    // -----------------------------------------------------------------------
    // Register File
    // -----------------------------------------------------------------------
    wire [7:0]  rf_rd_data_a, rf_rd_data_b;
    reg         rf_wr_en;
    reg  [4:0]  rf_wr_addr;
    reg  [7:0]  rf_wr_data;
    reg         rf_wr_word_en;
    reg  [4:0]  rf_wr_word_addr;
    reg  [15:0] rf_wr_word_data;
    wire [15:0] reg_x, reg_y, reg_z;

    // I/O mapped register access
    wire [7:0]  rf_io_rd_data;
    reg         rf_io_wr_en;
    reg  [4:0]  rf_io_wr_addr;
    reg  [7:0]  rf_io_wr_data;

    spark_regfile u_regfile (
        .clk            (clk),
        .rst_n          (rst_n),
        .rd_addr_a      (dec_rd_addr),
        .rd_data_a      (rf_rd_data_a),
        .rd_addr_b      (dec_rr_addr),
        .rd_data_b      (rf_rd_data_b),
        .wr_en          (rf_wr_en),
        .wr_addr        (rf_wr_addr),
        .wr_data        (rf_wr_data),
        .wr_word_en     (rf_wr_word_en),
        .wr_word_addr   (rf_wr_word_addr),
        .wr_word_data   (rf_wr_word_data),
        .reg_x          (reg_x),
        .reg_y          (reg_y),
        .reg_z          (reg_z),
        .io_rd_addr     (5'b0),
        .io_rd_data     (rf_io_rd_data),
        .io_wr_en       (rf_io_wr_en),
        .io_wr_addr     (rf_io_wr_addr),
        .io_wr_data     (rf_io_wr_data)
    );

    // -----------------------------------------------------------------------
    // ALU
    // -----------------------------------------------------------------------
    wire [7:0]  alu_op_a, alu_op_b;
    wire [7:0]  alu_result;
    wire [7:0]  alu_sreg_out;
    wire [15:0] alu_mul_result;

    assign alu_op_a = rf_rd_data_a;
    assign alu_op_b = dec_use_imm ? dec_imm8 : rf_rd_data_b;

    spark_alu u_alu (
        .op_a       (alu_op_a),
        .op_b       (alu_op_b),
        .alu_op     (dec_alu_op),
        .carry_in   (sreg[`SREG_C]),
        .result     (alu_result),
        .sreg_out   (alu_sreg_out),
        .mul_result (alu_mul_result)
    );

    // -----------------------------------------------------------------------
    // Pointer address calculation
    // -----------------------------------------------------------------------
    reg  [15:0] ptr_addr;
    reg  [15:0] ptr_value;
    reg  [15:0] ptr_updated;

    always @(*) begin
        case (dec_ptr_sel)
            2'd0: ptr_value = reg_x;
            2'd1: ptr_value = reg_y;
            2'd2: ptr_value = reg_z;
            default: ptr_value = 16'h0000;
        endcase

        case (dec_ptr_mode)
            2'b00: begin // No modification
                ptr_addr = ptr_value;
                ptr_updated = ptr_value;
            end
            2'b01: begin // Post-increment
                ptr_addr = ptr_value;
                ptr_updated = ptr_value + 16'd1;
            end
            2'b10: begin // Pre-decrement
                ptr_addr = ptr_value - 16'd1;
                ptr_updated = ptr_value - 16'd1;
            end
            2'b11: begin // Displacement
                ptr_addr = ptr_value + {10'b0, dec_ptr_disp};
                ptr_updated = ptr_value;
            end
        endcase
    end

    // Pointer register base address for word write
    wire [4:0] ptr_reg_addr;
    assign ptr_reg_addr = (dec_ptr_sel == 2'd0) ? 5'd26 :
                          (dec_ptr_sel == 2'd1) ? 5'd28 : 5'd30;

    // -----------------------------------------------------------------------
    // Branch condition evaluation
    // -----------------------------------------------------------------------
    wire branch_taken;
    wire branch_bit_value;
    assign branch_bit_value = sreg[dec_bit_idx];
    // BRBS: branch if bit set (opcode bit 10 = 0)
    // BRBC: branch if bit clear (opcode bit 10 = 1)
    assign branch_taken = (instruction_reg[10] == 1'b0) ? branch_bit_value :
                                                           ~branch_bit_value;

    // Sign-extended branch offset
    wire [15:0] branch_offset;
    assign branch_offset = {{9{dec_imm7[6]}}, dec_imm7};

    // Sign-extended relative jump/call offset
    wire [15:0] rjmp_offset;
    assign rjmp_offset = {{4{dec_imm12[11]}}, dec_imm12};

    // -----------------------------------------------------------------------
    // Interrupt priority encoder
    // -----------------------------------------------------------------------
    reg [4:0]  highest_irq;
    reg        irq_found;

    always @(*) begin
        irq_found = 1'b0;
        highest_irq = 5'd0;
        if (sreg[`SREG_I]) begin
            // Priority scan from highest to lowest
            if (irq_lines[0])       begin highest_irq = 5'd1;  irq_found = 1'b1; end
            else if (irq_lines[1])  begin highest_irq = 5'd2;  irq_found = 1'b1; end
            else if (irq_lines[2])  begin highest_irq = 5'd3;  irq_found = 1'b1; end
            else if (irq_lines[3])  begin highest_irq = 5'd4;  irq_found = 1'b1; end
            else if (irq_lines[4])  begin highest_irq = 5'd5;  irq_found = 1'b1; end
            else if (irq_lines[5])  begin highest_irq = 5'd6;  irq_found = 1'b1; end
            else if (irq_lines[6])  begin highest_irq = 5'd7;  irq_found = 1'b1; end
            else if (irq_lines[7])  begin highest_irq = 5'd8;  irq_found = 1'b1; end
            else if (irq_lines[8])  begin highest_irq = 5'd9;  irq_found = 1'b1; end
            else if (irq_lines[9])  begin highest_irq = 5'd10; irq_found = 1'b1; end
            else if (irq_lines[10]) begin highest_irq = 5'd11; irq_found = 1'b1; end
            else if (irq_lines[11]) begin highest_irq = 5'd12; irq_found = 1'b1; end
            else if (irq_lines[12]) begin highest_irq = 5'd13; irq_found = 1'b1; end
            else if (irq_lines[13]) begin highest_irq = 5'd14; irq_found = 1'b1; end
            else if (irq_lines[14]) begin highest_irq = 5'd15; irq_found = 1'b1; end
            else if (irq_lines[15]) begin highest_irq = 5'd16; irq_found = 1'b1; end
            else if (irq_lines[16]) begin highest_irq = 5'd17; irq_found = 1'b1; end
            else if (irq_lines[17]) begin highest_irq = 5'd18; irq_found = 1'b1; end
            else if (irq_lines[18]) begin highest_irq = 5'd19; irq_found = 1'b1; end
            else if (irq_lines[19]) begin highest_irq = 5'd20; irq_found = 1'b1; end
            else if (irq_lines[20]) begin highest_irq = 5'd21; irq_found = 1'b1; end
        end
    end

    // -----------------------------------------------------------------------
    // ADIW / SBIW computation
    // -----------------------------------------------------------------------
    wire [15:0] adiw_input;
    wire [15:0] adiw_result;
    wire [15:0] sbiw_result;

    assign adiw_input = {rf_rd_data_b, rf_rd_data_a}; // Using word register
    assign adiw_result = adiw_input + {10'b0, dec_imm6};
    assign sbiw_result = adiw_input - {10'b0, dec_imm6};

    // -----------------------------------------------------------------------
    // Main CPU state machine
    // -----------------------------------------------------------------------
    reg [1:0] irq_cycle;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= `CPU_STATE_FETCH;
            pc              <= 16'h0000;
            sreg            <= 8'h00;
            sp              <= 16'h08FF;   // Top of SRAM
            instruction_reg <= 16'h0000;
            instruction_next_reg <= 16'h0000;
            skip_next       <= 1'b0;
            irq_pending     <= 1'b0;
            irq_num         <= 5'd0;
            irq_cycle       <= 2'd0;
            fetch_second_word <= 1'b0;
            saved_first_word <= 16'h0000;

            // Control outputs
            dm_addr  <= 16'h0000;
            dm_wdata <= 8'h00;
            dm_rd    <= 1'b0;
            dm_wr    <= 1'b0;
            io_addr  <= 6'h00;
            io_wdata <= 8'h00;
            io_rd    <= 1'b0;
            io_wr    <= 1'b0;
            eio_addr <= 8'h00;
            eio_wdata <= 8'h00;
            eio_rd   <= 1'b0;
            eio_wr   <= 1'b0;
            irq_ack  <= 1'b0;
            irq_ack_num <= 5'd0;

            rf_wr_en        <= 1'b0;
            rf_wr_addr      <= 5'd0;
            rf_wr_data      <= 8'h00;
            rf_wr_word_en   <= 1'b0;
            rf_wr_word_addr <= 5'd0;
            rf_wr_word_data <= 16'h0000;
            rf_io_wr_en     <= 1'b0;
            rf_io_wr_addr   <= 5'd0;
            rf_io_wr_data   <= 8'h00;

        end else begin
            // Default de-assertions
            dm_rd    <= 1'b0;
            dm_wr    <= 1'b0;
            io_rd    <= 1'b0;
            io_wr    <= 1'b0;
            eio_rd   <= 1'b0;
            eio_wr   <= 1'b0;
            irq_ack  <= 1'b0;
            rf_wr_en <= 1'b0;
            rf_wr_word_en <= 1'b0;
            rf_io_wr_en   <= 1'b0;

            case (state)
                // -----------------------------------------------------------
                // FETCH: Read instruction from program memory
                // -----------------------------------------------------------
                `CPU_STATE_FETCH: begin
                    pm_addr <= pc;

                    // Check for pending interrupts
                    if (irq_found && !skip_next) begin
                        irq_pending <= 1'b1;
                        irq_num <= highest_irq;
                        state <= `CPU_STATE_IRQ;
                        irq_cycle <= 2'd0;
                    end else begin
                        state <= `CPU_STATE_DECODE;
                    end
                end

                // -----------------------------------------------------------
                // DECODE: Latch instruction, prepare operands
                // -----------------------------------------------------------
                `CPU_STATE_DECODE: begin
                    if (fetch_second_word) begin
                        instruction_next_reg <= pm_data;
                        fetch_second_word <= 1'b0;
                        state <= `CPU_STATE_EXECUTE;
                    end else begin
                        instruction_reg <= pm_data;

                        if (skip_next) begin
                            skip_next <= 1'b0;
                            // Check if skipped instruction is 32-bit
                            // For simplicity, skip 1 word and re-fetch
                            pc <= pc + 16'd1;
                            state <= `CPU_STATE_FETCH;
                        end else begin
                            // Check if this is a 32-bit instruction
                            // (LDS, STS, JMP, CALL detected by pattern)
                            casez (pm_data)
                                16'b1001_000?_????_0000,   // LDS
                                16'b1001_001?_????_0000,   // STS
                                16'b1001_010?_????_110?,   // JMP
                                16'b1001_010?_????_111?: begin // CALL
                                    saved_first_word <= pm_data;
                                    instruction_reg <= pm_data;
                                    fetch_second_word <= 1'b1;
                                    pc <= pc + 16'd1;
                                    pm_addr <= pc + 16'd1;
                                    state <= `CPU_STATE_DECODE;
                                end
                                default: begin
                                    state <= `CPU_STATE_EXECUTE;
                                end
                            endcase
                        end
                    end
                end

                // -----------------------------------------------------------
                // EXECUTE: Perform ALU/branch/memory operations
                // -----------------------------------------------------------
                `CPU_STATE_EXECUTE: begin
                    // Default: advance PC by 1 (for single-word instructions)
                    next_pc = pc + (dec_is_32bit ? 16'd2 : 16'd1);

                    // ----- ALU operations with register writeback -----
                    if (dec_reg_write && !dec_cp_op && !dec_io_read &&
                        !dec_mem_read && !dec_indirect_read && !dec_pop_op &&
                        !dec_lpm_op && !dec_bld_op && !dec_movw_op) begin
                        if (dec_use_imm && !dec_sreg_write) begin
                            // LDI: load immediate
                            rf_wr_en   <= 1'b1;
                            rf_wr_addr <= dec_rd_addr;
                            rf_wr_data <= dec_imm8;
                        end else begin
                            rf_wr_en   <= 1'b1;
                            rf_wr_addr <= dec_rd_addr;
                            rf_wr_data <= alu_result;
                        end
                    end

                    // ----- MOV -----
                    if (dec_reg_write && !dec_cp_op && !dec_sreg_write &&
                        !dec_use_imm && dec_alu_op == `ALU_OP_OR &&
                        instruction_reg[15:10] == 6'b001011) begin
                        rf_wr_en   <= 1'b1;
                        rf_wr_addr <= dec_rd_addr;
                        rf_wr_data <= rf_rd_data_b;
                    end

                    // ----- MOVW -----
                    if (dec_movw_op) begin
                        rf_wr_word_en   <= 1'b1;
                        rf_wr_word_addr <= dec_rd_addr;
                        rf_wr_word_data <= {rf_rd_data_b, rf_rd_data_a};
                    end

                    // ----- MUL result to R1:R0 -----
                    if (dec_mul_op) begin
                        rf_wr_word_en   <= 1'b1;
                        rf_wr_word_addr <= 5'd0;
                        rf_wr_word_data <= alu_mul_result;
                    end

                    // ----- ADIW / SBIW -----
                    if (dec_adiw_op) begin
                        rf_wr_word_en   <= 1'b1;
                        rf_wr_word_addr <= dec_rd_addr;
                        rf_wr_word_data <= adiw_result;
                        // Update SREG
                        sreg[`SREG_C] <= ~adiw_result[15] & adiw_input[15];
                        sreg[`SREG_Z] <= (adiw_result == 16'h0000);
                        sreg[`SREG_N] <= adiw_result[15];
                        sreg[`SREG_V] <= ~adiw_input[15] & adiw_result[15];
                        sreg[`SREG_S] <= adiw_result[15] ^ (~adiw_input[15] & adiw_result[15]);
                    end

                    if (dec_sbiw_op) begin
                        rf_wr_word_en   <= 1'b1;
                        rf_wr_word_addr <= dec_rd_addr;
                        rf_wr_word_data <= sbiw_result;
                        sreg[`SREG_C] <= sbiw_result[15] & ~adiw_input[15];
                        sreg[`SREG_Z] <= (sbiw_result == 16'h0000);
                        sreg[`SREG_N] <= sbiw_result[15];
                        sreg[`SREG_V] <= adiw_input[15] & ~sbiw_result[15];
                        sreg[`SREG_S] <= sbiw_result[15] ^ (adiw_input[15] & ~sbiw_result[15]);
                    end

                    // ----- Update SREG from ALU -----
                    if (dec_sreg_write && !dec_adiw_op && !dec_sbiw_op) begin
                        sreg[`SREG_C] <= alu_sreg_out[`SREG_C];
                        sreg[`SREG_Z] <= alu_sreg_out[`SREG_Z];
                        sreg[`SREG_N] <= alu_sreg_out[`SREG_N];
                        sreg[`SREG_V] <= alu_sreg_out[`SREG_V];
                        sreg[`SREG_S] <= alu_sreg_out[`SREG_S];
                        sreg[`SREG_H] <= alu_sreg_out[`SREG_H];
                    end

                    // ----- SREG bit set/clear (BSET/BCLR) -----
                    if (dec_sreg_bit_set)
                        sreg[dec_bit_idx] <= 1'b1;
                    if (dec_sreg_bit_clr)
                        sreg[dec_bit_idx] <= 1'b0;

                    // ----- BST (Bit Store to T) -----
                    if (dec_bst_op)
                        sreg[`SREG_T] <= rf_rd_data_a[dec_bit_idx];

                    // ----- BLD (Bit Load from T) -----
                    if (dec_bld_op) begin
                        rf_wr_en   <= 1'b1;
                        rf_wr_addr <= dec_rd_addr;
                        rf_wr_data <= rf_rd_data_a;
                        rf_wr_data[dec_bit_idx] <= sreg[`SREG_T];
                    end

                    // ----- I/O Read (IN) -----
                    if (dec_io_read && !dec_skip_op) begin
                        // Check if reading SREG, SPL, SPH
                        if (dec_io_addr == `IO_SREG) begin
                            rf_wr_en   <= 1'b1;
                            rf_wr_addr <= dec_rd_addr;
                            rf_wr_data <= sreg;
                        end else if (dec_io_addr == `IO_SPL) begin
                            rf_wr_en   <= 1'b1;
                            rf_wr_addr <= dec_rd_addr;
                            rf_wr_data <= sp[7:0];
                        end else if (dec_io_addr == `IO_SPH) begin
                            rf_wr_en   <= 1'b1;
                            rf_wr_addr <= dec_rd_addr;
                            rf_wr_data <= sp[15:8];
                        end else if (dec_io_addr < 6'h20) begin
                            // Regular I/O space
                            io_addr <= dec_io_addr;
                            io_rd   <= 1'b1;
                            state   <= `CPU_STATE_MEMORY;
                        end else begin
                            // Extended I/O mapped through data memory
                            eio_addr <= {2'b0, dec_io_addr};
                            eio_rd   <= 1'b1;
                            state    <= `CPU_STATE_MEMORY;
                        end
                    end

                    // ----- I/O Write (OUT) -----
                    if (dec_io_write && !dec_bit_set_op && !dec_bit_clr_op) begin
                        if (dec_io_addr == `IO_SREG) begin
                            sreg <= rf_rd_data_a;
                        end else if (dec_io_addr == `IO_SPL) begin
                            sp[7:0] <= rf_rd_data_a;
                        end else if (dec_io_addr == `IO_SPH) begin
                            sp[15:8] <= rf_rd_data_a;
                        end else if (dec_io_addr < 6'h20) begin
                            io_addr  <= dec_io_addr;
                            io_wdata <= rf_rd_data_a;
                            io_wr    <= 1'b1;
                        end else begin
                            eio_addr  <= {2'b0, dec_io_addr};
                            eio_wdata <= rf_rd_data_a;
                            eio_wr    <= 1'b1;
                        end
                    end

                    // ----- SBI / CBI -----
                    if (dec_bit_set_op) begin
                        io_addr  <= dec_io_addr;
                        io_rd    <= 1'b1;
                        state    <= `CPU_STATE_MEMORY;
                    end
                    if (dec_bit_clr_op) begin
                        io_addr  <= dec_io_addr;
                        io_rd    <= 1'b1;
                        state    <= `CPU_STATE_MEMORY;
                    end

                    // ----- PUSH -----
                    if (dec_push_op) begin
                        dm_addr  <= sp;
                        dm_wdata <= rf_rd_data_a;
                        dm_wr    <= 1'b1;
                        sp       <= sp - 16'd1;
                    end

                    // ----- POP -----
                    if (dec_pop_op) begin
                        sp      <= sp + 16'd1;
                        dm_addr <= sp + 16'd1;
                        dm_rd   <= 1'b1;
                        state   <= `CPU_STATE_MEMORY;
                    end

                    // ----- Direct memory access (LDS/STS) -----
                    if (dec_mem_read && !dec_pop_op && !dec_indirect_read) begin
                        dm_addr <= dec_imm16;
                        dm_rd   <= 1'b1;
                        state   <= `CPU_STATE_MEMORY;
                    end

                    if (dec_mem_write && !dec_push_op && !dec_indirect_write) begin
                        dm_addr  <= dec_imm16;
                        dm_wdata <= rf_rd_data_a;
                        dm_wr    <= 1'b1;
                    end

                    // ----- Indirect memory access (LD/ST with X, Y, Z) -----
                    if (dec_indirect_read) begin
                        // Check if address is in I/O or SRAM space
                        if (ptr_addr >= `IO_REG_BASE + 16'h20 &&
                            ptr_addr < `IO_REG_BASE + 16'h60) begin
                            io_addr <= ptr_addr[5:0] - 6'h20;
                            io_rd   <= 1'b1;
                        end else begin
                            dm_addr <= ptr_addr;
                            dm_rd   <= 1'b1;
                        end
                        // Update pointer if post-inc or pre-dec
                        if (dec_ptr_mode == 2'b01 || dec_ptr_mode == 2'b10) begin
                            rf_wr_word_en   <= 1'b1;
                            rf_wr_word_addr <= ptr_reg_addr;
                            rf_wr_word_data <= ptr_updated;
                        end
                        state <= `CPU_STATE_MEMORY;
                    end

                    if (dec_indirect_write) begin
                        if (ptr_addr >= `IO_REG_BASE + 16'h20 &&
                            ptr_addr < `IO_REG_BASE + 16'h60) begin
                            io_addr  <= ptr_addr[5:0] - 6'h20;
                            io_wdata <= rf_rd_data_a;
                            io_wr    <= 1'b1;
                        end else begin
                            dm_addr  <= ptr_addr;
                            dm_wdata <= rf_rd_data_a;
                            dm_wr    <= 1'b1;
                        end
                        if (dec_ptr_mode == 2'b01 || dec_ptr_mode == 2'b10) begin
                            rf_wr_word_en   <= 1'b1;
                            rf_wr_word_addr <= ptr_reg_addr;
                            rf_wr_word_data <= ptr_updated;
                        end
                    end

                    // ----- LPM -----
                    if (dec_lpm_op) begin
                        pm_addr <= reg_z[15:1]; // Word address
                        state <= `CPU_STATE_MEMORY;
                    end

                    // ----- Branch -----
                    if (dec_branch_op) begin
                        if (branch_taken)
                            next_pc = pc + 16'd1 + branch_offset;
                    end

                    // ----- RJMP -----
                    if (dec_jump_op && !dec_is_32bit) begin
                        if (instruction_reg[15:12] == 4'b1100) begin
                            // RJMP
                            next_pc = pc + 16'd1 + rjmp_offset;
                        end else if (instruction_reg == 16'b1001_0101_0000_1001) begin
                            // IJMP
                            next_pc = reg_z;
                        end
                    end

                    // ----- JMP (32-bit) -----
                    if (dec_jump_op && dec_is_32bit)
                        next_pc = dec_imm22[15:0];

                    // ----- RCALL -----
                    if (dec_call_op && !dec_is_32bit) begin
                        if (instruction_reg[15:12] == 4'b1101) begin
                            // RCALL - push PC+1 and jump
                            dm_addr  <= sp;
                            dm_wdata <= pc[7:0] + 8'd1;  // Low byte
                            dm_wr    <= 1'b1;
                            sp       <= sp - 16'd1;
                            next_pc  = pc + 16'd1 + rjmp_offset;
                            state    <= `CPU_STATE_MEMORY;
                        end else if (instruction_reg == 16'b1001_0101_0001_1001) begin
                            // ICALL
                            dm_addr  <= sp;
                            dm_wdata <= pc[7:0] + 8'd1;
                            dm_wr    <= 1'b1;
                            sp       <= sp - 16'd1;
                            next_pc  = reg_z;
                            state    <= `CPU_STATE_MEMORY;
                        end
                    end

                    // ----- CALL (32-bit) -----
                    if (dec_call_op && dec_is_32bit) begin
                        dm_addr  <= sp;
                        dm_wdata <= pc[7:0] + 8'd2;  // Low byte of return addr
                        dm_wr    <= 1'b1;
                        sp       <= sp - 16'd1;
                        next_pc  = dec_imm22[15:0];
                        state    <= `CPU_STATE_MEMORY;
                    end

                    // ----- RET / RETI -----
                    if (dec_ret_op) begin
                        sp    <= sp + 16'd1;
                        dm_addr <= sp + 16'd1;
                        dm_rd   <= 1'b1;
                        state   <= `CPU_STATE_MEMORY;
                        if (dec_reti_op)
                            sreg[`SREG_I] <= 1'b1;
                    end

                    // ----- CPSE (Skip if Equal) -----
                    if (dec_skip_op && instruction_reg[15:10] == 6'b000100) begin
                        if (rf_rd_data_a == rf_rd_data_b)
                            skip_next <= 1'b1;
                    end

                    // ----- SBRC / SBRS -----
                    if (dec_skip_op && instruction_reg[15:10] == 6'b111111) begin
                        // SBRS: skip if bit set
                        if (rf_rd_data_a[dec_bit_idx])
                            skip_next <= 1'b1;
                    end
                    if (dec_skip_op && instruction_reg[15:10] == 6'b111110) begin
                        // SBRC: skip if bit clear
                        if (!rf_rd_data_a[dec_bit_idx])
                            skip_next <= 1'b1;
                    end

                    // ----- SLEEP -----
                    if (dec_sleep_op) begin
                        // Enter sleep mode (simplified: just stall)
                        state <= `CPU_STATE_STALL;
                    end

                    // Advance PC if not going to MEMORY state or stall
                    if (state != `CPU_STATE_MEMORY && state != `CPU_STATE_STALL &&
                        !dec_pop_op && !dec_ret_op && !dec_lpm_op &&
                        !(dec_io_read && !dec_skip_op && dec_io_addr != `IO_SREG &&
                          dec_io_addr != `IO_SPL && dec_io_addr != `IO_SPH) &&
                        !dec_bit_set_op && !dec_bit_clr_op &&
                        !(dec_indirect_read)) begin
                        pc <= next_pc;
                        state <= `CPU_STATE_FETCH;
                    end else if (state == `CPU_STATE_EXECUTE) begin
                        // If we didn't change state, go to MEMORY
                        state <= `CPU_STATE_MEMORY;
                        pc <= next_pc;
                    end
                end

                // -----------------------------------------------------------
                // MEMORY: Complete memory operations
                // -----------------------------------------------------------
                `CPU_STATE_MEMORY: begin
                    // ----- CALL: push high byte of return address -----
                    if (dec_call_op) begin
                        dm_addr  <= sp;
                        dm_wdata <= pc[15:8]; // Was set to next_pc already
                        dm_wr    <= 1'b1;
                        sp       <= sp - 16'd1;
                        state    <= `CPU_STATE_FETCH;
                    end

                    // ----- RET/RETI: read return address (low byte first) -----
                    else if (dec_ret_op) begin
                        if (irq_cycle == 2'd0) begin
                            // Read high byte
                            pc[7:0] <= dm_rdata;
                            sp      <= sp + 16'd1;
                            dm_addr <= sp + 16'd1;
                            dm_rd   <= 1'b1;
                            irq_cycle <= 2'd1;
                        end else begin
                            pc[15:8] <= dm_rdata;
                            irq_cycle <= 2'd0;
                            state <= `CPU_STATE_FETCH;
                        end
                    end

                    // ----- POP: read data -----
                    else if (dec_pop_op) begin
                        rf_wr_en   <= 1'b1;
                        rf_wr_addr <= dec_rd_addr;
                        rf_wr_data <= dm_rdata;
                        state <= `CPU_STATE_FETCH;
                        pc <= pc + 16'd1;
                    end

                    // ----- LDS: read data -----
                    else if (dec_mem_read && !dec_indirect_read) begin
                        rf_wr_en   <= 1'b1;
                        rf_wr_addr <= dec_rd_addr;
                        rf_wr_data <= dm_rdata;
                        state <= `CPU_STATE_FETCH;
                    end

                    // ----- Indirect read (LD) -----
                    else if (dec_indirect_read) begin
                        rf_wr_en   <= 1'b1;
                        rf_wr_addr <= dec_rd_addr;
                        rf_wr_data <= (io_rd) ? io_rdata : dm_rdata;
                        state <= `CPU_STATE_FETCH;
                        pc <= pc + 16'd1;
                    end

                    // ----- LPM -----
                    else if (dec_lpm_op) begin
                        rf_wr_en   <= 1'b1;
                        rf_wr_addr <= dec_rd_addr;
                        // Select low or high byte based on Z[0]
                        rf_wr_data <= reg_z[0] ? pm_data[15:8] : pm_data[7:0];
                        // Post-increment Z if needed
                        if (dec_ptr_mode == 2'b01) begin
                            rf_wr_word_en   <= 1'b1;
                            rf_wr_word_addr <= 5'd30;
                            rf_wr_word_data <= reg_z + 16'd1;
                        end
                        state <= `CPU_STATE_FETCH;
                        pc <= pc + 16'd1;
                    end

                    // ----- I/O read completion -----
                    else if (dec_io_read && !dec_skip_op) begin
                        rf_wr_en   <= 1'b1;
                        rf_wr_addr <= dec_rd_addr;
                        rf_wr_data <= io_rdata;
                        state <= `CPU_STATE_FETCH;
                        pc <= pc + 16'd1;
                    end

                    // ----- SBI completion -----
                    else if (dec_bit_set_op) begin
                        io_addr  <= dec_io_addr;
                        io_wdata <= io_rdata | (8'd1 << dec_bit_idx);
                        io_wr    <= 1'b1;
                        state <= `CPU_STATE_FETCH;
                        pc <= pc + 16'd1;
                    end

                    // ----- CBI completion -----
                    else if (dec_bit_clr_op) begin
                        io_addr  <= dec_io_addr;
                        io_wdata <= io_rdata & ~(8'd1 << dec_bit_idx);
                        io_wr    <= 1'b1;
                        state <= `CPU_STATE_FETCH;
                        pc <= pc + 16'd1;
                    end

                    // ----- SBIC/SBIS -----
                    else if (dec_skip_op && dec_io_read) begin
                        if (instruction_reg[9]) begin
                            // SBIS: skip if bit set
                            if (io_rdata[dec_bit_idx])
                                skip_next <= 1'b1;
                        end else begin
                            // SBIC: skip if bit clear
                            if (!io_rdata[dec_bit_idx])
                                skip_next <= 1'b1;
                        end
                        state <= `CPU_STATE_FETCH;
                        pc <= pc + 16'd1;
                    end

                    else begin
                        state <= `CPU_STATE_FETCH;
                    end
                end

                // -----------------------------------------------------------
                // STALL: Sleep / halt state
                // -----------------------------------------------------------
                `CPU_STATE_STALL: begin
                    // Wake on interrupt
                    if (irq_found) begin
                        state <= `CPU_STATE_FETCH;
                    end
                end

                // -----------------------------------------------------------
                // IRQ: Interrupt handling
                // -----------------------------------------------------------
                `CPU_STATE_IRQ: begin
                    case (irq_cycle)
                        2'd0: begin
                            // Push PC low byte
                            dm_addr  <= sp;
                            dm_wdata <= pc[7:0];
                            dm_wr    <= 1'b1;
                            sp       <= sp - 16'd1;
                            irq_cycle <= 2'd1;
                        end
                        2'd1: begin
                            // Push PC high byte
                            dm_addr  <= sp;
                            dm_wdata <= pc[15:8];
                            dm_wr    <= 1'b1;
                            sp       <= sp - 16'd1;
                            irq_cycle <= 2'd2;
                        end
                        2'd2: begin
                            // Jump to interrupt vector
                            // AVR vectors: each vector is 2 words apart
                            pc <= {11'b0, irq_num} << 1;
                            sreg[`SREG_I] <= 1'b0;  // Disable global interrupts
                            irq_ack <= 1'b1;
                            irq_ack_num <= irq_num;
                            irq_pending <= 1'b0;
                            irq_cycle <= 2'd0;
                            state <= `CPU_STATE_FETCH;
                        end
                        default: begin
                            irq_cycle <= 2'd0;
                            state <= `CPU_STATE_FETCH;
                        end
                    endcase
                end

                default: state <= `CPU_STATE_FETCH;
            endcase
        end
    end

endmodule
