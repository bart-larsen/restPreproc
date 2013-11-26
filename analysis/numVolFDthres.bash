#!/usr/bin/env bash
## get number of volumes (fd at .5)
## check out
# paste RewardRest/10662_20090507/afni_restproc/power_nogsr/tmp/10662_20090507_restepi.float_tsh_vr_motion.tcat.deltamotion.FD.1D RewardRest/10662_20090507/afni_restproc/power_nogsr/tmp/10662_20090507_restepi.float_tsh_vr_motion.tcat.deltamotion.FD.extreme0.5.1D|sort -nr 
scriptdir=$(cd $(dirname $0);pwd)
cd ../RewardRest/
outputfile=$scriptdir/../txt/SubjectTimeAgeSexFD.txt
echo sid age tpoint sex remaingvols origvols| tr ' ' "	" | tee $outputfile
ls -d 1*_* --color=no | perl -F"_" -slane 'push @{$a{$F[0]}}, $F[1]; END{for my $l (sort(keys %a)){ @v=sort(@{$a{$l}}); print join("\n", map { "t". ($_+1) ." ${l}_$v[$_]" } (0..$#v)) }}'| while read tpoint sid; do
  origvols=$(3dinfo -nv $sid/${sid}_restepi+orig.HEAD)
  remaingvols=$(3dinfo -nv $sid/afni_restproc/power_nogsr/pm.cleanEPI+tlrc.HEAD)
  age=$(cat $sid/$sid.age.txt)
  sex=$(cat $sid/$sid.sex.txt)
  echo $sid $age $tpoint $sex $remaingvols $origvols| tr ' ' "	"
  #fdfile=$sid/afni_restproc/power_nogsr/tmp/${sid}_restepi.float_tsh_vr_motion.tcat.deltamotion.FD.1D
  #lt1vols=$(perl -slane '$i++ if $_ < .1; END{print $i}' $fdfile)
  #lt2vols=$(perl -slane '$i++ if $_ < .2; END{print $i}' $fdfile)
  #lt3vols=$(perl -slane '$i++ if $_ < .3; END{print $i}' $fdfile)
  #lt4vols=$(perl -slane '$i++ if $_ < .4; END{print $i}' $fdfile)
  #lt5vols=$(perl -slane '$i++ if $_ < .5; END{print $i}' $fdfile)
  #echo $sid $age $sex $remaingvols $lt1vols $lt2vols $lt3vols $lt4vols $lt5vols $remaingvols $origvols| tr ' ' "	"
done | tee -a $outputfile

grep t1 $outputfile > ${outputfile/.txt/.t1.txt}
