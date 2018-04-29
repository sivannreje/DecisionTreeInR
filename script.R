

getmode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

changeToNumeric<-function(data) {
  data$over_draft = as.numeric(as.character(data$over_draft))
  data$credit_usage = as.numeric(as.character(data$credit_usage))
  data$current_balance = as.numeric(as.character(data$current_balance))
  data$Average_Credit_Balance = as.numeric(as.character(data$Average_Credit_Balance))
  data$cc_age = as.numeric(as.character(data$cc_age))
  data$num_dependents = as.numeric(as.character(data$num_dependents))
  return (data)
}

getAllModes<-function(data) {
  #remove cells with 'NA' in every col
  badCreditHistory<-is.na(data$credit_history)
  badPurpose<-is.na(data$purpose)
  badPersonalStatus<-is.na(data$personal_status)
  badPropertyMagnitude<-is.na(data$property_magnitude)
  badHousing<-is.na(data$housing)
  badJob<-is.na(data$job)
  
  #create factors without NA for cols
  cleanCreditHistory<-data$credit_history[!badCreditHistory]
  cleanPurpose<-data$purpose[!badPurpose]
  cleanPersonalStatus<-data$personal_status[!badPersonalStatus]
  cleanPropertyMagnitude<-data$property_magnitude[!badPropertyMagnitude]
  cleanHousing<-data$housing[!badHousing]
  cleanJob<-data$job[!badJob]
  
  return (list(getmode(cleanCreditHistory), getmode(cleanPurpose), getmode(cleanPersonalStatus), getmode(cleanPropertyMagnitude), getmode(cleanHousing), getmode(cleanJob)))
}

dataPreparation<-function() {
  library(readxl)
  library(rstudioapi)
  setwd(dirname(rstudioapi::getSourceEditorContext()$path))
  #import excel as data frame splitted values by comma
  excelSpreadsheet <- read_excel("GermanCredit.xlsx", col_names = FALSE)
  data <- data.frame(do.call('rbind', strsplit(excelSpreadsheet$X__2, ",")), stringsAsFactors = FALSE)
  
  #replace columns to rows and rows to columns
  data<- as.data.frame(t(data), stringsAsFactors = FALSE)
  
  #insert the columns names
  colnames(data) <- c("over_draft","credit_usage","credit_history","purpose","current_balance","Average_Credit_Balance","personal_status","property_magnitude","cc_age","housing","job","num_dependents","class") 
  
  #insert 'NA' where blank
  data[data==""] <- NA
  
  #change data type to numeric
  data<-changeToNumeric(data)
  #get all means of all numeric columns
  allMeans<-colMeans(Filter(is.numeric, data), na.rm=TRUE)
  
  #get most frequent value for each none numeric columns
  allModes<- getAllModes(data)
  
  #get a list of all values to replace the 'NA' values
  toFill<-list(allMeans[1],allMeans[2], allModes[[1]][1],allModes[[2]][1], allMeans[3], allMeans[4], allModes[[3]][1], allModes[[4]][1], allMeans[5], allModes[[5]][1], allModes[[6]][1], allMeans[6])

    #replace all 'na' values
  indx<-which(is.na(data), arr.ind = TRUE)
  data[indx]<-toFill[indx[,2]]
  return (data)
}

data<-dataPreparation()