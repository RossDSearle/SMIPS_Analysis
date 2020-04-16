library(raster)
library(RCurl)
library(ncdf4)
library(stringr)
library(lubridate)

rasterOptions(datatype="FLT4S", timer=TRUE, format='GTiff',progress="text",chunksize=1e+08,maxmemory=1e+09, overwrite=TRUE) 


rootDir <- 'C:/Projects/SMIPS/SMEstimates/BOM'
logFile <- paste0(rootDir, '/copyLog.csv')
#templateR <- raster(paste0(rootDir,'/CSIRO/Wetness-Index/Final/2015/CSIRO_Wetness-Index_2015-11-19.tif'))
templateR <- raster('C:/Temp/holes/Analysis_Wetness_Index_2016-01-15.tif')
atts <- c('s0_pct','sm_pct' )


for (j in 1:length(atts)) {
  att <- atts[j]
  
    dts <- seq(from=as.Date('2016/01/01'), to=as.Date(format(Sys.Date(), format="%Y/%m/%d")), by = "days")
    
    for (i in 1:length(dts)) {
      
      dy <- dts[i]
      if(!dir.exists(paste0(rootDir, '/BOM/', att))){dir.create(paste0(rootDir, '/BOM/', att))}
      fname <- paste0(rootDir, '/BOM/', att, '/BOM_', att, '_', format(dy, format="%Y-%m-%d"), '.tif')
      
      if(!file.exists(fname)){
        print(paste0('Extracting from BOM - ', basename(fname)))
        
        dirn <- dirname(fname)
        if(!dir.exists(dirn)){dir.create(dirn, recursive = T)}
        
        doy <- as.numeric(strftime(dy, format = "%j"))
        url <- paste0('http://www.bom.gov.au/jsp/awra/thredds/dodsC/AWRA/values/day/', att, '_', year(dy), '.nc.ascii?', att, '[', doy-1, ':1:',doy-1,']')
        outFile <- paste0(tempdir(), 'AWRAData.txt')
        download.file(url = url, destfile = outFile, quiet = T)
        dt <- read.table(outFile, skip=12, nrows = 681 , sep = ',')
        # odData1 <- read.table(text=d1, skip=12, nrows = 681 , sep = ',')
        dt2 <- dt[,-1]
        m <- as.matrix(dt2)
        m[m==-999.0] <- NA
        r <- raster(nrows=681, ncols=841, xmn=111.975, xmx= 154.025, ymn=-44.025, ymx=-9.975, crs=CRS('+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0'),  vals=m)
        NAvalue(r) <- -999
        rs <- resample(r, templateR, method='ngb', filename=fname)
        
        cat(att, ',', url, ',', fname, ',', as.character(now()), '\n', file = logFile, append = T )
        
      }  
    }

}
