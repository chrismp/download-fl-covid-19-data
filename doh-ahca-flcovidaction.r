args <- commandArgs(trailingOnly=TRUE)

pkgs <- c("jsonlite")

for(x in pkgs){
  if(!is.element(x, installed.packages()[,1])){
    install.packages(x,repo="http://cran.rstudio.com/")
  } else {
    print(paste(x, " library already installed"))
  }
}

library(jsonlite)

options(scipen = 999)

print("Starting script to download raw data")
url <- args[1]
offset <- 0
esriStandardMaxLength <- 32000
data <- list()

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
  
  if(length(json$features)==0) break
  
  latestListIndex <- length(data)+1
  data[[latestListIndex]] <- json$features$attributes
  
  offset <- offset + esriStandardMaxLength
}

print("Done parsing JSON")

outdf <- do.call(rbind,data)

downloadedFiles <- list.files(
  path = args[2],
  full.names = T
)

previousDataFileName <- downloadedFiles[length(downloadedFiles)]
if(length(previousDataFileName)>0){
  latestFileDF <- read.csv(previousDataFileName)  
  
  tmp <- "temp.csv"
  write.csv(
    x = outdf,
    file = tmp,
    na = '',
    row.names = F
  )
  
  print("Comparing latest data to most recently downloaded data file.")
  notDownloadingHospitalBedData <- !grepl("HOSPITALS_esri",args[1],fixed=T)
  if (notDownloadingHospitalBedData) {
    print(paste0("Previously downloaded file size: ",file.size(previousDataFileName)))
    print(paste0("Downloaded file size: ",file.size(tmp)))
    if(file.size(previousDataFileName)==file.size(tmp)){
      print("State's latest data has not been changed.")
      file.remove(tmp)
      stop(1)
    }
  } else {
    previousData <- read.csv(previousDataFileName)
    
    if(max(outdf$EditDate)==max(previousData$EditDate)){
      print("Hospital beds data has not been changed.")
      file.remove(tmp)
      stop(1)
    }
  }
}


write.csv(
  x = outdf,
  file = args[4],
  na = '',
  row.names = F
)

write.csv(
  x = outdf,
  file = args[3],
  na = '',
  row.names = F
)
print("===========")
