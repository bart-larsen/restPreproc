#!/usr/bin/env bash -xe
maxjobs=2
sleeptime=100
for dir in /Volumes/Serena/Rest/Subjects/*/pipeTests/fca/; do 
  #[ ! -r $dir/withPhysio.corr.1D ] &&  rest_preproc_v6_redoBad -s $(basename $(dirname $(dirname $dir))) -p -a afni -x &
  subj=$(basename $(dirname $(dirname $dir))) 
  rest_preproc_v6_redoBad -s $subj -t ort -a bp &
   sleep 2; 
   while [ $(jobs |wc -l) -ge $maxjobs ]; do 
    echo sleeping; 
    sleep $sleeptime;
    done;
done
