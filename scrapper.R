data = read.csv('./data/Police_Interventions1.csv')
#-------------------------------------
require(reticulate)
require(tidygeocoder)
require(lubridate)
require(dplyr)




get_neighb = function(la,lo){
  o=reverse_geo(lat = la, long = lo, method = 'osm',
                verbose = FALSE)
  out = as.list(o)$address
  return(out)
}


neighbs = rep("",nrow(data))
maxr = nrow(data)
for(a in seq(1,maxr,10000)){
 b  = min(a+10000-1,maxr)
 neighbs[a:b] = get_neighb(data$LATITUDE.x[a:b],data$LONGITUDE.x[a:b])
print("writing to file") 
write.csv(neighbs, './data/neighbs.csv')
 print(b)
}