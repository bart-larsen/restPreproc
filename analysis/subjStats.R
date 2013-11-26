library(ggplot2) # load fancy graphing library
library(plyr)    # use ddplyr to do easy grouping stats

# this is the output of numVolFDthres.bash
# now used as input
subjList <- read.table('../txt/SubjectTimeAgeSexFD.t1.txt',sep="\t",header=T)

## break into age groups
subjList$agegroup <- cut(subjList$age,breaks=c(-Inf,12, 15, 18, 21,Inf))
# we could rename these groups
#levels(subjList$agegroup ) <-c('babys','kids','youngteens','oldteens','youngadults','theelderly')


# how many volumes to keep, various thresholds for % original volumes removed
thresholds <- c(.5,.2,.15,.1, 1)

# dataframe to label each group's count above each threshold 
countAtThres <- adply(thresholds,1,
  function(p) {
   ddply(subjList,.(agegroup), 
    function(x){ 
     thr <- 200-200*p
     cnt <- length(which(x$remaingvols > thr))
     #cnt <- sprintf("n=%d",cnt)
     return(c(age=mean(x$age),percent=p,count=cnt,thr=thr ))
     })
   })

# use this to draw black lines over the graph and label for each threshold explored
thresholds.df <- data.frame(labels=sprintf('%d%%',thresholds*100),ycepts=200-200*thresholds)

# the actual plot, 
p<-ggplot(subjList,aes(y=remaingvols,x=age))+geom_point(aes(shape=sex,color=agegroup))+ 
     theme_bw() + ggtitle('Thresholding by TRs Remaining for Subject Age Groups') +
     geom_hline(data=thresholds.df,aes(yintercept=ycepts)) +
     geom_text(data=thresholds.df, aes(y=ycepts,x=9,label=labels),size=I(4)) +
     geom_text(data=countAtThres,aes(label=count,x=age,y=thr,color=agegroup),vjust=-.5,size=I(3))

# show the plot
print(p)
# save the plot
ggsave(p,file="imgs/FD@.5_percentDropouts.png")


# True or False: lost no more than 20% of the volumes
subjList[,'>20%'] <- as.numeric(subjList$remaingvols)>200-.2*200
