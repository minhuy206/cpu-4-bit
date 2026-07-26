`timescale 1ns / 1ps

// Post-layout gate-level simulation testbench.
// Compile this with the powered netlist (.pnl.v), the Sky130 functional
// standard-cell models. Xcelium applies SDF through xcelium_sdf.cmd.
module cpu_4bit_tb_gls;

  logic clk;
  logic rst_n;
  logic halted;

  logic [3:0] imem_addr;
  logic [7:0] imem_rdata;
  logic [7:0] program_memory [0:15];
  integer i;

  // These supplies connect the powered netlist's VPWR/VGND ports.
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
      $dumpfile("runs/manual_tcl_util65/post_layout_wave.vcd");
      $dumpvars(0, cpu_4bit_tb_gls);
    end
  end

  initial begin
    $sdf_annotate(
        "runs/manual_tcl_util65/cpu_4bit_manual_final_fixed.nom.sdf",
        dut,
        ,
        "runs/manual_tcl_util65/post_layout_sdf.log",
        "TYPICAL"
    );
  end

  initial begin
    for (i = 0; i < 16; i = i + 1) begin
      program_memory[i] = 8'h00;
    end
    $readmemh("memory/program.hex", program_memory);
  end

  // The external zero-wait-state instruction-memory model remains in the TB.
  assign imem_rdata = program_memory[imem_addr];

  initial begin
    clk = 1'b0;
    // Match CLOCK_PERIOD=20 ns in config.json.
    forever #10 clk = ~clk;
  end

  initial begin
    rst_n = 1'b0;
    repeat (2) @(posedge clk);
    rst_n = 1'b1;

    wait (halted === 1'b1);
    @(posedge clk);

    // Yosys preserves these as escaped one-bit names in the gate netlist.
    if ({dut.\acc[3] , dut.\acc[2] , dut.\acc[1] , dut.\acc[0] } == 4'd6) begin
      $display("POST-LAYOUT GLS PASSED: ACC = 6");
    end else begin
      $error("POST-LAYOUT GLS FAILED: ACC = %b%b%b%b, expected 0110",
          dut.\acc[3] , dut.\acc[2] , dut.\acc[1] , dut.\acc[0] );
    end

    $finish;
  end

  initial begin
    #2000;
    $fatal(1, "POST-LAYOUT GLS TIMEOUT: CPU did not halt");
  end

endmodule
