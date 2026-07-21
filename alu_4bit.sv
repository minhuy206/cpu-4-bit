module alu_4bit (
    input logic [3:0] a,
    input logic [3:0] b,
    input logic [3:0] alu_op,

    output logic [3:0] result,
    output logic       zero,
    output logic       carry,
    output logic       borrow,
    output logic       negative,
    output logic       overflow
);

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

  logic [4:0] temp;

  always_comb begin
    result   = 4'b0000;
    carry    = 1'b0;
    borrow   = 1'b0;
    overflow = 1'b0;
    temp     = 5'b00000;

    case (alu_op)
      ALU_ADD: begin
        temp     = {1'b0, a} + {1'b0, b};
        result   = temp[3:0];
        carry    = temp[4];
        overflow = (~(a[3] ^ b[3])) & (result[3] ^ a[3]);
      end

      ALU_SUB: begin
        result   = a - b;
        borrow   = (a < b);
        overflow = (a[3] ^ b[3]) & (result[3] ^ a[3]);
      end

      ALU_AND: begin
        result = a & b;
      end

      ALU_OR: begin
        result = a | b;
      end

      ALU_XOR: begin
        result = a ^ b;
      end

      ALU_NOT: begin
        result = ~a;
      end

      ALU_INC: begin
        temp     = {1'b0, a} + 5'b00001;
        result   = temp[3:0];
        carry    = temp[4];
        overflow = (a == 4'b0111);
      end

      ALU_DEC: begin
        result   = a - 4'b0001;
        borrow   = (a == 4'b0000);
        overflow = (a == 4'b1000);
      end

      ALU_SHL: begin
        result = a << 1;
        carry  = a[3];
      end

      ALU_SHR: begin
        result = a >> 1;
        carry  = a[0];
      end

      ALU_PASS_B: begin
        result = b;
      end

      default: begin
        result = 4'b0000;
      end
    endcase
  end

  assign zero     = (result == 4'b0000);
  assign negative = result[3];

endmodule
