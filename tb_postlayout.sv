`timescale 1ns / 1ps

module cpu_4bit_tb_postlayout;

  logic clk;
  logic rst_n;
  logic halted;
  logic [3:0] imem_addr;
  logic [7:0] imem_rdata;
  logic [7:0] program_memory [0:15];
  integer i;

  supply1 VPWR;
  supply0 VGND;

  cpu_4bit dut (
      .clk       (clk),
      .rst_n     (rst_n),
      .VPWR      (VPWR),
      .VGND      (VGND),
      .imem_addr (imem_addr),
      .imem_rdata(imem_rdata),
      .halted    (halted)
  );

  initial begin
    if ($test$plusargs("DUMP_WAVE")) begin
      $dumpfile("runs/manual_tcl_util65_v2/post_layout_npcfix_wave.vcd");
      $dumpvars(0, cpu_4bit_tb_postlayout);
    end
  end

  initial begin
    if (!$test$plusargs("NO_SDF")) begin
      $sdf_annotate(
          "runs/manual_tcl_util65_v2/cpu_4bit_manual_npcfix.nom.sdf",
          dut,
          ,
          "runs/manual_tcl_util65_v2/post_layout_npcfix_sdf.log",
          "MAXIMUM"
      );
    end
  end

  initial begin
    for (i = 0; i < 16; i = i + 1) begin
      program_memory[i] = 8'h00;
    end
    $readmemh("memory/program.hex", program_memory);
  end

  assign imem_rdata = program_memory[imem_addr];

  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  initial begin
    rst_n = 1'b0;
    repeat (1) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;

    wait (halted === 1'b1);
    @(posedge clk);

    if ({dut.\acc[3] , dut.\acc[2] , dut.\acc[1] , dut.\acc[0] } == 4'd6) begin
      $display("POST-LAYOUT SIMULATION PASSED: ACC = 6");
    end else begin
      $error("POST-LAYOUT SIMULATION FAILED: ACC = %b%b%b%b, expected 0110", dut.\acc[3] , dut.\acc[2] , dut.\acc[1] , dut.\acc[0] );
    end

    $finish;
  end

  initial begin
    #2000;
    $fatal(1, "POST-LAYOUT SIMULATION TIMEOUT: CPU did not halt");
  end

endmodule
