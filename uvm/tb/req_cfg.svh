class req_cfg extends uvm_object;
  `uvm_object_utils(req_cfg)

  int                     id;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  req_profile_e           profile;
  int unsigned            num_items = 60;

  // delay buckets: 0 | [1:3] | [4:10] | [11:30]
  int unsigned wd[4];
  // hold buckets:  1 | [2:4] | [5:8]  | [9:16]
  int unsigned wh[4];

  function new(string name = "req_cfg");
    super.new(name);
    set_profile(PROF_BALANCED);
  endfunction

  function void set_profile(req_profile_e p);
    profile = p;
    case (p)
      PROF_BALANCED: begin wd = '{2, 4, 3, 1}; wh = '{3, 4, 2, 1}; end
      PROF_HEAVY:    begin wd = '{8, 2, 0, 0}; wh = '{0, 2, 4, 4}; end
      PROF_LIGHT:    begin wd = '{0, 1, 4, 5}; wh = '{6, 3, 1, 0}; end
      PROF_SATURATE: begin wd = '{1, 0, 0, 0}; wh = '{2, 4, 2, 1}; end
    endcase
  endfunction
endclass
