module program_rom (
    input  logic [3:0] address,
    output logic [7:0] instruction
);

  logic [7:0] memory [0:15];
  integer i;

  initial begin
    for (i = 0; i < 16; i = i + 1) begin
      memory[i] = 8'h00;
    end

    $readmemh("memory/program.hex", memory);
  end

  assign instruction = memory[address];

endmodule
