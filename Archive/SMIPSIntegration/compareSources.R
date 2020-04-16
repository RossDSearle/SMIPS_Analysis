library(raster)
library(stringr)
rasterOptions(datatype="FLT4S", timer=TRUE, format='GTiff',progress="text",chunksize=1e+08,maxmemory=1e+09, overwrite=TRUE)

smipsRoot <- 'C:/Projects/SMIPS/Rasters/Wetness_Index'
anuRoot <- 'C:/Projects/SMIPS/Rasters/ANU/Tiffs'
bomRoot <- 'C:/Projects/SMIPS/Rasters/BOM'

yr = 2017

files <- list.files(paste0(anuRoot, '/', yr), pattern = '.tif', full.names = T)

lc2a <- numeric(length = length(files))
lc2b <- numeric(length = length(files))
lb2a <- numeric(length = length(files))
lmr <- numeric(length = length(files))

for (i  in 1:length(files)) {

  dt1 <- str_split(basename(files[i]), '_')
  dt2 <-  str_replace(dt1[[1]][3], '.tif', '')
  bits <- str_split(dt2, '-')
  tyear <- bits[[1]][1]
  tmonth <- bits[[1]][2]
  tday <-  bits[[1]][3]

  smipF <- paste0(smipsRoot, '/', yr, '/SMIPSv05_wetness_forecast_', tyear,tmonth,tday , '.tif')
  anuF <- files[i]
  bomF <- paste0(bomRoot, '/', yr, '/BOM_Soil-Moisture_', dt2, '.tif')



  ######   BOM raster dates are out by 1 day - need to fix by reimporting

  if(file.exists(smipF) & file.exists(anuF) & file.exists(bomF)){

    smips <- raster(smipF)
    anu <- raster(anuF)
    bom <- raster(bomF)
    anu2 <- anu / 2000

    NAvalue(bom) <- -999

    anur <- resample(anu2, smips, method='bilinear' )
    bomr <- resample(bom, smips, method='bilinear' )

    stk <- stack(smips,anur,bomr)
    plot(stk)

    jnk=layerStats(stk, 'pearson', na.rm=T)
    corr_matrix=jnk$'pearson correlation coefficient'
    corr_matrix

    c2b <- corr_matrix[1,3]
    c2a <- corr_matrix[1,2]
    b2a <- corr_matrix[3,2]

    minr <- min(stk)
    maxr <- max(stk)
    ranger <- maxr-minr
    meanRange <-cellStats(ranger, stat = 'mean')

    lc2b[i] <- c2b
    lc2a[i] <- c2a
    lb2a[i] <- b2a
    lmr[i] <- meanRange

  }

}

dfAnal <- data.frame(lc2b, lc2a, lb2a,lmr)
dfAnal

plot(seq(1:365), dfAnal$lc2b, type='l')
lines(seq(1:365), dfAnal$lc2a, type='l', col='red')
lines(seq(1:365), dfAnal$lb2a, type='l', col='green')








smips <- raster('C:/Projects/SMIPS/Rasters/Wetness_Index/2017/SMIPSv05_wetness_forecast_20170101.tif')
anu <- raster('C:/Projects/SMIPS/Rasters/ANU/Tiffs/2017/ANU_Soil-Moisture_2017-01-01.tif')
bom <- raster('C:/Projects/SMIPS/Rasters/BOM/2017/BOM_Soil-Moisture_2017-01-02.tif')
anu2 <- anu / 2000


minr <- min(stk)
maxr <- max(stk)
ranger <- maxr-minr
meanRange <-cellStats(ranger, stat = 'mean')
sd(ranger)
plot(ranger)

sd(stk)

std <- cellStats(stk, stat = 'sd')

plot(std)


plot(m)

beginCluster()
x <- clusterR(stk, range, verbose=T)

stkr <- addLayer(stk, ranger)
plot(stkr)
