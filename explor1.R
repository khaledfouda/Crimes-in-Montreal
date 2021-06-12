source('./helper.R')
# require(dplyr)
# require(lubridate)
# library(xts)
# library(tidyr)

data = read.csv('./data/ts_all_categories.csv')
# group by Year-Month
data %>%
  mutate(DATE=paste0(year(DATE),'-',sprintf("%02d",month(DATE)))) %>% 
  group_by(DATE) %>%
  summarise(count = sum(count)) -> data

data %>% head(2)

tso = ts.analysis$proto()
tso$init(data)
plot(tso$resid$residuals)
var(tso$resid$residuals)
tso$stl.out

par(mfrow=c(2,1))
pacf(tso$stl.out$remainder, main = "STL")
pacf(tso$resid$residuals, main=paste(tso$fit.arima))



arim


ss = arima(dts, c(2,0,0), list(order=c(2,1,0),period=c(12)))
require(TSA)
LB.test(tso$fit.arima)
checkresiduals(tso$fit.arima)
autoplot(forecast(tso$fit.arima,h=84))

