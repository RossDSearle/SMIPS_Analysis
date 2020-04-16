library(raster)
library(stringr)


ind2 <- raster('M:/SMIPSv0.5/API_VOlSM_OpenLoop/API_VOlSM_OpenLoop_tiff/2016/SMIPSv05_volSM_forecast_20160113.tif')

rootDir <- 'M:/blendedPrecipOutputs/blendedPrecipTiff'

fl <- list.files(rootDir, pattern = '.tif$', full.names = T, recursive = T)
for (i in 134: length(fl)){
  print(paste0(i, ' of ', length(fl)))
  inR <- raster(fl[i])
  outR <- leaflet::projectRasterForLeaflet(inR)
  bits <- str_split(basename(fl[i]), '_')
  dirname(fl[i])
  outfname <- paste0(dirname(fl[i]), '/',bits[[1]][1], '_',bits[[1]][2], '_',bits[[1]][3], '_WGS84WM_',bits[[1]][4])
  writeRaster(outR, outfname, overwrite=T)
}