#############
# load up common bits of the processing pipeline
#############
#
# loads
#  - env variables (fsl export type)
#  - the file path (settings, via e.g rewardrest.cfg)
#  - some functions (printInfo add3dNote)
# expect 
#  - $TASK will be set, or that we want rewardrest
#  - $scriptdir exists (the directory of all the scripts and settings)

[ -z "$scriptdir" -o  ! -d $scriptdir ] && echo "do not know where to find configs (scriptdir=$scriptdir)" && exit 1
[ -z "$SUBJECT" -o -z "$VISIT" ] && echo "need SUBJECT and VISIT; e.g.    qsub $0 -Vv SUBJECT=10845,VISIT=20100924"  && exit 1

# use compressed nifti
#set +e
#source /data/Luna1/ni_tools/ni_path.bash
#set -e
export FSLOUTPUTTYPE="NIFTI_GZ"

# load settings
case "$TASK" in
 multimodal) source $scriptdir/MMrest.cfg;;
 reward)     source $scriptdir/rewardrest.cfg;;
 *)          source $scriptdir/rewardrest.cfg;;
esac

####### add3dNote
# function to add notes to file fsl touches (autitable and reproducable research!)
# add3dNote inputfile.nii.gz outputed.nii.gz "cmd -in inputfile.nii.gz -out outputed.nii.gz"
function add3dNote {
  prev=$1; shift; new=$1;shift; note="$@"

  prompt="[$(whoami)@$(hostname): $(date)]"

  prevnote="$(3dNotes $prev | sed '1,2d')";
  [ -n "$prevnote" ] && prevnote="$prevnote\n"

  # also run the presumably fsl command
  # if the third argument is "*RUN*"
  if [ "$1" == "*RUN*" ]; then
   shift
   note="$@"
   $@
  fi
  
  3dNotes -HH "$prevnote$prompt $note" $new
}


######## printInfo 
# print script, its arguments, the date, the version, and the environment
##
# find the first date in this script, call that the script version
scriptver=$(perl -lne 'print&&exit if /#\d{4}/' $0)  
# what commit are we on
gitver=$(cd $(dirname $0);git show|head -n1)   
running="$0 $@"
function printInfo {
 echo "$running"
 echo "at: $(date)"
 echo "script version:"
 echo "  scriptdate: $scriptver"
 echo "  git:        $gitver"
 echo "#located in $scriptdir"
 echo "working/start directory: $(pwd)"
 echo -e "\n\nENV\n"
 env
}

