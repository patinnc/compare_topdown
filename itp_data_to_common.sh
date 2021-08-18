#!/bin/bash

INF=$1
if [ "$INF" == "" ]; then
  echo $0.$LINENO required arg to $0 is missing. Should be path of metrics_out.average.csv file"
  exit 1
fi
if [ ! -e $INF ]; then
  echo $0.$LINENO didn't find  metrics_out.average.csv filename $INF"
  exit 1
fi
if [ -d $INF ]; then
  if [ -e  $INF/metrics_out.average.csv ]; then
    INF=$INF/metrics_out.average.csv
  else
    echo "$0.$LINENO didn't find  metrics_out.average.csv file in dir $INF"
    exit 1
  fi
fi
DIRNM=`dirname $INF`
awk -F, -v fmt="%8.3f" -v dirnm="$DIRNM" -v dlm=" " '
  BEGIN{
    n_lkup=split("time   mem_bw    %busy   frqGHz LatCycls  Lat(ns)  L3MssBW      IPC %retiring %bad_spec %frt_end %bck_end  %cyc_be %cyc_uopRet pkg_watts LatUnc(ns) LatUncCycls LatUncBW %L3_miss   bw_rmt", list, " ");
    #printf("n_lkup= %d\n", n_lkup);
    for (i=1; i <= n_lkup; i++) { lkup[list[i]] = i; }
  }
  /metric_memory bandwidth read .MB\/sec./{ i=lkup["mem_bw"]; sv[i] = sprintf(fmt, 0.001*$2); }
  /metric_CPU utilization %/{ i=lkup["%busy"]; sv[i] = sprintf(fmt, $2); }
  /metric_CPU operating frequency/{ i = lkup["frqGHz"]; frq = $2+0.0; sv[i] = sprintf(fmt, frq);
     #printf("list[%d]= %s, frq= %s\n", i, list[i], sv[i]);
  }
  /metric_Average LLC data read miss latency .in ns./{ i = lkup["LatCycls"]; sv[i] = sprintf(fmt, frq*$2);
      i = lkup["Lat(ns)"]; sv[i] = sprintf(fmt, $2);
      i = lkup["L3MssBW"]; sv[i] = "";
  }
  /metric_CPI/{ i = lkup["IPC"]; sv[i] = sprintf(fmt, 1.0/$2); }
  /metric_TMAM_Retiring.%.|metric_TMA_Retiring.%./{ i = lkup["%retiring"]; sv[i] = sprintf(fmt, $2); }
  /metric_TMAM_Bad_Speculation|metric_TMA_Bad_Speculation/{ i = lkup["%bad_spec"]; sv[i] = sprintf(fmt, $2); }
  /metric_TMAM_Frontend_Bound|metric_TMA_Frontend_Bound/{ i = lkup["%frt_end"]; sv[i] = sprintf(fmt, $2); }
  /metric_TMAM_Backend_bound|metric_TMA_Backend_Bound/{ i = lkup["%bck_end"]; sv[i] = sprintf(fmt, $2); }
  /metric_package power/{ i = lkup["pkg_watts"]; sv[i] = sprintf(fmt, $2); }
  END {
# avg_tot    0.023   98.947    2.700  373.124  169.602    0.001    0.998   49.922    0.006   28.375   21.698    0.653   99.216  132.456   85.557  230.987    0.005   21.772    0.004
#    time   mem_bw    %busy   frqGHz LatCycls  Lat(ns)  L3MssBW      IPC %retiring %bad_spec %frt_end %bck_end  %cyc_be %cyc_uopRet pkg_watts LatUnc(ns) LatUncCycls LatUncBW %L3_miss   bw_rmt
            0.023   98.712    2.700  451.029  167.058            0.998   49.860    0.023   28.334   21.783                  132.136         
    for (j=1; j <= 2; j++) {
      for (i=1; i <= n_lkup; i++) {
        v = sv[i];
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
