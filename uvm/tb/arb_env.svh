class arb_env extends uvm_env;
  `uvm_component_utils(arb_env)

  arb_env_cfg    cfg;
  req_agent      agt[ARB_N];
  gnt_monitor    gmon;
  arb_scoreboard sb;
  arb_coverage   cov;
  arb_vseqr      vseqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(arb_env_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("NOCFG", "arb_env_cfg not found")

    foreach (agt[i]) begin
      string nm = $sformatf("req_agt_%0d", i);
      uvm_config_db#(req_cfg)::set(this, nm, "cfg", cfg.rcfg[i]);
      agt[i] = req_agent::type_id::create(nm, this);
    end

    gmon  = gnt_monitor::type_id::create("gmon", this);
    vseqr = arb_vseqr::type_id::create("vseqr", this);
    if (cfg.en_sb)  sb  = arb_scoreboard::type_id::create("sb", this);
    if (cfg.en_cov) cov = arb_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    foreach (agt[i]) begin
      vseqr.req_seqr[i] = agt[i].seqr;
      if (cfg.en_cov) agt[i].mon.ap.connect(cov.req_imp);
    end
    if (cfg.en_sb)  gmon.ap.connect(sb.snap_imp);
    if (cfg.en_cov) gmon.ap.connect(cov.snap_imp);
  endfunction
endclass
