#!/usr/bin/env bash
set -xe
# need:
#   SUBJECT
#   VISIT
# optional:
#   TASK (passed to common)
#   REDO (remove old)
#
# take FS mprage and align to MNI
# aditionally create all the anatomical files we might need in processing rest
# optimized for use with torque
# - make other jobs wait on this one

#2013-08-15 
# initial coding 

# assume if spool is in the cwd, we are using torque and the scriptdir needs to be hardcoded
scriptdir=$(cd $(dirname $0);pwd)              
[[ $scriptdir =~ spool ]] && scriptdir="/home/foranw/src/restPreproc"


# get add3dNote and printInfo, also set up some env vars (FSL export type=nii.gz)
source $scriptdir/common.src.bash
# additionally sources the correct configuration file
# which gives us
#FSDir:        what dir has free surfer aseg.mgz and mprage.mgz
#s:            subjuect, probably always "${SUBJECT}_${VISIT}"
#origmprage:   location of (or where to put) the origianl mprage (copied from FS)

# directory suffix for different versions of processing
OUTDIR=$(dirname $origmprage)

[ -z "$s" ]                          && echo "need \$s as subject[_date]!" && exit 1;
[ -z "$origmprage" ]                 && echo "need \$origmprage as output to copy!" && exit 1;
[ -z "$FSDir" -o ! -r "$FSDir" ]     && echo "\$FSDir=root of subject freesurfer ($FSDir) DNE!" && exit 1;


#### Anatomical
#  1 copy anatomical
#  2 put in afni BRIK/HEAD and orient to RPI
#  3 use aseg to create masks for non brain tissue, BS, WM, etc
#  4 warp to mni
#
[ ! -d $FSDir/${s}/mri/ ] && echo "cannot find subjects FS $FSDir/${s}/mri/" && exit 1

[ -r $OUTDIR -a -z "$REDO" ] && echo "$OUTDIR exists, use REDO to start again" && exit # this is okay, continue with other things
[ -r $OUTDIR -a -n "$REDO" ] && rm -r $OUTDIR 

mkdir $OUTDIR # not -p because we have bigger problems if subjectdir DNE

cd $OUTDIR

printInfo > processing
which preprocessMprage  >> processing 

mri_convert $FSDir/${s}/mri/T1.mgz        mprage.nii.gz    # $(basename $origmprage)
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


### ALIGN TO MNI
#run michael's normalization script 	
#"Running affine (linear) warp to extract warp coefficients"
#"Running nonlinear transformation to warp mprage to: ${reference}"
preprocessMprage -r MNI_2mm -n mprage.nii.gz -d n

