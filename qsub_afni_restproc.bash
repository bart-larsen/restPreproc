#!/usr/bin/env bash
#
# ==== $0 ====
#   run afni_restproc in subject_visit directory struct on wallace
#   normally
#     run with wrapper queallAfni_restproc.bash 
#     with settings from e.g. rewardrest.cfg
#  
#END
#
# PBS SETTINGS:
#   three cpus for 5 hours
#   afni will eat all cpus for only some bits of streem
#PBS -l ncpus=3
#PBS -l walltime=5:00:00
#PBS -q batch
#
#
#2013-11-21 WF
# setup for afni_preproc for power neuroimage 2012 (no global signal regression)
# copy of script validated by SM on skynet:/Volumes/Phillips/Rest/rest_scripts/rest_preproc_transition

# get script info -- log to file
scriptdir=$(cd $(dirname $0);pwd)              
# if torque has copied the script, we need the hardcoded path
[[ $scriptdir =~ spool ]] && scriptdir="/home/foranw/src/restPreproc"
scriptdateversion="$(perl -slane 'if(m/\d{4}-\d{2}-d{2}/){print $&}' $scriptdir/$(basename $0))"
scriptgitversion="$(cd $scriptdir; git log|sed 1q)"



# ./onlyafniproc.bash -sid 10152_20100514 -sdir /Volumes/Phillips/Rest_Reward/10152_20100514/ -aseg /Volumes/Phillips/Rest_Reward/10152_20100514/anat/aseg.mgz -t1 /Volumes/Phillips/Rest_Reward/10152_20100514/anat/T1.mgz -t2 /Volumes/Phillips/Rest_Reward/10152_20100514/rest/all.nii.gz -physio /Volumes/Phillips/Rest/physio1D/10152_RetroTS.slibase.1D
### OR
# qsub onlyafniproc.bash -vV sid="10152_20100514",sdir="/data/Luna1/Reward/Rest/10152_20100514/",aseg="/data/Luna1/Reward/FS_Subjects/10152_20100514/mri/aseg.mgz",t1="/data/Luna1/Reward/FS_Subjects/10152_20100514/mri/T1.mgz",t2="/data/Luna1/Reward/Rest/10152_20100514/Dimon_rest.nii.gz.nii.gz",physio="/data/Luna1/Reward/Physio/10152/20100514/rest_21_RetroTS.slibase.1D"

## Where to save output
# e.g. /data/Luna1/Reward/Rest/10152_20100514/afni_restproc/power_nogsr
afnidirname=afni_restproc
innerdir=power_nogsr

while [ -n "$1" ]; do
 case $1 in 
  -sdir)      sdir=$2;        shift 2;;  # subject's folder -- base directory for preprocessing output
  -sid)       sid=$2;         shift 2;;  # subject id       -- where to find FS stuff, what to prefix files
  -t1)        t1=$2;          shift 2;;  # t1 image, mgz format (/data/Luna1/{TASK}/FS_Subjects/${sid}/mri/T1.mgz)
  -aseg)      aseg=$2;        shift 2;;  # FS segmentation, mgz format (/data/Luna1/{TASK}/FS_Subjects/${sid}/mri/aseg.mgz) 
  -t2)        t2=$2;          shift 2;;  # functional image, BRIK format
  -physio)    physio=$2;      shift 2;;  # location of physio file (RetroTS)
  *) 
     sed -ne "s:\$0:$0:g;s/# //p;/END/q" $0;                             # print header
     echo " USAGE: ";
     perl -lne 'print "\t$1:\t$2" if m/^\s+(-.*)\).*shift.*# (.*)$/' $0; # print options
     echo ;
     echo -e "[Unrecognized option '$1']"; 
     echo ;
     exit 1;;
 esac
done

set -xe

for varname in sid sdir t1 t2 physio; do
  # check for defined inputs
  [ -z "${!varname}" ] && echo "Requires -$varname" && exit 1
  [ "$varname" = "sid" ] && continue # sid doesn't have to have directory

  # make absolute path
  printf -v $varname "$(cd $(dirname ${!varname}); pwd)/$(basename ${!varname})"

  # don't need to be able to read sdir, we will make it
  [ "$varname" = "sdir" ] && continue

  # sanity check for file existance
  [ ! -r ${!varname} ] && echo "could not read $varname (${!varname}), exiting" && exit 1;
done


[  -r $sdir/$afnidirname/$innerdir && -n "$REDO" ] && rm -r $sdir/$afnidirname/$innerdir
[  -r $sdir/$afnidirname/$innerdir ] && echo "ALREADY RUN!" && exit 1

mkdir -p $sdir/$afnidirname
cd $sdir/$afnidirname

## TODO: pull sql info

## write to processing log (script,time,version,git version)
echo -e "$(date +%F\|%H:%M)\t$innerdir\tstart\t$scriptdir/$(basename $0) ($scriptdateversion/$scriptgitversion)" >> $sdir/processing.log

#### ACTUALL RUN
case $innerdir in
 power_nogsr)
   afni_restproc.py \
	-despike off \
	-aseg $aseg \
	-anat $t1 \
	-epi  $t2 \
	-script $innerdir.tcsh \
	-dest $innerdir \
	-prefix pm \
	-tlrc \
	-dvarscensor \
	-episize 3 \
	-dreg \
	-smoothfirst \
	-smoothrad 6 \
	-smoothtogether \
	-bandpass \
	-includebrain \
	-polort 0 \
	-globalwm \
	-censorleft 1 \
	-censorright 2 \
	-fdlimit 0.5 \
	-dvarslimit 5 \
	-modenorm  | tee ${innerdir}_$sid.log ;;
   *)
    echo unknown $innerdir;
    exit 1;;
esac

# all went well
echo -e "$(date +%F\|%H:%M)\t$innerdir\tfinish\t$scriptdir/$(basename $0) ($scriptdateversion/$scriptgitversion)" >> $sdir/processing.log
exit 0

### LEFTOVERs

# covnert mprage from FS
#mri_convert $t1 mprage+orig.HEAD

#nifti to AFNI
#3dcopy $t2 restepi+orig

# dcm2nii is off
#Dimon -infile_prefix $(dirname $t2)/ -GERT_Reco -dicom_org -sort_by_acq_time -gert_create_dataset -gert_to3d_prefix ${sid}_restepi -quit

# t1 and aseg can be .mgz
# if restepi is nii.gz, renaming gets funky
#afni_restproc.py \
#  -anat $t1     \
#  -epi  $t2   \
#  -aseg $aseg          \
#  -rvt  $physio        \
#  -prefix restpp \
#  -dest   restpp  \
#  -script preproc_$sid.tcsh \
#  -anat_has_skull yes \
#  -smoothrad 4 \
#  -venterode 2 \
#  -wmerode 1   \
#  -bandpass \
#  -setbands 0.009 0.08 \
#  -bpassregs \
#  -dreg \
#  -tlrclast \
#  -exec  off \
#  -tsnr 2>&1  #| tee afni_$sid.log
#  
#
#
        #-exec  off \

#tcsh -xef preproc_$sid.tcsh 2>&1 | tee preprocout.$sid.log
