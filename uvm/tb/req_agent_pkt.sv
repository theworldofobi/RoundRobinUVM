package req_agent_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import arb_params_pkg::*;

  typedef enum {PROF_BALANCED, PROF_HEAVY, PROF_LIGHT, PROF_SATURATE} req_profile_e;

  `include "req_cfg.svh"
  `include "req_item.svh"
  `include "req_seq_lib.svh"
  `include "req_driver.svh"
  `include "req_monitor.svh"
  `include "req_agent.svh"
endpackage
