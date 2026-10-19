class req_driver extends uvm_driver #(req_item);
  `uvm_component_utils(req_driver)
  virtual req_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual req_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "req_if not found")
  endfunction

  task run_phase(uvm_phase phase);
    req_item it;
    vif.req <= 1'b0;
    forever begin
      seq_item_port.get_next_item(it);
      wait (vif.rst_n === 1'b1);
      fork begin
        fork
          drive(it);
          @(negedge vif.rst_n);
        join_any
        disable fork;
      end join
      if (vif.rst_n !== 1'b1) vif.cb.req <= 1'b0;
      seq_item_port.item_done();
    end
  endtask

  protected task drive(req_item it);
    @(vif.cb);
    repeat (it.delay) @(vif.cb);
    vif.cb.req <= 1'b1;
    do @(vif.cb); while (vif.cb.gnt !== 1'b1);
    repeat (it.hold - 1) @(vif.cb);
    vif.cb.req <= 1'b0;
  endtask
endclass
