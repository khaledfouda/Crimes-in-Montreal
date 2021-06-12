library(proto)

ts.analysis <- proto(
  expr = {
    data = NA # A data of two columns named "DATE" and "count"
    period = 12
    start = c(2015,1)
    end = c(2021,4) 
    dts =  NA # ts(data,start,end,period)
    fit.stl = NA # fit object
    fit.arima = NA
    stl.out = NA # trends seasonal residuals
    resid = NA # residuals from arima model.
    # Methods:
    plot.stl = NA # a simple plot(fit) in x11() window
    plot.monthly = NA # monthplot(dts) and forecast::seasonplot(dts)
    plot.arima = NA # plot(forecast(fit,h=2-))
    plot.rqqp = NA # Normal QQ plot of residuals.
    norm.test = NA # Returns a table of <period, p-value, Normal?>
    paired.t = NA # Returns a table of <group1, group2, p-value> Applied only to
    # groups that passed the normality test.
    init = NA #call it first with the data to run the models. 
  }
)

ts.analysis$init <- function(., ts.data){
  require(dplyr)
  require(lubridate)
  require(tidyr)
  require(forecast)
  require(ggplot2)
  require(ggpubr)
  require(rstatix)
  
  if(all(colnames(ts.data)!= c('DATE','count'))){
    print("Wrong column names. Expected (DATE,count)")
    return()
  }
  .$data = ts.data
  .$dts = ts(.$data$count, start =.$start, end=.$end,frequency = .$period)
  .$fit.stl = stl(.$dts, s.window = "period")
  .$fit.arima = auto.arima(.$dts)
  .$resid = data.frame( 'residuals'=.$fit.arima$residuals[1:nrow(.$data)],
                        'DATE' = .$data$DATE)
  .$stl.out = .$fit.stl$time.series %>% as.data.frame
}

ts.analysis$plot.stl = function(.){
  #x11()
  plot(.$fit.stl)
}
ts.analysis$plot.monthly = function(.){
  #x11()
  par(mfrow=c(2,1))
  monthplot(.$dts)
  seasonplot(.$dts)
}
ts.analysis$plot.arima = function(.){
  plot(forecast(.$fit.arima,h=20))
}
ts.analysis$norm.test = function(.){
  return(3)
}

