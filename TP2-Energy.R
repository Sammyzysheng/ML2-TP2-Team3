####################################################
####           Load required packages           ####
####################################################

installIfAbsentAndLoad <- function(neededVector) {
  for(thispackage in neededVector) {
    if( ! require(thispackage, character.only = T) )
    { install.packages(thispackage)}
    require(thispackage, character.only = T)
  }
}

needed <- c('tidyverse','repr','lubridate','gbm','ggplot2','xgboost','Ecdat','reshape2','ggcorrplot','car')  
installIfAbsentAndLoad(needed)

options(tibble.width = Inf)
options(warn=-1)
#Read the data
dpath <- "./"
train <- read.csv(paste(dpath, "train.csv", sep=""),row.names = NULL)
building<-read.csv('building_metadata.csv',row.names = NULL)
weather_train<-read.csv('weather_train.csv',row.names = NULL)
#Join train data
train<-train%>%
  left_join(building,by='building_id')%>%
  left_join(weather_train,by=c('site_id',"timestamp"))
rm(weather_train)
head(train)
train.summary=summary(train)
head(weather_train,300)
#Preprocess data
#Converting features
#workday or not
train$wday=wday(train$timestamp)
train$workday=ifelse(train$wday %in% c(1,2,3,4,5),1,0)
#month
train$month=month(train$timestamp)
#target
train$meter_reading=log1p(train$meter_reading)
#feature selection
names_selected=c("building_id","site_id","meter","primary_use","square_feet","air_temperature","cloud_coverage","wind_direction","wind_speed", "month","workday","meter_reading")
train.new=train[names_selected]
#convert categorical variable to numeric
train.new$primary_use=as.integer(as.factor(train.new$primary_use))
head(train.new.site1)
train.new$air_temperature[is.na(train.new$air_temperature)] <- mean(train.new$air_temperature, na.rm = TRUE)
train.new$cloud_coverage[is.na(train.new$cloud_coverage)] <- mean(train.new$cloud_coverage, na.rm = TRUE)
train.new$wind_direction[is.na(train.new$wind_direction)] <- mean(train.new$wind_direction, na.rm = TRUE)
train.new$wind_speed[is.na(train.new$wind_speed)] <- mean(train.new$wind_speed, na.rm = TRUE)

# correlations

ggcorrplot(cor(train.new), type = "lower", lab = TRUE, hc.order = TRUE,
           title = "Correlation Matrix for All Features")

# Potentially significant correlations: 
# square feet correlated with meter reading at 0.37
# wind direction with wind speed at 0.42
# wind speed with cloud coverage at 0.18
# unsurprisingly, building ID and site ID are highly correlated because they are linked
# site and building ID are each somewhat correlated with temperature and cloud coverage (due to location)


# evaluate multicollinearity between predictors
train.new.site1=train.new[train.new$site_id==1,]

simple.regression <- lm(meter_reading~.-site_id, data = train.new.site1)

vif(simple.regression) # remove meter_reading before checking for VIF

# unsurpisingly, the VIF of building and site ID are both extremely high given
# how we know they are completely linked and 98% correlated with one another.
# the rest of the predictors appear to be okay, with VIFs at ~1 even when building and site ID
# are removed from the model.

#traing
train.new.site1=train.new[train.new$site_id==1,]
n=nrow(train.new.site1)
train.index=sample(seq(1,n),n*0.8,replace = F)
xgb.data.train <- xgb.DMatrix(as.matrix(train.new.site1[train.index, colnames(train.new.site1) != 'meter_reading']), label = train.new.site1$meter_reading[train.index])
xgb.data.test <- xgb.DMatrix(as.matrix(train.new.site1[-train.index, colnames(train.new) != "meter_readings"]), label = train.new.site1$meter_reading[-train.index])
#select model training round
params <- list(booster = "gbtree",nthread = 4, objective = "reg:squarederror",
               eta=0.05, gamma=0, max_depth=10, min_child_weight=1, subsample=1, colsample_bytree=0.85  )

xgbcv <- xgb.cv( params = params, data = xgb.data.train , nrounds = 1000, nfold = 5, showsd = T, stratified = T, print.every.n = 10, early.stop.round = 100, maximize = F)
#best iteration

xgbcv$evaluation_log[xgbcv$best_iteration]


# = parameters = #
# = eta candidates = #
eta=c(0.05,0.1,0.5)
# = max_depth candidates = #
md=c(6,10,12)
# = sub_sample candidates = #
ss=c(0.25,0.5,0.75,1)
#eta
test_rmse=c()
for(i in 1:length(eta)){
  params=list(booster = "gbtree",nthread = 4, objective = "reg:squarederror",
              eta = eta[i], gamma=0, max_depth=10, min_child_weight=1, 
              subsample=1, colsample_bytree=0.85)
  xgbcv <- xgb.cv( params = params, data = xgb.data.train , nrounds = 1000, nfold = 2, showsd = T, stratified = T, print.every.n = 10, maximize = F)
  test_rmse[i] = xgbcv$evaluation_log[,4]
  
}
test_rmse = data.frame(iter=1:10,test_rmse)
colnames(test_rmse) =  c('iter',eta)

test_rmse = melt(test_rmse, id.vars = "iter")
ggplot(data = test_rmse) + geom_line(aes(x = iter, y = value, color = variable))

#Max depth
test_rmse=c()
for(i in 1:length(md)){
  params=list(booster = "gbtree",nthread = 4, objective = "reg:squarederror",
              eta = 0.5, gamma=0, max_depth=md[i], min_child_weight=1, 
              subsample=1, colsample_bytree=0.85)
  xgbcv <- xgb.cv( params = params, data = xgb.data.train , nrounds = 10, nfold = 2, print.every.n = 10, maximize = F)
  test_rmse[i] = xgbcv$evaluation_log[,4]
  
}
test_rmse = data.frame(iter=1:500,test_rmse)
colnames(test_rmse) =  c('iter',md)

test_rmse = melt(test_rmse, id.vars = "iter")
ggplot(data = test_rmse) + geom_line(aes(x = iter, y = value, color = variable))
#Subsample candidates
test_rmse=c()
for(i in 1:length(ss)){
  params=list(booster = "gbtree",nthread = 4, objective = "reg:squarederror",
              eta = 0.5 , gamma=0, max_depth=6, min_child_weight=1, 
              subsample=ss[i], colsample_bytree=0.85)
  xgbcv <- xgb.cv( params = params, data = xgb.data.train , nrounds = 1000, nfold = 2, showsd = T, stratified = T, print.every.n = 10, maximize = F)
  test_rmse[i] = xgbcv$evaluation_log[,4]
  
}
test_rmse = data.frame(iter=1:500,test_rmse)
colnames(test_rmse) =  c('iter',ss)

test_rmse = melt(test_rmse, id.vars = "iter")
ggplot(data = test_rmse) + geom_line(aes(x = iter, y = value, color = variable))

#Fit best model

params=list(booster = "gbtree",nthread = 4, objective = "reg:squarederror",
            eta = 0.5 , gamma=0, max_depth=6, min_child_weight=1, 
            subsample=1, colsample_bytree=0.85)
xgb1 <- xgb.train (params = params, data = xgb.data.train, nrounds = 500, watchlist = list(val=xgb.data.test,train=xgb.data.train), print.every.n = 10, 
                   early.stop.round = 10, maximize = F , eval_metric = "rmse")

#Outcome evaluation: Feature importance

mat <- xgb1.importance (feature_names = colnames(train.new.site1),model = xgb1)
xgb.plot.importance (importance_matrix = mat) 
