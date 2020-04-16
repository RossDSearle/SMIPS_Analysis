library(httr)
library(dplyr)
library(DBI)
library(RSQLite)
library(forecast)

source('C:/Users/sea084/Dropbox/RossRCode/Git/SensorFederator/Backends/Backend_Utils.R')
source('C:/Users/sea084/Dropbox/RossRCode/Git/SensorFederator/Harvesting/HarvestUtils.R')


#http://esoil.io/thredds/wcs/SMIPSall/SMIPSv0.5.nc?SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage&FORMAT=GeoTIFF&COVERAGE=Analysis_Wetness_Index&BBOX=133,-26,140,-20&CRS=OGC:CRS84&TIME=2020-03-18T00:00:00Z


dbFedPath <- "C:/Users/sea084/Dropbox/RossRCode/Git/SensorFederator/DB/SensorFederator.sqlite"
dbStorePath <- paste0("C:/Projects/SensorFederator/DataStore/SensorFederatorDataStore.db")

conFed <- dbConnect(RSQLite::SQLite(), dbFedPath, flags = SQLITE_RW)
conStore <- dbConnect(RSQLite::SQLite(), dbStorePath, flags = SQLITE_RW)


sql <- "SELECT * FROM Sites INNER JOIN Sensors ON Sites.SiteID = Sensors.SiteID WHERE QualityIndex > 0.9 and DataType='Soil-Moisture';"
#sql <- "Select * from Sensors where DataType = 'Soil-Moisture' and HasData = 'TRUE'"
allSensors <- doQuery(conFed, sql)

smlocs <- distinct(data.frame(allSensors$SiteID, allSensors$SiteName, allSensors$Latitude, allSensors$Longitude))
colnames(smlocs) <- c('SiteID', 'Latitude', 'Longitude')
nrow(smlocs)


for(i in 1:nrow(smlocs)){
    print(paste0(i, ' of ', nrow(smlocs)))
    loc <- smlocs[i,]
    smipsURL <- paste0('http://esoil.io/SMIPS_API/SMIPS/TimeSeries?longitude=', loc$Longitude, '&latitude=',  loc$Latitude,'&sdate=20-11-2015&edate=20-03-2020')
    
    resp <- GET(smipsURL)
    response <- content(resp, "text", encoding = 'UTF-8')
    stream <- fromJSON(response)
    df <- stream$DataStream
    head(df[[1]])
    write.csv(df, paste0('C:/Projects/SMIPS/SMIPSAnalysis/ProbSitesSMIPSts/SMIPS_', loc$SiteID, '.csv'  ))
}


fls <- list.files('C:/Projects/SMIPS/SMIPSAnalysis/ProbSitesSMIPSts', full.names = T)

i=32

odf <- data.frame()

