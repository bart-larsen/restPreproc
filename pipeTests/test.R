library(ggplot2)
library(reshape2)

pipes <- c('bp_ort_noPhysio','bp_3dD_noPhysio','withPhysio')
dirs  <- Sys.glob('/Volumes/Serena/Rest/Subjects/1*/pipeTests/fca/') # change subjs if this is changed!
subjs <- substr(dirs,31,35)

numROI   <- 244
numSubjs <- length(dirs)
numPipes <- length(pipes)

# 'a' will be 4d array
#  roiXroiXsubjXpipe

a <- array(0, c(numROI,numROI,numSubjs,numPipes) )


# build a
for ( diridx in 1:length(dirs) ) {
   print(diridx);
   for ( pipeidx in 1:length(pipes)) {

     # what file, does it exist
     subjfile=paste(dirs[diridx],pipes[pipeidx],'.corr.1D',sep='')
     if(! file.exists(subjfile) ) { print( c("skipping",subjfile) ); next }

     # what data, is it a fit?
     d <- read.table( subjfile );
     if( any(! dim(d) == numROI ) ) { print(  c( "skipping",subjfile," wrong size ",dim(d) )  ); next }


     a[,,diridx,pipeidx] <- as.matrix(d)
  }
}

# remove 0's
a[a==0] <- NA

# ttests between pipelines for each connection across subjects

#t.test(a[20,30,,1],a[20,30,,2],var.equal=TRUE) # 20 <-> 30, ort vs 3dD

m1vm2 <- array(0,c(numROI,numROI))
for (i in 1:numROI ) { 
  for (j in i:numROI ) {
   m1vm2[i,j] <- t.test(a[i,j,,1],a[20,30,,2],var.equal=TRUE)$p.value
  }
}

ggheat <- function(m) {
   m<-as.data.frame(m)
   names(m)<-read.table("/Volumes/Serena/Rest/Subjects/10888/pipeTests/fca/2droi.row.1D")
   m$roi <- as.numeric(rownames(m))
   dm <- melt(m,id='roi'); 
   dm$variable <- as.numeric(dm$variable)
   dm$value[dm$value==0] <- NA
   return (ggplot(dm,aes(variable,roi))+geom_tile(aes(fill=value)))
}

simMean<-apply(a[,,,1],c(1,2),mean,na.rm=TRUE)
bpregMean<-apply(a[,,,2],c(1,2),mean,na.rm=TRUE)
simMean[  lower.tri(simMean)  ] <- NA
bpregMean[lower.tri(bpregMean)] <- NA
diag(simMean)   <- NA
diag(bpregMean) <- NA

m1      <- ggheat(simMean)+opts(title=pipes[1])
m2      <- ggheat(bpregMean)+opts(title=pipes[2])
ttested <- ggheat(m1vm2)+opts(title="bandpass sim vs first")

library(gridExtra)
grid.arrange(arrangeGrob(m1,m2,ncol=2),ttested)
grid.newpage()
grid.arrange(grob(hist(m1Mean)),grob(hist(m2Mean)),ncol=2)

