library(raster)
library(ncdf4)



###    This data is available at 
###    http://wenfo.org/ausenv/#/2017/Soil_moisture/Grid/Actual/States_and%20Territories/bar,timeseries,options/-23.07/135.08/4/South%20Australia/Satellite/Opaque

###    metadata is at http://wald.anu.edu.au/australias-environment/


####   Get ANU Data as a annual netcdf lump
####   http://dapds00.nci.org.au/thredds/fileServer/ub8/au/OzWALD/daily/OzWALD.daily.Ssoil.2017.nc

brk <- brick('C:/systemp/OzWALD.daily.Ssoil.2017.nc')

r3 <- t(r1)
r1 <- flip(brk[[1]], direction = 2)
r1 <- t(brk[[1]])
r2 <- flip(r1, direction = 1)
plot(r2)


ncinB <- nc_open('C:/systemp/OzWALD.daily.Ssoil.2017.nc')
brk2 <- brick('C:/Projects/SMIPS/SMIPSAnalysis/AWRA/sm_pct_2017_Actual_day.nc')
plot(brk2[[1]])





######   The ANU data is only publically available as far as I can see in a yearly dump
######   The script below extarcts the daily data from the yearly dump, 
######   Tbut from above should only be run once the yearly dump is available

library(raster)
library(RCurl)
library(stringr)
library(lubridate)

rasterOptions(datatype="FLT4S", timer=TRUE, format='GTiff',progress="text",chunksize=1e+08,maxmemory=1e+09, overwrite=TRUE) 


rootDir <- '//ternsoils/E/SMIPS/SMIPSv0.5/Data'
logFile <- paste0(rootDir, '/copyLog.csv')
templateR <- raster(paste0(rootDir,'/CSIRO/Wetness-Index/Final/2015/CSIRO_Wetness-Index_2015-11-19.tif'))

atts <- c('Ssoil')


for (j in 1:length(atts)) {
  att <- atts[j]
  
  dts <- seq(from=as.Date('2015/01/01'), to=as.Date(format(Sys.Date(), format="%Y/%m/%d")), by = "days")
  
  for (i in 1:length(dts)) {
    
    dy <- dts[i]
    fname <- paste0(rootDir, '/ANU/', att, '/Final/', year(dy) , '/ANU_', att, '_', format(dy, format="%Y-%m-%d"), '.tif')
    
    if(!file.exists(fname)){
      print(paste0('Extracting from BOM - ', basename(fname)))
      
      dirn <- dirname(fname)
      if(!dir.exists(dirn)){dir.create(dirn, recursive = T)}
      
      doy <- as.numeric(strftime(dy, format = "%j"))
      url <- paste0('http://dapds00.nci.org.au/thredds/dodsC/ub8/au/OzWALD/daily/OzWALD.daily.', att, '.', year(dy), '.nc.ascii?', att, '[', doy-1, ':1:',doy-1,']')
      outFile <- paste0(tempdir(), 'ANUData.txt')
      #outFile <- paste0('c:/temp/ANUData.txt')
      download.file(url = url, destfile = outFile, quiet = T)
      dt <- read.table(outFile, skip=12, nrows = 841 , sep = ',')
      dt2 <- dt[,-1]
      m <- as.matrix(dt2)
      r <- raster(nrows=681, ncols=841, xmn=111.975, xmx= 154.025, ymn=-44.025, ymx=-9.975, crs=CRS('+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0'),  vals=t(m))
      NAvalue(r) <- -999
      rs <- resample(r, templateR, method='ngb', filename=fname)
      
      cat(att, ',', url, ',', fname, ',', as.character(now()), '\n', file = logFile, append = T )
      
    }  
  }
  
}






