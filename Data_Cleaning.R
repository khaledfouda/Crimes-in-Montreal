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
                DATE = as.Date(DATE, "%Y-%m-%d"),
                QUART = mapply(quart.rep, QUART),
                STREET = NOM_TEMP, NOM_TEMP = NULL,
                MUNICIP = MUN_TEMP, MUN_TEMP = NULL) -> data
data$MONTH = month(data$DATE)
data$YEAR = year(data$DATE)
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

# The following function does the extraction of the full address given
# the coordinates.
get_addr = function(lat,long){
  pull=reverse_geo(lat = lat, long = long, method = 'osm', verbose = FALSE)
  addr = as.list(pull)$address
  return(addr)
}
# We now apply the function to all the coordinates.
# Note that would take several hours to run.
# addrss: A list of all the full addresses.
n = nrow(data)
addrss = rep("",n)
# I will lookup 10^4 locations per request.
lookup = FALSE
if(lookup ==TRUE){
  for(a in seq(1,n,10000)){
    b  = min(a+10000-1,n)
    addrss[a:b] = get_addr(data$LATITUDE.x[a:b],data$LONGITUDE.x[a:b])
    # After each lookup (of 10^4 locations), the list is saved to disk.
    print("writing to file") 
    write.csv(neighbs, './data/addresses.csv')
    print(b)
  }
}
#--------------------------------------------------------
# read the list in case it was previousely saved and do the cleaning mentioned above.
addrss = read.csv('./data/neighbs.csv')
# print  a sample
head(addrss$x,2)
# We notice that the neighbourhood belong to the 7 last items.
# The following function extracts the first three items from the last 7 items from the address
ext.nei = function(addr){
  ext = paste(unlist((strsplit(addr,',')[[1]] %>% tail(7))[1:3]),collapse = ',')
  return(ext)
}
# Now apply to the list
addrss$ext=mapply(ext.nei,addrss$x )
# Add the municiplity for comparison reasons.
addrss$munc = data$MUNICIP
# For most of the locations, the second item is the neighbourhood so 
# we set the neighbourhoods to it and later correct the wrong ones.
addrss$nei = mapply( function(d) strsplit(d,",")[[1]][2], addrss$ext)
table(addrss$nei)
# We notice two things:
# 1. Locations in "Dorval" are set to "Agglomeration de montreal"
# 2. All Motreal's (city not island) neighbourhoods are the first item of the list
# not the second.
addrss %>% filter(nei==" Montréal") %>% select(X) -> mtl.ids
addrss[unlist(mtl.ids),]$nei = mapply( function(d) strsplit(d,",")[[1]][1], 
                                    addrss[unlist(mtl.ids),]$ext)
# Similarly for Dorval
addrss %>% filter(nei==" Agglomération de Montréal") %>% select(X) -> drv.ids
addrss[unlist(drv.ids),]$nei = mapply( function(d) strsplit(d,",")[[1]][1], 
                                   addrss[unlist(drv.ids),]$ext)
table(addrss$nei)
# Add municiplity in place of NA values, to be corrected in exel.
addrss %>% mutate( nei = ifelse(nei=='NA',munc,nei) ) -> addrss
#---------
# All seems okay, a couple of further notes:
# 1. Some locations didn't have long/lat values and their address is set to NA
# I will fix them by guessing the neighborhoods using the street name and city values.
# 2. Some names in the list needs to be shortened so it's easier to visualize.
# I will fix that in a Excel file.
require(openxlsx)
write.xlsx(table(addrss$nei), './data/list_neighbourhoods.xlsx')
new.addrss = read.xlsx('./data/list_neighbourhoods_corrected.xlsx',
                       rowNames = FALSE,colNames = FALSE)
# Replace addresses in the dataframe addess
for(i in 1:nrow(new.addrss)){
  addrss %>% mutate( nei=replace(nei, nei==new.addrss[i,1], new.addrss[i,2])) -> addrss
}
table(addrss$nei) %>% as.data.frame() %>% arrange(desc(Freq))
#-----------------------------------------
# Some of those under the category "louis Riel" belong to either Anjou or Mercier
addrss %>% filter(nei=="Louis-Riel") %>% select(X) -> lr.ids
addrss[unlist(lr.ids),]$nei = mapply( 
  function(d) ifelse(d=="ANJ","Anjou","Mercier-Hochelaga-Maisonneuve"),
  addrss[unlist(lr.ids),]$munc)
round((table(addrss$nei)/sum(table(addrss$nei)))*100,2) %>%
  as.data.frame() %>% arrange(desc(Freq))
#----------------------
# 12.92% of the data has unknown location.
# Now we merge the data.
data$borough = addrss$nei
data$X = NULL
data$STREET = NULL
data$MUNICIP = NULL
#----------------------------------
# Save to disk or load from desk if it's been saved earlier
#write.csv(data, './data/Police_Interventions_cleaned.csv')
#data = read.csv('./data/Police_Interventions_cleaned.csv')
#--------------------------------
# save a time-series version of the data
# as well as time-series per category.
data %>% 
  arrange(DATE) %>% 
  group_by(DATE) %>% 
  summarise(count = n()) %>% 
  write.csv('./data/ts_all_categories.csv',row.names = FALSE)

for(cat in rownames(table(data$CATEGORIE))){
  file.name = paste0('./data/ts_',
                     paste0(strsplit(cat,' ')[[1]],collapse = '_'),
                     '.csv')
  data %>%
    filter(CATEGORIE==cat) %>%
    arrange(DATE) %>%
    group_by(DATE) %>%
    summarise(count = n()) %>%
    write.csv(file.name, row.names=FALSE)
}
#-------------------------------------------
