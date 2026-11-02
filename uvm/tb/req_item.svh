class req_item extends uvm_sequence_item;
  `uvm_object_utils(req_item)

  rand int unsigned delay;
  rand int unsigned hold;

  int unsigned wd[4] = '{1, 1, 1, 1};
  int unsigned wh[4] = '{1, 1, 1, 1};

  int          id;
  int unsigned wait_cycles;

  constraint c_legal  { hold inside {[1:16]}; delay <= 30; }

  constraint c_delay_w {
    delay dist { 0 := wd[0], [1:3] :/ wd[1], [4:10] :/ wd[2], [11:30] :/ wd[3] };
  }

  constraint c_hold_w {
    hold dist { 1 := wh[0], [2:4] :/ wh[1], [5:8] :/ wh[2], [9:16] :/ wh[3] };
  }

  function new(string name = "req_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("id=%0d delay=%0d hold=%0d wait=%0d", id, delay, hold, wait_cycles);
  endfunction
endclass
