#!/usr/bin/env bash

#
# check for epi (Dimon from dcm if DNE)
# dcm2nii does not orient some brains correctly 
# output should be afni format for intput to afni_restproc.py
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
[ -z "$expectedRestDicoms" ]         && echo "need \$expectedRestDicoms as dicom dir!" && exit 1;
[ -z "$dcmdirs" -o ! -r "$dcmdirs" ] && echo "\$dcmdirs=root of subject dicoms ($dcmdirs) DNE!" && exit 1;
# dont care about mprage, using T1 from FreeSurfer
#[ -z "$origmprage" ]                 && echo "need \$origmprage as output to save!" && exit 1;



#### FUNCTIONAL
# convert epi from dicoms if we need it
if [ ! -r $origepi ]; then
 # find a rest directory and make sure it has enough dcms
 #restdcmdir=$(find -L $dcmdirs -iname '*rest*' -type d | tail -n1)
 # restdcmdir is found by rewardrest.cfg -- which should've been run already

 [ -z "$restdcmdir"  ] && echo "no dcmdir ($dcmdirs -> $restdcmdir) for $s!" && exit 1
 [ $(ls $restdcmdir/MR* | wc -l ) -ne $expectedRestDicoms ] && echo "$s: $restdcmdir doesnt have 200 MR* dcms!" && exit 1

 [ ! -d $restdir ] && mkdir -p $restdir
 cd $restdir
 Dimon -infile_prefix $restdcmdir/ \
	    -GERT_Reco \
	    -dicom_org \
	    -sort_by_acq_time \
	    -gert_create_dataset \
	    -gert_to3d_prefix $(basename ${origepi%%+orig.HEAD*}) \
	    -quit  | tee  $restdir/$s.Dimon.$(date +%F).log
	    #-gert_write_as_nifti \


 mysql -h lncddb.acct.upmchs.net -u lncd --password=B@ngal0re lunadb -Be "select * from tsubjectinfo where lunaid = ${SUBJECT}" | tee $sid.subjectinfo.txt
 mysql -h lncddb.acct.upmchs.net -u lncd --password=B@ngal0re lunadb -Be "select date_format(vt.VisitDate,'%Y%m%d') as scandate, vl.*, vt.* from tvisittasks as vt join tvisitlog as vl on vl.visitid=vt.visitid having vt.lunaid = $SUBJECT and scandate = $VISIT"| tee $sid.visitinfo.txt
 mysql -h lncddb.acct.upmchs.net -u lncd --password=B@ngal0re lunadb -NBe "select datediff(vt.VisitDate,si.DateOfBirth)/365.25 as age from tvisittasks as vt left join tsubjectinfo as si on si.LunaID=vt.LunaID where si.LunaID = $SUBJECT and date_format(vt.VisitDate,'%Y%m%d') = '$VISIT'" | tee $sid.age.txt

 cd -
 #mv $(basename $origepi)* $(dirname $origepi)/Dimon_$(basename $origepi)

 # # mricron tool: nii yes, gz yes,  no reorient, no crop, ,annonymize, no protocol in named,no date in name, output to folder
 ## not used because some are dcm->nii's appear flipped!
 # dcm2niigz=$(dcm2nii -n y -g y  -r n -x n -a y -p n -d n -o $(dirname $origepi) ${restdcmdir}/* | sed -n 's/GZip...//p' )
 # [ -z "$dcm2niigz" -o ! -r "$dcm2niigz" ] && echo "$dcm2niigz:dcm2nii failed? did not create $origepi" && exit 1
 # 3dcopy $dcm2niigz $origepi
fi

#### anatomical check
# not the best place, but it's a place :)
#[ ! -r $origmprage ] && echo "no mprage!!! run qsub mprage_to_MNI.bash -Vv SUBJECT=$SUBJECT,VISIT=$VISIT" && exit 1

#echo "rest image is read"
