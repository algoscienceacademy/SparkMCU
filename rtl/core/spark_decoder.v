// ============================================================================
// SparkMCU - AVR Instruction Decoder
// ============================================================================
// Decodes 16-bit AVR instructions into control signals
// Supports the core ATmega328P instruction set
// ============================================================================

`include "spark_pkg.v"

module spark_decoder (
    input  wire [15:0] instruction,
    input  wire [15:0] instruction_next,  // For 32-bit instructions (LDS, STS, CALL, JMP)

    // Register addresses
    output reg  [4:0]  rd_addr,         // Destination register
    output reg  [4:0]  rr_addr,         // Source register
    output reg  [7:0]  imm8,            // 8-bit immediate
    output reg  [5:0]  imm6,            // 6-bit immediate (ADIW/SBIW)
    output reg  [11:0] imm12,           // 12-bit relative address (RJMP/RCALL)
    output reg  [6:0]  imm7,            // 7-bit branch offset
    output reg  [21:0] imm22,           // 22-bit address (JMP/CALL)
    output reg  [15:0] imm16,           // 16-bit address (LDS/STS)
    output reg  [5:0]  io_addr,         // I/O address (IN/OUT)
    output reg  [2:0]  bit_idx,         // Bit index

    // ALU control
    output reg  [3:0]  alu_op,

    // Control signals
    output reg         use_imm,          // Use immediate as operand B
    output reg         reg_write,        // Write to register file
    output reg         reg_word_write,   // Word register write
    output reg         mem_read,         // Memory read
    output reg         mem_write,        // Memory write
    output reg         io_read,          // I/O read
    output reg         io_write,         // I/O write
    output reg         push_op,          // PUSH operation
    output reg         pop_op,           // POP operation
    output reg         branch_op,        // Branch instruction
    output reg         jump_op,          // Jump instruction
    output reg         call_op,          // Call instruction
    output reg         ret_op,           // RET instruction
    output reg         reti_op,          // RETI instruction
    output reg         sreg_write,       // Write to SREG from ALU
    output reg         skip_op,          // Skip next instruction (CPSE, SBRC, SBRS, SBIC, SBIS)
    output reg         is_32bit,         // 32-bit instruction
    output reg         indirect_read,    // Indirect memory read (LD)
    output reg         indirect_write,   // Indirect memory write (ST)
    output reg  [1:0]  ptr_sel,          // Pointer register select (0=X, 1=Y, 2=Z)
    output reg  [1:0]  ptr_mode,         // 0=none, 1=post-inc, 2=pre-dec, 3=displacement
    output reg  [5:0]  ptr_disp,         // Displacement for LDD/STD
    output reg         mul_op,           // Multiply operation
    output reg         movw_op,          // MOVW operation
    output reg         lpm_op,           // LPM instruction
    output reg         sleep_op,         // SLEEP instruction
    output reg         wdr_op,           // WDR instruction
    output reg         nop_op,           // NOP instruction
    output reg         bit_set_op,       // SBI operation
    output reg         bit_clr_op,       // CBI operation
    output reg         bld_op,           // BLD (bit load from T)
    output reg         bst_op,           // BST (bit store to T)
    output reg         sreg_bit_set,     // BSET (set SREG bit)
    output reg         sreg_bit_clr,     // BCLR (clear SREG bit)
    output reg         cp_op,            // Compare (no writeback)
    output reg         adiw_op,          // ADIW
    output reg         sbiw_op,          // SBIW
    output reg         valid              // Valid instruction
);

    // Instruction field extraction
    wire [3:0] opcode_hi  = instruction[15:12];
    wire [1:0] opcode_mid = instruction[11:10];

    always @(*) begin
        // Default all outputs
        rd_addr         = 5'b0;
        rr_addr         = 5'b0;
        imm8            = 8'b0;
        imm6            = 6'b0;
        imm12           = 12'b0;
        imm7            = 7'b0;
        imm22           = 22'b0;
        imm16           = 16'b0;
        io_addr         = 6'b0;
        bit_idx         = 3'b0;
        alu_op          = 4'b0;
        use_imm         = 1'b0;
        reg_write       = 1'b0;
        reg_word_write  = 1'b0;
        mem_read        = 1'b0;
        mem_write       = 1'b0;
        io_read         = 1'b0;
        io_write        = 1'b0;
        push_op         = 1'b0;
        pop_op          = 1'b0;
        branch_op       = 1'b0;
        jump_op         = 1'b0;
        call_op         = 1'b0;
        ret_op          = 1'b0;
        reti_op         = 1'b0;
        sreg_write      = 1'b0;
        skip_op         = 1'b0;
        is_32bit        = 1'b0;
        indirect_read   = 1'b0;
        indirect_write  = 1'b0;
        ptr_sel         = 2'b0;
        ptr_mode        = 2'b0;
        ptr_disp        = 6'b0;
        mul_op          = 1'b0;
        movw_op         = 1'b0;
        lpm_op          = 1'b0;
        sleep_op        = 1'b0;
        wdr_op          = 1'b0;
        nop_op          = 1'b0;
        bit_set_op      = 1'b0;
        bit_clr_op      = 1'b0;
        bld_op          = 1'b0;
        bst_op          = 1'b0;
        sreg_bit_set    = 1'b0;
        sreg_bit_clr    = 1'b0;
        cp_op           = 1'b0;
        adiw_op         = 1'b0;
        sbiw_op         = 1'b0;
        valid           = 1'b1;

        casez (instruction)
            // ===========================================================
            // NOP
            // ===========================================================
            16'b0000_0000_0000_0000: begin
                nop_op = 1'b1;
            end

            // ===========================================================
            // MOVW Rd+1:Rd, Rr+1:Rr
            // ===========================================================
            16'b0000_0001_????_????: begin
                movw_op = 1'b1;
                rd_addr = {instruction[7:4], 1'b0};
                rr_addr = {instruction[3:0], 1'b0};
                reg_word_write = 1'b1;
            end

            // ===========================================================
            // MUL Rd, Rr (unsigned)
            // ===========================================================
            16'b1001_11??_????_????: begin
                mul_op = 1'b1;
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                alu_op = `ALU_OP_MUL;
                reg_word_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // ADD Rd, Rr / LSL Rd (ADD Rd, Rd)
            // ===========================================================
            16'b0000_11??_????_????: begin
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                alu_op = `ALU_OP_ADD;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // ADC Rd, Rr / ROL Rd (ADC Rd, Rd)
            // ===========================================================
            16'b0001_11??_????_????: begin
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                alu_op = `ALU_OP_ADC;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // SUB Rd, Rr
            // ===========================================================
            16'b0001_10??_????_????: begin
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                alu_op = `ALU_OP_SUB;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // SBC Rd, Rr
            // ===========================================================
            16'b0000_10??_????_????: begin
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                alu_op = `ALU_OP_SBC;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // CP Rd, Rr
            // ===========================================================
            16'b0001_01??_????_????: begin
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                alu_op = `ALU_OP_SUB;
                cp_op = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // CPC Rd, Rr
            // ===========================================================
            16'b0000_01??_????_????: begin
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                alu_op = `ALU_OP_SBC;
                cp_op = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // CPSE Rd, Rr (Compare, Skip if Equal)
            // ===========================================================
            16'b0001_00??_????_????: begin
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                alu_op = `ALU_OP_SUB;
                skip_op = 1'b1;
            end

            // ===========================================================
            // AND Rd, Rr / TST Rd (AND Rd, Rd)
            // ===========================================================
            16'b0010_00??_????_????: begin
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                alu_op = `ALU_OP_AND;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // EOR Rd, Rr / CLR Rd (EOR Rd, Rd)
            // ===========================================================
            16'b0010_01??_????_????: begin
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                alu_op = `ALU_OP_EOR;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // OR Rd, Rr
            // ===========================================================
            16'b0010_10??_????_????: begin
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                alu_op = `ALU_OP_OR;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // MOV Rd, Rr
            // ===========================================================
            16'b0010_11??_????_????: begin
                rd_addr = instruction[8:4];
                rr_addr = {instruction[9], instruction[3:0]};
                reg_write = 1'b1;
                // Pass through (OR with 0x00 effectively)
                alu_op = `ALU_OP_OR;
                // Actually, for MOV we just pass Rr through
            end

            // ===========================================================
            // SUBI Rd, K (R16-R31)
            // ===========================================================
            16'b0101_????_????_????: begin
                rd_addr = {1'b1, instruction[7:4]};
                imm8 = {instruction[11:8], instruction[3:0]};
                use_imm = 1'b1;
                alu_op = `ALU_OP_SUB;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // SBCI Rd, K (R16-R31)
            // ===========================================================
            16'b0100_????_????_????: begin
                rd_addr = {1'b1, instruction[7:4]};
                imm8 = {instruction[11:8], instruction[3:0]};
                use_imm = 1'b1;
                alu_op = `ALU_OP_SBC;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // ANDI Rd, K / CBR Rd, K (R16-R31)
            // ===========================================================
            16'b0111_????_????_????: begin
                rd_addr = {1'b1, instruction[7:4]};
                imm8 = {instruction[11:8], instruction[3:0]};
                use_imm = 1'b1;
                alu_op = `ALU_OP_AND;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // ORI Rd, K / SBR Rd, K (R16-R31)
            // ===========================================================
            16'b0110_????_????_????: begin
                rd_addr = {1'b1, instruction[7:4]};
                imm8 = {instruction[11:8], instruction[3:0]};
                use_imm = 1'b1;
                alu_op = `ALU_OP_OR;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // CPI Rd, K (R16-R31)
            // ===========================================================
            16'b0011_????_????_????: begin
                rd_addr = {1'b1, instruction[7:4]};
                imm8 = {instruction[11:8], instruction[3:0]};
                use_imm = 1'b1;
                alu_op = `ALU_OP_SUB;
                cp_op = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // LDI Rd, K (R16-R31)
            // ===========================================================
            16'b1110_????_????_????: begin
                rd_addr = {1'b1, instruction[7:4]};
                imm8 = {instruction[11:8], instruction[3:0]};
                use_imm = 1'b1;
                reg_write = 1'b1;
            end

            // ===========================================================
            // COM Rd
            // ===========================================================
            16'b1001_010?_????_0000: begin
                rd_addr = instruction[8:4];
                alu_op = `ALU_OP_COM;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // NEG Rd
            // ===========================================================
            16'b1001_010?_????_0001: begin
                rd_addr = instruction[8:4];
                alu_op = `ALU_OP_NEG;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // SWAP Rd
            // ===========================================================
            16'b1001_010?_????_0010: begin
                rd_addr = instruction[8:4];
                alu_op = `ALU_OP_SWAP;
                reg_write = 1'b1;
            end

            // ===========================================================
            // INC Rd
            // ===========================================================
            16'b1001_010?_????_0011: begin
                rd_addr = instruction[8:4];
                alu_op = `ALU_OP_INC;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // ASR Rd
            // ===========================================================
            16'b1001_010?_????_0101: begin
                rd_addr = instruction[8:4];
                alu_op = `ALU_OP_ASR;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // LSR Rd
            // ===========================================================
            16'b1001_010?_????_0110: begin
                rd_addr = instruction[8:4];
                alu_op = `ALU_OP_LSR;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // ROR Rd
            // ===========================================================
            16'b1001_010?_????_0111: begin
                rd_addr = instruction[8:4];
                alu_op = `ALU_OP_ROR;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // DEC Rd
            // ===========================================================
            16'b1001_010?_????_1010: begin
                rd_addr = instruction[8:4];
                alu_op = `ALU_OP_DEC;
                reg_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // ADIW Rd+1:Rd, K (R24, R26, R28, R30)
            // ===========================================================
            16'b1001_0110_????_????: begin
                rd_addr = {2'b11, instruction[5:4], 1'b0};
                imm6 = {instruction[7:6], instruction[3:0]};
                adiw_op = 1'b1;
                reg_word_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // SBIW Rd+1:Rd, K (R24, R26, R28, R30)
            // ===========================================================
            16'b1001_0111_????_????: begin
                rd_addr = {2'b11, instruction[5:4], 1'b0};
                imm6 = {instruction[7:6], instruction[3:0]};
                sbiw_op = 1'b1;
                reg_word_write = 1'b1;
                sreg_write = 1'b1;
            end

            // ===========================================================
            // RJMP k
            // ===========================================================
            16'b1100_????_????_????: begin
                imm12 = instruction[11:0];
                jump_op = 1'b1;
            end

            // ===========================================================
            // RCALL k
            // ===========================================================
            16'b1101_????_????_????: begin
                imm12 = instruction[11:0];
                call_op = 1'b1;
            end

            // ===========================================================
            // JMP k (32-bit)
            // ===========================================================
            16'b1001_010?_????_110?: begin
                if (instruction[3:1] == 3'b110) begin
                    imm22 = {instruction[8:4], instruction[0], instruction_next};
                    jump_op = 1'b1;
                    is_32bit = 1'b1;
                end
            end

            // ===========================================================
            // CALL k (32-bit)
            // ===========================================================
            16'b1001_010?_????_111?: begin
                if (instruction[3:1] == 3'b111) begin
                    imm22 = {instruction[8:4], instruction[0], instruction_next};
                    call_op = 1'b1;
                    is_32bit = 1'b1;
                end
            end

            // ===========================================================
            // RET
            // ===========================================================
            16'b1001_0101_0000_1000: begin
                ret_op = 1'b1;
            end

            // ===========================================================
            // RETI
            // ===========================================================
            16'b1001_0101_0001_1000: begin
                reti_op = 1'b1;
                ret_op = 1'b1;
            end

            // ===========================================================
            // BRBS s, k (branch if SREG bit set)
            // ===========================================================
            16'b1111_00??_????_????: begin
                bit_idx = instruction[2:0];
                imm7 = instruction[9:3];
                branch_op = 1'b1;
            end

            // ===========================================================
            // BRBC s, k (branch if SREG bit clear)
            // ===========================================================
            16'b1111_01??_????_????: begin
                bit_idx = instruction[2:0];
                imm7 = instruction[9:3];
                branch_op = 1'b1;
            end

            // ===========================================================
            // BLD Rd, b
            // ===========================================================
            16'b1111_100?_????_0???: begin
                rd_addr = instruction[8:4];
                bit_idx = instruction[2:0];
                bld_op = 1'b1;
                reg_write = 1'b1;
            end

            // ===========================================================
            // BST Rd, b
            // ===========================================================
            16'b1111_101?_????_0???: begin
                rd_addr = instruction[8:4];
                bit_idx = instruction[2:0];
                bst_op = 1'b1;
            end

            // ===========================================================
            // SBRC Rr, b (Skip if Bit in Register Cleared)
            // ===========================================================
            16'b1111_110?_????_0???: begin
                rd_addr = instruction[8:4];
                bit_idx = instruction[2:0];
                skip_op = 1'b1;
            end

            // ===========================================================
            // SBRS Rr, b (Skip if Bit in Register Set)
            // ===========================================================
            16'b1111_111?_????_0???: begin
                rd_addr = instruction[8:4];
                bit_idx = instruction[2:0];
                skip_op = 1'b1;
            end

            // ===========================================================
            // IN Rd, A
            // ===========================================================
            16'b1011_0???_????_????: begin
                rd_addr = instruction[8:4];
                io_addr = {instruction[10:9], instruction[3:0]};
                io_read = 1'b1;
                reg_write = 1'b1;
            end

            // ===========================================================
            // OUT A, Rr
            // ===========================================================
            16'b1011_1???_????_????: begin
                rd_addr = instruction[8:4]; // Source register
                io_addr = {instruction[10:9], instruction[3:0]};
                io_write = 1'b1;
            end

            // ===========================================================
            // SBI A, b (Set Bit in I/O)
            // ===========================================================
            16'b1001_1010_????_????: begin
                io_addr = {1'b0, instruction[7:3]};
                bit_idx = instruction[2:0];
                bit_set_op = 1'b1;
                io_write = 1'b1;
            end

            // ===========================================================
            // CBI A, b (Clear Bit in I/O)
            // ===========================================================
            16'b1001_1000_????_????: begin
                io_addr = {1'b0, instruction[7:3]};
                bit_idx = instruction[2:0];
                bit_clr_op = 1'b1;
                io_write = 1'b1;
            end

            // ===========================================================
            // SBIC A, b / SBIS A, b (Skip if Bit in I/O Clear/Set)
            // ===========================================================
            16'b1001_1001_????_????: begin
                io_addr = {1'b0, instruction[7:3]};
                bit_idx = instruction[2:0];
                skip_op = 1'b1;
                io_read = 1'b1;
            end

            16'b1001_1011_????_????: begin
                io_addr = {1'b0, instruction[7:3]};
                bit_idx = instruction[2:0];
                skip_op = 1'b1;
                io_read = 1'b1;
            end

            // ===========================================================
            // PUSH Rr
            // ===========================================================
            16'b1001_001?_????_1111: begin
                rd_addr = instruction[8:4];
                push_op = 1'b1;
                mem_write = 1'b1;
            end

            // ===========================================================
            // POP Rd
            // ===========================================================
            16'b1001_000?_????_1111: begin
                rd_addr = instruction[8:4];
                pop_op = 1'b1;
                mem_read = 1'b1;
                reg_write = 1'b1;
            end

            // ===========================================================
            // LDS Rd, k (32-bit)
            // ===========================================================
            16'b1001_000?_????_0000: begin
                rd_addr = instruction[8:4];
                imm16 = instruction_next;
                mem_read = 1'b1;
                reg_write = 1'b1;
                is_32bit = 1'b1;
            end

            // ===========================================================
            // STS k, Rr (32-bit)
            // ===========================================================
            16'b1001_001?_????_0000: begin
                rd_addr = instruction[8:4];
                imm16 = instruction_next;
                mem_write = 1'b1;
                is_32bit = 1'b1;
            end

            // ===========================================================
            // LD Rd, Z  /  LD Rd, Z+  /  LD Rd, -Z
            // ===========================================================
            16'b1000_000?_????_0000: begin // LD Rd, Z
                rd_addr = instruction[8:4];
                ptr_sel = 2'd2;
                ptr_mode = 2'b00;
                indirect_read = 1'b1;
                reg_write = 1'b1;
            end

            16'b1001_000?_????_0001: begin // LD Rd, Z+
                rd_addr = instruction[8:4];
                ptr_sel = 2'd2;
                ptr_mode = 2'b01;
                indirect_read = 1'b1;
                reg_write = 1'b1;
                reg_word_write = 1'b1;
            end

            16'b1001_000?_????_0010: begin // LD Rd, -Z
                rd_addr = instruction[8:4];
                ptr_sel = 2'd2;
                ptr_mode = 2'b10;
                indirect_read = 1'b1;
                reg_write = 1'b1;
                reg_word_write = 1'b1;
            end

            // ===========================================================
            // LDD Rd, Z+q
            // ===========================================================
            16'b10?0_??0?_????_0???: begin
                rd_addr = instruction[8:4];
                ptr_sel = 2'd2;
                ptr_mode = 2'b11;
                ptr_disp = {instruction[13], instruction[11:10], instruction[2:0]};
                indirect_read = 1'b1;
                reg_write = 1'b1;
            end

            // ===========================================================
            // LD Rd, Y  / LD Rd, Y+  / LD Rd, -Y
            // ===========================================================
            16'b1000_000?_????_1000: begin // LD Rd, Y
                rd_addr = instruction[8:4];
                ptr_sel = 2'd1;
                ptr_mode = 2'b00;
                indirect_read = 1'b1;
                reg_write = 1'b1;
            end

            16'b1001_000?_????_1001: begin // LD Rd, Y+
                rd_addr = instruction[8:4];
                ptr_sel = 2'd1;
                ptr_mode = 2'b01;
                indirect_read = 1'b1;
                reg_write = 1'b1;
                reg_word_write = 1'b1;
            end

            16'b1001_000?_????_1010: begin // LD Rd, -Y
                rd_addr = instruction[8:4];
                ptr_sel = 2'd1;
                ptr_mode = 2'b10;
                indirect_read = 1'b1;
                reg_write = 1'b1;
                reg_word_write = 1'b1;
            end

            // ===========================================================
            // LDD Rd, Y+q
            // ===========================================================
            16'b10?0_??0?_????_1???: begin
                rd_addr = instruction[8:4];
                ptr_sel = 2'd1;
                ptr_mode = 2'b11;
                ptr_disp = {instruction[13], instruction[11:10], instruction[2:0]};
                indirect_read = 1'b1;
                reg_write = 1'b1;
            end

            // ===========================================================
            // LD Rd, X  / LD Rd, X+  / LD Rd, -X
            // ===========================================================
            16'b1001_000?_????_1100: begin // LD Rd, X
                rd_addr = instruction[8:4];
                ptr_sel = 2'd0;
                ptr_mode = 2'b00;
                indirect_read = 1'b1;
                reg_write = 1'b1;
            end

            16'b1001_000?_????_1101: begin // LD Rd, X+
                rd_addr = instruction[8:4];
                ptr_sel = 2'd0;
                ptr_mode = 2'b01;
                indirect_read = 1'b1;
                reg_write = 1'b1;
                reg_word_write = 1'b1;
            end

            16'b1001_000?_????_1110: begin // LD Rd, -X
                rd_addr = instruction[8:4];
                ptr_sel = 2'd0;
                ptr_mode = 2'b10;
                indirect_read = 1'b1;
                reg_write = 1'b1;
                reg_word_write = 1'b1;
            end

            // ===========================================================
            // ST Z, Rr  / ST Z+, Rr  / ST -Z, Rr
            // ===========================================================
            16'b1000_001?_????_0000: begin // ST Z, Rr
                rd_addr = instruction[8:4];
                ptr_sel = 2'd2;
                ptr_mode = 2'b00;
                indirect_write = 1'b1;
            end

            16'b1001_001?_????_0001: begin // ST Z+, Rr
                rd_addr = instruction[8:4];
                ptr_sel = 2'd2;
                ptr_mode = 2'b01;
                indirect_write = 1'b1;
                reg_word_write = 1'b1;
            end

            16'b1001_001?_????_0010: begin // ST -Z, Rr
                rd_addr = instruction[8:4];
                ptr_sel = 2'd2;
                ptr_mode = 2'b10;
                indirect_write = 1'b1;
                reg_word_write = 1'b1;
            end

            // ===========================================================
            // STD Z+q, Rr
            // ===========================================================
            16'b10?0_??1?_????_0???: begin
                rd_addr = instruction[8:4];
                ptr_sel = 2'd2;
                ptr_mode = 2'b11;
                ptr_disp = {instruction[13], instruction[11:10], instruction[2:0]};
                indirect_write = 1'b1;
            end

            // ===========================================================
            // ST Y, Rr  / ST Y+, Rr  / ST -Y, Rr
            // ===========================================================
            16'b1000_001?_????_1000: begin // ST Y, Rr
                rd_addr = instruction[8:4];
                ptr_sel = 2'd1;
                ptr_mode = 2'b00;
                indirect_write = 1'b1;
            end

            16'b1001_001?_????_1001: begin // ST Y+, Rr
                rd_addr = instruction[8:4];
                ptr_sel = 2'd1;
                ptr_mode = 2'b01;
                indirect_write = 1'b1;
                reg_word_write = 1'b1;
            end

            16'b1001_001?_????_1010: begin // ST -Y, Rr
                rd_addr = instruction[8:4];
                ptr_sel = 2'd1;
                ptr_mode = 2'b10;
                indirect_write = 1'b1;
                reg_word_write = 1'b1;
            end

            // ===========================================================
            // STD Y+q, Rr
            // ===========================================================
            16'b10?0_??1?_????_1???: begin
                rd_addr = instruction[8:4];
                ptr_sel = 2'd1;
                ptr_mode = 2'b11;
                ptr_disp = {instruction[13], instruction[11:10], instruction[2:0]};
                indirect_write = 1'b1;
            end

            // ===========================================================
            // ST X, Rr  / ST X+, Rr  / ST -X, Rr
            // ===========================================================
            16'b1001_001?_????_1100: begin // ST X, Rr
                rd_addr = instruction[8:4];
                ptr_sel = 2'd0;
                ptr_mode = 2'b00;
                indirect_write = 1'b1;
            end

            16'b1001_001?_????_1101: begin // ST X+, Rr
                rd_addr = instruction[8:4];
                ptr_sel = 2'd0;
                ptr_mode = 2'b01;
                indirect_write = 1'b1;
                reg_word_write = 1'b1;
            end

            16'b1001_001?_????_1110: begin // ST -X, Rr
                rd_addr = instruction[8:4];
                ptr_sel = 2'd0;
                ptr_mode = 2'b10;
                indirect_write = 1'b1;
                reg_word_write = 1'b1;
            end

            // ===========================================================
            // LPM (R0 implied) / LPM Rd, Z / LPM Rd, Z+
            // ===========================================================
            16'b1001_0101_1100_1000: begin // LPM (R0)
                rd_addr = 5'd0;
                ptr_sel = 2'd2;
                lpm_op = 1'b1;
                reg_write = 1'b1;
            end

            16'b1001_000?_????_0100: begin // LPM Rd, Z
                rd_addr = instruction[8:4];
                ptr_sel = 2'd2;
                ptr_mode = 2'b00;
                lpm_op = 1'b1;
                reg_write = 1'b1;
            end

            16'b1001_000?_????_0101: begin // LPM Rd, Z+
                rd_addr = instruction[8:4];
                ptr_sel = 2'd2;
                ptr_mode = 2'b01;
                lpm_op = 1'b1;
                reg_write = 1'b1;
                reg_word_write = 1'b1;
            end

            // ===========================================================
            // BSET s (SEC, SEZ, SEN, SEV, SES, SEH, SET, SEI)
            // ===========================================================
            16'b1001_0100_0???_1000: begin
                bit_idx = instruction[6:4];
                sreg_bit_set = 1'b1;
            end

            // ===========================================================
            // BCLR s (CLC, CLZ, CLN, CLV, CLS, CLH, CLT, CLI)
            // ===========================================================
            16'b1001_0100_1???_1000: begin
                bit_idx = instruction[6:4];
                sreg_bit_clr = 1'b1;
            end

            // ===========================================================
            // SLEEP
            // ===========================================================
            16'b1001_0101_1000_1000: begin
                sleep_op = 1'b1;
            end

            // ===========================================================
            // WDR
            // ===========================================================
            16'b1001_0101_1010_1000: begin
                wdr_op = 1'b1;
            end

            // ===========================================================
            // ICALL / IJMP (via Z register)
            // ===========================================================
            16'b1001_0101_0000_1001: begin // IJMP
                jump_op = 1'b1;
                ptr_sel = 2'd2;
            end

            16'b1001_0101_0001_1001: begin // ICALL
                call_op = 1'b1;
                ptr_sel = 2'd2;
            end

            default: begin
                valid = 1'b0;
                nop_op = 1'b1;
            end
        endcase
    end

endmodule
