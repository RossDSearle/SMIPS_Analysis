library(stringr)



fl <- list.files('E:/SMIPS/SMIPSv0.5/Data/CSIRO/BlendedRainfall/Final', '.tif', recursive = T, full.names = T)
fl <- list.files('E:/SMIPS/SMIPSv0.5/Data/CSIRO/Volumetric-Moisture/Final', '.tif', recursive = T, full.names = T)
fl <- list.files('E:/SMIPS/SMIPSv0.5/Data/CSIRO/Wetness-Index/Final', '.tif', recursive = T, full.names = T)

# delete WGS84WM files
for (i in 1:length(fl)){
  if (str_detect(fl[i], 'WGS84WM')){
    unlink(fl[i])
  }
}

# rename files
for (i in 1:length(fl)){
  fname <- basename(fl[i])
  dirName <- dirname(fl[i])
  d <- str_split(fname, '_')[[1]][4]
  y <- str_sub(d, 1, 4)
  m <- str_sub(d, 5, 6)
  d <- str_sub(d, 7, 8)
  #newName <- paste0('CSIRO_Blended-Rainfall_', y, '-', m, '-', d, '.tif')
  newName <- paste0('CSIRO_Wetness-Index_', y, '-', m, '-', d, '.tif')
  file.rename(fl[i], paste0(dirName, '/', newName))
}

for (i in 1:length(fl)){
  newname <- str_replace(fl[i], 'CSIRO_Wetness-Index_', 'CSIRO_Blended-Rainfall_')

  file.rename(fl[i], newName)
}