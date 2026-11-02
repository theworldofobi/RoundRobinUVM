class arb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(arb_scoreboard)

  uvm_analysis_imp #(arb_snap, arb_scoreboard) snap_imp;
  arb_ref_model model;

  bit [ARB_N-1:0] exp_grant, prev_grant, prev_req;
  int unsigned    wait_cnt[ARB_N], max_wait[ARB_N], grants[ARB_N];
  int unsigned    n_cmp, n_err;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    snap_imp = new("snap_imp", this);
    model    = arb_ref_model::type_id::create("model");
  endfunction

  function void write(arb_snap s);
    if (s.rst_n !== 1'b1) begin
      model.reset();
      exp_grant = '0; prev_grant = '0; prev_req = '0;
      foreach (wait_cnt[i]) wait_cnt[i] = 0;
      return;
    end

    if ($isunknown(s.req) || $isunknown(s.grant)) begin
      n_err++;
      `uvm_error("SB_X", s.convert2string())
      return;
    end

    n_cmp++;
    if (s.grant !== exp_grant) begin
      n_err++;
      `uvm_error("SB_MISMATCH", $sformatf("%s expected grant=%b",
                 s.convert2string(), exp_grant))
    end

    check_fairness(s);
    exp_grant  = model.step(s.req);
    prev_grant = s.grant;
    prev_req = s.req;
  endfunction

  protected function void check_fairness(arb_snap s);
    bit new_grant = (s.grant != '0) && (s.grant != prev_grant);
    for (int i = 0; i < ARB_N; i++) begin
      bit was_waiting = prev_req[i] && !prev_grant[i];
      if (s.grant[i]) begin
        if (new_grant) grants[i]++;
        wait_cnt[i] = 0;
      end else if (!s.req[i]) begin
        wait_cnt[i] = 0;
      end else if (new_grant && was_waiting) begin
        wait_cnt[i]++;
        if (wait_cnt[i] > max_wait[i]) max_wait[i] = wait_cnt[i];
        if (wait_cnt[i] > ARB_N - 1)
          `uvm_error("SB_STARVE", $sformatf("req[%0d] passed over %0d times at cycle %0d",
                     i, wait_cnt[i], s.cycle))
      end
    end
  endfunction

  function void check_phase(uvm_phase phase);
    if (n_cmp == 0) `uvm_error("SB_EMPTY", "no cycles compared")
  endfunction

  function void report_phase(uvm_phase phase);
    string g = "", w = "";
    foreach (grants[i]) begin
      g = {g, $sformatf(" %0d", grants[i])};
      w = {w, $sformatf(" %0d", max_wait[i])};
    end
    `uvm_info("SB", $sformatf("compared=%0d errors=%0d | grants:%s | max passed-over:%s",
              n_cmp, n_err, g, w), UVM_NONE)
  endfunction
endclass
