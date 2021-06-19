require(dplyr)
require(lubridate)
library(xts)
library(tidyr)

data = read.csv('../data/output/ts_all_categories.csv')
# group by Year-Month
data %>%
  mutate(YYM=paste0(year(DATE),'-',sprintf("%02d",month(DATE)))) %>% 
  arrange(year(DATE),month(DATE)) %>%
  group_by(YYM) %>%
  summarise(count = sum(count)) -> data
# Define time series
dts = ts(data$count, start = c(2015,1), end=c(2021,5),frequency = 12)
plot(dts)
# Take a subset
dts.subs = window(dts, start=c(2015,1), end=c(2018,12))
plot(dts.subs)
#------------------
# Seasonal Decomposition (stl) <trend, seasonality, irregular components>
fit = stl(dts, s.window = "period")
x11()
plot(fit)
# Additional plots
x11()
par(mfrow=c(2,1))
monthplot(dts)
library(forecast)
seasonplot(dts)
#-----------------------
# Using stl() I will test for differeces between years.
fit$time.series %>% 
  as.data.frame %>%
  select(remainder) -> ts.resid
ts.resid$YEAR = unlist(strsplit(data$YYM,'-'))[seq(1,76*2,2)] 
ts.resid[1:5,]
ts.resid %>%
  group_by(YEAR) %>%
  mutate(i1 = row_number()) %>%
  spread(YEAR,remainder) %>% 
  select(-i1) %>% 
  as.data.frame -> ts.resid.spread
#--------------
#plot densities
require(ggplot2)
require(ggpubr)
ts.resid %>%
  ggplot(aes(x=remainder)) +
  geom_density() +
  facet_wrap(~YEAR) 

ggqqplot(ts.resid, 'remainder',facet.by = 'YEAR')  
# Normlality test:

ts.resid %>% 
  group_by(YEAR) %>%
  summarise(`p-value` = round(shapiro.test(remainder)$p.value,3),
            `Normal?` = `p-value`>.05,
            Mean = round(mean(remainder),3),
            CV = round(sd(remainder)/Mean,3)) %>%
  as.data.frame

require(rstatix)

ts.resid %>%
  filter(YEAR!=2015&YEAR!=2021) %>%
t_test(remainder~YEAR,paired = TRUE, detailed = TRUE) %>%
  as.data.frame() %>%
  select(estimate, group1, group2, df, p) %>%
  add_significance() 
#----------------------------------

#-----------------------
# Using xts
data.d = read.csv('./data/ts_all_categories.csv')
dts.x = xts(data.d$count, order.by = as.Date(data.d$DATE))
plot(dts.x)
dts.x.month <- apply.monthly(dts.x, mean)
plot(dts.x.month, ylim = range(dts.x))
#---------------------------------
# Exponential Model
#>>
# simple - models level
fit = HoltWinters(dts, beta=FALSE, gamma=FALSE)
plot(fit)
# double Exp: models and trend
fit = HoltWinters(dts, gamma=FALSE)
plot(fit)
# triple exp: models, trend, seasonal
fit = HoltWinters(dts.subs)
plot(fit)
# predict next three future values
pred = as.data.frame(forecast(fit, 28))
pred$Actual = c(tail(dts,28))
plot(forecast(fit, 3))
plot(seq(1:28), pred$`Point Forecast`,type = 'l',col="blue",ylim = c(1344,2686))
points(seq(1:28), pred$Actual,type = 'l',col="red")
abline(v=12)
abline(v=24)
#------------------------------
#Automated Forecasting:
## forecast automatically selects exponenttial and arima model.
#he ets() function supports both additive and multiplicative models.
#The auto.arima() function can handle both seasonal and nonseasonal ARIMA models.
#Models are chosen to maximize one of several fit criteria
#-------------------------
# Automated forecasting using an exponential model
fit <- ets(dts);fit
plot(fit)
# Automated forecasting using an ARIMA model
fit <- auto.arima(dts);fit
plot(fit)
plot(forecast(fit,h=20))
#---------------------------------
# Next to check 
#https://a-little-book-of-r-for-time-series.readthedocs.io/en/latest/src/timeseries.html

d = resid(fit)
resid(fit) %>% as.data.frame