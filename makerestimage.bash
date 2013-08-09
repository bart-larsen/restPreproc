#!/usr/bin/env bash
dcmdirs=$dicomDir
restdir=$(dirname $origepi)

[ -z "$s" ]                          && echo "need \$s as subject[_date]!" && exit 1;
[ -z "$origepi" ]                    && echo "need \$origepi as output to save!" && exit 1;
[ -z "$expectedRestDicoms" ]         && echo "need \$expectedRestDicoms as dicom dir!" && exit 1;
[ -z "$dcmdirs" -o ! -r "$dcmdirs" ] && echo "\$dcmdirs=root of subject dicoms ($dcmdirs) DNE!" && exit 1;
[ -z "$FSDir" -o ! -r "$FSDir" ]     && echo "\$FSDir=root of subject freesurfer ($FSDir) DNE!" && exit 1;

#### FUNCTIONAL
# 1. convert epi from dicoms if we need it
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

#### Anatomical
#  1.1 copy anatomical
#  1.2 put in afni BRIK/HEAD and orient to RPI
#  2. warp to mni
#
[ ! -d $FSDir/${s}/mri/ ] && echo "cannot find subjects FS $FSDir/${s}/mri/" && exit 1

[ -r $restdir/anat ] || mkdir $restdir/anat 
if [ ! -r $restdir/anat/mprage.nii.gz ] ; then
  cd $restdir/anat
  mri_convert $FSDir/${s}/mri/T1.mgz        mprage.nii.gz
  mri_convert $FSDir/${s}/mri/brainmask.mgz mprage_bet.nii.gz
  mri_convert $FSDir/${s}/mri/aseg.mgz      aseg.nii.gz


  ##
  # make all RPI and in afni BRIK/HEAD format
  ##
  
  3dcopy mprage_bet.nii.gz mprage_bet
  3dresample -orient RPI -prefix mprage_bet_RPI -inset mprage_bet+orig
  
  3dcopy mprage.nii.gz mprage
  3dresample -orient RPI -prefix mprage_RPI -inset mprage+orig
  
  3dcopy aseg.nii.gz aseg
  3dresample -orient RPI -prefix aseg_RPI -inset aseg+orig


  ##
  # create WM, Ventricals, Non-brain-tissue(NBT) and GM masks
  ##

  3dcalc -prefix WM   -a aseg_RPI+orig -expr 'amongst(a,2,7,41,46,77,78,79)'            
  3dcalc -prefix Vent -a aseg_RPI+orig -expr 'amongst(a,4,5,14,15,43,44)'               
  3dcalc -prefix GM_L -a aseg_RPI+orig -expr 'amongst(a,3,8,10,11,12,13,17,18,26,28)'   
  3dcalc -prefix GM_R -a aseg_RPI+orig -expr 'amongst(a,42,47,49,50,51,52,53,54,58,60)' 
  3dcalc -prefix BS   -a aseg_RPI+orig -expr 'amongst(a,16)'                            
  3dcalc -prefix NBT  -a mprage_bet_RPI+orig -b WM+orig -c Vent+orig -d GM_L+orig -e GM_R+orig -f BS+orig -expr '(a/a)-(b+c+d+e+f)'
  
  # erode masks by 1 voxel to reduce partial volume effect 
  3dcalc -prefix WM_erod -a WM+orig -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'a*(1-amongst(0,b,c,d,e,f,g))'
  
  # after some test dont erode Ventrical masks, as no voxels will survive
  #3dcalc -a Vent+orig -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'a*(1-amongst(0,b,c,d,e,f,g))' -prefix Vent_erod
  
  3dcalc -prefix NBT_erod -a NBT+orig -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'a*(1-amongst(0,b,c,d,e,f,g))'
  


  #run michael's normalization script 	
  #"Running affine (linear) warp to extract warp coefficients"
  #"Running nonlinear transformation to warp mprage to: ${reference}"
  $scriptdir/rest_preprocessMprage -r MNI_2mm -n mprage.nii.gz -d n

  cd -
fi
