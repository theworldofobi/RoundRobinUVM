`uvm_analysis_imp_decl(_snap)
`uvm_analysis_imp_decl(_req)

class arb_coverage extends uvm_component;
  `uvm_component_utils(arb_coverage)

  uvm_analysis_imp_snap #(arb_snap, arb_coverage) snap_imp;
  uvm_analysis_imp_req  #(req_item, arb_coverage) req_imp;

  int               ptr;
  int               gidx;
  int               prev_gidx;
  int unsigned      req_pop;
  bit [ARB_N-1:0]   dec_req;
  bit [ARB_N-1:0]   prev_gnt, prev_req;

  covergroup cg_cycle;
    cp_pop: coverpoint req_pop {
      bins none = {0};
      bins one  = {1};
      bins some = {[2:ARB_N-1]};
      bins all  = {ARB_N};
    }
  endgroup

  covergroup cg_decision;
    cp_ptr:  coverpoint ptr       { bins ptr_v[] = {[0:ARB_N-1]}; }
    cp_req:  coverpoint dec_req   { bins pat[]   = {[1:(1<<ARB_N)-1]}; }
    cp_gnt:  coverpoint gidx      { bins g[]     = {[0:ARB_N-1]}; }
    cp_prev: coverpoint prev_gidx { bins g[]     = {[0:ARB_N-1]}; }
    cp_wrap: coverpoint gidx      { bins wrap    = (ARB_N-1 => 0); }
    x_ptr_req: cross cp_ptr, cp_req;
    x_trans:   cross cp_prev, cp_gnt;
  endgroup

  covergroup cg_req with function sample(req_item t);
    cp_id: coverpoint t.id { bins id[] = {[0:ARB_N-1]}; }
    cp_wait: coverpoint t.wait_cycles {
      bins immediate = {1};
      bins short     = {[2:4]};
      bins mid       = {[5:15]};
      bins long      = {[16:$]};
    }
    cp_hold: coverpoint t.hold {
      bins one    = {1};
      bins short  = {[2:4]};
      bins mid    = {[5:8]};
      bins long   = {[9:16]};
    }
    cp_delay: coverpoint t.delay {
      bins zero   = {0};
      bins short  = {[1:3]};
      bins mid    = {[4:10]};
      bins long   = {[11:$]};
    }
    x_id_wait: cross cp_id, cp_wait;
    x_id_hold: cross cp_id, cp_hold;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_cycle    = new();
    cg_decision = new();
    cg_req      = new();
    clear_state();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    snap_imp = new("snap_imp", this);
    req_imp  = new("req_imp", this);
  endfunction

  protected function void clear_state();
    ptr = ARB_N - 1; prev_gidx = -1;
    prev_gnt = '0;   prev_req = '0;
  endfunction

  protected function int onehot_idx(bit [ARB_N-1:0] v);
    foreach (v[i]) if (v[i]) return i;
    return -1;
  endfunction

  function void write_snap(arb_snap s);
    if (s.rst_n !== 1'b1) begin
      clear_state();
      return;
    end
    req_pop = $countones(s.req);
    cg_cycle.sample();

    if (s.gnt != '0 && s.gnt != prev_gnt) begin
      gidx    = onehot_idx(s.gnt);
      dec_req = prev_req;
      cg_decision.sample();
      ptr       = gidx;
      prev_gidx = gidx;
    end
    prev_gnt = s.gnt;
    prev_req = s.req;
  endfunction

  function void write_req(req_item t);
    cg_req.sample(t);
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("cycle %.1f%% | decision %.1f%% | request %.1f%%",
              cg_cycle.get_coverage(), cg_decision.get_coverage(),
              cg_req.get_coverage()), UVM_NONE)
  endfunction
endclass
