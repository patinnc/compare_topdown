#!/bin/bash

# input is output of "./tst_itpLite_spin.sh > tmp.jnk"
if [ "$1" == "" ]; then
  echo "$0.$LINENO arg should be file output of tst_itpLite_spin.sh"
  exit 1
fi
INF=$1
if [ ! -e $INF ]; then
  echo "$0.$LINENO didn't find file $INF. Bye"
  exit 1
fi

grep -E "_r[kv][01]$" $INF   | awk -v script="$0.$LINENO.awk" '
 BEGIN{
   list_repl_old = "%td_ret   %td_bs   %td_fe   %td_be"
   list_repl_new = "%retiring %bad_spec %frt_end %bck_end";
   n_replo = split(list_repl_old, arr_repl_old, " ");
   n_repln = split(list_repl_new, arr_repl_new, " ");
   if (n_replo != n_repln) {
      printf("%s: n_replo= %d not eq n_repln= %d. bye\n", script, n_replo, n_repln) > "/dev/stderr";
      err=1;
      exit(1);
   }
 }
 {
   if ($NF == "_rk0" || $NF == "_rv0") {
    typ=1;
   }
   if ($NF == "_rk1" || $NF == "_rv2") {
    typ=2;
   }
   if ($NF == "_rk0" || $NF == "_rk1") {
    n0++;
    cols[n0] = NF;
    for(i=1; i <= NF; i++) {
      col[n0,i] = $i;
    }
    for(i=1; i <= NF-1; i++) {
     v = $i;
     if (v == "time") {continue;}
     for (jj=1; jj <= n_repln; jj++) {
        if (arr_repl_old[jj] == v) {
          v = arr_repl_new[jj];
          break;
        }
     }
     if (!(v in hdr_list)) {
       hdr_list[v] = ++hdr_mx;
       hdr_lkup[hdr_mx] = v;
     }
     hdr_i = hdr_list[v];
     col2hdr[n0,i] = hdr_i;
     sv[typ,hdr_i,"hdr"] = v;
    }
   }
   if ($NF == "_rv0" || $NF == "_rv1") {
     dir[n0] = $(NF-1);
     for(i=1; i <= NF-1; i++) {
       j = col2hdr[n0,i];
       dt[n0,j] = $i;
     }
   }
 }
 END{
   if (err == 1) {
     printf("%s: exit awk script due to errs\n", script) > "/dev/stderr";
     exit(1);
   }
   for (j=1; j <= n0; j++) {
     file = dir[j] "/params.txt";
     str = "";
     str_not_tool = "";
     while ((getline < file) > 0) {
       parm = $1;
       str = str "," $0;
       $1 = "";
       arg = $0;
       if (!(parm in parm_list)) {
         parm_list[parm] = ++parm_mx;
         parm_lkup[parm_mx] = parm;
       }
       if (parm != "tool") {
         str_not_tool = str_not_tool "," parm "=" arg;
       }
       parm_i = parm_list[parm];
       if (!((parm_i,arg) in arg_list)) {
         arg_mx[parm_i]++;
         arg_list[parm_i,arg] = arg_mx[parm_i];
         arg_lkup[parm_i,arg_mx[parm_i]] = arg;
         #printf("add arg_lkup[%d] param= %s, arg= %s\n", arg_mx[parm_i], parm, arg);
       }
       arg_i = arg_list[parm_i,arg];
       params[j,parm_i] = arg;
       #if (parm == "type") { printf("params[%d,%d]= %s\n", j, parm_i, params[j,parm_i]) > "/dev/stderr";}
     }
     if (!(str_not_tool in list_str_not_tool)) {
         list_str_not_tool[str_not_tool] = ++str_not_tool_mx;
         lkup_str_not_tool[str_not_tool_mx] = str_not_tool;
         printf("add lkup_str_not_tool[%d]= %s\n", str_not_tool_mx, str_not_tool);
     }
     param_str_not_tool[j] = str_not_tool;
     printf("param_str_not_tool[%d] = %s\n", j, str_not_tool);
     close(file);
     printf("%s  %s\n", str, file);
   }
   for (i=1; i <= parm_mx; i++) {
     for (j=1; j <= arg_mx[i]; j++) {
       printf("parm[%d]= %s, arg= %s\n", i, parm_lkup[i], arg_lkup[i,j]);
     }
   }
   dlm=";";
   #for (j=1; j <= n0; j++) {
   #    kstr = param_str_not_tool[j];
   #    printf("file[%d] kstr %s\n", j, kstr);
   #}
   for (k=1; k <= str_not_tool_mx; k++) {
     kstr = lkup_str_not_tool[k];
     printf("str_not_tool[%d]= %s\n", k, kstr);
   }
#   printf("kstr");
#   for (j=1; j <= n0; j++) {
#       kstr = params[j,parm_i];
#       if (param_str_not_tool[j] != kstr) { continue; }
#       printf("%s%s", dlm, kstr);
#   }
#   printf("\n");
   printf("\n");

   #params[j,parm_i] = arg;
   for (pp=1; pp <= parm_mx; pp++) {
     pstr = parm_lkup[pp];
     #params[j,parm_i] = arg;
     printf("%s", pstr);
     for (k=1; k <= str_not_tool_mx; k++) {
       kstr = lkup_str_not_tool[k];
       for (j=1; j <= n0; j++) {
         if (param_str_not_tool[j] != kstr) { continue; }
         parg = params[j,pp];
       #if (pstr == "type") { printf("params[%d,%d]= %s\n", j, pp, params[j,pp]) > "/dev/stderr";}
         printf("%s%s", dlm, parg);
       }
     }
     printf("\n");
   }
   #printf("\n");
   printf("kstr");
   for (k=1; k <= str_not_tool_mx; k++) {
     kstr = lkup_str_not_tool[k];
     for (j=1; j <= n0; j++) {
       if (param_str_not_tool[j] != kstr) { continue; }
       printf("%s%s", dlm, kstr);
     }
   }
   printf("\n");
   printf("dir");
   for (k=1; k <= str_not_tool_mx; k++) {
     kstr = lkup_str_not_tool[k];
     for (j=1; j <= n0; j++) {
       if (param_str_not_tool[j] != kstr) { continue; }
       nn = split(dir[j], arr, "/");
       v = (arr[nn] == "" ? arr[nn-1] : arr[nn]);
       printf("%s%s", dlm, v);
     }
   }
   printf("\n");
    for(i=1; i <= hdr_mx; i++) {
     v = hdr_lkup[i];
     if (v == "directory") {continue;}
     printf("%s", hdr_lkup[i]);
   for (k=1; k <= str_not_tool_mx; k++) {
     kstr = lkup_str_not_tool[k];
     for (j=1; j <= n0; j++) {
       if (kstr != param_str_not_tool[j]) { continue; }
       val = dt[j,i];
       printf("%s%s", dlm, val);
     }
    }
    printf("\n");
   }
 }' 
