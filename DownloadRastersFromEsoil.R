library(utils)
library(raster)

#http://esoil.io/thredds/wcs/SMIPSall/SMIPSv0.5.nc?SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage&FORMAT=GeoTIFF&COVERAGE=Analysis_Wetness_Index&BBOX=133,-26,140,-20&CRS=OGC:CRS84&TIME=2020-03-18T00:00:00Z

rootDir <- 'C:/Projects/SMIPS/SMEstimates/CSIRO'

dys <- seq(as.Date("2016/1/1"), as.Date("2020/3/25"), "day")

att <- 'Analysis_Wetness_Index'
att <- 'Openloop_Wetness_Index'

if(!dir.exists(paste0(rootDir, '/', att))) {dir.create(paste0(rootDir, '/', att))}
  
for (i in 1:length(dys)){
  print(i)
  d <- dys[i]
  outFile <-  paste0(rootDir, '/', att, '/', att, '_', d, '.tif')
  if(!file.exists(outFile)){
    url <- paste0('http://esoil.io/thredds/wcs/SMIPSall/SMIPSv0.5.nc?SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage&FORMAT=GeoTIFF&COVERAGE=', att, '&CRS=OGC:CRS84&TIME=', d, 'T00:00:00Z')
    download.file(url, outFile, mode = 'wb', quiet = T)
  }
}

download.file(url, 'c:/temp/testWI.tif', mode = 'wb', quiet = T)


library(utils)
library(raster)
url <- paste0('http://esoil.io/thredds/wcs/SMIPSall/SMIPSv0.5.nc?SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage&FORMAT=GeoTIFF&COVERAGE=Analysis_Wetness_Index&CRS=OGC:CRS84&TIME=2016-01-01T00:00:00Z')
download.file(url, outFile, mode = 'wb', quiet = T)
r <- raster(outFile)
plot(r)
hist(r)