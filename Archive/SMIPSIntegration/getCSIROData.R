library(stringr)
library(raster)
library(lubridate)
source('C:/Users/sea084/Dropbox/RossRCode/myFunctions/DateTimeUtils.R')

rasterOptions(datatype="FLT4S", timer=F, format='GTiff',progress="",chunksize=1e+08,maxmemory=1e+09, overwrite=TRUE)


startDate <- '2015-11-20'

atts <- c('API_VOlSM_OpenLoop', 'WETNESS_ANALYSIS', 'Blended_Rainfall')
attNames <- c('volSM_forecast', 'wetness_forecast', 'GPM_gauge_blendedDailyPrecip_LiShaoMethod')
outAttNames <- c('Volumetric-Moisture', 'Wetness-Index', 'Blended-Daily-Precip')
attPaths <- c('//OSM-12-CDC.it.csiro.au/OSM_CBR_LW_SATSOILMOIST_processed/SMIPSv0.5/API_VOlSM_OpenLoop/API_VOlSM_OpenLoop_tiff',
                  '//OSM-12-CDC.it.csiro.au/OSM_CBR_LW_SATSOILMOIST_processed/SMIPSv0.5/WETNESS_ANALYSIS/WETNESS_ANALYSIS_tiff',
                  '//OSM-12-CDC.it.csiro.au/OSM_CBR_LW_SATSOILMOIST_processed/blendedPrecipOutputs/blendedPrecipTiff')

#rootDir <- 'C:/Projects/SMIPS/Rasters'
rootDir <- 'E:/SMIPS/SMIPSv0.5/Data'
CSIROOutRoot <- paste0(rootDir, '/CSIRO')

days <- seq(as.Date(startDate), Sys.Date() - 1, "day")



for (j in 1:length(atts)){

      print(paste0('Downloading data for ', atts[j], '....'))
      pb <- txtProgressBar(min = 0, max = length(days), style = 3)
      att <- atts[j]
      attName <- attNames[j]
      outAttName <- outAttNames[j]

      destDirRoot <- paste0(CSIROOutRoot, '/', outAttName, '/Final' )
      downloadRoot <-  paste0(attPaths[j])

        for(i in 1:length(days)){
          yr <- lubridate::year(days[i])
          dt <- as.character(days[i], format='%Y%m%d')
          downloadPath <-  paste0(downloadRoot, '/', yr)
          destDir <- paste0(destDirRoot, '/', yr)
          if(att == 'Blended_Rainfall'){
            downloadFile <- paste0(downloadPath, '/', dt, '_', attName, '.tif')
            downloadFileWM <- paste0(downloadPath, '/', dt, '_', 'WGS84WM_', attName, '.tif')
          }else{
            downloadFile <- paste0(downloadPath, '/SMIPSv05_', attName, '_' , dt, '.tif')
            downloadFileWM <- paste0(downloadPath, '/SMIPSv05_', attName, '_WGS84WM_' , dt, '.tif')
          }

          destFile <- paste0(destDir, '/CSIRO_', outAttName, '_' , days[i], '.tif')
          if(!dir.exists(destDir)){dir.create(destDir, recursive = T)}

            if(file.exists(downloadFile))
            {
              if(!file.exists(destFile))
              {
                  r <- raster(downloadFile)
                  writeRaster(r,filename = destFile, overwrite = T, progress = "")
              }
            }

          # destFileWM <- paste0(destDir, '/CSIRO_', outAttName, '_' , days[i], '_WGS84WM.tif')
          # if(file.exists(downloadFileWM))
          # {
          #   if(!file.exists(destFileWM))
          #   {
          #     r <- raster(downloadFileWM)
          #     writeRaster(r,filename = destFileWM, overwrite = T, progress = "")
          #   }
          # }
          setTxtProgressBar(pb, i)
        }
    close(pb)
}
