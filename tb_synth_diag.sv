`timescale 1ns / 1ps

module cpu_4bit_tb_synth_diag;
  logic clk;
  logic rst_n;
  logic halted;
  logic [3:0] imem_addr;
  logic [7:0] imem_rdata;
  logic [7:0] program_memory [0:15];
  integer i;

  cpu_4bit dut (
      .clk(clk),
      .rst_n(rst_n),
      .imem_addr(imem_addr),
      .imem_rdata(imem_rdata),
      .halted(halted)
  );

  initial begin
    for (i = 0; i < 16; i = i + 1)
      program_memory[i] = 8'h00;
    $readmemh("memory/program.hex", program_memory);
  end

  assign imem_rdata = program_memory[imem_addr];

  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  initial begin
    rst_n = 1'b0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    wait (halted === 1'b1);
    @(posedge clk);

    if ({dut.\acc[3] , dut.\acc[2] , dut.\acc[1] , dut.\acc[0] } == 4'd6)
      $display("SYNTHESIS GLS PASSED: ACC = 0110");
    else
      $error("SYNTHESIS GLS FAILED: ACC = %b%b%b%b, expected 0110", dut.\acc[3] , dut.\acc[2] , dut.\acc[1] , dut.\acc[0] );
    $finish;
  end

  initial begin
    #2000;
    $fatal(1, "SYNTHESIS GLS TIMEOUT");
  end
endmodule
