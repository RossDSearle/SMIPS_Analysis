library(raster)
library(rgdal)

pdks <- readOGR('e:/temp/smips', 'SMAPBirchipPolygon')
extent(pdks)

ext <- 0.2

clpExt <- extent(c(142.6556-ext, 143.029+ext, -35.85385-ext, -35.50771+ext ))
dts <- c('2016-04-12', '2016-06-09', '2017-03-02')
yrs <- c('2016', '2016', '2017')


product <- 'M:/SMIPSv0.5/API_OPENLOOP'
product <- 'E:/SMIPS/SMIPSv0.5/Data/CSIRO/Wetness-Index/Final/'

outproduct <- 'CSIRO_Wetness-Index'
outproduct <- 'CSIRO_OpenLoop'

#20170102_SMIPSv05_API_forecast.flt

for(i in 1:length(dts)){
  print(dts[i])
  
    r <- raster(paste0(product, '/', yrs[i], '/CSIRO_Wetness-Index_', dts[i], '.tif'))
    
    crp <- crop(r, clpExt, filename=paste0('e:/temp/clip_', outproduct, '_', dts[i], '.tif'), overwrite=T)
    plot(crp)
}

r <- raster(paste0(product, '/2017/20170102_SMIPSv05_API_forecast.flt'))
crp <- crop(r, clpExt, filename=paste0('e:/temp/clip_', outproduct, '_', dts[i], '.tif'), overwrite=T)



