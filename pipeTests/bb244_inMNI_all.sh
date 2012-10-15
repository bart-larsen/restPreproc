#!/usr/bin/env bash

set -xe

#########
# 
# get bb244 rois in subject native space
# and get timecouse of the aveage in each ROI
# must have run rest_redoBad and have bp+ort bp+3dD folders
# 
#  switches:
#########

subjdir="/Volumes/Serena/Rest/Subjects"
bbDir="/Volumes/Serena/Rest/Subjects/stats/science_regions"
subjexample="$subjdir/10153/pipeTests/bp+ort_noPhysio/rest_preproc_mni.nii.gz"
bb244=$bbDir/bb244MNI_LPI_2mm.nii.gz
if [ ! -r $bb244 ]; then
   ### original bb244 might be bad?
   #3dcopy -overwrite $bbDir/bb244+tlrc $bbDir/bb244MNI.nii.gz
   #3dresample -overwrite -inset $bbDir/bb244MNI.nii.gz -prefix $bbDir/bb244MNI_res.nii.gz -master /Volumes/Serena/Rest/Subjects/10153/pipeTests/bp+ort_noPhysio/rest_preproc_mni.nii.gz
  3dUndump -srad 5 -prefix $bb244  -master $subjexample \
           -orient LPI -xyz $bbDir/bb244_coordinate
fi


#find $subjdir -maxdepth 4 -mindepth 4 -name rest_preproc_MNI.nii.gz | while read file; do
for file in $subjdir/*/pipeTests/*/rest_preproc_mni.nii.gz; do
   echo $file
   cd $(dirname $file)
   #[ -r ROIStats_mni.1D ] && echo "completed" && continue
   # use nzmean instead of mean?
   3dROIstats -nzmean -nomeanout -numROI 264 -quiet -mask $bb244 rest_preproc_mni.nii.gz  > ROIStats_mni.1D
done

