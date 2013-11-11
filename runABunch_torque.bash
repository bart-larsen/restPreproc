#!/usr/bin/env bash
set -xe
source rewardrest.cfg
scriptdir=$(cd $(dirname $0);pwd)
dicomRootDir="/data/Luna1/Raw/MRRC_Org/"  
# SUBJECT=10152 VISIT=20111123 ~/src/restPreproc/rest_preproc_torque

#for dir in /data/Luna1/Raw/MRRC_Org/10128/20080925/ /data/Luna1/Raw/MRRC_Org/10152/20100514; do
for dir in $(find  $dicomRootDir/ -maxdepth 2 -type d -name '[1-2][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' ); do
 #subj_date=$(basename $dir)
 #subj=${subj_date%%_*}
 #date=${subj_date##*_}
 date=$(basename $dir)
 subj=$(basename $(dirname $dir))
 [ -z "$subj" -o -z "$date" ] && echo "bad subj_date $subj_date" && continue
 

# physioDir="/data/Luna1/Reward/Physio/"    
#for dir in $(ls -d $physioDir/*/20* | tail -n 2); do
 #date=$(basename $dir)
 #subj=$(basename $(dirname $dir))

# REDO EVERYONE
#cat ~/src/physioCmp/txt/subject_list.txt|tail -n4 | while read subjdate junk;  do
# subj=${subjdate%%_*}
# date=${subjdate##*_}

 s="${subj}_${date}"

 if qstat -f | grep $s-mprage; then 
   echo "job already running"
   continue
 else
  echo "nothing running"
 fi
 jobid=$(qsub mprage_to_MNI.bash   -h -o logs/ -j oe -N $s-mprage                        -Vv SUBJECT=$subj,VISIT=$date)
 qsub rest_preproc_torque             -o logs/ -j oe -N $s-phys -W depend=afterok:$jobid -Vv SUBJECT=$subj,VISIT=$date
 #qsub rest_preproc_torque          -o logs/ -N $s-noph -W depend=afterok:$jobid -Vv SUBJECT=$subj,VISIT=$date,NOPHYSIO=1,REDO=1
 #qsub rest_preproc_afniproc_torque -o logs/ -N $s-afni -W depend=afterok:$jobid -Vv SUBJECT=$subj,VISIT=$date #,REDO=1
done
