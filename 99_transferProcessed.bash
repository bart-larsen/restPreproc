#!/usr/bin/env bash
scriptdir=$(cd $(dirname $0);pwd)

cd RewardRest/
# find all timepoint ones
# by putting them into a hash (key=>subjecid) of arrays (t1, t2, t3, etc)
ls -d 1*_* --color=no | perl -F"_" -slane 'push @{$a{$F[0]}}, $F[1]; END{print join("\t",$_, sort(@{$a{$_}})) for (keys %a)}'|cut -f1-2|tr '  ' '_' > $scriptdir/txt/t1.txt

# read each subject and get the 3 imporant files (roistats, preproced epi, and age)
while read t1p; do
 find $t1p/{*age*,afni_restproc/power_nogsr/{*roistats*,*clean*}};
done <$scriptdir/txt/t1.txt | tee $scriptdir/txt/files.txt

# send away
rsync -av --files-from=$scriptdir/txt/files.txt ./ clone@10.145.64.112:~clone/Desktop/Scripts/RewardRestSubjs
