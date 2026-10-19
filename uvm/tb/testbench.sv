`include "uvm_macros.svh"
import uvm_pkg::*;

`include "arb_if.sv"
`include "req_agent_pkg.sv"
`include "arb_env_pkg.sv"
`include "arb_test_pkg.sv"

module tb_top;
  import arb_params_pkg::*;
  import arb_test_pkg::*;

  logic clk = 1'b0;
  always #5 clk = ~clk;

  arb_if #(ARB_N) arb (clk);
  req_if          rq [ARB_N] (clk);

  rr_arbiter #(.N(ARB_N)) dut (
    .clk  (clk),
    .rst_n(arb.rst_n),
    .req  (arb.req),
    .gnt  (arb.gnt)
  );

  for (genvar i = 0; i < ARB_N; i++) begin : g_req
    assign rq[i].rst_n = arb.rst_n;
    assign arb.req[i]  = rq[i].req;
    assign rq[i].gnt   = arb.gnt[i];

    initial uvm_config_db#(virtual req_if)::set(
      null, $sformatf("uvm_test_top.env.req_agt_%0d*", i), "vif", rq[i]);
  end

  initial begin
    arb.rst_n = 1'b0;
    repeat (5) @(posedge clk);
    arb.rst_n <= 1'b1;
  end

  initial begin
    if ($test$plusargs("DUMP")) begin
      $dumpfile("dump.vcd");
      $dumpvars(0, tb_top);
    end
  end

  initial begin
    uvm_config_db#(virtual arb_if #(ARB_N))::set(null, "uvm_test_top.env*", "vif", arb);
    run_test();
  end
endmodule
