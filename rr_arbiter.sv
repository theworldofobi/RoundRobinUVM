module fixed_priority_encoder #(
  parameter N = 4
) (
  input  logic [N-1:0] req,
  output logic [N-1:0] grant
);

  assign grant = req & (~req + 1'b1);

endmodule

module mask_gen #(
  parameter N = 4
) (
  input  logic [N-1:0] grant,
  output logic [N-1:0] mask
);

  logic [N-1:0] shift;
  assign shift = grant << 1;
  assign mask  = ~(shift - 1'b1);

endmodule

module round_robin_arbiter #(
  parameter N = 4
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [N-1:0] req,
  output logic [N-1:0] grant
);
  
  logic [N-1:0] mask_d, mask_q;
  logic [N-1:0] req_masked, grant_masked, grant_unmasked, grant_d;
  logic         hold;

  assign req_masked = req & mask_q;

  fixed_priority_encoder #(
    .N(N)
  ) u_pe_masked (
    .req  (req_masked),
    .grant(grant_masked)
  );

  fixed_priority_encoder #(
    .N(N)
   ) u_pe_raw (
    .req  (req),
    .grant(grant_unmasked)
  );

  assign grant_d = (|req_masked) ? grant_masked : grant_unmasked;

  mask_gen #(
    .N(N)
   ) u_mask (
    .grant(grant_d),
    .mask (mask_d)
  );

  assign hold = |(grant & req);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant  <= '0;
      mask_q <= '1;
    end else if (!hold) begin
      grant  <= grant_d;
      if (!req) mask_q <= mask_d;
    end
  end
  
endmodule
