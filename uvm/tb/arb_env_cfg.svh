class arb_env_cfg extends uvm_object;
  `uvm_object_utils(arb_env_cfg)

  req_cfg rcfg[ARB_N];
  bit     en_sb  = 1;
  bit     en_cov = 1;

  function new(string name = "arb_env_cfg");
    super.new(name);
    foreach (rcfg[i]) begin
      rcfg[i]    = req_cfg::type_id::create($sformatf("rcfg_%0d", i));
      rcfg[i].id = i;
    end
  endfunction

  function void set_all_profiles(req_profile_e prof);
    foreach (rcfg[i]) rcfg[i].set_profile(prof);
  endfunction

  function void set_num_items(int unsigned n);
    foreach (rcfg[i]) rcfg[i].num_items = n;
  endfunction
endclass
