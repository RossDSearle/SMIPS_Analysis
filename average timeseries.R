library(raster)
rasterOptions(datatype="FLT4S", timer=TRUE, format='GTiff',progress="text",chunksize=1e+08,maxmemory=1e+09, overwrite=TRUE) 

inDir <- 'C:/Projects/SMIPS/SMEstimates/CSIRO/Analysis_Wetness_Index'
fls <- list.files(inDir, full.names = T)
stk <- stack(fls)
mvs <- calc(stk, fun = mean)


beginCluster(n = 6)
t_parallel <- system.time({
  parallel_mean <- clusterR(stk, fun = calc,
                            args = list(fun = mean, na.rm = TRUE))
})
endCluster()


r <- stk[[1]]

for (i in 2:nlayers(stk)) {
  print(i)
  r <- sum(r, stk[[i]])
}

rm <- r/nlayers(stk)

writeRaster(rm, 'C:/Projects/SMIPS/SMIPSAnalysis/NoDataAnalysis/indAvg.tif')

blockSize(stk)

outRasterDir <- 'C:/Projects/SMIPS/SMIPSAnalysis'
tictoc::tic()
templateR <- raster(stk[[1]])
outR<-raster(templateR)
outR<-writeStart(outR,filename=paste0(outRasterDir, '/meanAnalysisWetnessIndex.tif'),overwrite=TRUE,NAflag=-9999,datatype="FLT4S")
bs <- blockSize(stk)
pb <- pbCreate(bs$n, progress='text', style=3, label='Progress',timer=TRUE)

for (r in 1:bs$n) {
  
  ncells = bs$nrows[r] * ncol(templateR)
  theSeq = seq(ncells)
  m = data.frame(theSeq)
  
  for (i in 1:nlayers(stk)) 
  {
    print(i)
    rl = raster(stk, layer=i)[]
    m[names(rl)] <- rl    
  }
  
  suitvals <- apply(m,1,mean)
  
  #prediction = predict(model, cubCovVals[, -1], neighbors = 9)
  prediction = predict(model, cubCovVals[, -1])
  outR <- writeValues(outR, prediction, bs$row[r])
  print(paste0(r, ' of ', bs$n))
  pbStep(pb, r)
}

out<-writeStop(outR)
pbClose(pb)
