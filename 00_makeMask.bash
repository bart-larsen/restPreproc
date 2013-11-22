bb244=bb244.txt
SUBJECT=10152
VISIT=20100514
# use subject and visit to set sdir
source rewardrest.cfg
subjexample="$sdir/afni_restproc/power_nogsr/pm.cleanEPI+tlrc.HEAD"
set -xe
3dUndump -srad 5 -prefix bb244Mask -master $subjexample \
         -orient LPI -xyz bb244.txt -overwrite
