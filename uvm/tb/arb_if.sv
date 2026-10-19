`ifndef ARB_N_VAL
`define ARB_N_VAL 4
`endif

package arb_params_pkg;
  parameter int ARB_N = `ARB_N_VAL;
endpackage

// one requester line driven by one agent
interface req_if (input logic clk);
  logic req;
  wire  gnt;
  wire  rst_n;

  clocking cb @(posedge clk);
    default input #1step output #1;
    output req;
    input  gnt, rst_n;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input req, gnt, rst_n;
  endclocking
endinterface

// whole bus observed passively
interface arb_if #(parameter int N = 4) (input logic clk);
  logic         rst_n;
  wire  [N-1:0] req;
  wire  [N-1:0] gnt;

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst_n, req, gnt;
  endclocking
endinterface
