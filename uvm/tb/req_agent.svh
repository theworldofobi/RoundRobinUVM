class req_agent extends uvm_agent;
  `uvm_component_utils(req_agent)

  req_cfg       cfg;
  req_sequencer seqr;
  req_driver    drv;
  req_monitor   mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(req_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("NOCFG", "req_cfg not found")
    is_active = cfg.is_active;

    mon    = req_monitor::type_id::create("mon", this);
    mon.id = cfg.id;

    if (is_active == UVM_ACTIVE) begin
      seqr     = req_sequencer::type_id::create("seqr", this);
      drv      = req_driver::type_id::create("drv", this);
      seqr.cfg = cfg;
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
