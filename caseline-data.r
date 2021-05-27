args <- commandArgs(trailingOnly=TRUE)
print(args)

pkgs <- c("jsonlite","data.table","dplyr")

for(x in pkgs){
  if(!is.element(x, installed.packages()[,1])){
    install.packages(x,repo="http://cran.rstudio.com/")
  } else {
    print(paste(x, " library already installed"))
  }
}

library(jsonlite)
library(data.table)
library(dplyr)

options(scipen = 999)

print("Starting script to download raw data")
esriStandardMaxLength <- 32000
data <- list()

trgtYr <- 2020
curYear <- as.integer(format(Sys.Date(),'%Y'))
url <- paste0(args[1],'/Case_Data_2020/',args[2])
feed2021 <- '/Florida_COVID19_Case_Line_Data_2021/'
repeat {
  if (trgtYr > curYear) break
  offset <- 0
  repeat{
    fullURL <- paste0(url,"&resultOffset=",offset)
    print(paste0(
      "Opening URL: ",
      fullURL
    ))
    
    json <- fromJSON(
      txt = fullURL
    )
    
    if("error" %in% names(json)){
      print(paste0("ERROR CODE: ",json$error$code))
      print(paste0("ERROR MESSAGE: ",json$error$message))
      print(paste0("ERROR DETAIL: ",json$error$details))
      print("===")
      Sys.sleep(5)
      next
    }
    
    if(length(json$features)==0){
      print("NO CASES LEFT TO PROCESS FOR THIS YEAR")
      trgtYr <- trgtYr + 1
      url <- paste0(args[1],feed2021,args[2])
      break
    } 
    
    latestListIndex <- length(data)+1
    data[[latestListIndex]] <- json$features$attributes
    
    offset <- offset + esriStandardMaxLength
  }
  
}

print("Done parsing JSON")

# outdf <- do.call(rbind,data)
outdf <- rbindlist(
  l = data,
  fill = T
)

downloadedFiles <- list.files(
  path = args[3],
  full.names = T
)

previousDataFileName <- downloadedFiles[length(downloadedFiles)]
if(length(previousDataFileName)>0){
  latestFileData <- fread(previousDataFileName)
  
  tmp <- "temp.csv"
  write.csv(
    x = outdf,
    file = tmp,
    na = '',
    row.names = F
  )
  
  print("Comparing latest data to most recently downloaded data file.")
  print(paste0("Previously downloaded file size: ",file.size(previousDataFileName)))
  print(paste0("Downloaded file size: ",file.size(tmp)))
  if(file.size(previousDataFileName)==file.size(tmp)){
    print("State's latest data has not been changed.")
    file.remove(tmp)
    stop(1)
  }
  # notDownloadingHospitalBedData <- !grepl("HOSPITALS_esri",args[1],fixed=T)
  # if (notDownloadingHospitalBedData) {
  #   if(grepl('Florida_Testing',args[1],fixed=T)){
  #     state1 <- filter(
  #       .data = outdf,
  #       County_1=='State'
  #     )
  #     
  #     state2 <- filter(
  #       .data = latestFileData,
  #       County_1=='State'
  #     )
  #     
  #     if(state1$TPositive == state2$TPositive){
  #       print("State's latest data has not been changed.")
  #       file.remove(tmp)
  #       stop(1)
  #     }
  #   } else{
  #     print(paste0("Previously downloaded file size: ",file.size(previousDataFileName)))
  #     print(paste0("Downloaded file size: ",file.size(tmp)))
  #     if(file.size(previousDataFileName)==file.size(tmp)){
  #       print("State's latest data has not been changed.")
  #       file.remove(tmp)
  #       stop(1)
  #     }
  #   }
  # } else {
  #   # previousData <- read.csv(previousDataFileName)
  #   previousData <- fread(previousDataFileName)
  #   
  #   if(max(outdf$EditDate)==max(previousData$EditDate)){
  #     print("Hospital beds data has not been changed.")
  #     file.remove(tmp)
  #     stop(1)
  #   }
  # }
}


write.csv(
  x = outdf,
  file = args[4],
  na = '',
  row.names = F
)

write.csv(
  x = outdf,
  file = args[5],
  na = '',
  row.names = F
)
print("===========")
