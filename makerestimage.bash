#!/usr/bin/env bash
dcmdirs="${dicomRootDir}/${s}/"
restdir=$(dirname $origepi)

[ -z "$s" ]                          && echo "need \$s as subject[_date]!" && exit 1;
[ -z "$origepi" ]                    && echo "need \$origepi as output to save!" && exit 1;
[ -z "$expectedRestDicoms" ]         && echo "need \$expectedRestDicoms as dicom dir!" && exit 1;
[ -z "$dcmdirs" -o ! -r "$dcmdirs" ] && echo "\$dcmdirs=root of subject dicoms ($dcmdirs) DNE!" && exit 1;
[ -z "$FSDir" -o ! -r "$FSDir" ]     && echo "\$FSDir=root of subject freesurfer ($FSDir) DNE!" && exit 1;

#
# convert epi from dicoms if we need it
#
if [ ! -r $origepi ]; then

 # find a rest directory and make sure it has enough dcms
 restdcmdir=$(find $dcmdirs -iname '*rest*' -type d | tail -n1)
 [ -z "$restdcmdir"  ] && echo "no dcmdir for $s!" && exit 1
 [ $(ls $restdcmdir/MR* | wc -l ) -ne $expectedRestDicoms ] && echo "$s: $restdcmdir doesnt have 200 MR* dcms!" && exit 1

 [ ! -d $restdir ] && mkdir -p $restdir
 cd $restdir
 Dimon -gert_to3d_prefix $(basename $origepi) -infile_prefix $restdcmdir/ -gert_create_dataset -gert_write_as_nifti -dicom_org
 mv $(basename $origepi)* $origepi
 cd -
fi

## Copy anatomical  if it doesn't exist

[ ! -d $FSDir/${s}/mri/ ] && echo "cannot find subjects FS $FSDir/${s}/mri/" && exit 1

if [ ! -r $restdir/anat/mprage.nii.gz ] ; then
  [ -r $restdir/anat ] || mkdir $restdir/anat 
  cd $restdir/anat
  mri_convert $FSDir/${s}/mri/T1.mgz        mprage.nii.gz
  mri_convert $FSDir/${s}/mri/brainmask.mgz mprage_bet.nii.gz
  mri_convert $FSDir/${s}/mri/aseg.mgz      aseg.nii.gz
  cd -
fi
