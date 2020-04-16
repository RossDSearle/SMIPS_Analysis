library(raster)
library(httr)
library(ncdf4)
library(stringr)

rasterOptions(datatype="FLT4S", timer=TRUE, format='GTiff',progress="text",chunksize=1e+08,maxmemory=1e+09, overwrite=TRUE) 

source('C:/Users/sea084/Dropbox/RossRCode/myFunctions/DateTimeUtils.R')


downloadRoot <- 'C:/Projects/SMIPS/SMEstimates/BOM/AWRANetCDFs'

att <- 's0_pct' #0-10cm
att <- 'sm_pct' #0-90cm
att <- 'ss_pct' #10-90cm

atts <- c('s0_pct','sm_pct', 'ss_pct')

yrs <- seq(2005, 2020, 1)

downloadPath <- paste0(downloadRoot)
if(!dir.exists(downloadPath)){dir.create(downloadPath, recursive = T)}

##### Download NetCDF Data From BOM #######


for(i in 1:length(atts)){
  att<-atts[i]
  for (y in 1:length(yrs)) {    
    yr <- yrs[y]
    print(paste0(att, ' ', yr))
    
      out <- tryCatch(
        {
          url <- paste0('http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/', att, '_', yr, '.nc')
          outFile <- paste0(downloadPath, '/', att, '_', yr, '.nc')
          download.file(url = url, destfile = outFile, quiet = T, mode = 'wb')
        }, error=function(e){})
  }
}
  
