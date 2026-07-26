`timescale 1ns / 1ps

module cpu_4bit_tb;

  logic clk;
  logic rst_n;
  logic halted;

  logic [3:0] imem_addr;
  logic [7:0] imem_rdata;
  logic [7:0] program_memory [0:15];
  integer i;

  cpu_4bit dut (
      .clk       (clk),
      .rst_n     (rst_n),
      .imem_addr (imem_addr),
      .imem_rdata(imem_rdata),
      .halted    (halted)
  );

  // Program memory belongs to the test environment, not the CPU core.
  initial begin
    for (i = 0; i < 16; i = i + 1) begin
      program_memory[i] = 8'h00;
    end

    $readmemh("memory/program.hex", program_memory);
  end

  // Zero-wait-state, asynchronous instruction-memory model.
  assign imem_rdata = program_memory[imem_addr];

  // Match the 20 ns clock period used by physical design and post-layout GLS.
  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  // Reset and check the CPU.
  initial begin
    rst_n = 1'b0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;

    // Wait for the CPU to execute HLT.
    wait (halted);

    // Wait for the signals to settle.
    @(posedge clk);

    if (dut.acc == 4'd6) $display("TEST PASSED: ACC = %0d", dut.acc);
    else $error("TEST FAILED: ACC = %0d, expected 6", dut.acc);

    $finish;
  end

  // Stop the simulation if the CPU never executes HLT.
  initial begin
    #500;
    $fatal(1, "TEST TIMEOUT: CPU did not halt");
  end

  // Print the CPU state on each clock edge.
  always @(posedge clk) begin
    if (rst_n) begin
      $display("time=%0t PC=%0d IR=%h ACC=%0d halted=%b", $time, dut.pc, dut.ir, dut.acc, halted);
    end
  end

endmodule
