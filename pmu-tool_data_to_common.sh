#!/bin/bash

INF=$1
if [ "$INF" == "" ]; then
  echo $0.$LINENO required arg to $0 is missing. Should be path of pmt.csv file"
  exit 1
fi
if [ ! -e $INF ]; then
  echo $0.$LINENO didn't find  pmt.csv filename $INF"
  exit 1
fi
if [ -d $INF ]; then
  if [ -e  $INF/pmt.csv ]; then
    INF=$INF/pmt.csv
  else
    echo "$0.$LINENO didn't find  pmt.csv file in dir $INF"
    exit 1
  fi
fi
DIRNM=`dirname $INF`
# Area,Value,Unit,Description,Sample,Stddev,Multiplex,Bottleneck,Idle
# Frontend_Bound,28.4,% Slots,,frontend_retired.latency_ge_4:pp,0.0,3.71,,
# Bad_Speculation,0.0,% Slots <,This category represents fraction of slots wasted due to incorrect speculations...,,0.0,3.71,,
# Backend_Bound,21.7,% Slots,,,0.0,3.71,,
# Retiring,49.9,% Slots <,This category represents fraction of slots utilized by useful work i...,uops_retired.retire_slots,0.0,3.71,,
# CPU_Utilization,1.0,Metric,Average CPU Utilization,,0.0,3.7,,
# Retiring.Light_Operations.Other_Light_Ops,100.0,% Uops <,This metric represents non-floating-point (FP) uop fraction the CPU has executed...,,0.0,3.71,,
awk -F, -v fmt="%8.3f" -v dirnm="$DIRNM" -v dlm=" " '
  BEGIN{
    n_lkup=split("time   mem_bw    %busy   frqGHz LatCycls  Lat(ns)  L3MssBW      IPC %retiring %bad_spec %frt_end %bck_end  %cyc_be %cyc_uopRet pkg_watts LatUnc(ns) LatUncCycls LatUncBW %L3_miss   bw_rmt", list, " ");
    #printf("n_lkup= %d\n", n_lkup);
    for (i=1; i <= n_lkup; i++) { lkup[list[i]] = i; }
    add_xtra = 0;
  }
  /metric_memory bandwidth read .MB\/sec./{ i=lkup["mem_bw"]; sv[i] = sprintf(fmt, 0.001*$2); }
  /metric_Average LLC data read miss latency .in ns./{ i = lkup["LatCycls"]; sv[i] = sprintf(fmt, frq*$2);
      i = lkup["Lat(ns)"]; sv[i] = sprintf(fmt, $2);
      i = lkup["L3MssBW"]; sv[i] = "";
  }
  /metric_CPI/{ i = lkup["IPC"]; sv[i] = sprintf(fmt, 1.0/$2); }
  /metric_package power/{ i = lkup["pkg_watts"]; sv[i] = sprintf(fmt, $2); }
  FNR == 1 { if ($1 == "CPUs") {printf("got_cpus\n"); add_xtra = 1;}}
  add_xtra == 1 {if (add_xtra == 1 && index($1, "-T1") > 1) { next; }}
  $(1+add_xtra) == "Frequency"{    i = lkup["frqGHz"]; frq = $(2+add_xtra)+0.0; sv[i] += sprintf(fmt, frq); ++num[i]; }
  $(1+add_xtra) == "CPU_Utilization"{ i=lkup["%busy"]; sv[i] += sprintf(fmt, $(2+add_xtra)*100); ++num[i]; }
  $(1+add_xtra) == "Retiring"{ i = lkup["%retiring"]; sv[i] += sprintf(fmt, $(2+add_xtra)); ++num[i]; }
  $(1+add_xtra) == "Bad_Speculation"{ i = lkup["%bad_spec"]; sv[i] += sprintf(fmt, $(2+add_xtra)); ++num[i]; }
  $(1+add_xtra) == "Frontend_Bound"{ i = lkup["%frt_end"]; sv[i] += sprintf(fmt, $(2+add_xtra)); ++num[i]; }
  $(1+add_xtra) == "Backend_Bound"{ i = lkup["%bck_end"]; sv[i] += sprintf(fmt, $(2+add_xtra)); ++num[i]; }
  END {
# avg_tot    0.023   98.947    2.700  373.124  169.602    0.001    0.998   49.922    0.006   28.375   21.698    0.653   99.216  132.456   85.557  230.987    0.005   21.772    0.004
#    time   mem_bw    %busy   frqGHz LatCycls  Lat(ns)  L3MssBW      IPC %retiring %bad_spec %frt_end %bck_end  %cyc_be %cyc_uopRet pkg_watts LatUnc(ns) LatUncCycls LatUncBW %L3_miss   bw_rmt
            0.023   98.712    2.700  451.029  167.058            0.998   49.860    0.023   28.334   21.783                  132.136         
    for (j=1; j <= 2; j++) {
      for (i=1; i <= n_lkup; i++) {
        v = sv[i];
        n = num[i];
        if (n > 0) { v = v / n ; }
        if (j == 1 && v != "") {
          printf("%s%8s", dlm, list[i]);
        } 
        if (j == 2 && v != "") {
          v =  (dlm == " " && v == "" ? "_" : v);
          printf("%s%8s", dlm, v);
        }
      }
      printf("%s%s%s%s\n", dlm, (j==1?"directory":dirnm), dlm, (j==1 ? "_rk0" : "_rv0"));
    }
  }
  ' $INF
