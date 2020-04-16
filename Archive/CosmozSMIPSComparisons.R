library(RCurl)
library(XML)
library(xml2)
library(stringr)
library(htmltidy)
library(TSdist)
library(xts)
library(forecast)
library(TTR)

rootDir <- 'C:/Users/sea084/Dropbox/RossRCode/Shiny/SMIPS'
AnalysisRoot <- 'C:/Projects/SMIPS/SMIPSAnalysis/ComparisonStats'

source(paste0(rootDir, '/scripts/Functions/SOSFunctions.R'))
source('C:/Users/sea084/Dropbox/RossRCode/myFunctions/ModelUtils.R')

smdf <- read.csv('C:/Users/sea084/Dropbox/RossRCode/Shiny/SMIPS/LocationsForProps/Soil Moisture_Continuous.csv') 

coz <- smdf[grepl('cosmoz', smdf$procedure ) & grepl('soil_moisture_filtered', smdf$procedure),  ]



sdate = '2015-10-01'
edate = '2017-12-01'

analSdate = '2015-10-01'
#analSdate = '2016-08-01'
#analSdate = '2017-01-01'
analEdate = '2017-12-01'

smoothingFactor = 3

fl <- list.files(paste0(AnalysisRoot, '/Data'), pattern = 'Cosmoz', full.names = T )

lsite <- character(length = length(fl))
lInd_R2 <- numeric(length = length(fl))
lInd_Con <- numeric(length = length(fl))
lVol_R2 <- numeric(length = length(fl))
lVol_Con <- numeric(length = length(fl))

lAWRA_R2 <- numeric(length = length(fl))
lAWRA_Con <- numeric(length = length(fl))
lAWRASurf_R2 <- numeric(length = length(fl))
lAWRASurf_Con <- numeric(length = length(fl))


for (z in 1 : length(fl)){

    fn <- fl[z]
    print(fn)
    siteName <- str_replace(basename(fn), '.rds', '')
    tss <- na.omit(readRDS(fn))
    
    sn <- str_split(siteName, '_')[[1]][3]
    tssA <- readRDS(paste0('C:/Projects/SMIPS/SMIPSAnalysis/ComparisonStats/data/AWRA_Site_', sn, '.rds'))
    tssSurf <- readRDS(paste0('C:/Projects/SMIPS/SMIPSAnalysis/ComparisonStats/data/AWRA_Site_SurfMoist', sn, '.rds'))
    
   
    tss$smipsVol <- tss$smipsVol * 0.33
    tss$smipsInd <- tss$smipsInd * 60
    #tss$cozmm <- tss$coz * 3
    tss[tss > 70] <- 70
    
    tssA <- tssA * 100
    tssSurf <- tssSurf * 100
    
    tss22  <- merge.xts(tss, tssA)
    tss2 <- merge.xts(tss22, tssSurf)
    tss2 <- na.omit(tss2)
    colnames(tss2) <- c('coz', 'smipsInd', 'smipsVol', 'AWRA_SoilProfile', 'AWRA_Surf')
    
    tss2$coz <- SMA(tss2$coz, n = smoothingFactor)
    tss2$smipsInd <- SMA(tss2$smipsInd, n = smoothingFactor)
    tss2$smipsVol <- SMA(tss2$smipsVol, n = smoothingFactor)
    tss2$AWRA_SoilProfile <- SMA(tss2$AWRA_SoilProfile , n = smoothingFactor) 
    tss2$AWRA_Surf <- SMA(tss2$AWRA_Surf , n = smoothingFactor) 
    
    SiteTSs <- tss2[paste0(analSdate, '/', analEdate)] 
    
    if(length(SiteTSs)> 0){
    plot.xts(SiteTSs, main = paste0('Cosmoz Site ', siteName), cex.main=2, legend.loc = 'topright')
    
    
    #stss <- standardiseTS(tss)
    #plot.xts(stss, main = paste0('Cosmoz Site ', siteName), cex.main=2, legend.loc = 'topright')
    
    
    fI <- fitStats(tss2$coz , tss2$smipsInd, paste0('Index ', siteName), paste0(AnalysisRoot, '/Ind_', siteName, '.txt'))
    fV <- fitStats(tss2$coz , tss2$smipsVol, paste0('Vol ', siteName), paste0(AnalysisRoot, '/Vol_', siteName, '.txt'))
    fA <- fitStats(tss2$coz , tss2$AWRA_SoilProfile, paste0('AwraProfile ', siteName), paste0(AnalysisRoot, '/AWRA_Profile', siteName, '.txt'))
    fASurf <- fitStats(tss2$coz , tss2$AWRA_Surf, paste0('AwraSurface ', siteName), paste0(AnalysisRoot, '/AWRA_Surf', siteName, '.txt'))
    
   
    lsite[z] <- siteName
    lInd_R2[z] <- as.numeric(str_split(fI, ',')[[1]][1])
    lInd_Con[z] <- as.numeric(str_split(fI, ',')[[1]][2])
    lVol_R2[z] <- as.numeric(str_split(fV, ',')[[1]][1])
    lVol_Con[z] <- as.numeric(str_split(fV, ',')[[1]][2])
    
    lAWRA_R2[z] <- as.numeric(str_split(fA, ',')[[1]][1])
    lAWRA_Con[z] <- as.numeric(str_split(fA, ',')[[1]][2])
    lAWRASurf_R2[z] <- as.numeric(str_split(fASurf, ',')[[1]][1])
    lAWRASurf_Con[z] <- as.numeric(str_split(fASurf, ',')[[1]][2])
    
    }

}

resultsDF <- data.frame(lsite, lInd_R2, lVol_R2, lAWRA_R2,lAWRASurf_R2, lInd_Con,  lVol_Con,  lAWRA_Con, lAWRASurf_Con)

write.csv(resultsDF, paste0(AnalysisRoot, '/fits.csv'))







SiteTSs <- tss[paste0(analSdate, '/', analEdate)] 
siteName = 'Test'
plot.xts(SiteTSs, main = paste0('Cosmoz Site ', siteName), cex.main=2, legend.loc = 'topright')


fitStats(outTS$coz , outTS$smipsVol, '', 'c:/temp/stuff.txt')

fitStats(SiteTSs$coz , SiteTSs$smipsVol, '', 'c:/temp/stuff.txt')



standardiseTS <- function(tss){

    minV <- max(tss$coz) 
    maxV <- min(tss$coz)
    valsCoz <- (tss$coz - minV) / (maxV - minV)
    
    minV <- max(tss$smipsInd) 
    maxV <- min(tss$smipsInd)
    valssmipsInd <- (tss$smipsInd - minV) / (maxV - minV)
    
    minV <- max(tss$smipsVol) 
    maxV <- min(tss$smipsVol)
    valssmipsVol <- (tss$smipsVol - minV) / (maxV - minV)
    
    outTS <- cbind(valsCoz, valssmipsInd, valssmipsVol)

}

