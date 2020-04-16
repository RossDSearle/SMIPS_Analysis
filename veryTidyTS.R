library(xts)
library(DBI)
library(RSQLite)



rootDir <-  'C:/Projects/SensorFederator'

doQuery <- function(con, sql){
  res <- dbSendQuery(con, sql)
  rows <- dbFetch(res)
  dbClearResult(res)
  return(rows)
}

getProbeData<- function(conStore, sid){
  
  sqlSenNum <- paste0("select * from Sensors where SiteID='", sid, "' and DataType = 'Soil-Moisture'")
  storeSensors <- doQuery(conStore, sqlSenNum)
  
  allTS <- vector('list', length = nrow(storeSensors))
  for (j in 1:nrow(storeSensors)) {
    
    if(storeSensors$upperDepth[j] != 'NA'){
      sensorNum <- storeSensors$sensorNum[j]
      df <- getSensorData(conStore, sensorNum)
      #probeTs <- getTidyTS( d, removeNA=T, upperBound=100, lowerBound=0)
      probeTs <- xts(df[,3], order.by=as.Date(df[,2]))
      print(head(probeTs))
      colnames(probeTs) <- paste0('SM ',storeSensors$upperDepth[j])
      allTS[[j]] <-  probeTs
    }
  }
  
  tss <- do.call(merge, allTS)
  print(plot(tss, main=sid))
  return(tss)
}


getTidyTS <- function(ts, removeNA=T, upperBound=NULL, lowerBound=NULL, flatCnt=NULL, removeOutliers=NULL, removeStartDays=NULL){
  
  ######   exlude values outside bounds
  if(!is.null(upperBound)){
    ts[ts>upperBound] <- NA
  }
  if(!is.null(lowerBound)){
    ts[ts<lowerBound] <- NA
  }
  
  ######  remove flat spot values
  if(!is.null(flatCnt)){
    sdf <- aggregate(data.frame(count = its), list(value = its), length)
    colnames(sdf) <- c('value', 'count')
    sorteddata <- sdf[order(-sdf$count),]
    remVals <- sorteddata[sorteddata$count >= flatCnt, ]$value
    if(length(remVals) > 0){
      for (i in 1:length(remVals)) {
        ts[ts==remVals[i]] <- NA
      }
    }
  }
  
  ######   remove outliers  
  if(!is.null(removeOutliers)){
    
    # lq <- quantile(its, probs = c(0.01), na.rm=T)
    # lb <- as.numeric(lq[1])
    # its[its<lb] <- NA
    
    i <- tsoutliers(ts)
    ts[i$index] <- NA
  }
  
  if(!is.null(removeStartDays)){
   ts <- ts[removeStartDays:nrow(ts)]
  }
  

  if(removeNA){
    ts <-  na.omit(ts)
  }
  return(ts)
}




plotlyPlot <- function(tss){
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
  return(fig)
}

dbStorePath <- paste0(rootDir, "/DataStore/SensorFederatorDataStore.db")
conStore <- dbConnect(RSQLite::SQLite(), dbStorePath, flags = SQLITE_RO)


sid <- 'SFS_47'
sid <- 'SFS_57'
sid <- 'SFS_60'


ts <- getProbeData(conStore, sid)
its <- ts[,1]
plot(its)
tts <- getTidyTS(ts=its, removeNA = F, upperBound = 100, lowerBound = 3, flatCnt = 10, removeOutliers = T, removeStartDays = 100)
lines(tts, col='red')



removeStartDays=100
tts <- its[removeStartDays:nrow(its)]


plotlyPlot(ts)
its <- ts[,1]


flatCnt <- 20

sdf <- aggregate(data.frame(count = its), list(value = its), length)
colnames(sdf) <- c('value', 'count')
head(sdf)
sorteddata <- sdf[order(-sdf$count),]
#head(sorteddata, 100)
remVals <- sorteddata[sorteddata$count >= flatCnt, ]$value
for (i in 1:length(remVals)) {
  its[its==remVals[i]] <- NA
}

plot(its)



ts <- getProbeData(conStore, sid)
plotlyPlot(ts)
its <- ts[,1]
plotlyPlot(its)

lq <- quantile(its, probs = c(0.01), na.rm=T)
lq
lb <- as.numeric(lq[1])

its[its<lb] <- NA
plot(its)
tail(its)

library(forecast)
tsc <- tsclean(its)
tsc <-tsclean(its, replace.missing = F, lambda = 0.01)
plot(its)
lines(tsc, col='red')

i <- tsoutliers(its)
tsc <- its
tsc[i$index] <- NA

plot(its)
lines(tsc, col='blue')
plot(tsc)


ts[-1:removeStartDays] <- NA