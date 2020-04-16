library(ncdf4)
library(raster)

rootDir <- 'C:/Projects/SMIPS/SMEstimates/BOM/AWRANetCDFs'

#att <- 's0_pct' #0-10cm
#att <- 'sm_pct' #0-90cm
#att <- 'ss_pct' #10-90cm
atts <- c('s0_pct','sm_pct', 'ss_pct')

yrs <- seq(2016, 2020, 1)

outFileName <- paste0(rootDir, '/Allinncdf/AWRA.nc')

Longvector = seq(112, 154, by = 0.05)
Latvector = seq(-10, -44,  by = -0.05)
dimX = ncdim_def("Long", "degrees_north", Longvector)
dimY = ncdim_def("Lat", "degrees_south", Latvector)
dimT = ncdim_def("time", units = "days since 1900-01-01", 1:2000, unlim = T, calendar = 'gregorian', longname='time')
#dimT = ncdim_def("time", "days since 1899-12-31", seq(dimSD, dimED), calendar = 'gregorian', longname='time')
var3d1 = ncvar_def(name=atts[1], units='Percent', longname='Soil Moisture 0-10cm', dim=list(dimX,dimY,dimT), missval=-999,  prec="double", compression=9)
var3d2 = ncvar_def(name=atts[2], units='Percent', longname='Soil Moisture 0-90cm', dim=list(dimX,dimY,dimT), missval=-999,  prec="double", compression=9)
var3d3 = ncvar_def(name=atts[3], units='Percent', longname='Soil Moisture 10-90cm', dim=list(dimX,dimY,dimT), missval=-999,  prec="double", compression=9)

nc = nc_create(outFileName, list(var3d1, var3d2,var3d3))
r<- raster('C:/Projects/SMIPS/SMEstimates/BOM/AWRANetCDFs/geotifs/sm_pct/sm_pct_2016-01-22.tif')
ncvar_put( nc, nc$var$s0_pct, t(r[]), start=c(1,1,1), count=c(-1,-1,1))
nc_close(nc)

dayCnt =1
for(i in 1:length(yrs)){
  
  yr <- yrs[i]
  
  numDays <- days.in.year(yr)
  
  for(k in 1:numDays){
    
    print(paste0(yr, ' : ', k))
    
    out <- tryCatch(
      {
        
        infile <- paste0(downloadPath, '/', yr, '_', k, '.txt')
        r <- raster(templateR)
        NAvalue(r) <- -999
        dt <- read.table(infile, skip=12, nrows = 681 , sep = ',')
        dt2 <- dt[,-1]
        m <- as.matrix(dt2)
        r[] <- m
        rm2 <- flip(r, direction='y')
        ncvar_put( nc, var3d, rm2[], start=c(1,1,dayCnt), count=c(-1,-1,1))
        
        
      }, error=function(e){})
    
    dayCnt <- dayCnt + 1
    
  }
  
}

nc_close(nc)
