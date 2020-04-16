library(RCurl)
library(XML)
library(xml2)
library(stringr)
library(htmltidy)
library(TSdist)
library(xts)
library(forecast)
library(TTR)
library(raster)

rootDir <- 'C:/Users/sea084/Dropbox/RossRCode/Shiny/SMIPS'
AnalysisRoot <- 'C:/Projects/SMIPS/SMIPSAnalysis/ComparisonStats'

source(paste0(rootDir, '/scripts/Functions/SOSFunctions.R'))
source('C:/Users/sea084/Dropbox/RossRCode/myFunctions/ModelUtils.R')

smdf <- read.csv('C:/Users/sea084/Dropbox/RossRCode/Shiny/SMIPS/LocationsForProps/Soil Moisture_Continuous.csv') 
coz <- smdf[grepl('cosmoz', smdf$procedure ) & grepl('soil_moisture_filtered', smdf$procedure),  ]
coz <- smdf[grepl('cosmoz', smdf$procedure ) ,  ]

sdate = '2015-10-01'
edate = '2017-12-01'

analSdate = '2016-08-01'
analEdate = '2017-12-01'

unitsDF <- read.csv(paste0('C:/Users/sea084/Dropbox/RossRCode/Shiny/SMIPS/ConfigFiles/units.csv'))

for(i in 1: nrow(coz)){
  
      siteName <- str_split(str_split(coz$procedure[i], '/')[[1]][7], '[.]')[[1]][3]
      fname <- paste0(AnalysisRoot, '/Data/Cosmoz_Site_', siteName, '.rds')
      if(!file.exists(fname)){
      
          uri <- paste0(coz$procedure[i], ',', coz$ObsPropURL[i])
          print(paste0('Extracting data for : ', coz$procedure[i]))
          respCoz <- getSOSAPIgetObservations(uri,  output='URL', startDate=sdate, endDate=edate)
        
          CosDF <- getSOSAPIgetObservationsAsDF(procedure = uri, output='Response', startDate=sdate, endDate=edate, aggtype = 'AveragePrec')
          
          if(!is.null(CosDF)){
              SmipsIndexDF <-SMIPSAPIgetObservationsAsDF(procedure = 'SoilMoistureIndex', output = 'Response', lon = coz$lon[i], lat= coz$lat[i], startDate = sdate, endDate = edate)
              SmipsVolDF <-SMIPSAPIgetObservationsAsDF(procedure = 'VolumetricSoilMoist', output = 'Response', lon = coz$lon[i], lat= coz$lat[i], startDate = sdate, endDate = edate)
              #SmipsVolDF$values <- SmipsVolDF$values * 0.33
            
              tsCos <- xts(read.zoo(CosDF))
              #tsCos <- SMA(tsCos, n = 10)
              tsSmipsIndex <- xts(read.zoo(SmipsIndexDF))
              #tsSmipsIndex <- SMA(tsSmipsIndex, n = 10)
              tsSmipsVol <- xts(read.zoo(SmipsVolDF))
              #tsSmipsVol <- SMA(tsSmipsVol, n = 10)
            
              mt1  <- merge.xts(tsCos, tsSmipsIndex, join="inner")
              mt2 <- merge.xts(mt1, tsSmipsVol, join="inner")
              colnames(mt2) <- c('coz', 'smipsInd', 'smipsVol')
              
              siteName <- str_split(str_split(coz$procedure[i], '/')[[1]][7], '[.]')[[1]][3]
              saveRDS(mt2, paste0(AnalysisRoot, '/Data/Cosmoz_Site_', siteName, '.rds'))
          }
     }
}






















