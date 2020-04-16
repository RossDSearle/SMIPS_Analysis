library(raster)
library(ncdf4)
library(stringr)
library(doParallel)


#Rasters of annual daily soil water estimates
#http://dap.nci.org.au/thredds/remoteCatalogService?catalog=http://dapds00.nci.org.au/thredds/catalog/ub8/au/OzWALD/daily/catalog.xml

### drill a pixel
#http://dapds00.nci.org.au/thredds/dodsC/ub8/au/OzWALD/daily/OzWALD.daily.Ssoil.2017.nc.ascii?Ssoil[0:1:364][384:1:384][271:1:271]

# Get ANU Data

# data Are only available as Annual rasters so will need to run this once a year as they become available

rootDir <- 'C:/Projects/SMIPS/Rasters'
anuSrcRoot <- paste0(rootDir, '/ANU')
ext <- extent(c(111.975, 154.025, -44.025, -9.975))
SMIPSTemplateRaster <- raster(paste0(rootDir, '/CSIRO/Wetness_Index/Final/2017/SMIPSv05_wetness_forecast_20170101.tif'))

yrs <- c(2015, 2016, 2017)
atts <-c('Ssoil')

print('ANU Soil Moisture Information Processing')
for (j in length(atts)) {

    for (i  in length(yrs)) {

        att<-atts[j]
        yr<-yrs[i]
        brk <- brick(paste0(anuSrcRoot, '/', att, '/Downloads/OzWALD.daily.', att, '.', yr, '.nc'))
        print(paste0('Extracting ANU ', att ,' data for ', yr))
        pb <- txtProgressBar(min = 0, max = nlayers(brk), style = 3)

        outRawDir <- paste0(anuSrcRoot, '/', att,  '/RawTiffs/', yr)

        if(!dir.exists(outRawDir)){dir.create(outRawDir, recursive = T)}
        for(i in 1:nlayers(brk)){

          outRawFile <- paste0(outRawDir, '/ANU_', att, '_', brk@z[[1]][i],'.tif' )
          if(!file.exists(outRawFile)){
              r1 <- t(brk[[i]])
              r2 <- flip(r1, direction = 1)
              writeRaster(r2, filename =  outRawFile)
          }

          outFinalDir <- paste0(anuSrcRoot, '/', att,  '/Final/', yr)
          if(!dir.exists(outFinalDir)){dir.create(outFinalDir, recursive = T)}
          outFinalFile <- paste0(outFinalDir, '/ANU_', att, '_', brk@z[[1]][i],'.tif' )
          if(!file.exists(outFinalFile)){
            r <- raster(outRawFile)
            r1 <- t(r)
            anu <- flip(r1, direction = 1)
            anu2 <- anu / 2000
            anur <- resample(anu2, SMIPSTemplateRaster, method='bilinear' )
            writeRaster(anur, filename = outFinalFile )
          }


          setTxtProgressBar(pb, i)
        }

        close(pb)

    }
}




print(paste0('Extracting ANU ', att ,' data for ', yr))
pb <- txtProgressBar(min = 0, max = nlayers(brk), style = 3)

outRawDir <- paste0(anuSrcRoot, '/', att,  '/RawTiffs/', yr)

if(!dir.exists(outRawDir)){dir.create(outRawDir, recursive = T)}

numcpus = detectCores()
numcpus = 5
cl<-makeCluster(numcpus,outfile="")
registerDoParallel(cl)
#foreach(k=1:length(infiles), .packages=c('raster','rgdal'), .export= c("parallelExtract")) %dopar% parallelExtract(infiles = infiles, theStack = theStack, outDir = outDir)
foreach(i=1:nlayers(brk), .packages=c('raster','rgdal') ) %dopar% ProcessANUData(brk, att, yr, anuSrcRoot, SMIPSTemplateRaster)
stopCluster(cl)


ProcessANUData <- function(brk, att, yr, anuSrcRoot, SMIPSTemplateRaster){

  outRawDir <- paste0(anuSrcRoot, '/', att,  '/RawTiffs/', yr)
  if(!dir.exists(outRawDir)){dir.create(outRawDir, recursive = T)}

    outRawFile <- paste0(outRawDir, '/ANU_', att, '_', brk@z[[1]][i],'.tif' )
    if(!file.exists(outRawFile)){
      r1 <- t(brk[[i]])
      r2 <- flip(r1, direction = 1)
      writeRaster(r2, filename =  outRawFile)
    }

    outFinalDir <- paste0(anuSrcRoot, '/', att,  '/Final/', yr)
    if(!dir.exists(outFinalDir)){dir.create(outFinalDir, recursive = T)}
    outFinalFile <- paste0(outFinalDir, '/ANU_', att, '_', brk@z[[1]][i],'.tif' )
    if(!file.exists(outFinalFile)){
      r <- raster(outRawFile)
      anu2 <- r / 2000
      anur <- resample(anu2, SMIPSTemplateRaster, method='bilinear' )
      writeRaster(anur, filename = outFinalFile )
    }

}