class req_monitor extends uvm_monitor;
  `uvm_component_utils(req_monitor)

  typedef enum {S_IDLE, S_WAIT, S_GRANT} state_e;

  virtual req_if vif;
  int            id;
  uvm_analysis_port #(req_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual req_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "req_if not found")
  endfunction

  task run_phase(uvm_phase phase);
    state_e      st     = S_IDLE;
    int unsigned idle_n = 0, wait_n = 0, hold_n = 0;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.rst_n !== 1'b1) begin
        st = S_IDLE; idle_n = 0;
        continue;
      end
      case (st)
        S_IDLE:
          if (vif.mon_cb.req === 1'b1) begin
            wait_n = 1; hold_n = 0; st = S_WAIT;
          end else idle_n++;
        S_WAIT:
          if (vif.mon_cb.gnt === 1'b1) begin
            hold_n = 1; st = S_GRANT;
          end else wait_n++;
        S_GRANT:
          if (vif.mon_cb.req === 1'b1) hold_n++;
          else begin
            publish(idle_n, wait_n, hold_n);
            idle_n = 1;
            st     = S_IDLE;
          end
      endcase
    end
  endtask

  protected function void publish(int unsigned idle_n, wait_n, hold_n);
    req_item t = req_item::type_id::create("obs");
    t.id          = id;
    t.delay       = (idle_n > 0) ? idle_n - 1 : 0;
    t.wait_cycles = wait_n;
    t.hold        = hold_n;
    `uvm_info("REQMON", t.convert2string(), UVM_HIGH)
    ap.write(t);
  endfunction
endclass
