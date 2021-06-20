
require(dplyr)
require(lubridate)
library(xts)
library(tidyr)
library(forecast)

data = read.csv('../data/output/ts_Fatal_Crime.csv')

data = read.csv('../data/output/ts_Armed_Robbery.csv')
# group by Year-Month
data %>%
  mutate(YYM=paste0(year(DATE),'-',sprintf("%02d",month(DATE)))) %>% 
  arrange(year(DATE),month(DATE)) %>%
  group_by(YYM) %>%
  summarise(count = sum(count)) -> data
# Define time series
dts = ts(data$count, start = c(2015,1), end=c(2021,5),frequency = 12)




fit = stl(dts, s.window = "period");fit$weights
plot(fit)

monthplot(dts)
seasonplot(dts)
fit <- auto.arima(dts);fit
plot(fit)
plot(forecast(fit,h=20))