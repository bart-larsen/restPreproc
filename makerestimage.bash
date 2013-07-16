#!/usr/bin/env bash
dcmdirs="${dicomRootDir}/${s}/"
restdir=$(dirname $origepi)

[ -z "$origepi" ]                    && echo "need origepi!" && exit 1;
[ -z "$expectedRestDicoms" ]         && echo "need expectedRestDicoms!" && exit 1;
[ -z "$dcmdirs" -o ! -r "$dcmdirs" ] && echo "$dcmdirs DNE!" && exit 1;

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
 Dimon -infile_prefix $restdcmdir/ -gert_create_dataset -gert_write_as_nifti -dicom_org
 mv OutBrick* $origepi
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
