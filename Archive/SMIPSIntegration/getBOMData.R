library(raster)
library(RCurl)
library(ncdf4)
library(stringr)
library(lubridate)
library(doParallel)

rasterOptions(datatype="FLT4S", timer=F, format='GTiff',progress="",chunksize=1e+08,maxmemory=1e+09, overwrite=TRUE)

source('C:/Users/sea084/Dropbox/RossRCode/myFunctions/DateTimeUtils.R')

rootDir <- 'C:/Projects/SMIPS/Rasters'
bomOutRoot <- paste0(rootDir, '/BOM')

#awncpath <- 'C:/Projects/SMIPS/SMIPSAnalysis/AWRA/sm_pct_2017_Actual_day.nc'

ext <- extent(c(111.975, 154.025, -44.025, -9.975))
templateR <- raster(ext)
res(templateR) <- 0.05
crs(templateR) <- CRS(" +proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

SMIPSTemplateRaster <- raster(paste0(rootDir, '/CSIRO/Wetness_Index/Final/2017/SMIPSv05_wetness_forecast_20170101.tif'))

days <- seq(as.Date("2015-01-01"), Sys.Date(), "day")

atts <- c('s0_pct','sm_pct')
#att <- 'sm_pct'

for(j in 1: length(atts)){

        att <- atts[j]
        downloadRoot <- paste0(bomOutRoot, '/', att, '/Downloads' )

        cat('Downloading data from the BoM for', att, '....')
        pb <- txtProgressBar(min = 0, max = length(days), style = 3)
        for(i in 1:length(days)){

          yr <-  lubridate::year(days[i])
          doy <- lubridate::yday(days[i])
          downloadPath <- paste0(downloadRoot, '/', yr)
          downloadFile <- paste0(downloadPath, '/', yr, '_' , doy, '.txt')
          if(!dir.exists(downloadPath)){dir.create(downloadPath)}
          ##### Download Data From BOM #######
          if(!file.exists(downloadFile)){

            out <- tryCatch(
              {
                #j <- RCurl::getURL(paste0('http://www.bom.gov.au/jsp/awra/thredds/dodsC/AWRA/values/day/sm_pct_', yr, '.nc.ascii?sm_pct[', k-1, ':1:',k-1,']'))
                url <- paste0('http://www.bom.gov.au/jsp/awra/thredds/dodsC/AWRA/values/day/', att, '_', yr, '.nc.ascii?', att, '[', doy-1, ':1:',doy-1,']')
                download.file(url = url, destfile = downloadFile, quiet = T)

              }, error=function(e){})
          }

          ##### Convert Raw BOM raster to tif  #######
          outRawTifDir <- paste0(bomOutRoot, '/', att, '/RawTiffs/', yr)
          if(!dir.exists(outRawTifDir)){dir.create(outRawTifDir, recursive = T)}

          fnameRaw = paste0(outRawTifDir, '/BOM_', att, '_', as.character(days[i]), '.tif' )
          if(!file.exists(fnameRaw)){
            out <- tryCatch(
              {
                infile <- downloadFile
                r <- raster(templateR)
                NAvalue(r) <- -999

                dt <- read.table(infile, skip=12, nrows = 681 , sep = ',')
                dt2 <- dt[,-1]
                m <- as.matrix(dt2)
                r[] <- m
                r[r < 0] <- NA
                ro <- mask(r, SMIPSTemplateRaster, filename = fl[i], overwrite = T)

                #writeRaster(r, filename = fnameRaw)
              }, error=function(e){})

          }

            outFinalDir <- paste0(bomOutRoot, '/', att, '/Final/', yr)
            if(!dir.exists(outFinalDir)){dir.create(outFinalDir, recursive = T)}

            fnameTif = paste0(outFinalDir, '/BOM_', att, '_', as.character(days[i]), '.tif' )

            ##### Resample to SMIPS resolution #######
            if(!file.exists(fnameTif)){
            r <- raster(fnameRaw)
            bomr <- resample(r, SMIPSTemplateRaster, method='bilinear', filename= fnameTif )
            }

            setTxtProgressBar(pb, i)
      }
}




