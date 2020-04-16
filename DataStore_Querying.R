library(DBI)
library(RSQLite)
library(stringr)


rootDir <-  'C:/Projects/SensorFederator'
dbFedPath <- "C:/Users/sea084/Dropbox/RossRCode/Git/SensorFederator/DB/SensorFederator.sqlite"
dbStorePath <- paste0(rootDir, "/DataStore/SensorFederatorDataStore.db")

source('C:/Users/sea084/Dropbox/RossRCode/Git/SensorFederator/Backends/Backend_Utils.R')
source('C:/Users/sea084/Dropbox/RossRCode/Git/SensorFederator/Harvesting/TSUtils.R')

conFed <- dbConnect(RSQLite::SQLite(), dbFedPath, flags = SQLITE_RW)
conStore <- dbConnect(RSQLite::SQLite(), dbStorePath, flags = SQLITE_RW)



#########  Quality Assessment  ######################################################################
sql <- "Select * from Sensors where DataType = 'Soil-Moisture' and HasData = 'TRUE'"
sm <- doQuery(conFed, sql)

odf <- data.frame(stringsAsFactors = F)
for (i in 1:nrow(sm)){
  print(i)
  rec <- sm[i,]
  sqlSenNum <- paste0("select * from Sensors where SiteID='", rec$SiteID, "' and upperDepth = '", rec$UpperDepth, 
                      "' and lowerDepth = '", rec$LowerDepth, "' and DataType = 'Soil-Moisture'")
  storeSens <- doQuery(conStore, sqlSenNum)
  if(nrow(storeSens)>0){
    sensorNum <- storeSens$sensorNum
    
    d <- getSensorData(conStore, sensorNum)
    ts <- xts(d[,3], order.by=as.Date(d[,2]))
    q <- assessTSQuality(ts, verbose = T, maxVal=80,  minVal=5, minNumDays=20, desiredNumDays=100)
    #print(q)
    #print(plot(ts, main = paste0('Quality for ', rec$SiteID, ' ',  rec$SensorName, ' = ', format(q$QualityIndex, digits=2) )))
    
    df <- data.frame(rec$SiteID, rec$DataType, rec$UpperDepth, rec$LowerDepth, 
                     format(q$QualityIndex, digits=2), q$LowestIndexName, format(q$LowestIndexValue, digits=2), 
                     format(q$IinRange, digits=2), format(q$IvalidProp, digits=2), format(q$InumGaps, digits=2), 
                     format(q$ItotalGapsDays, digits=2), format(q$IdesiredNumDays, digits=2), 
                     q$StartDate, q$EndDate, q$TotalNumDays, q$TotalValidDays, format(q$ValidProportion, digits=2), q$NumGaps, q$NumGapDays, q$NumInRange,
                     q$StandardDeviation, q$MeanValue, q$IsActive, q$HarvestDate, q$HasData, 
                     stringsAsFactors = F)
    
    odf<-rbind(odf, df)
  }
}


colnames(odf) <- c('SiteID','DataType', 'UpperDepth', 'LowerDepth',  names(q))


odf

write.csv(odf, 'c:/temp/SMQual.csv')



