class arb_snap extends uvm_sequence_item;
  `uvm_object_utils(arb_snap)

  logic             rst_n;
  logic [ARB_N-1:0] req;
  logic [ARB_N-1:0] gnt;
  longint unsigned  cycle;

  function new(string name = "arb_snap");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("cyc=%0d rst_n=%b req=%b gnt=%b", cycle, rst_n, req, gnt);
  endfunction
endclass

class gnt_monitor extends uvm_monitor;
  `uvm_component_utils(gnt_monitor)

  virtual arb_if #(ARB_N) vif;
  uvm_analysis_port #(arb_snap) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual arb_if #(ARB_N))::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "arb_if not found")
  endfunction

  task run_phase(uvm_phase phase);
    longint unsigned cyc = 0;
    forever begin
      arb_snap s;
      @(vif.mon_cb);
      s       = arb_snap::type_id::create("s");
      s.rst_n = vif.mon_cb.rst_n;
      s.req   = vif.mon_cb.req;
      s.gnt   = vif.mon_cb.gnt;
      s.cycle = cyc++;
      ap.write(s);
    end
  endtask
endclass
