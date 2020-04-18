library(raster)
library(ncdf4)
library(lubridate)


atts <- c('S0', 'SS', 'SM')
att <- 'sm_pct'

rootDir <- 'C:/Projects/SMIPS'
AnalysisRoot <- paste0(rootDir, '/SMIPSAnalysis/ProbSitesAWRA_', att)
if(!dir.exists(AnalysisRoot)){dir.create(AnalysisRoot)}

probeLocs <- read.csv(paste0(rootDir, '/ProbeAnalysis/ProbeQualitySummary.csv'), stringsAsFactors = F)


nc <- nc_open(paste0('C:/Projects/SMIPS/SMEstimates/BOM/AWRANetCDFs/Allinncdf/AWRA.nc'))

nc$dim$time$id

dys <-  ncvar_get(nc, "time") 
tail(dys)
validDays <- dys[dys!=-2147483647]
originString <- nc$dim$time$units

d <- as.matrix(ncvar_get( nc, att, start=c(1,1,1), count=c(nc$dim$Long$len, nc$dim$Lat$len, 1) ))
template <- raster(as.matrix(t(d)), xmn=min(nc$dim$Long$vals), xmx=max(nc$dim$Long$vals), ymn=min(nc$dim$Lat$vals), ymx=max(nc$dim$Lat$vals))
plot(template)

dts <- dmy("31/12/2015") + days(validDays)

for(i in 1: nrow(probeLocs)){
  
  rec <- probeLocs[i,]
  siteName <- rec$SiteID
  fname <- paste0(AnalysisRoot, '/AWRA_', att, '_', siteName, '.csv')
  print(fname)

  c <- cellFromXY(template, c(rec$Longitude,rec$Latitude))
  row <- rowFromCell(template, c)
  col <- colFromCell(template, c)
  vs <- ncvar_get( nc, att, start=c(col,row,1), count=c(1, 1, length(validDays)) )
  
    df<-data.frame( dts, vs)
    
    df$dts <- paste0(as.Date(df$dts), 'T00:00:00')
    
    colnames(df) <- c('t', "v")
    
    write.csv(df, paste0(AnalysisRoot,'/',att, '_',  siteName, '.csv'))
  
}





