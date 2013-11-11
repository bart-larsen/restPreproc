#!/usr/bin/env bash

#
# check for anatomical image (fail out if DNE)
# check for epi (Dimon from dcm if DNE)
# 

# this expects to be sourced by another function
#  if it needs to be tested
#    export SUBJECT=10845 VISIT=20100924
#    source rewardrest.cfg
#    source makerestimage.bash


restdir=$(dirname $origepi)
dcmdirs=$dicomDir

# these should all be source from cfg file which would be loaded by common.src.bash 
[ -z "$s" ]                          && echo "need \$s as subject[_date]!" && exit 1;
[ -z "$origepi" ]                    && echo "need \$origepi as output to save!" && exit 1;
[ -z "$origmprage" ]                 && echo "need \$origmprage as output to save!" && exit 1;
[ -z "$expectedRestDicoms" ]         && echo "need \$expectedRestDicoms as dicom dir!" && exit 1;
[ -z "$dcmdirs" -o ! -r "$dcmdirs" ] && echo "\$dcmdirs=root of subject dicoms ($dcmdirs) DNE!" && exit 1;



#### FUNCTIONAL
# convert epi from dicoms if we need it
if [ ! -r $origepi ]; then
 # find a rest directory and make sure it has enough dcms
 restdcmdir=$(find -L $dcmdirs -iname '*rest*' -type d | tail -n1)
 [ -z "$restdcmdir"  ] && echo "no dcmdir for $s!" && exit 1
 [ $(ls $restdcmdir/MR* | wc -l ) -ne $expectedRestDicoms ] && echo "$s: $restdcmdir doesnt have 200 MR* dcms!" && exit 1

 [ ! -d $restdir ] && mkdir -p $restdir
 cd $restdir
 Dimon -infile_prefix $restdcmdir/ \
	    -GERT_Reco \
	    -quit \
	    -dicom_org \
	    -sort_by_acq_time \
	    -gert_write_as_nifti \
	    -gert_create_dataset \
	    -gert_to3d_prefix Dimon_$(basename $origepi)
 #mv $(basename $origepi)* $(dirname $origepi)/Dimon_$(basename $origepi)

 # mricron tool: nii yes, gz yes,  no reorient, no crop, ,annonymize, no protocol in named,no date in name, output to folder
 dcm2niigz=$(dcm2nii -n y -g y  -r n -x n -a y -p n -d n -o $(dirname $origepi) ${restdcmdir}/* | sed -n 's/GZip...//p' )
 [ -z "$dcm2niigz" -o ! -r "$dcm2niigz" ] && echo "$dcm2niigz:dcm2nii failed? did not create $origepi" && exit 1
 3dcopy $dcm2niigz $origepi
 cd -
fi

#### anatomical check
# not the best place, but it's a place :)
[ ! -r $origmprage ] && echo "no mprage!!! run qsub mprage_to_MNI.bash -Vv SUBJECT=$SUBJECT,VISIT=$VISIT" && exit 1

echo "rest image is read"
