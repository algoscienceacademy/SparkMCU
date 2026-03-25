// ============================================================================
// SparkMCU - AVR-Compatible ALU (Arithmetic Logic Unit)
// ============================================================================
// Implements all AVR arithmetic and logic operations
// Generates status flags (C, Z, N, V, S, H)
// ============================================================================

`include "spark_pkg.v"

module spark_alu (
    input  wire [7:0]  op_a,        // Operand A (Rd)
    input  wire [7:0]  op_b,        // Operand B (Rr / K)
    input  wire [3:0]  alu_op,      // ALU operation selector
    input  wire        carry_in,    // Carry input (from SREG)
    output reg  [7:0]  result,      // ALU result
    output reg  [7:0]  sreg_out,    // Status register output {I,T,H,S,V,N,Z,C}
    output wire [15:0] mul_result   // 16-bit multiply result
);

    // Internal signals
    wire [8:0]  add_result;
    wire [8:0]  adc_result;
    wire [8:0]  sub_result;
    wire [8:0]  sbc_result;
    wire [4:0]  half_add;
    wire [4:0]  half_adc;
    wire [4:0]  half_sub;
    wire [4:0]  half_sbc;

    // Unsigned multiply
    assign mul_result = op_a * op_b;

    // Addition / subtraction with carry computation
    assign add_result = {1'b0, op_a} + {1'b0, op_b};
    assign adc_result = {1'b0, op_a} + {1'b0, op_b} + {8'b0, carry_in};
    assign sub_result = {1'b0, op_a} - {1'b0, op_b};
    assign sbc_result = {1'b0, op_a} - {1'b0, op_b} - {8'b0, carry_in};

    // Half-carry computation (lower nibble)
    assign half_add = {1'b0, op_a[3:0]} + {1'b0, op_b[3:0]};
    assign half_adc = {1'b0, op_a[3:0]} + {1'b0, op_b[3:0]} + {4'b0, carry_in};
    assign half_sub = {1'b0, op_a[3:0]} - {1'b0, op_b[3:0]};
    assign half_sbc = {1'b0, op_a[3:0]} - {1'b0, op_b[3:0]} - {4'b0, carry_in};

    // ALU operation
    always @(*) begin
        // Default: preserve SREG bits I and T
        sreg_out = 8'h00;

        case (alu_op)
            `ALU_OP_ADD: begin
                result = add_result[7:0];
                sreg_out[`SREG_C] = add_result[8];
                sreg_out[`SREG_Z] = (add_result[7:0] == 8'h00);
                sreg_out[`SREG_N] = add_result[7];
                sreg_out[`SREG_V] = (op_a[7] & op_b[7] & ~result[7]) |
                                    (~op_a[7] & ~op_b[7] & result[7]);
                sreg_out[`SREG_S] = sreg_out[`SREG_N] ^ sreg_out[`SREG_V];
                sreg_out[`SREG_H] = half_add[4];
            end

            `ALU_OP_ADC: begin
                result = adc_result[7:0];
                sreg_out[`SREG_C] = adc_result[8];
                sreg_out[`SREG_Z] = (adc_result[7:0] == 8'h00);
                sreg_out[`SREG_N] = adc_result[7];
                sreg_out[`SREG_V] = (op_a[7] & op_b[7] & ~result[7]) |
                                    (~op_a[7] & ~op_b[7] & result[7]);
                sreg_out[`SREG_S] = sreg_out[`SREG_N] ^ sreg_out[`SREG_V];
                sreg_out[`SREG_H] = half_adc[4];
            end

            `ALU_OP_SUB: begin
                result = sub_result[7:0];
                sreg_out[`SREG_C] = sub_result[8];
                sreg_out[`SREG_Z] = (sub_result[7:0] == 8'h00);
                sreg_out[`SREG_N] = sub_result[7];
                sreg_out[`SREG_V] = (op_a[7] & ~op_b[7] & ~result[7]) |
                                    (~op_a[7] & op_b[7] & result[7]);
                sreg_out[`SREG_S] = sreg_out[`SREG_N] ^ sreg_out[`SREG_V];
                sreg_out[`SREG_H] = half_sub[4];
            end

            `ALU_OP_SBC: begin
                result = sbc_result[7:0];
                sreg_out[`SREG_C] = sbc_result[8];
                sreg_out[`SREG_Z] = (sbc_result[7:0] == 8'h00);
                sreg_out[`SREG_N] = sbc_result[7];
                sreg_out[`SREG_V] = (op_a[7] & ~op_b[7] & ~result[7]) |
                                    (~op_a[7] & op_b[7] & result[7]);
                sreg_out[`SREG_S] = sreg_out[`SREG_N] ^ sreg_out[`SREG_V];
                sreg_out[`SREG_H] = half_sbc[4];
            end

            `ALU_OP_AND: begin
                result = op_a & op_b;
                sreg_out[`SREG_C] = 1'b0;
                sreg_out[`SREG_Z] = (result == 8'h00);
                sreg_out[`SREG_N] = result[7];
                sreg_out[`SREG_V] = 1'b0;
                sreg_out[`SREG_S] = result[7];
                sreg_out[`SREG_H] = 1'b0;
            end

            `ALU_OP_OR: begin
                result = op_a | op_b;
                sreg_out[`SREG_C] = 1'b0;
                sreg_out[`SREG_Z] = (result == 8'h00);
                sreg_out[`SREG_N] = result[7];
                sreg_out[`SREG_V] = 1'b0;
                sreg_out[`SREG_S] = result[7];
                sreg_out[`SREG_H] = 1'b0;
            end

            `ALU_OP_EOR: begin
                result = op_a ^ op_b;
                sreg_out[`SREG_C] = 1'b0;
                sreg_out[`SREG_Z] = (result == 8'h00);
                sreg_out[`SREG_N] = result[7];
                sreg_out[`SREG_V] = 1'b0;
                sreg_out[`SREG_S] = result[7];
                sreg_out[`SREG_H] = 1'b0;
            end

            `ALU_OP_COM: begin
                result = ~op_a;
                sreg_out[`SREG_C] = 1'b1;
                sreg_out[`SREG_Z] = (result == 8'h00);
                sreg_out[`SREG_N] = result[7];
                sreg_out[`SREG_V] = 1'b0;
                sreg_out[`SREG_S] = result[7];
                sreg_out[`SREG_H] = 1'b0;
            end

            `ALU_OP_NEG: begin
                result = 8'h00 - op_a;
                sreg_out[`SREG_C] = (result != 8'h00);
                sreg_out[`SREG_Z] = (result == 8'h00);
                sreg_out[`SREG_N] = result[7];
                sreg_out[`SREG_V] = (result == 8'h80);
                sreg_out[`SREG_S] = sreg_out[`SREG_N] ^ sreg_out[`SREG_V];
                sreg_out[`SREG_H] = result[3] | op_a[3];
            end

            `ALU_OP_INC: begin
                result = op_a + 8'h01;
                sreg_out[`SREG_C] = 1'b0;  // INC does not affect carry
                sreg_out[`SREG_Z] = (result == 8'h00);
                sreg_out[`SREG_N] = result[7];
                sreg_out[`SREG_V] = (op_a == 8'h7F);
                sreg_out[`SREG_S] = sreg_out[`SREG_N] ^ sreg_out[`SREG_V];
                sreg_out[`SREG_H] = 1'b0;
            end

            `ALU_OP_DEC: begin
                result = op_a - 8'h01;
                sreg_out[`SREG_C] = 1'b0;  // DEC does not affect carry
                sreg_out[`SREG_Z] = (result == 8'h00);
                sreg_out[`SREG_N] = result[7];
                sreg_out[`SREG_V] = (op_a == 8'h80);
                sreg_out[`SREG_S] = sreg_out[`SREG_N] ^ sreg_out[`SREG_V];
                sreg_out[`SREG_H] = 1'b0;
            end

            `ALU_OP_LSR: begin
                result = {1'b0, op_a[7:1]};
                sreg_out[`SREG_C] = op_a[0];
                sreg_out[`SREG_Z] = (result == 8'h00);
                sreg_out[`SREG_N] = 1'b0;
                sreg_out[`SREG_V] = op_a[0];  // N xor C
                sreg_out[`SREG_S] = op_a[0];
                sreg_out[`SREG_H] = 1'b0;
            end

            `ALU_OP_ROR: begin
                result = {carry_in, op_a[7:1]};
                sreg_out[`SREG_C] = op_a[0];
                sreg_out[`SREG_Z] = (result == 8'h00);
                sreg_out[`SREG_N] = carry_in;
                sreg_out[`SREG_V] = carry_in ^ op_a[0];
                sreg_out[`SREG_S] = sreg_out[`SREG_N] ^ sreg_out[`SREG_V];
                sreg_out[`SREG_H] = 1'b0;
            end

            `ALU_OP_ASR: begin
                result = {op_a[7], op_a[7:1]};
                sreg_out[`SREG_C] = op_a[0];
                sreg_out[`SREG_Z] = (result == 8'h00);
                sreg_out[`SREG_N] = op_a[7];
                sreg_out[`SREG_V] = op_a[7] ^ op_a[0];
                sreg_out[`SREG_S] = sreg_out[`SREG_N] ^ sreg_out[`SREG_V];
                sreg_out[`SREG_H] = 1'b0;
            end

            `ALU_OP_SWAP: begin
                result = {op_a[3:0], op_a[7:4]};
                sreg_out = 8'h00;  // SWAP does not affect flags
            end

            `ALU_OP_MUL: begin
                result = mul_result[7:0];  // Low byte
                sreg_out[`SREG_C] = mul_result[15];
                sreg_out[`SREG_Z] = (mul_result == 16'h0000);
                sreg_out[`SREG_N] = 1'b0;
                sreg_out[`SREG_V] = 1'b0;
                sreg_out[`SREG_S] = 1'b0;
                sreg_out[`SREG_H] = 1'b0;
            end

            default: begin
                result = 8'h00;
                sreg_out = 8'h00;
            end
        endcase
    end

endmodule
