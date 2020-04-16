library(ncdf4)
library(raster)
library(rgdal)
library(lubridate)

#another way to get a raster from the netcdf but the below approach is more generalisable
#r <- raster('C:/Projects/SMIPS/SMEstimates/BOM/AWRANetCDFs/s0_pct_2012.nc', band=33)



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
dimT = ncdim_def("time", units = "days since 2016-01-01", 1:1500 , unlim = T, calendar = 'gregorian', longname='time')
#dimT = ncdim_def("time", "days since 1899-12-31", seq(dimSD, dimED), calendar = 'gregorian', longname='time')
var3d1 = ncvar_def(name=atts[1], units='Percent', longname='Soil Moisture 0-10cm', dim=list(dimX,dimY,dimT), missval=-999,  prec="double", compression=9)
var3d2 = ncvar_def(name=atts[2], units='Percent', longname='Soil Moisture 0-90cm', dim=list(dimX,dimY,dimT), missval=-999,  prec="double", compression=9)
var3d3 = ncvar_def(name=atts[3], units='Percent', longname='Soil Moisture 10-90cm', dim=list(dimX,dimY,dimT), missval=-999,  prec="double", compression=9)

ncNew = nc_create(outFileName, list(var3d1, var3d2,var3d3))

for(i in 1:length(atts)){

  att <- atts[i]
  geotifsPath <- paste0(rootDir, '/geotifs/', att)

  if(!dir.exists(geotifsPath)){dir.create(geotifsPath, recursive = T)}
  
  
  dcnt <- 0
  for (j in 1:length(yrs)) {
    
  
    yr<-yrs[j]
    print(paste0(att, ' ', yr))
    nc <- nc_open(paste0(rootDir,'/', att, '_',yr, '.nc'))
    
    lons <- ncvar_get(nc, "longitude") 
    lats <- ncvar_get(nc, "latitude") 
    dys <-  ncvar_get(nc, "time") 
    originString <- nc$dim$time$units
    
    for (k in 1:length(dys)) {
      theDay <- ymd("2016-01-01") + days(dcnt)
      #dfo <- as.numeric(difftime(theDay,ymd("1900-01-01")))
      outFile <- paste0(geotifsPath, '/', att, '_',theDay, '.tif' )
      #if(!file.exists(outFile)){
       
      
      d <- as.matrix(ncvar_get( nc, att, start=c(1,1,k), count=c(nc$dim$longitude$len, nc$dim$latitude$len, 1) ))
        ncr <- raster(as.matrix(t(d)), xmn=min(lons), xmx=max(lons), ymn=min(lats), ymx=max(lats))
       
        writeRaster(ncr, outFile, overwrite=T)
        
        ncvar_put( ncNew, att, d[], start=c(1,1,dcnt+1), count=c(-1,-1,1))
      #}
        dcnt = dcnt+1
        print(k)
      
    }
  }
}
nc_close(ncNew)
nc_close(nc)





tnc <- nc_open('C:/Projects/SMIPS/SMEstimates/BOM/AWRANetCDFs/Allinncdf/AWRA.nc')
ncvar_get(tnc, "time") 
nc_close(tnc)



