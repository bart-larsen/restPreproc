#!/usr/bin/env bash

scriptdir=$(cd $(dirname $0); pwd);
oldyoungsubjects=$( (head -n3 $scriptdir/subj_date_age.txt; tail -n3 $scriptdir/subj_date_age.txt) | awk '{print $1 "_" $2}'   )

#for sid in $oldyoungsubjects; do
for sid in 10845_20100924 10152_20100514; do

  if qstat -f | grep $sid-arp; then 
    echo "job already running"
    continue
  fi
  
  SUBJECT=${sid%%_*}
  VISIT=${sid##*_}

  # get settings, using SUBJECT and VISIT
  source $scriptdir/rewardrest.cfg # FSDIR sdir origepi physiofile
  # get restepi if needed using SUBJECT and VISIT, saving using sid
  [ ! -r $origepi ] && source $scriptdir/makerestimage.bash

  qsub -o $scritpdir/torquelog -j oe  -N $sid-arp qsub_afni_restproc.bash -Vv \
      sid="$sid",sdir="$sdir/",aseg="$fsdir/mri/aseg.mgz",t1="$fsdir/mri/T1.mgz",t2="$origepi",physio="$physiofile" #,REDO=1

  ## NO QSUB
  #./onlyafniproc.bash             \
  #    -sid    $sid                \
  #    -sdir   $sdir/              \
  #    -aseg   $fsdir/mri/aseg.mgz \
  #    -t1     $fsdir/mri/T1.mgz   \
  #    -t2     $origepi            \
  #    -physio $physiofile
done
