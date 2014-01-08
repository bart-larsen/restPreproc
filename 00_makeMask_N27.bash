#!/usr/bin/env bash
set -xe
AFNIPATH=$(dirname $(which afni))

mnibrain="~/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c.nii"

[ -d masks ] || mkdir masks
cd masks
3dUndump -srad 5 -prefix bb264Mask_MNI -master $mnibrain  -orient LPI -xyz ../txt/bb264_coords

# just to make sure dxyz is the same (3x3x3)
subjexample="/data/Luna1/Reward/Rest/10845_20100924/afni_restproc/power_nogsr_mni/pmmni.cleanEPI+tlrc.HEAD"
3dresample -inset bb264Mask_MNI+tlrc. -master $subjexample -prefix bb264Mask_MNI_3x3x3
# via http://afni.nimh.nih.gov/afni/community/board/read.php?1,65877,65878#msg-65878
#export AFNI_ANALYZE_ORIENT = LPI
#export AFNI_ANALYZE_ORIGINATOR = YES

ls $AFNIPATH/TT_N27+tlrc*
adwarp -resam NN -apar $AFNIPATH/TT_N27+tlrc -dpar bb264Mask_MNI+tlrc -prefix bb264Mask_N27 -force 

# just to make sure dxyz is the same (3x3x3)
subjexample="/data/Luna1/Reward/Rest//10152_20100514/afni_restproc/power_nogsr/pm.cleanEPI+tlrc.HEAD"
3dresample -master $subjexample -inset bb264Mask_N27+tlrc -prefix bb264Mask_N27_3x3x3
