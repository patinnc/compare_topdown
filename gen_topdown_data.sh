#!/bin/bash

GOT_QUIT=0
# function called by trap
catch_signal() {
    printf "\rSIGINT caught      "
    GOT_QUIT=1
}

trap 'catch_signal' SIGINT

VER=36
SCR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#echo "$0.$LINENO SCR_DIR= $SCR_DIR" > /dev/stderr
# select my perf binary
PATH=/root/60secs:$PATH  

RT_DIR=/root
DO_ITP_COLL=$RT_DIR/perfspect/perf-collect
DO_ITP_POST=$RT_DIR/perfspect/perf-postprocess
DO_SPINX=$RT_DIR/60secs/extras/spin.x
DO_PERF3=$RT_DIR/60secs/do_perf3.sh
DO_GET_BW=$RT_DIR/60secs/get_bw.sh
DO_PMU_TOOL=${RT_DIR}/pmu-tools/toplev.py
NUM_CPUS=`grep -c processor /proc/cpuinfo`
NUM_HLF=$((NUM_CPUS/2))
WRK_TYP=freq_sml
WRK_TYP="mem_bw -s 2m -b 64"
WRK_TYP="spin"
WRK_TYP="spin_fast"
ARR_WRK_TYP=("freq_sml" "mem_bw -s 64k -b 64" "mem_bw -s 512k -b 64" "mem_bw -s 1m -b 64" "mem_bw -s 2m -b 64")
ARR_WRK_TYP=("freq_sml")
DUR_SECS=10
TOP_DIR=`pwd`
LST_MON_TYP="pid sys cpu"
LST_MON_TOOL="pmu-tool itp itpLite"
LST_WRK_SZ="$NUM_CPUS $NUM_HLF"
LST_STAGE="echo_cmds gen_data print_data"
ITERS=-1
QUIT_AFTER_ITERS=-1  # if != -1 then quit after this iter. (ITERS % 2)==0 is echo cmds, 1 is do cmds