for (i in 1:length(fls)) {
  print(i)
  f <- fls[i]
  fn <- basename(f)
  sid <- str_replace(fn, 'SMIPS_', '')
  sid2 <- str_replace(sid, '.csv', '')
  
  smipsDF <- read.csv(f, stringsAsFactors = F)
  smipsTS <- xts(smipsDF[,3], order.by=as.Date(smipsDF[,2]))
  tsSMIPS <- getTidyTS( smipsTS, removeNA=T, upperBound=100, lowerBound=0)
  #plot(tsProbe)
  
 
  
  sqlSenNum <- paste0("select * from Sensors where SiteID='", sid2, "' and DataType = 'Soil-Moisture'")
  storeSensors <- doQuery(conStore, sqlSenNum)
  
  for (j in 1:nrow(storeSensors)) {
    
    if(storeSensors$upperDepth[j] != 'NA'){
        sensorNum <- storeSensors$sensorNum[j]
        probeData <- na.omit(getSensorData(conStore, sensorNum))
        
        its <- xts(probeData$value, order.by=as.Date(as.POSIXlt(probeData$dt, tz = "Australia/Brisbane",  tryFormats = c("%Y-%m-%d %H:%M:%OS") )))
        colnames(its) <- 'value'
        #its <- xts(probeData, order.by=index(probeData))
        
        originTs <- getTidyTS(ts=its, removeNA = F, upperBound = NULL, lowerBound = NULL, flatCnt = NULL, removeOutliers = NULL, removeStartDays = NULL)
        probeTs <- getTidyTS(ts=its, removeNA = T, upperBound = 100, lowerBound = 3, flatCnt = 10, removeOutliers = T, removeStartDays = 100)

        if(!is.null(probeTs)){
        
          if(nrow(probeTs) > 0){
          
            a  <- merge(originTs,probeTs, join = 'inner')
            plot(a)
            
              mts <- merge(tsSMIPS*100,probeTs, join = 'inner')
              compTS <- na.omit(mts)
              plot(mts)
              plot(probeTs)
              lines(tsSMIPS*100, col='red')
              
              omts <- merge(tsSMIPS*100,originTs)
              origcompTS <- na.omit(omts)
              
              sm <-  ma(tsSMIPS*100, 10)
              smXTS <- xts(sm, order.by=index(tsSMIPS) )
              smoothTS <- merge(smXTS, probeTs, join = 'inner')
              smoothTS2 <- na.trim(smoothTS)
              
              
              if(nrow(compTS) > 0){
                  colnames(compTS) <- c('SMIPS', paste0( storeSensors$SiteID[j],'!', storeSensors$upperDepth[j] ))
                  
                   plot(smoothTS2)
                  # addLegend("topright", on=1, legend.names = colnames(bob2), lty=c(1, 1), lwd=c(2, 1), col=1:ncol(bob2))
                  
                  dfcomp <- na.omit(as.data.frame(coredata(compTS)))
                  dforiginal<- na.omit(as.data.frame(coredata(origcompTS)))
                  dfSmooth <- na.omit(as.data.frame(coredata(smoothTS)))
                #  qts <- quantile(df2$`Cosmoz_10!0`, c(0.01, 0.99))
                #  k <- df2$`Cosmoz_10!0`
                # ts4 <- (probeTs-4.6) * (100/25)
  
                 # plot(df3)
                 # points(df2, col='red')
                  cr <- cor(dfcomp[,1], dfcomp[,2])
                  cr2 <- cor(dforiginal[,1], dforiginal[,2])
                  cr3 <- cor(dfSmooth[,1], dfSmooth[,2])
                  rdf <- data.frame(siteID=sid2, depth=storeSensors$lowerDepth[j], R2Clean=cr,R2orig=cr2, R2smth=cr3)
                  odf<- rbind(odf, rdf)
              }
            }
         }
     }
   }
}

write.csv(odf, 'C:/Projects/SMIPS/SMIPSAnalysis/probesVSmipsNew2.csv', row.names = F )


odf <- read.csv('C:/Projects/SMIPS/SMIPSAnalysis/probesVSmips.csv', stringsAsFactors = F)

mean(odf[odf$R2Clean>0, ]$R2Clean, na.rm=T)
mean(odf[odf$R2orig >0, ]$R2orig, na.rm=T)


mean(odf[odf$depth==100, ]$R2, na.rm=T )
mean(odf[odf$depth==200, ]$R2, na.rm=T)
mean(odf[odf$depth==300, ]$R2, na.rm=T)
mean(odf[odf$depth==300, ]$R2smth, na.rm=T)
mean(odf[odf$depth==400, ]$R2, na.rm=T)
mean(odf[odf$depth==400, ]$R2smth, na.rm=T)
mean(odf[odf$depth==500, ]$R2, na.rm=T)
mean(odf[odf$depth==600, ]$R2, na.rm=T)
mean(odf[odf$depth==700, ]$R2, na.rm=T)
mean(odf[odf$depth==800, ]$R2, na.rm=T)
mean(odf[odf$depth==900, ]$R2, na.rm=T)

unique(odf$depth)


length(as.numeric(tsSMIPS))
length(sm)

sm <-  ma(tsSMIPS, 30)
smXTS <- xts(sm, order.by=index(tsSMIPS) )
bob <- merge(tsSMIPS, smXTS)
plot(bob)

df <- na.omit(data.frame(tsSMIPS, sm))


cor(df$tsSMIPS, df$sm)

head(tsSMIPS)

bob <- merge(tsSMIPS, as.xts(sm))


s <- ksmooth(time(tsSMIPS), tsSMIPS, "normal", bandwidth = 3)
tsSmooth <- xts(s[2]$y, order.by=as.Date(s[1]$x, format='%Y-%m-%d' ))

smts <- merge(tsSMIPS,tsSmooth, join='left')
head(smts)
compTS <- na.trim(mts)
plot(smts)


d <- s[1]
head(d$x)
