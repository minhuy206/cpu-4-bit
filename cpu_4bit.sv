module cpu_4bit (
    input  logic       clk,
    input  logic       rst_n,

    // External, asynchronous instruction-memory interface
    output logic [3:0] imem_addr,
    input  logic [7:0] imem_rdata,

    output logic       halted
);

  // CPU registers
  logic [3:0] pc;
  logic [7:0] ir;
  logic [3:0] acc;

  // Status registers
  logic zero_flag;
  logic carry_flag;
  logic borrow_flag;
  logic negative_flag;
  logic overflow_flag;

  // Instruction fields
  logic [3:0] opcode;
  logic [3:0] operand;

  assign opcode    = ir[7:4];
  assign operand   = ir[3:0];
  assign imem_addr = pc;

  // Control signals
  logic [3:0] alu_op;
  logic       ir_load;
  logic       pc_inc;
  logic       pc_load;
  logic       acc_write;
  logic       flag_write;

  control_unit u_control_unit (
      .clk      (clk),
      .rst_n    (rst_n),
      .opcode   (opcode),
      .zero_flag(zero_flag),

      .alu_op    (alu_op),
      .ir_load   (ir_load),
      .pc_inc    (pc_inc),
      .pc_load   (pc_load),
      .acc_write (acc_write),
      .flag_write(flag_write),
      .halted    (halted)
  );

  // ALU signals
  logic [3:0] alu_result;
  logic       alu_zero;
  logic       alu_carry;
  logic       alu_borrow;
  logic       alu_negative;
  logic       alu_overflow;

  alu_4bit u_alu (
      .a     (acc),
      .b     (operand),
      .alu_op(alu_op),

      .result  (alu_result),
      .zero    (alu_zero),
      .carry   (alu_carry),
      .borrow  (alu_borrow),
      .negative(alu_negative),
      .overflow(alu_overflow)
  );

  // CPU registers update
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc            <= 4'b0000;
      ir            <= 8'b0000_0000;
      acc           <= 4'b0000;

      zero_flag     <= 1'b0;
      carry_flag    <= 1'b0;
      borrow_flag   <= 1'b0;
      negative_flag <= 1'b0;
      overflow_flag <= 1'b0;
    end else begin
      if (ir_load) ir <= imem_rdata;

      if (pc_load) pc <= operand;
      else if (pc_inc) pc <= pc + 4'd1;

      if (acc_write) acc <= alu_result;

      if (flag_write) begin
        zero_flag     <= alu_zero;
        carry_flag    <= alu_carry;
        borrow_flag   <= alu_borrow;
        negative_flag <= alu_negative;
        overflow_flag <= alu_overflow;
      end
    end
  end

endmodule
