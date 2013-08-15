#!/usr/bin/env bash

source rewardrest.cfg
scriptdir=$(cd $(dirname $0);pwd)
# dicomRootDir="/data/Luna1/Raw/MRCTR/"  
# SUBJECT=10152 VISIT=20111123 ~/src/restPreproc/rest_preproc_torque

#for dir in $(ls -d $dicomRootDir/*_* | head -n 3); do
# subj_date=$(basename $dir)
# subj=${subj_date%%_*}
# date=${subj_date##*_}

# physioDir="/data/Luna1/Reward/Physio/"    
#for dir in $(ls -d $physioDir/*/20* | tail -n 2); do
 #date=$(basename $dir)
 #subj=$(basename $(dirname $dir))

# REDO EVERYONE
cat ~/src/physioCmp/txt/subject_list.txt | while read subjdate junk;  do
 subj=${subjdate%%_*}
 date=${subjdate##*_}
 s=${subj}_${date}
 echo $jobname
 qstat -f | grep $s-mprage  && echo "job already running" && continue
 jobid=$(qsub mprage_to_MNI.bash    -N $s-mprage                        -Vv REDO=1,SUBJECT=$subj,VISIT=$date -o logs/)
 qsub rest_preproc_torque           -N $s-phys -W depend=afterok:$jobid -Vv REDO=1,SUBJECT=$subj,VISIT=$date -o logs/
 qsub rest_preproc_afniproc_torque  -N $s-afni -W depend=afterok:$jobid -Vv REDO=1,SUBJECT=$subj,VISIT=$date -o logs/
 qsub rest_preproc_torque           -N $s-noph -W depend=afterok:$jobid -Vv REDO=1,SUBJECT=$subj,VISIT=$date,NOPHYSIO=1 -o logs/
done
