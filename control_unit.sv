module control_unit (
    input logic clk,
    input logic rst_n,

    input logic [3:0] opcode,
    input logic       zero_flag,

    output logic [3:0] alu_op,

    output logic ir_load,
    output logic pc_inc,
    output logic pc_load,
    output logic acc_write,
    output logic flag_write,
    output logic halted
);

  // Instruction opcodes
  localparam logic [3:0]
        OP_NOP = 4'h0,
        OP_LDI = 4'h1,
        OP_ADD = 4'h2,
        OP_SUB = 4'h3,
        OP_AND = 4'h4,
        OP_OR  = 4'h5,
        OP_XOR = 4'h6,
        OP_NOT = 4'h7,
        OP_SHL = 4'h8,
        OP_SHR = 4'h9,
        OP_JMP = 4'hA,
        OP_JZ  = 4'hB,
        OP_INC = 4'hC,
        OP_DEC = 4'hD,
        OP_HLT = 4'hF;

  // ALU operation codes
  localparam logic [3:0]
        ALU_ADD    = 4'h0,
        ALU_SUB    = 4'h1,
        ALU_AND    = 4'h2,
        ALU_OR     = 4'h3,
        ALU_XOR    = 4'h4,
        ALU_NOT    = 4'h5,
        ALU_INC    = 4'h6,
        ALU_DEC    = 4'h7,
        ALU_SHL    = 4'h8,
        ALU_SHR    = 4'h9,
        ALU_PASS_B = 4'hA;

  typedef enum logic [1:0] {
    FETCH,
    EXECUTE,
    HALT
  } state_t;

  state_t state;
  state_t next_state;

  // State register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= FETCH;
    else state <= next_state;
  end

  // Control logic
  always_comb begin
    // Default values
    alu_op     = ALU_ADD;

    ir_load    = 1'b0;
    pc_inc     = 1'b0;
    pc_load    = 1'b0;
    acc_write  = 1'b0;
    flag_write = 1'b0;
    halted     = 1'b0;

    next_state = state;

    case (state)

      FETCH: begin
        // IR <- ROM[PC]
        // PC <- PC + 1
        ir_load    = 1'b1;
        pc_inc     = 1'b1;
        next_state = EXECUTE;
      end

      EXECUTE: begin
        // Normally return to FETCH after execution
        next_state = FETCH;

        case (opcode)

          OP_NOP: begin
            // Do nothing
          end

          OP_LDI: begin
            // ACC <- operand
            alu_op     = ALU_PASS_B;
            acc_write  = 1'b1;
            flag_write = 1'b1;
          end

          OP_ADD: begin
            // ACC <- ACC + operand
            alu_op     = ALU_ADD;
            acc_write  = 1'b1;
            flag_write = 1'b1;
          end

          OP_SUB: begin
            // ACC <- ACC - operand
            alu_op     = ALU_SUB;
            acc_write  = 1'b1;
            flag_write = 1'b1;
          end

          OP_AND: begin
            // ACC <- ACC & operand
            alu_op     = ALU_AND;
            acc_write  = 1'b1;
            flag_write = 1'b1;
          end

          OP_OR: begin
            // ACC <- ACC | operand
            alu_op     = ALU_OR;
            acc_write  = 1'b1;
            flag_write = 1'b1;
          end

          OP_XOR: begin
            // ACC <- ACC ^ operand
            alu_op     = ALU_XOR;
            acc_write  = 1'b1;
            flag_write = 1'b1;
          end

          OP_NOT: begin
            // ACC <- ~ACC
            alu_op     = ALU_NOT;
            acc_write  = 1'b1;
            flag_write = 1'b1;
          end

          OP_SHL: begin
            // ACC <- ACC << 1
            alu_op     = ALU_SHL;
            acc_write  = 1'b1;
            flag_write = 1'b1;
          end

          OP_SHR: begin
            // ACC <- ACC >> 1
            alu_op     = ALU_SHR;
            acc_write  = 1'b1;
            flag_write = 1'b1;
          end

          OP_INC: begin
            // ACC <- ACC + 1
            alu_op     = ALU_INC;
            acc_write  = 1'b1;
            flag_write = 1'b1;
          end

          OP_DEC: begin
            // ACC <- ACC - 1
            alu_op     = ALU_DEC;
            acc_write  = 1'b1;
            flag_write = 1'b1;
          end

          OP_JMP: begin
            // PC <- operand
            pc_load = 1'b1;
          end

          OP_JZ: begin
            // PC <- operand if zero flag is set
            if (zero_flag) pc_load = 1'b1;
          end

          OP_HLT: begin
            halted     = 1'b1;
            next_state = HALT;
          end

          default: begin
            // Unknown opcode acts as NOP
          end

        endcase
      end

      HALT: begin
        halted     = 1'b1;
        next_state = HALT;
      end

      default: begin
        next_state = FETCH;
      end

    endcase
  end

endmodule
