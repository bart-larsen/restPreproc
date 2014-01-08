#!/usr/bin/env bash

SUBJECT=10152
VISIT=20100514
runtype=power_nogsr_mni
pfix=pmmni

# use subject and visit to set sdir
source rewardrest.cfg
subjexample="$sdir/afni_restproc/$runtype/$pfix.cleanEPI+tlrc.HEAD"

bb244="txt/bb264_coords"
set -xe
3dUndump -srad 5 -prefix masks/bb264Mask_MNI -master $subjexample \
         -orient LPI -xyz txt/bb244.txt -overwrite
