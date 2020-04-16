library(raster)
library(RCurl)
library(ncdf4)
library(stringr)

rasterOptions(datatype="FLT4S", timer=TRUE, format='GTiff',progress="text",chunksize=1e+08,maxmemory=1e+09, overwrite=TRUE) 

source('C:/Users/sea084/Dropbox/RossRCode/myFunctions/DateTimeUtils.R')

outDir <- 'c:/temp'

awncpath <- 'C:/Projects/SMIPS/SMIPSAnalysis/AWRA/sm_pct_2017_Actual_day.nc'

downloadRoot <- 'C:/Projects/SMIPS/SMIPSAnalysis/AWRA/Downloads'

att <- 's0_pct' #0-10cm
#att <- 'sm_pct' #0-90cm
att <- 'ss_pct' #10-90cm

yrs <- seq(2015, 2017, 1)

downloadPath <- paste0(downloadRoot, '/', att)
if(!dir.exists(downloadPath)){dir.create(downloadPath, recursive = T)}


##### Download Data From BOM #######

for(i in 1:length(yrs)){
  
  yr <- yrs[i]
  
  numDays <- days.in.year(yr)
  
  for(k in 1:numDays){
    
    print(paste0(yr, ' : ', k))
    
    out <- tryCatch(
      {
        #j <- RCurl::getURL(paste0('http://www.bom.gov.au/jsp/awra/thredds/dodsC/AWRA/values/day/sm_pct_', yr, '.nc.ascii?sm_pct[', k-1, ':1:',k-1,']')) 
        url <- paste0('http://www.bom.gov.au/jsp/awra/thredds/dodsC/AWRA/values/day/', att, '_', yr, '.nc.ascii?', att, '[', k-1, ':1:',k-1,']')
        outFile <- paste0(downloadPath, '/', yr, '_', k, '.txt')
        download.file(url = url, destfile = outFile, quiet = T)
        #cat(j, file = outFile)
        
      }, error=function(e){})
  }
}


templateR<- raster()

dt <- read.table(infile, skip=12, nrows = 681 , sep = ',')
dt2 <- dt[,-1]
m <- as.matrix(dt2)
r <- raster(nrows=681, ncols=841, xmn=111.975, xmx= 154.025, ymn=-44.025, ymx=-9.975, crs=CRS('+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0'),  vals=m)
plot(r)
NAvalue(r) <- -999

brk <- brick(awncpath)
templateR <- brk[[1]]


outFileName <- paste0(outDir, '/AWRA_', att, '.nc')


Longvector = seq(112, 154, by = 0.05)
Latvector = seq(-44, -10, by = 0.05)

daysInYrs <- days.in.year(yrs)
numDays <- sum(daysInYrs)


dimSD <- daysSinceDate('1899-12-31', paste0(yrs[1], '-01-01') )
dimED <- daysSinceDate('1899-12-31', paste0(yrs[length(yrs)],'-12-31') )

ds = seq(from=dimSD, to=dimED, by=1)
dimX = ncdim_def("Long", "degrees_north", Longvector)
dimY = ncdim_def("Lat", "degrees_south", Latvector)
dimT = ncdim_def("time", "days since 1899-12-31", seq(dimSD, dimED), calendar = 'gregorian', longname='time')
var3d = ncvar_def( att, "units", list(dimX,dimY,dimT), -999,  prec="double", compression=1)

nc = nc_create(outFileName, list(var3d))

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




######        AWRA Data   ########################


smdf <- read.csv('C:/Users/sea084/Dropbox/RossRCode/Shiny/SMIPS/LocationsForProps/Soil Moisture_Continuous.csv') 
coz <- smdf[grepl('cosmoz', smdf$procedure ) & grepl('soil_moisture_filtered', smdf$procedure),  ]


sdate = '2015-10-01'
edate = '2017-12-01'

analSdate = '2016-08-01'
analEdate = '2017-12-01'


infile <- 'C:/Projects/SMIPS/SMIPSAnalysis/AWRA/AWRA_s0_pct_2015_2017.nc'
brk <- brick(infile)


for(i in 1: nrow(coz)){
  
  siteName <- str_split(str_split(coz$procedure[i], '/')[[1]][7], '[.]')[[1]][3]
  fname <- paste0(AnalysisRoot, '/Data/Cosmoz_Site_', siteName, '.rds')
  #print(fname)
  if(file.exists(fname)){
    
    uri <- paste0(coz$procedure[i], ',', coz$ObsPropURL[i])
    print(paste0('Extracting data for : ', coz$procedure[i]))
    v <- t(extract(brk, rbind(c( coz$lat[i], coz$lon[i]))))
    
    vs <- as.numeric(v[,1])
    dts <- brk@z
    
    
    df<-data.frame( dts, vs)
    df$Date <- as.character(df$Date)
    df$Date <- as.POSIXct(paste0(as.Date(df$Date), 'T00:00:00'), format="%Y-%m-%dT%H:%M:%S")
    
    colnames(df) <- c('Date', "AWRA")
    
    
    tsAWRA <- xts(read.zoo(df))
    colnames(tsAWRA) <- 'AWRA'
    saveRDS(tsAWRA, file = paste0('C:/Projects/SMIPS/SMIPSAnalysis/ComparisonStats/data/AWRA_Site_SurfMoist', siteName, '.rds'))
    
  }}

