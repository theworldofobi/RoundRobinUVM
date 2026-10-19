class arb_base_test extends uvm_test;
  `uvm_component_utils(arb_base_test)

  arb_env     env;
  arb_env_cfg cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void configure();
  endfunction

  virtual function arb_base_vseq make_vseq();
    return arb_rand_vseq::type_id::create("vseq");
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = arb_env_cfg::type_id::create("cfg");
    configure();
    uvm_config_db#(arb_env_cfg)::set(this, "env", "cfg", cfg);
    env = arb_env::type_id::create("env", this);
    uvm_top.set_timeout(5ms, 0);
  endfunction

  task run_phase(uvm_phase phase);
    arb_base_vseq v = make_vseq();
    phase.raise_objection(this);
    wait (env.vseqr.vif.rst_n === 1'b1);
    v.start(env.vseqr);
    repeat (20) @(posedge env.vseqr.vif.clk);
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server rs = uvm_report_server::get_server();
    int errs = rs.get_severity_count(UVM_ERROR) + rs.get_severity_count(UVM_FATAL);
    if (errs == 0) `uvm_info("RESULT", "*** TEST PASSED ***", UVM_NONE)
    else           `uvm_info("RESULT", $sformatf("*** TEST FAILED: %0d errors ***", errs), UVM_NONE)
  endfunction
endclass

class arb_rand_test extends arb_base_test;
  `uvm_component_utils(arb_rand_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void configure(); cfg.set_num_items(60); endfunction
endclass

class arb_hog_test extends arb_base_test;
  `uvm_component_utils(arb_hog_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void configure();
    cfg.set_num_items(60);
    foreach (cfg.rcfg[i]) cfg.rcfg[i].set_profile((i < 2) ? PROF_HEAVY : PROF_LIGHT);
  endfunction
endclass

`define ARB_VSEQ_TEST(TNAME, VSEQ) \
class TNAME extends arb_base_test; \
  `uvm_component_utils(TNAME) \
  function new(string name, uvm_component parent); super.new(name, parent); endfunction \
  function arb_base_vseq make_vseq(); return VSEQ::type_id::create("vseq"); endfunction \
endclass

`ARB_VSEQ_TEST(arb_sat_test,     arb_sat_vseq)
`ARB_VSEQ_TEST(arb_single_test,  arb_single_vseq)
`ARB_VSEQ_TEST(arb_sparse_test,  arb_sparse_vseq)
`ARB_VSEQ_TEST(arb_sweep_test,   arb_ptr_sweep_vseq)
`ARB_VSEQ_TEST(arb_reset_test,   arb_reset_vseq)
`ARB_VSEQ_TEST(arb_regress_test, arb_regress_vseq)
