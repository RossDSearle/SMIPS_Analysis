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

ProcessANUData <- function(brk, att, yr, anuSrcRoot, SMIPSTemplateRaster){

resp1 <- ''
resp2 <- ''

  # out <- tryCatch(
  #   {

        outRawDir <- paste0(anuSrcRoot, '/', att,  '/RawTiffs/', yr)
        if(!dir.exists(outRawDir)){dir.create(outRawDir, recursive = T)}

        outRawFile <- paste0(outRawDir, '/ANU_', att, '_', brk@z[[1]][i],'.tif' )
        if(!file.exists(outRawFile)){
          r1 <- t(brk[[i]])
          r2 <- flip(r1, direction = 1)
          writeRaster(r2, filename =  outRawFile)
          resp1 <- paste0( 'Raw raster ', basename(outRawFile), ' extracted from NetCDF')
        }else{
          resp1 <- paste0(response, 'Raw raster ', basename(outRawFile), ' already existed on disk')
        }

        outFinalDir <- paste0(anuSrcRoot, '/', att,  '/Final/', yr)
        if(!dir.exists(outFinalDir)){dir.create(outFinalDir, recursive = T)}
        outFinalFile <- paste0(outFinalDir, '/ANU_', att, '_', brk@z[[1]][i],'.tif' )
        if(!file.exists(outFinalFile)){
          r <- raster(outRawFile)
          anu2 <- r / 2000
          anur <- resample(anu2, SMIPSTemplateRaster, method='bilinear' )
          writeRaster(anur, filename = outFinalFile )
          resp2 <- paste0('Final raster ', basename(outFinalFile), ' written from rawTiff')
        }else{
          resp2 <- paste0('Final raster ', basename(outFinalFile), ' already existed on disk')
        }
        ar <- paste(resp1, resp2, sep='\n')
        return(ar)
    # }, error=function(e){
    #   return("X")
    # })

  #return(cat(resp1, resp2, sep='\n'))
  #return(cat("Hi", sep='\n'))
}

unlist(outs)



d <- lapply(outs, cat, collapse = '\n')

cat(outs)


rootDir <- 'C:/Projects/SMIPS/Rasters'
anuSrcRoot <- paste0(rootDir, '/ANU')
ext <- extent(c(111.975, 154.025, -44.025, -9.975))
SMIPSTemplateRaster <- raster(paste0(rootDir, '/CSIRO/Wetness_Index/Final/2017/SMIPSv05_wetness_forecast_20170101.tif'))

yrs <- c(2015, 2016, 2017)
atts <-c('Ssoil')
#numcpus = detectCores()
numcpus = 4

print('ANU Soil Moisture Information Processing')
for (j in 1:length(atts)) {

  for (i  in 1:length(yrs)) {

    att<-atts[j]
    yr<-yrs[i]
    print(yr)
    brk <- brick(paste0(anuSrcRoot, '/', att, '/Downloads/OzWALD.daily.', att, '.', yr, '.nc'))
    outRawDir <- paste0(anuSrcRoot, '/', att,  '/RawTiffs/', yr)

    if(!dir.exists(outRawDir)){dir.create(outRawDir, recursive = T)}

      print(paste0('Extracting ANU ', att ,' data for ', yr))
      outRawDir <- paste0(anuSrcRoot, '/', att,  '/RawTiffs/', yr)
      if(!dir.exists(outRawDir)){dir.create(outRawDir, recursive = T)}

      cl<-makeCluster(numcpus,outfile="")
      registerDoParallel(cl)
      outs <- foreach(i=1:nlayers(brk), .packages=c('raster','rgdal') ) %dopar% ProcessANUData(brk, att, yr, anuSrcRoot, SMIPSTemplateRaster)
      #outs <- foreach(i=1:3, .packages=c('raster','rgdal') ) %dopar% ProcessANUData(brk, att, yr, anuSrcRoot, SMIPSTemplateRaster)
      foreach(i=1:3) %do% sqrt(i)
       stopCluster(cl)
  }
}

ProcessANUData(brk, att, yr, anuSrcRoot, SMIPSTemplateRaster)

