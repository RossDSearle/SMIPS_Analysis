library(httr)
library(dplyr)
library(DBI)
library(RSQLite)
library(forecast)
library(stringr)
library(xts)
library(ggplot2)
library(plotly)


#############    Functions - Ignore to next line of Hashes
doQuery <- function(con, sql){
  res <- dbSendQuery(con, sql)
  rows <- dbFetch(res)
  dbClearResult(res)
  return(rows)
}


getSensorData <- function(conStore, sensorNum, sdate=NULL, edate=NULL){
  sql <- paste0("SELECT sensorNum, datetime(sensorData.dateTime) as dt, sensorData.value
      FROM SensorData
      WHERE SensorData.sensorNum = ", sensorNum,"")
  if(is.null(sdate)){
    sql <- paste0(sql,  " ORDER BY dt;")
  }else{
    sql <- paste0(sql,  "  and dt  between '",sdate,"' and '",edate,"' ORDER BY dt;")
  }
  df <-  doQuery(conStore, sql)
  return(df)
}


getTidyTS <- function(df, removeNA=T, upperBound=NULL, lowerBound=NULL){
  ts <- xts(df[,3], order.by=as.Date(df[,2]))
  if(!is.null(upperBound)){
    ts[ts>upperBound] <- NA
  }
  if(!is.null(lowerBound)){
    ts[ts<lowerBound] <- NA
  }

  ts <- na.trim(ts)
  if(removeNA){
    ts <-  na.omit(ts)
  }
  return(ts)
}

####################################################################################################

##########   Start Here   ######################

dbFedPath <- "c:/Users/mcj002/Dropbox/Documents/Projects/AgSoilMoist/DB/SensorFederator.sqlite"
dbStorePath <- paste0("c:/Users/mcj002/Dropbox/Documents/Projects/AgSoilMoist/DB/SensorFederatorDataStore.db")

conFed <- dbConnect(RSQLite::SQLite(), dbFedPath, flags = SQLITE_RW)
conStore <- dbConnect(RSQLite::SQLite(), dbStorePath, flags = SQLITE_RW)


sql <- "SELECT * FROM Sites INNER JOIN Sensors ON Sites.SiteID = Sensors.SiteID WHERE QualityIndex > 0.9 and DataType='Soil-Moisture';"

allSensors <- doQuery(conFed, sql)

smlocs <- distinct(data.frame(allSensors$SiteID, allSensors$SiteName, allSensors$Latitude, allSensors$Longitude, stringsAsFactors = F))
colnames(smlocs) <- c('SiteID', 'SiteName', 'Latitude', 'Longitude')
nrow(smlocs)

smlocs

#i=1

for (i in 1:nrow(smlocs)) {

  print(i)
  rec <- smlocs[i,]
 
  sqlSenNum <- paste0("select * from Sensors where SiteID='", rec$SiteID, "' and DataType = 'Soil-Moisture'")
  storeSensors <- doQuery(conStore, sqlSenNum)
  
  allTS <- vector('list', length = nrow(storeSensors))
  for (j in 1:nrow(storeSensors)) {
    
    if(storeSensors$upperDepth[j] != 'NA'){
      sensorNum <- storeSensors$sensorNum[j]
      d <- getSensorData(conStore, sensorNum)
      probeTs <- getTidyTS( d, removeNA=T, upperBound=100, lowerBound=0)
      colnames(probeTs) <- paste0('SM ',storeSensors$upperDepth[j])
      allTS[[j]] <-  probeTs
    }
  }
  
 tss <- do.call(merge, allTS)
 #plot(tss , main=paste0(storeSensors$SiteID))
 #addLegend("topright", on=1, legend.names = colnames(tss), lty=c(1, 1), lwd=c(2, 1), col=1:ncol(tss))
 a<-data.frame(date=index(tss), coredata(tss))
 library(tidyverse)
 b<-a%>%gather(key='Depth',value='Moisture',starts_with("SM"))
 
 c<-ggplot(b, aes(x=date,y=Moisture, group=Depth))+
   geom_line(aes(colour=Depth))+
   theme_light()+
   theme(axis.text.x=element_text(angle=90,hjust=1)) +
   #scale_y_continuous(name=(expression("Soil moisture " ~(m^3/m^3))))+
   #scale_x_date("Date",date_labels = "%d-%m-%Y",date_breaks = "1 month")+
   ggtitle(paste0(storeSensors$SiteID))
 fig<-ggplotly(c)
 fig
 ID<-paste0(storeSensors$SiteID)
 row<-i
 filename<-paste0("c:/Users/mcj002/Dropbox/Documents/Projects/AgSoilMoist/DB/Html_PlotlyTest/",row,"_",ID,".html")
 htmlwidgets::saveWidget(as_widget(fig), filename[1],selfcontained = FALSE)
 
 #Export plots
 filename2<-paste0("c:/Users/mcj002/Dropbox/Documents/Projects/AgSoilMoist/DB/PlotsTest/",row,"_",ID,".tif")
#tiff(filename = filename2[1],width=1500, height=750,units="px",res=100)
 tiff(filename = filename2[1],width=1500, height=750,units="px",res=100)

print( ggplot(b, aes(x=date,y=Moisture, group=Depth))+
   geom_line(aes(colour=Depth))+
   theme_light()+
   theme(axis.text.x=element_text(angle=90,hjust=1)) +
   scale_y_continuous(name=(expression("Soil moisture " ~(m^3/m^3))))+
   scale_x_date("Date",date_labels = "%d-%m-%Y",date_breaks = "1 month")+
   ggtitle(paste0(storeSensors$SiteID)))
 dev.off()
}


#}