library(stringr)
library(raster)
library(lubridate)

rasterOptions(datatype="FLT4S", timer=TRUE, format='GTiff',progress="text",chunksize=1e+08,maxmemory=1e+09) # maxmemory = max no of cells to read into memory

# products <- c('Wetness-Index', 'BlendedRainfall')
# productPaths <- c('//OSM-12-CDC.it.csiro.au/OSM_CBR_LW_SATSOILMOIST_processed/SMIPSv0.5/WETNESS_ANALYSIS/WETNESS_ANALYSIS_tiff', 
#                   '//OSM-12-CDC.it.csiro.au/OSM_CBR_LW_SATSOILMOIST_processed/blendedPrecipOutputs/blendedPrecipTiff',
#                    '//OSM-12-CDC.it.csiro.au/OSM_CBR_LW_SATSOILMOIST_processed/blendedPrecipOutputs/blendedPrecipTiff')

rootDir <- '//ternsoils/E/SMIPS/SMIPSv0.5/Data'

logFile <- paste0(rootDir, '/copyLog.csv')

#####   Copy the Wetness Index Files to the Web Server

product <- 'Wetness-Index'
productPath <- '//OSM-12-CDC.it.csiro.au/OSM_CBR_LW_SATSOILMOIST_processed/SMIPSv0.5/WETNESS_ANALYSIS/WETNESS_ANALYSIS_tiff' 

destDir <- paste0('E:/SMIPS/SMIPSv0.5/Data/CSIRO/', product, '/Final' )
srcDir <-  paste0(productPath)

fl <- list.files(srcDir, pattern = '.tif$', recursive = T, full.names = T)
fl2 <- fl[!grepl('_forecastErrorVar_', fl, ignore.case=TRUE)]
fl3 <- fl2[!grepl('forecast_WGS84WM', fl2, ignore.case=TRUE)]
print(paste0('Number of files available = ', length(fl3)))

for(i in 1:length(fl3)){
  
  f <- fl3[i]
  yrDir <- basename(dirname(f))
  fb <- basename(f)
  bits <- str_split(fb, '_')
  dbit <- str_remove(bits[[1]][4], '.tif')
  mth <- str_sub(dbit, 5, 6)
  dy <- str_sub(dbit, 7, 8)
  
  dnew <- paste0(destDir, '/', yrDir)
  outF <- paste0(destDir, '/', yrDir, '/CSIRO_',product, '_',yrDir, '-', mth, '-',  dy, '.tif' )
  
  if(!dir.exists(dnew)) 
  {
    dir.create(dnew, recursive = T)
  }
  if(!file.exists(outF))
  {
    r <- raster(f)
    print(outF)
    # copy as a raster so that we get a compressed version
    suppressWarnings(writeRaster(r,outF, overwrite = T, progress = ""))
    cat(product, ',', f, ',', outF, ',', as.character(now()), '\n', file = logFile, append = T )
    #file.copy(f, outF)
  }
}




#####   Copy the Blended Rainfall Files to the Web Server

product <- 'Blended-Rainfall'
productPath <- '//OSM-12-CDC.it.csiro.au/OSM_CBR_LW_SATSOILMOIST_processed/blendedPrecipOutputs/blendedPrecipTiff' 

destDir <- paste0('E:/SMIPS/SMIPSv0.5/Data/CSIRO/', product, '/Final' )
srcDir <-  paste0(productPath)

fl <- list.files(srcDir, pattern = '.tif$', recursive = T, full.names = T)
fl3 <- fl[!grepl('WGS84WM', fl, ignore.case=TRUE)]
print(paste0('Number of files available = ', length(fl3)))

for(i in 1:length(fl3)){
  
  f <- fl3[i]
  yrDir <- basename(dirname(f))
  fb <- basename(f)
  bits <- str_split(fb, '_')
  dbit <- bits[[1]][1]
  mth <- str_sub(dbit, 5, 6)
  dy <- str_sub(dbit, 7, 8)
  
  dnew <- paste0(destDir, '/', yrDir)
  outF <- paste0(destDir, '/', yrDir, '/CSIRO_',product, '_',yrDir, '-', mth, '-',  dy, '.tif' )
  
  if(!dir.exists(dnew)) 
  {
    dir.create(dnew, recursive = T)
  }
  if(!file.exists(outF))
  {
    r <- raster(f)
    print(outF)
    # copy as a raster so that we get a compressed version
    suppressWarnings(writeRaster(r,outF, overwrite = T, progress = ""))
    cat(product, ',', f, ',', outF, ',', as.character(now()), '\n', file = logFile, append = T )
    #file.copy(f, outF)
  }
}
