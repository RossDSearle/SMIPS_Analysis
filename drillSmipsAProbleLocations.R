library(httr)
library(dplyr)
library(DBI)
library(RSQLite)
library(forecast)
library(jsonlite)

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

smlocs <- distinct(data.frame(allSensors$SiteID, allSensors$Latitude, allSensors$Longitude))
colnames(smlocs) <- c('SiteID', 'Latitude', 'Longitude')
nrow(smlocs)


product <- 'Openloop_Wetness_Index'

for(i in 1:nrow(smlocs)){
  print(paste0(i, ' of ', nrow(smlocs)))
  loc <- smlocs[i,]
  smipsURL <- paste0('http://esoil.io/SMIPS_API/SMIPS/TimeSeries?product=', product, '&longitude=', loc$Longitude, '&latitude=',  loc$Latitude,'&sdate=20-11-2015&edate=20-03-2020')
  
  resp <- GET(smipsURL)
  response <- content(resp, "text", encoding = 'UTF-8')
  stream <- fromJSON(response)
  df <- stream$DataStream
  head(df[[1]])
  write.csv(df, paste0('C:/Projects/SMIPS/SMIPSAnalysis/ProbSites', product,'/', product,'_', loc$SiteID, '.csv'  ))
}
