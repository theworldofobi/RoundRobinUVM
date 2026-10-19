class req_sequencer extends uvm_sequencer #(req_item);
  `uvm_component_utils(req_sequencer)
  req_cfg cfg;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

class req_base_seq extends uvm_sequence #(req_item);
  `uvm_object_utils(req_base_seq)
  `uvm_declare_p_sequencer(req_sequencer)

  function new(string name = "req_base_seq");
    super.new(name);
  endfunction

  protected task send_random();
    req_item it = req_item::type_id::create("it");
    start_item(it);
    it.id = p_sequencer.cfg.id;
    it.wd = p_sequencer.cfg.wd;
    it.wh = p_sequencer.cfg.wh;
    if (!it.randomize()) `uvm_fatal("RAND", "weighted randomize failed")
    finish_item(it);
  endtask

  protected task send_directed(int unsigned dmin, dmax, hmin, hmax);
    req_item it = req_item::type_id::create("it");
    start_item(it);
    it.id = p_sequencer.cfg.id;
    it.c_delay_w.constraint_mode(0);
    it.c_hold_w.constraint_mode(0);
    if (!it.randomize() with { delay inside {[dmin:dmax]}; hold inside {[hmin:hmax]}; })
      `uvm_fatal("RAND", "directed randomize failed")
    finish_item(it);
  endtask
endclass

class req_rand_seq extends req_base_seq;
  `uvm_object_utils(req_rand_seq)
  int unsigned num_items = 0;

  function new(string name = "req_rand_seq");
    super.new(name);
  endfunction

  task body();
    int unsigned n = (num_items != 0) ? num_items : p_sequencer.cfg.num_items;
    repeat (n) send_random();
  endtask
endclass

class req_directed_seq extends req_base_seq;
  `uvm_object_utils(req_directed_seq)
  int unsigned dmin = 0, dmax = 0, hmin = 1, hmax = 1, count = 1;

  function new(string name = "req_directed_seq");
    super.new(name);
  endfunction

  task body();
    repeat (count) send_directed(dmin, dmax, hmin, hmax);
  endtask
endclass
