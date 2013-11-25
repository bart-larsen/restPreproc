#!/usr/bin/env bash

# quick script to see average time taken by torque
# using access logs

#
# using script bits from  https://github.com/jeroenjanssens/data-science-toolbox.git
#

export preproctype=power_nogsr
for f in RewardRest/*/processing.log; do
  fd=$(basename $(dirname $f));
  id=${fd%%_*}
  date=${fd##*_}
  export id date
  perl -slane '$a{$3} = int($1)*60+int($2) if m/(\d{2}):(\d{2}).*$ENV{preproctype}.*(start|finish)/;
       END{ 
        $a{finish}+=24*60 if $a{start}>$a{finish}; 
        $diff=($a{finish} - $a{start})/60;
        print join("\t",@ENV{qw/id date/},$a{start},$a{finish},$diff) if $a{finish}
      } ' $f;
done | tee txt/times 
Rscript -e '
   df<-read.table("txt/times");
   names(df)<-c("luna","date","start","finish","dur");
   df$label <- with(df, ifelse(dur>3|dur<=.1,paste(luna,date,sep="_"),""));

   library(ggplot2);
   p<-ggplot(df,aes(x=dur,y=luna,label=label))+geom_point()+geom_text(size=I(2),hjust=-.2);
   pdf("99_time.pdf");
   print(p);
   dev.off();
'
