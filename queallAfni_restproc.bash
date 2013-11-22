#!/usr/bin/env bash

# call with REDO=1 to redo everyone

scriptdir=$(cd $(dirname $0); pwd);
oldyoungsubjects=$( (head -n3 $scriptdir/subj_date_age.txt; tail -n3 $scriptdir/subj_date_age.txt) | awk '{print $1 "_" $2}'   )

for sid in $(find /data/Luna1/Raw/MRRC_Org/ -maxdepth 2 -type d -iname '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'); do
 sid=$(basename $(dirname $sid))_$(basename $sid)
#for sid in $oldyoungsubjects; do
#for sid in 10845_20100924 10152_20100514; do
  if qstat -f | grep $sid-arp; then 
    echo "job already running"
    continue
  fi
  
  SUBJECT=${sid%%_*}
  VISIT=${sid##*_}

  # get settings, using SUBJECT and VISIT
  source $scriptdir/rewardrest.cfg # FSDIR sdir origepi physiofile restdicomdir
  # sanity check
  [ $s != $sid ] && echo "$s != $sid ($SUBJECT $VISIT)" && exit 1

  # skip if there is no ret
  [ -z "$restdcmdir" -o ! -d "$restdcmdir" ] && echo "no restdcmdir for $s! skipping!" && continue

  # this is pushed to gromit inside qsub command
  # get restepi if needed using SUBJECT and VISIT, saving using sid
  #[ ! -r $origepi ] && source $scriptdir/makerestimage.bash
  export SUBJECT VISIT origepi 

  # qsub can take care of this, but it'll write a log file. this is easier
  [ -z "$REDO" -a -r $sdir/afni_restproc/power_nogsr/pm.cleanEPI+tlrc.HEAD ] && echo "already done, skipping" && continue

  set -x
  qsub  -o $scriptdir/torquelog -j oe  -N $sid-arp qsub_afni_restproc.bash -Vv \
      sid="$sid",sdir="$sdir/",aseg="$fsdir/mri/aseg.mgz",t1="$fsdir/mri/T1.mgz",t2="$origepi",physio="$physiofile",runtype="power_nogsr",origepi=$origepi,REDO=$REDO
  set +x

  ## NO QSUB
  #./onlyafniproc.bash             \
  #    -sid    $sid                \
  #    -sdir   $sdir/              \
  #    -aseg   $fsdir/mri/aseg.mgz \
  #    -t1     $fsdir/mri/T1.mgz   \
  #    -t2     $origepi            \
  #    -physio $physiofile
done
