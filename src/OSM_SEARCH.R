
setwd("D:/CODE/projects/mtl/Crimes-in-Montreal/src")
#-------------------------------------
require(reticulate)
require(tidygeocoder)
require(lubridate)
require(tidyverse)
#========================================
input = read.csv('../data/output/Police_Interventions_cleaned.csv')
# The following function does the extraction of the full address given
# the coordinates.
get_addr = function(lat,long){
  pull=reverse_geo(lat = lat, long = long, method = 'osm', verbose = FALSE)
  addr = as.list(pull)$address
  return(addr)
}

out.query = data.frame(id=input$idnum, addrss=NA)
# subset the data so that we don't send NAs
input %>% filter(!is.na(LATITUDE)) -> input


# I will lookup 10^4 locations per request.
addrs.per.request = 1e4
maxn = nrow(input)

  cat("BEGIN --\n")
for(a in seq(1,maxn,addrs.per.request)){
  b  = min(a+addrs.per.request-1,maxn)
  
  out.query$addrss[input$idnum[a:b]] = 
     get_addr(input$LATITUDE[a:b],input$LONGITUDE[a:b])
  # After each lookup (of 10^4 locations), the list is saved to disk.
  cat("writing to file\n") 
  write.csv(out.query, 
            '../data/processing/OSM_ADDS.csv', row.names = F)
  cat('Finished ',b, '/', maxn, 'lookups.',maxn-b, 'are left.')
}
#--------------------------------------------------------