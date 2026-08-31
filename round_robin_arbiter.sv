module round_robin_arbiter #(
  parameter N = 4
) (
  input  logic         clk,
  input  logic         rst_an,
  input  logic [N-1:0] req,
  output logic [N-1:0] grant
);
  logic [N-1:0] rotate_ptr;
  logic [N-1:0] mask_req;
  logic [N-1:0] mask_grant;
  logic [N-1:0] grant_comb;
  logic         non_mask_req;
  logic [N-1:0] non_mask_grant;
  logic         update_ptr;

  assign update_ptr = | grant[N-1:0];
  
  always_ff @(posedge clk or negedge rst_an) begin
    if (!rst_an) begin
      rotate_ptr[N-1:0] <= '1;
    end else if (update_ptr) begin
      rotate_ptr[0] <= grant[N-1];
      rotate_ptr[1] <= grant[N-1] | grant[0];
    end
  end
  
  genvar i;
  generate
    for (i = 2; i < N; i++) begin : gen_rotate_ptr
      always_ff @(posedge clk or negedge rst_an) begin
        if (!rst_an) begin
          rotate_ptr[i] <= 1'b1;
        end else if (update_ptr) begin
          rotate_ptr[i] <= grant[N-1] | (|grant[i-1:0]);
        end
      end
    end
  endgenerate

  assign mask_req[N-1:0] = req[N-1:0] & rotate_ptr[N-1:0];
  assign mask_grant[0] = mask_req[0];
  
  generate
    for (i = 1; i < N; i++) begin : gen_mask_grant
      assign mask_grant[i] = (~|mask_req[i-1:0]) & mask_req[i];
    end
  endgenerate

  assign non_mask_grant[0] = req[0];

  generate
    for (i = 1; i < N; i++) begin : gen_non_mask_grant
      assign non_mask_grant[i] = (~|req[i-1:0]) & req[i];
    end
  endgenerate

  assign non_mask_req = ~|mask_req[N-1:0];
  assign grant_comb[N-1:0] = mask_grant[N-1:0] | (non_mask_grant[N-1:0] & {N{non_mask_req}});

  always_ff @(posedge clk or negedge rst_an) begin
    if (!rst_an) begin
      grant[N-1:0] <= '0;
    end else begin
      grant[N-1:0] <= grant_comb[N-1:0] & ~grant[N-1:0];
    end
  end

endmodule
