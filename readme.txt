
compare level 1 topdown stats for itp(perfspect), itpLite (60secs repo) and pmu-tools (Andi Kleen's repo)
Let you see topdown stats from different topdown tools running different workloads

To run it:
  cd compare_topdown
  get 60secs and pmu-tools and perf and spin.x (see below for github locations)
  edit gen_topdown_data.sh with paths to each tool
  as root do:
  ./gen_topdown_data.sh > tmp.txt
    This has 3 stages (echo cmds, then gen_dat then print_results)
    It run 3 monitoring tools against 'spin.x -w freq_sml' on all the cpus and on half the cpus.
    The script tries to run 'per system', 'per pid' and 'per cpu' data collection for each monitoring tool.
    So about 18 output directories
    
    sample output for cascade lake (48 cpus on 2 sockets) is included

  ./common_to_csv.sh tmp.txt > tmp1.txt
    reads the output from each dir and puts it into a common format
    creates a ';' delimited output in tmp1.txt

    I pasted the lines from tmp1.txt into excel spreadsheet sample_compare_itp_itpLite_pmu-tools.xlsx. The text csv lines look like below
    This lets you see the level 1 topdown stats from each tool with different workloads and monitoring parameters.
    Note that itp doesn't do 'per cpu' collection.
    Also pmu-tool doesn't really do 'per cpu' topdown... it computes the metrics per core and then reports both HT threads (so if you ran nothing on HT1 you'd get the HT0 stats posted to HT1).

    The 60secs tools are available from https://github.com/patinnc/60secs
      You can get spin.x is from https://github.com/patinnc/oppat (cd oppat; ./mk_spin.sh) or 
          you can get the statically linked spin.x binary from https://github.com/patinnc/patinnc.github.io/blob/master/bin/spin.x
        You can get the statically linked linux 5.10 perf from https://github.com/patinnc/patinnc.github.io/blob/master/bin/perf
    The pmu-tools are from https://github.com/andikleen/pmu-tools

      tool; pmu-tool; itp; itpLite; pmu-tool; itpLite; pmu-tool; itp; itpLite; pmu-tool; itpLite; itp; itpLite; itp; itpLite
      cpus; 48; 48; 48; 48; 48; 24; 24; 24; 24; 24; 48; 48; 24; 24
      type; sys; sys; sys; cpu; cpu; sys; sys; sys; cpu; cpu; pid; pid; pid; pid
      work; freq_sml; freq_sml; freq_sml; freq_sml; freq_sml; freq_sml; freq_sml; freq_sml; freq_sml; freq_sml; freq_sml; freq_sml; freq_sml; freq_sml
      kstr;,cpus= 48,type= sys,work= freq_sml;,cpus= 48,type= sys,work= freq_sml;,cpus= 48,type= sys,work= freq_sml;,cpus= 48,type= cpu,work= freq_sml;,cpus= 48,type= cpu,work= freq_sml;,cpus= 24,type= sys,work= freq_sml;,cpus= 24,type= sys,work= freq_sml;,cpus= 24,type= sys,work= freq_sml;,cpus= 24,type= cpu,work= freq_sml;,cpus= 24,type= cpu,work= freq_sml;,cpus= 48,type= pid,work= freq_sml;,cpus= 48,type= pid,work= freq_sml;,cpus= 24,type= pid,work= freq_sml;,cpus= 24,type= pid,work= freq_sml
      dir;tst_v36_pmu-tool_freq_sml_48cpus_sys;tst_v36_itp_freq_sml_48cpus_sys;tst_v36_itpLite_freq_sml_48cpus_sys;tst_v36_pmu-tool_freq_sml_48cpus_cpu;tst_v36_itpLite_freq_sml_48cpus_cpu;tst_v36_pmu-tool_freq_sml_24cpus_sys;tst_v36_itp_freq_sml_24cpus_sys;tst_v36_itpLite_freq_sml_24cpus_sys;tst_v36_pmu-tool_freq_sml_24cpus_cpu;tst_v36_itpLite_freq_sml_24cpus_cpu;tst_v36_itp_freq_sml_48cpus_pid;tst_v36_itpLite_freq_sml_48cpus_pid;tst_v36_itp_freq_sml_24cpus_pid;tst_v36_itpLite_freq_sml_24cpus_pid
      %busy;100;99.062;98.940;100;98.953;50;48.762;49.622;100;49.621;190.951;90.263;92.730;45.129
      frqGHz;2.7;2.699;2.696;2.7;2.696;2.7;2.699;2.696;2.7;2.696;2.700;2.700;2.700;2.700
      %retiring;49.9;49.863;49.911;49.8917;24.924;25.1;25.328;25.140;25.0917;25.002;24.970;24.934;25.114;25.088
      %bad_spec;0;0.024;0.024;0;0.014;0;0.170;0.017;0;0.010;0.007;0.003;0.010;0.003
      %frt_end;28.4;28.337;28.376;28.3958;14.175;0.1;0.132;0.096;0.1125;0.097;14.189;14.166;0.025;0.026
      %bck_end;21.7;21.776;21.690;21.7125;60.886;74.7;74.370;74.747;74.7083;74.892;60.833;60.898;74.851;74.883
      IPC;;0.998;0.998;;0.999;;1.002;1.001;;1.001;1.000;0.998;1.005;1.004
      mem_bw;;0.034;0.025;;0.025;;0.044;0.036;;0.035;;;;
      LatCycls;;421.495;293.865;;286.963;;421.313;336.368;;325.490;;;;
      Lat(ns);;156.139;133.575;;130.438;;156.103;152.894;;147.950;;;;
      pkg_watts;;133.218;133.643;;133.556;;119.275;120.239;;120.243;;;;
      %cyc_be;;;0.640;;0.643;;;0.312;;0.316;;0.631;;0.089
      %cyc_uopRet;;;99.225;;99.192;;;99.477;;99.510;;99.230;;99.833
      L3MssBW;;;0.001;;0.001;;;0.003;;0.003;;;;
      LatUnc(ns);;;84.473;;84.894;;;104.687;;104.919;;;;
      LatUncCycls;;;227.735;;228.873;;;282.203;;282.826;;;;
      LatUncBW;;;0.004;;0.004;;;0.006;;0.006;;;;
      %L3_miss;;;17.205;;16.724;;;15.755;;16.018;;;;
      bw_rmt;;;0.003;;0.003;;;0.006;;0.006;;;;

