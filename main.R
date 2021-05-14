#require(readxl)
require(lubridate)
require(dplyr)
# The two datasets are downloaded from https://donnees.montreal.ca/ville-de-montreal/actes-criminels
# and https://donnees.montreal.ca/ville-de-montreal/carte-postes-quartier respectively
interv = read.csv('./data/interventionscitoyendo.csv')
pdq = read.csv('./data/pdq.csv')

#---------------
# 1- Join the two dataframes by pdq ID
#---------------------
# convert "POSTE DE QUARTIER ID" to only the ID
pdq$PDQ = mapply( function(d) strsplit(d,'POSTE DE QUARTIER ')[[1]][2],pdq$DESC_LIEU)
# Join the two dataframe based on the PDQ number
data = merge(interv, pdq, by='PDQ', all.x = TRUE)
names(data)
#--------------------------
# 2 - keep releveant variables, rename variables and expand the date,
# and translate some features from french to English
#---------------------------
# Keep only relevant columns
data %>% select( CATEGORIE, DATE, QUART, NOM_TEMP, MUN_TEMP,
                 LONGITUDE.x, LATITUDE.x) -> data
# Translate Categories and day time
catg.fr = table(data$CATEGORIE) %>% names
catg.en = c("Resulting Death", "Break and Enter", "Mischief", "Auto Burglary",
            "Auto theft", "Armed Robbery")
catg.rep = function(c) catg.en[which(catg.fr==c)]
quart.fr = table(data$QUART) %>% names
quart.en = c('Day', 'Night', 'Evening')
quart.rep = function(c) quart.en[which(quart.fr==c)]
# Apply changes and extract the Year and month
data %>% mutate(CATEGORIE = mapply(catg.rep,CATEGORIE),
                MONTH = month(as.Date(DATE, "%Y-%m-%d")),
                YEAR = year(as.Date(DATE, "%Y-%m-%d")),
                QUART = mapply(quart.rep, QUART),
                STREET = NOM_TEMP, NOM_TEMP = NULL,
                MUNICIP = MUN_TEMP, MUN_TEMP = NULL) -> data
#-------------------------------------------------------------------
# 3 - Discard obsevations of the current month (May 2021) 
#since the data won't be complete.
#-------------------------------------
data %>% filter( !(YEAR ==2021 & MONTH==5 )) -> data
#-----------------------------------------------------------------------
# Save to disk or load from desk if it's been saved earlier
#write.csv(data, './data/Police_Interventions_cleaned.csv')
#data = read.csv('./data/Police_Interventions_cleaned.csv')
#------------------------------------------
# 4- Extract neighbourhoods.
# I will use OSM to lookup the long/lat coordinates, get the equivalent full address,
# and extract the neighbourhoods.
# After Neighbourhoods are extracted, further cleaning is required because:
# 1. Some have unnecessarily long names.
# 2. Some names are wrongfully extracted and needs to be corrected.
#-----------------------------------------------
require(reticulate)
require(tidygeocoder)

#reverse_geo(lasasadat = data$LATITUDE.x[5], long = data$LONGITUDE.x[5],
#            method = 'osm', verbose = TRUE)

strsplit(as.list(o)$address[1],',')
usethis::edit_r_environ()


get_neighb = function(la,lo){
  #print(d)o
  oo=reverse_geo(lat = la, long = lo, method = 'here',
              verbose = FALSE)
  out = as.list(o)$address
  #out = mapply(function(d)tail(unlist(strsplit(d,',')),3)[1],as.list(o)$address)
return(out)
}

mapply(get_neighb, data[1:5,] %>% select(LONGITUDE.x,LATITUDE.x)%>% c)

#get_neighb(data[82780,] %>% select(LONGITUDE.x,LATITUDE.x))


maxr = nrow(data%>% filter(LONGITUDE.x!=1))
for(a in seq(1,maxr,10000)){
  b  = min(a+10000,maxr)
(data%>% filter(LONGITUDE.x!=1))[a:b,] %>%
    mutate(neighbourhood=get_neighb(LATITUDE.x,LONGITUDE.x)) -> 
    (data%>% filter(LONGITUDE.x!=1))[a:b,]
}

for(i in 1:nrow(data)){
  if(data$LATITUDE.x[i]!=1){
    data$NEIGH[i] = get_neighb(data$LATITUDE.x[i],data$LONGITUDE.x[i])
  }
  else{
    data$NEIGH[i] = "UNKNOWN"
  }
  if(i%%1000==0){cat(i, ' ')}
}


data[1:1000,] %>%
  mutate(neighbourhood=get_neighb(LATITUDE.x,LONGITUDE.x))


system.time((d<-get_neighb(data$LATITUDE.x[1:10],data$LONGITUDE.x[1:10])))
system.time(for(i in 1:100)d=get_neighb(data$LATITUDE.x[i],data$LONGITUDE.x[i]))
(print("2"))

la = data$LATITUDE.x[140000:140050]; lo=data$LONGITUDE.x[140000:140050]
data$LATITUDE.x[1:100]

neighbs = rep("",nrow(data))
#data$neighbourhood = ""
maxr = nrow(data)
for(a in seq(140000,maxr,10000)){
  b  = min(a+10000-1,maxr)
  data$neighbourhood[a:b] = get_neighb(data$LATITUDE.x[a:b],data$LONGITUDE.x[a:b])
  print(b)
}
 b
 

neighbs2 = rep("",nrow(data))
maxr = nrow(data)
for(a in seq(140000,maxr,10000)){
 b  = min(a+10000-1,maxr)
 neighbs[a:b] = get_neighb(data$LATITUDE.x[a:b],data$LONGITUDE.x[a:b])
 print(b)
}






neighbsBU = neighbs

nei.df = data.frame(nei1 = neighbsBU[140000:maxr],
                    nei2 = neighbs[140000:maxr],
                    mun = data$MUNICIP[140000:maxr])









get_neighb = function(la,lo){
  #print(d)o
  ooo=reverse_geo(lat = la, long = lo, method = 'osm',
                verbose = FALSE)
  out = as.list(ooo)$address
  #out = mapply(function(d)tail(unlist(strsplit(d,',')),3)[1],as.list(o)$address)
  return(out)
}


address_components <- tribble(
  ~street, ~cty, ~st, ~ptlcode,
  "4036 Avenue du Parc-La Fontaine", "Montréal", "QC"," H2L 3M7"
)
write(neighbs,'./data/neighbss.csv')

#--------------------------------------------------------
nei = read.csv('data/neighbs.csv')
#head(nei$x)
mf = function(d)
  paste(unlist((strsplit(d,',')[[1]] %>% tail(7))[1:3]),collapse = ',')
nei$e=mapply( mf,nei$x )
nei$mun = data$MUNICIP

nei$nei = mapply( function(d) strsplit(d,",")[[1]][2], nei$e)
nei %>% filter(nei==" Montréal") %>% select(X) -> mtlids
nei[unlist(mtlids),]$nei = mapply( function(d) strsplit(d,",")[[1]][1], 
                                    nei[unlist(mtlids),]$e)

#table(nei$nei)


nei %>% filter(nei==" Agglomération de Montréal") %>% select(X) -> drv.ids
nei[unlist(drv.ids),]$nei = mapply( function(d) strsplit(d,",")[[1]][1], 
                                   nei[unlist(drv.ids),]$e)
table(nei$nei)
