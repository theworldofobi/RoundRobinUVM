class arb_base_vseq extends uvm_sequence;
  `uvm_object_utils(arb_base_vseq)
  `uvm_declare_p_sequencer(arb_vseqr)

  int unsigned n_items = 40;

  function new(string name = "arb_base_vseq");
    super.new(name);
  endfunction

  protected task directed(int i, int unsigned dmin, dmax, hmin, hmax,
                          int unsigned count = 1);
    req_directed_seq s = req_directed_seq::type_id::create($sformatf("dir_%0d", i));
    s.dmin = dmin; s.dmax = dmax;
    s.hmin = hmin; s.hmax = hmax;
    s.count = count;
    s.start(p_sequencer.req_seqr[i], this);
  endtask

  protected function void set_profile(int i, req_profile_e prof);
    p_sequencer.req_seqr[i].cfg.set_profile(prof);
  endfunction
endclass

// independent weighted traffic on every line
class arb_rand_vseq extends arb_base_vseq;
  `uvm_object_utils(arb_rand_vseq)
  function new(string name = "arb_rand_vseq"); super.new(name); endfunction

  task body();
    foreach (p_sequencer.req_seqr[i]) begin
      automatic int k = i;
      fork begin
        req_rand_seq s = req_rand_seq::type_id::create($sformatf("rand_%0d", k));
        s.start(p_sequencer.req_seqr[k], this);
      end join_none
    end
    wait fork;
  endtask
endclass

// every line requesting back-to-back
class arb_sat_vseq extends arb_base_vseq;
  `uvm_object_utils(arb_sat_vseq)
  function new(string name = "arb_sat_vseq"); super.new(name); endfunction

  task body();
    for (int i = 0; i < ARB_N; i++) begin
      automatic int k = i;
      fork directed(k, 0, 0, 1, 16, n_items); join_none
    end
    wait fork;
  endtask
endclass

// one line at a time, repeated grants to the same requester
class arb_single_vseq extends arb_base_vseq;
  `uvm_object_utils(arb_single_vseq)
  function new(string name = "arb_single_vseq"); super.new(name); endfunction

  task body();
    for (int k = 0; k < ARB_N; k++) directed(k, 0, 0, 1, 4, 10);
  endtask
endclass

// one request at a time on a random line
class arb_sparse_vseq extends arb_base_vseq;
  `uvm_object_utils(arb_sparse_vseq)
  function new(string name = "arb_sparse_vseq"); super.new(name); endfunction

  task body();
    repeat (n_items) directed($urandom_range(ARB_N - 1), 0, 5, 1, 4);
  endtask
endclass

// for each pointer k and each nonzero pattern p, park the pointer on k,
// then fire p simultaneously, closes x_ptr_req, including all wraparounds
class arb_ptr_sweep_vseq extends arb_base_vseq;
  `uvm_object_utils(arb_ptr_sweep_vseq)
  function new(string name = "arb_ptr_sweep_vseq"); super.new(name); endfunction

   task body();
    for (int k = 0; k < ARB_N; k++) begin
      for (int pat = 1; pat < (1 << ARB_N); pat++) begin
        directed(k, 0, 0, 1, 1);
        for (int j = 0; j < ARB_N; j++) begin
          if (pat[j]) begin
            automatic int jj = j;
            fork directed(jj, 0, 0, 1, 1); join_none
          end
        end
        wait fork;
      end
    end
  endtask
endclass

// random traffic with asynchronous resets injected mid-stream
class arb_reset_vseq extends arb_base_vseq;
  `uvm_object_utils(arb_reset_vseq)
  int unsigned n_resets = 3;
  function new(string name = "arb_reset_vseq"); super.new(name); endfunction

  task body();
    arb_rand_vseq rv = arb_rand_vseq::type_id::create("rv");
    fork rv.start(p_sequencer, this); join_none
    repeat (n_resets) begin
      repeat ($urandom_range(50, 150)) @(posedge p_sequencer.vif.clk);
      p_sequencer.vif.rst_n <= 1'b0;
      repeat ($urandom_range(1, 4)) @(posedge p_sequencer.vif.clk);
      p_sequencer.vif.rst_n <= 1'b1;
    end
    wait fork;
  endtask
endclass

// everything in one run, including a mid-run switch to hog weights
class arb_regress_vseq extends arb_base_vseq;
  `uvm_object_utils(arb_regress_vseq)
  function new(string name = "arb_regress_vseq"); super.new(name); endfunction

  task body();
    arb_ptr_sweep_vseq sweep  = arb_ptr_sweep_vseq::type_id::create("sweep");
    arb_single_vseq    single = arb_single_vseq::type_id::create("single");
    arb_sparse_vseq    sparse = arb_sparse_vseq::type_id::create("sparse");
    arb_sat_vseq       sat    = arb_sat_vseq::type_id::create("sat");
    arb_rand_vseq      bal    = arb_rand_vseq::type_id::create("bal");
    arb_rand_vseq      hog    = arb_rand_vseq::type_id::create("hog");
    arb_reset_vseq     rst    = arb_reset_vseq::type_id::create("rst");

    sweep.start(p_sequencer, this);
    single.start(p_sequencer, this);
    sparse.start(p_sequencer, this);
    sat.n_items = 10;
    sat.start(p_sequencer, this);
    bal.start(p_sequencer, this);

    for (int i = 0; i < ARB_N; i++) set_profile(i, (i < 2) ? PROF_HEAVY : PROF_LIGHT);
    hog.start(p_sequencer, this);
    for (int i = 0; i < ARB_N; i++) set_profile(i, PROF_BALANCED);

    rst.start(p_sequencer, this);
  endtask
endclass
