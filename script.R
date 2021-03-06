#get the most frequent level
getmode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

#change the numeric columns to be as numeric
changeToNumeric<-function(data) {
  data$over_draft = as.numeric(as.character(data$over_draft))
  data$credit_usage = as.numeric(as.character(data$credit_usage))
  data$current_balance = as.numeric(as.character(data$current_balance))
  data$Average_Credit_Balance = as.numeric(as.character(data$Average_Credit_Balance))
  data$cc_age = as.numeric(as.character(data$cc_age))
  data$num_dependents = as.numeric(as.character(data$num_dependents))
  return (data)
}

#return list with all average/mode values to fill into 'NA'
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

#manually discretize age with the categories: 'young', 'adult' and 'old' as factors
discretizeAge<-function(data) {
  i=0
  for(x in data$cc_age){
    i=i+1
    if(x<=30){
      data[i,"cc_age"]="young"
    } else if(x>30 & x<=45){
      data[i,"cc_age"]="adult"
    } else{
      data[i,"cc_age"]="old"
    }
  }
  data$cc_age<-as.factor(data$cc_age)
  
  return (data)
}

#Equal-Width discretization for numeric columns
discretizeNumeric <- function(cutLabels, bin, dataColumn) {
  minimumVal<-min(dataColumn)
  maximumVal<-max(dataColumn)
  width<- floor((maximumVal - minimumVal)/bin)
  dataColumnRes <- cut(dataColumn, 
                         breaks = seq(minimumVal, maximumVal, width), 
                         labels = cutLabels, 
                         right = TRUE)
  return (as.factor(dataColumnRes))
}

#main function for the data preparation
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
  toFillMeans<-c(allMeans[[1]][1],allMeans[[2]][1],allMeans[[3]][1], allMeans[[4]][1], allMeans[[5]][1], allMeans[[6]][1], allModes[[1]][1],allModes[[2]][1], allModes[[3]][1], allModes[[4]][1],allModes[[5]][1], allModes[[6]][1])
  
  #replace all 'na' values
  indx<-which(is.na(data), arr.ind = TRUE)
  data[indx]<-toFillMeans[indx[,2]]

  #return relevant columns to numeric - move to func
  overD<-data$over_draft
  creditUsage<-data$credit_usage
  currBalance<-data$current_balance
  avgCredit<-data$Average_Credit_Balance
  age<-data$cc_age
  numDep<-data$num_dependents
  aveCredBalance<-data$Average_Credit_Balance
  
  unlist(overD, recursive = TRUE, use.names = TRUE)
  unlist(creditUsage, recursive = TRUE, use.names = TRUE)
  unlist(currBalance, recursive = TRUE, use.names = TRUE)
  unlist(avgCredit, recursive = TRUE, use.names = TRUE)
  unlist(age, recursive = TRUE, use.names = TRUE)
  unlist(numDep, recursive = TRUE, use.names = TRUE)
  unlist(aveCredBalance, recursive = TRUE, use.names = TRUE)
  
  #discretization for age
  data<-discretizeAge(data)
  
  #discretozation for Over draft
  cutLabelsForOverDraft <-c("low", "medium", "high")
  data$over_draft <- discretizeNumeric(cutLabelsForOverDraft, 3, as.numeric(data$over_draft))
  
  #discretozation for average credit balance
  cutLabelsForAveCredBalance <-c("very low", "low", "medium", "high")
  data$Average_Credit_Balance <- discretizeNumeric(cutLabelsForAveCredBalance, 4, as.numeric(data$Average_Credit_Balance))
  
  
  return (data)
}

data<-dataPreparation()


#load rpart library
if(!require(rpart)){
  install.packages("rpart")
}
library(rpart)

#install.packages("rpart.plot")
library(rpart.plot)

#split to train and test sets
trainingSetindx <- sample(1:nrow(data), floor(0.8*nrow(data)))
testSetindx <- setdiff(1:nrow(data), trainingSetindx)

trainingSet <- data[trainingSetindx,]
testSet <- data[testSetindx,]
#trainingSet$over_draft<-as.character(trainingSet$over_draft)
#trainingSet$Average_Credit_Balance<-as.character(trainingSet$Average_Credit_Balance)
#trainingSet$cc_age<-as.character(trainingSet$cc_age)

print(class(trainingSet$over_draft))
print(class(trainingSet$Average_Credit_Balance))
print(class(trainingSet$cc_age))
#############################################################################################################################

#cunstruction of the decision tree

############################################################################################################################


fit <- rpart(class ~cc_age+  Average_Credit_Balance + purpose,
             data = trainingSet, 
             method = "class", 
             control = rpart.control(minsplit = 20, minbucket=1, cp=0.001))
printcp(fit)
#summary(fit)