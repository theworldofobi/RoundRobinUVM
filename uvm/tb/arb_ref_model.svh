class arb_ref_model extends uvm_object;
  `uvm_object_utils(arb_ref_model)

  int               last;
  bit [ARB_N-1:0]   owner;

  function new(string name = "arb_ref_model");
    super.new(name);
    reset();
  endfunction

  function void reset();
    last  = ARB_N - 1;
    owner = '0;
  endfunction

  function bit [ARB_N-1:0] step(bit [ARB_N-1:0] req);
    if ((owner & req) != '0) return owner;
    owner = '0;
    for (int k = 1; k <= ARB_N; k++) begin
      int idx = (last + k) % ARB_N;
      if (req[idx]) begin
        owner[idx] = 1'b1;
        last       = idx;
        break;
      end
    end
    return owner;
  endfunction
endclass
