#!/usr/bin/env bash
#
# check for anatomical image (fail out if DNE)
# check for epi (Dimon from dcm if DNE)
# 

# these should all be source from cfg file which would be loaded by common.src.bash 
[ -z "$s" ]                          && echo "need \$s as subject[_date]!" && exit 1;
[ -z "$origepi" ]                    && echo "need \$origepi as output to save!" && exit 1;
[ -z "$expectedRestDicoms" ]         && echo "need \$expectedRestDicoms as dicom dir!" && exit 1;
[ -z "$dcmdirs" -o ! -r "$dcmdirs" ] && echo "\$dcmdirs=root of subject dicoms ($dcmdirs) DNE!" && exit 1;

dcmdirs=$dicomDir
restdir=$(dirname $origepi)

#### anatomical check
# not the best place, but it's a place :)
[ ! -r $restdir/anat/mprage.nii.gz ] && echo "no mprage!!! run qsub mprage_to_MNI.bash -Vv SUBJECT=$SUBJECT,VISIT=$VISIT,OUTDIR=anat" && exit 1

#### FUNCTIONAL
# convert epi from dicoms if we need it
if [ ! -r $origepi ]; then
 # find a rest directory and make sure it has enough dcms
 restdcmdir=$(find -L $dcmdirs -iname '*rest*' -type d | tail -n1)
 [ -z "$restdcmdir"  ] && echo "no dcmdir for $s!" && exit 1
 [ $(ls $restdcmdir/MR* | wc -l ) -ne $expectedRestDicoms ] && echo "$s: $restdcmdir doesnt have 200 MR* dcms!" && exit 1

 [ ! -d $restdir ] && mkdir -p $restdir
 cd $restdir
 Dimon -gert_to3d_prefix $(basename $origepi) -infile_prefix $restdcmdir/ -gert_create_dataset -gert_write_as_nifti -dicom_org
 mv $(basename $origepi)* $origepi
 cd -
fi