for MON_TOOL in $LST_MON_TOOL; do
  for WRK_SZ in $LST_WRK_SZ; do
    for MON_TYP in $LST_MON_TYP; do
     for ((w=0; w < ${#ARR_WRK_TYP[@]}; w++)); do
      WRK_TYP=${ARR_WRK_TYP[$w]}
      WRK_TYP_STR=`echo "$WRK_TYP" | sed 's/ /_/g'`
      P=data/tst_v${VER}_${MON_TOOL}_${WRK_TYP_STR}_${WRK_SZ}cpus_${MON_TYP}
      mkdir -p $P
      cd $P
      P=`pwd` # get abs path
      cd $TOP_DIR
      echo ""
      echo "dir= $P"
      echo "dir= $P" > /dev/stderr
      DO_IT=1
      for STAGE in $LST_STAGE; do
        ITERS=$((ITERS+1))
        if [ "$MON_TOOL" == "pmu-tool" -a "$MON_TYP" == "pid" ]; then
          # pmu-tooli doesn't do per pid (as far as I know)
          DO_IT=0
        fi
        if [ "$MON_TOOL" == "itp" -a "$MON_TYP" == "cpu" ]; then
          # itp doesn't do per cpu 
          DO_IT=0
        fi
        if [ "$DO_IT" == "1" ]; then
          pushd $P > /dev/null
          echo "tool $MON_TOOL" > params.txt
          echo "cpus $WRK_SZ"  >> params.txt
          echo "type $MON_TYP"  >> params.txt
          echo "work $WRK_TYP"  >> params.txt
          DOE=
          OFILE_WRK=$P/wrk_out.txt
          OFILE_MON=$P/mon_out.txt
          if [ "$STAGE" == "echo_cmds" ]; then
            DOE=echo
            OFILE_WRK=$P/wrk_cmd.txt
            OFILE_MON=$P/mon_cmd.txt
          fi
          if [ "$STAGE" == "echo_cmds" -o  "$STAGE" == "gen_data" ]; then
            if [ "$MON_TYP" == "pid" ]; then
              MON_PID=
              $DOE $DO_SPINX -w $WRK_TYP -t $DUR_SECS -n $WRK_SZ &> $OFILE_WRK &
              PID=$!
              if [ "$MON_TOOL" == "itpLite" ]; then
                $DOE $DO_PERF3 -F -I 1 -p $P -P $PID -w $DUR_SECS > $OFILE_MON
              fi
              if [ "$MON_TOOL" == "itp" ]; then
                #echo "$0.$LINENO bef coll" > /dev/stderr
                if [ "$STAGE" == "echo_cmds" ]; then
                  LC_ALL=C.UTF-8 LANG=C.UTF-8 $DOE $DO_ITP_COLL -i 1 -o result.csv --pid $PID --tma > $OFILE_MON
                else
                  LC_ALL=C.UTF-8 LANG=C.UTF-8 $DOE $DO_ITP_COLL -i 1 -o result.csv --pid $PID --tma &> $OFILE_MON &
                  MON_PID=$!
                fi
              fi
              #echo "$0.$LINENO bef wait spin" > /dev/stderr
              wait $PID
              #echo "$0.$LINENO aft wait spin" > /dev/stderr
              if [ "$MON_TOOL" == "itp" ]; then
                if [ "$MON_PID" != "" ]; then
                  #echo "$0.$LINENO bef wait mon and kill -2 $MON_PID " > /dev/stderr
                  pkill -2 perf-collect
                  #jobs > /dev/stderr
                  wait
                  #echo "$0.$LINENO aft wait mon and kill -2 $MON_PID " > /dev/stderr
                fi
                LC_ALL=C.UTF-8 LANG=C.UTF-8 $DOE $DO_ITP_POST -o metrics_out.csv -r result.csv --epoch >> $OFILE_MON
              fi
            else
              OPT_C=
              if [ "$MON_TOOL" == "itpLite" ]; then
                if [ "$MON_TYP" == "cpu" ]; then
                  OPT_C=" -W -A "
                fi
                $DOE $DO_PERF3 -F -I 1 -p $P -x $DO_SPINX -X " -w $WRK_TYP -t $DUR_SECS -n $WRK_SZ " $OPT_C > $OFILE_WRK
              fi
              if [ "$MON_TOOL" == "itp" ]; then
                LC_ALL=C.UTF-8 LANG=C.UTF-8 $DOE $DO_ITP_COLL -i 1 -o result.csv  --tma -a "$DO_SPINX -w $WRK_TYP -t $DUR_SECS -n $WRK_SZ "> $OFILE_WRK
                LC_ALL=C.UTF-8 LANG=C.UTF-8 $DOE $DO_ITP_POST -o metrics_out.csv -r result.csv --epoch > $OFILE_MON
              fi
              if [ "$MON_TOOL" == "pmu-tool" ]; then
                if [ "$MON_TYP" == "sys" ]; then
                  OPT_C=" --global "
                fi
                if [ "$MON_TYP" == "cpu" ]; then
                  OPT_C=" --per-thread "
                fi
                if [ "$STAGE" == "echo_cmds" ]; then
                  $DOE python $DO_PMU_TOOL -l3  -x, -o pmt.csv -v $OPT_C --frequency --power  --nodes +CPU_Utilization  -- $DO_SPINX -w $WRK_TYP -t $DUR_SECS -n $WRK_SZ > $OFILE_WRK
                else
                  sysctl kernel.nmi_watchdog=0 && export PERF=$PERF_BIN && python $DO_PMU_TOOL -l3  -x, -o pmt.csv -v $OPT_C --frequency --power  --nodes +CPU_Utilization  -- $DO_SPINX -w $WRK_TYP -t $DUR_SECS -n $WRK_SZ > $OFILE_WRK
                  sysctl kernel.nmi_watchdog=1
                fi
              fi
            fi
          fi
          if [ "$STAGE" == "print_data" ]; then
            if [ -e $P/wrk_cmd.txt ]; then
              cat $P/wrk_cmd.txt
            fi
            if [ -e $P/mon_cmd.txt ]; then
              cat $P/mon_cmd.txt
            fi
            if [ "$MON_TOOL" == "itpLite" ]; then
              $DO_GET_BW -f $P | awk -v dirnm="$P" -v dlm=" " '
               {
                 if ($1 == "time" && got_end == "") {
                  got_end++;
                  str=dlm "directory" dlm "_rk1";
                 }
                 if ($1 == "avg_tot") {
                   got_end++;
                   str=dlm dirnm dlm "_rv1";
                 }
                 printf("%s%s\n", $0, str);
                 str = "";
               }'
            fi
            if [ "$MON_TOOL" == "itp" ]; then
              $SCR_DIR/itp_data_to_common.sh $P/metrics_out.average.csv
            fi
            if [ "$MON_TOOL" == "pmu-tool" ]; then
              $SCR_DIR/pmu-tool_data_to_common.sh $P/pmt.csv
            fi
          fi
          popd > /dev/null
        fi # end of if DOI_IT=1
        if [ "$QUIT_AFTER_ITERS" != "-1" ]; then
          if [[ $ITERS -ge $QUIT_AFTER_ITERS ]]; then
            echo "$0.$LINE got ITERS $ITERS -ge QUIT_AFTER_ITES $QUIT_AFTER_ITERS. Bye" > /dev/stderr
            exit 1
          fi
        fi
        if [ "$GOT_QUIT" != "0" ]; then
          echo "$0.$LINE got quit. Bye" > /dev/stderr
          exit 1
        fi
      done
     done # ARR_WRK_TYP
    done
  done
done
echo "$0.$LINENO bye"
exit




