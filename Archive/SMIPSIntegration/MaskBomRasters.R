library(raster)


mr <- raster('E:/SMIPS/SMIPSv0.5/Data/CSIRO/Wetness-Index/Final/2015/CSIRO_Wetness-Index_2015-11-19.tif')

fl <- list.files('E:/SMIPS/SMIPSv0.5/Data/BOM', '.tif$', recursive = T, full.names = T)

#pb <- txtProgressBar(min = 0, max = length(fl), style = 3)
for (i in 1522:length(fl)){
  print(paste0(i, ' ', fl[i]))
  r <- raster(fl[i])
  r[r < 0] <- NA
  ro <- mask(r, mr, filename = fl[i], overwrite = T)
 #setTxtProgressBar(pb, i)
}
#close(pb)


