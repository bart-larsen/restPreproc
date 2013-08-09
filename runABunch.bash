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
for dir in $(ls -d $physioDir/*/* | head -n 3); do
 date=$(basename $dir)
 subj=$(basename $(dirname $dir))
 SUBJECT=$subj VISIT=$date  $scriptdir/rest_preproc_torque |tee -a logs/$subj_date.log
 SUBJECT=$subj VISIT=$date  $scriptdir/rest_preproc_afniproc_torque |tee -a logs/$subj_date.afniproc.log &
 NOPHYSIO=1 SUBJECT=$subj VISIT=$date  $scriptdir/rest_preproc_torque|tee -a logs/$subj_date.nopysio.log &
done
