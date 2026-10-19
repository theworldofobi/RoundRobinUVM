class arb_vseqr extends uvm_sequencer;
  `uvm_component_utils(arb_vseqr)

  req_sequencer           req_seqr[ARB_N];
  virtual arb_if #(ARB_N) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual arb_if #(ARB_N))::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "arb_if not found")
  endfunction
endclass
