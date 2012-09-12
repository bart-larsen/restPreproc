#!/bin/bash

# 2012/09/11 - use ../@ROI_Corr_Mat instead of afni binary in /opt/ni_tools/afni/@ROI_Corr_Mat
#              3dresample needs -prefix ./$output if input is not in cwd and output is expected to be
#
# original Kai 2012/01/18
overwrite=yes
bb244=/Volumes/Serena/Rest/Subjects/stats/science_regions/bb244+tlrc

for ts in /Volumes/Serena/Rest/Subjects/*/pipeTests/*/rest_preproc_mni.nii.gz; do 
     fcaDir=$(dirname $ts)/../fca; # like .../pipeTests/bp+ort_noPhysio
     [ ! -d $fcaDir ] && mkdir $fcaDir

     pipeline=$(basename $(dirname $ts))
     prefix=${pipeline//+/_}
     # bp_3dD_noPhysio.zval.1D

     cd $fcaDir
     [ -r $prefix.zval.1D -a "$overwrite" != "yes" ] && echo "already complete: $ts" && continue
     @ROI_Corr_Mat -zval -ts $ts -roi $bb244 -prefix $prefix
     rm  *{BRIK,HEAD}

     # status update
     echo "$(date +%F/%H:%M) $(ls $(pwd)/$prefix.zval.1D)"

done
