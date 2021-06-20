require(lubridate)
require(tidyverse)
require(openxlsx)
"
June 2021

Police Interventions from April 1, 2015 to May 30, 2021 to be cleaned in this file.

Input files in the following directories are expected:

 ./data/input/interventionscitoyendo.csv 
   as downloaded from : 
      https://donnees.montreal.ca/ville-de-montreal/actes-criminels
      
      This is the main data file containing the interventions.
      
  ./data/input/pdq.csv
    as downloaded from :
      https://donnees.montreal.ca/ville-de-montreal/carte-postes-quartier
      
      This file contains extra informations on PDQ: Poste De Quartier:

  ./data/input/PDQ_BOR.xlsx
    A hand prepared excel file containing the corresponding police divisions 
      (joint neighbourhoods) for each PDQ id number.
    Credits goes to https://spvm.qc.ca


"
#-------------------------------------------------------------------
#-------- 1. Read data ----------------#
interv = read.csv('../data/input/interventionscitoyendo.csv')
pdq = read.csv('../data/input/pdq.csv')
spvm.pdq = read.xlsx('../data/input/PQD_BOR.xlsx',1,rowNames = F)
#-------------------------------------------------------------------
#-------- 2. Joining the first two datasets into one. --------#
#  The primary key in the three of them is the PDQ ID
# A string manipulation is required in one of them to extract the ID
pdq %>%
  mutate(PDQ = mapply( function(d)
    strsplit(d,'POSTE DE QUARTIER ')[[1]][2],DESC_LIEU),
         LONGITUDE = NULL, LATITUDE = NULL) %>%
  mutate(PDQ = as.numeric(PDQ)) -> pdq

data = left_join(interv, pdq, c('PDQ'))
#-------------------------------------------------------------------
#------- 3. Exploring & treating missing values. -------- #
# Whenever longitude or latitude are set to 1, they are missing 
data %>% 
  mutate(LONGITUDE = replace(LONGITUDE, LONGITUDE==1, NA),
         LATITUDE = replace(LATITUDE, LATITUDE==1, NA),
         CATEGORY = CATEGORIE,
         CATEGORIE = NULL) -> data
#--------------------
# analyzing NAs
print('Distribution of missing values')
colSums(is.na(data)) # shows #NA by column
print('Rows with missing pdq id')
data %>% 
  filter(is.na(PDQ))
' We Notice that we have 5 PDQ missing and 33125 coordiantions missing.
We will drop the 5 rows for now. As for the coordinations, we will later
use the pdq division (the third dataset) to estimate these missing values.
'
data %>% filter(!is.na(PDQ)) -> data
' Next we see how the missing coordinations are distributed
'
print("Missing Coordinations' distribution")
data %>% 
  filter(is.na(LONGITUDE)|is.na(LATITUDE))  %>% 
  select(CATEGORY) %>% 
  table() 
' Next we want to see how many of these missing coordinations have pdqs
That are not in the spvm$pdq dataset.
'
print("Missing Coordinations pdq distribution. -1: found in spvm.pdq")
data %>% 
  filter(is.na(LONGITUDE)|is.na(LATITUDE))  %>% 
  select(PDQ)  %>% 
  mutate(PDQ = ifelse(! PDQ %in% spvm.pdq$PDQ, PDQ, -1)) %>% 
  table()
' Result: We have only two unknown PDQs: 11 and 24.
 From searching spvm.qc.ca we found that they have equivalent PDQs.
 
'
data$PDQ[data$PDQ==24] = 26
data$PDQ[data$PDQ==11] = 9
#-------------------------------------------------------------------
#-------- 4. Merge the third dataset now that we matched the key column
data = left_join(data, spvm.pdq, c('PDQ')) #left_join doesn't sort the data
#-------------------------------------------------------------------
# --------- 5. Drop some of the unrelevant columns. -------
names(data)
data %>% 
  select(CATEGORY, DATE, QUART, PDQ,
         DIVISION, LONGITUDE, LATITUDE) -> data
#-------------------------------------------------------------------
#----------- 6. Translate some of the values from French to English
catg.fr = table(data$CATEGORY) %>% names
catg.en = c("Fatal Crime", "Break and Enter", "Mischief", "Auto Burglary",
            "Auto theft", "Armed Robbery")
catg.rep = function(c) catg.en[which(catg.fr==c)]
quart.fr = table(data$QUART) %>% names
quart.en = c('Day', 'Night', 'Evening')
quart.rep = function(c) quart.en[which(quart.fr==c)]
# Apply changes and extract the Year and month
data %>% mutate(CATEGORY = mapply(catg.rep,CATEGORY),
                DATE = as.Date(DATE, "%Y-%m-%d"),
                QUART = mapply(quart.rep, QUART)) -> data
#-------------------------------------------------------------------
# --------- 7. Drop Some of the not-needed-anymore variables from the env.
rm(pdq, interv, spvm.pdq, catg.en, catg.fr, quart.en, quart.fr,
  catg.rep, quart.rep)
#   -------- 8. Add two new columns for Month and Year
data$MONTH = month(data$DATE)
data$YEAR = year(data$DATE)
#-------------------------------------------------------------------
# -------- 8. Discard obsevations of the current month (June 2021) 
data %>% filter( !(YEAR ==2021 & MONTH==6 )) -> data
data$idnum = as.numeric(rownames(data))
#-----------------------------------------------------------------------
#------ 9. Save to disk or load from desk if it's been saved earlier
write.csv(data, '../data/output/Police_Interventions_cleaned.csv',row.names = F)
#data = read.csv('../data/output/Police_Interventions_cleaned.csv')
#---------------------------------------------------------------------
#---- 10. Converting coordinates into neighborhoods names.
"
 I will use Open-Street-Map to lookup thecoordinates and returns full addresses,
 We will later attempt to extract the neighbourhoods from the addresses.
 The last step would take some effort and might results in some misclassifications.
 
 The former step is easy to implement but would rather take a big amount of time to run.
 Nevertheless, I am thankful for free avaiablability of OSM.
 A side code file will be used to do that. It will save the following file:
    ./data/proccessing/OSM_ADDS.csv
    
  containing two columns. The addresses and the inquiry id associated with it.
  Below, assuming that the file was excuted, we will make use of that file.
  --------------------------------------------------------------------------
  The following files are expected : 
    data/processing/OSM_ADDS.csv
    data/processing/list_neighbourhoods_corrected.xlsx
    data/processing/NA_divisions_corrected.xlsx
"

# 4- Extract neighbourhoods.
#-----------------------------------------------
#--------------------------------------------------------
# read the list in case it was previousely saved and do the cleaning mentioned above.
addrss = read.csv('../data/processing/OSM_ADDS.csv')

# print  a sample
head(addrss$x,2)
# We notice that the neighbourhood belong to the 7 last items.
# The following function extracts the first three items from the last 7 items from the address
ext.nei = function(addr){
  ext = paste(unlist((strsplit(addr,',')[[1]] %>% tail(7))[1:3]),collapse = ',')
  return(ext)
}

data %>% filter(is.na(LATITUDE)) %>% pull(DIVISION) %>% table

#------------ begin of part ------------------------------------------------
# In the following part we extract the neighbourhood names from the addresses
# Except for the one neighbourhood that doesn't include Agglomeration
# and the 32765 (17.28%) Unknown coordinates.
addrss %>%  
  filter(str_detect(addrss, 'Agglomération') ) %>%
  pull(addrss)  -> ads

addrss %>%  
  filter(str_detect(addrss, 'Agglomération') ) %>%
  pull(id) -> ids
  

ads.new = mapply(ext.nei, ads)
#ads.new %>% view

tibble(labels=ads, idnum=ids) %>%
  separate(labels, c('a','b','c','d','e','f','g','h'), ', ',) -> ads.sep

skip.mtl = function(a,b) return(ifelse(b=='Montréal',a,b))

nei.choice = function(a,b,c,d,e,f,g,h){
  if(b== 'Agglomération de Montréal') return(a)
  else if(c=='Agglomération de Montréal') return(skip.mtl(a,b))
  else if(d=='Agglomération de Montréal') return(skip.mtl(b,c))
  else if(e=='Agglomération de Montréal') return(skip.mtl(c,d))
  else if(f=='Agglomération de Montréal') return(skip.mtl(d,e))
  else if(g=='Agglomération de Montréal') return(skip.mtl(e,f))
  else if(h=='Agglomération de Montréal') return(skip.mtl(f,g))
  else return('UNDEFINED')
}
ads.sep %>%
  rowwise() %>% 
  mutate(neig = nei.choice(a,b,c,d,e,f,g,h)) -> ads.sep

ads.sep %>%
  select(idnum, neig) %>%
  mutate(idnum = as.numeric(idnum)) -> ads.sep

#View(ads.sep)
table(ads.sep$neig)
length(table(ads.sep$neig))


data = left_join(data,ads.sep , c('idnum'))
#View(data[,c(5,11)])

#----------------------end of that part-------------------
#--------------DEAL WITH NA ADDRESSES ---------------
data %>% filter(is.na(neig)) %>% pull(DIVISION) %>% table
data %>% pull(neig) %>%  table %>% rownames
require(openxlsx)
# Write the two tables in xlsx and manually fixing them
# uncomment the following 4 lines if new changes are made
#write.xlsx(table(data$nei), '../data/processing/list_neighbourhoodsNEW.xlsx')
#data %>% filter(is.na(neig)) %>% pull(DIVISION) %>%
#  table %>%
#  write.xlsx('../data/processing/NA_divisionsNEW.xlsx')
# They are now fixed!. We read them and replace the new columns.
corr.nei = read.xlsx('../data/processing/list_neighbourhoods_corrected.xlsx',
                       rowNames = FALSE,colNames = TRUE)
corr.na = read.xlsx('../data/processing/NA_divisions_corrected.xlsx',
                    rowNames = FALSE,colNames = TRUE)

for(i in 1:nrow(corr.nei)){
  data %>% mutate( neig=replace(neig, neig==corr.nei[i,1], corr.nei[i,2])) -> data
}
for(i in 1:nrow(corr.na)){
  data %>%
    mutate( neig=replace(neig,
          (is.na(neig) & DIVISION==corr.na[i,1]), corr.na[i,2])) -> data
}
#----------------DONNNNNNNEEEEE lets print some results and save after
table(data$neig) %>% 
  as.data.frame() %>% 
  arrange(desc(Freq))
data %>% 
  filter(is.na(neig)) %>% 
  pull(DIVISION) %>% 
  table %>% 
  as.data.frame() %>%
  arrange(desc(Freq))

nas = data %>%
  filter(is.na(neig)) %>% 
  nrow
cat("Number of NAs = ",nas," and counts for ",round(nas/nrow(data),2),"%")
data %>% select(DIVISION) %>% table %>% length
data %>% select(neig) %>% table %>% length

rm(ads.sep, corr.na, corr.nei, ads, ads.new, i, ids, nas, ext.nei, nei.choice,
   skip.mtl, addrss)
#---------------END OF NA-------------------------------------
# keep relevant columns and save!. ##
data %>%
  mutate(ARRONDIS = neig) %>%
  select(CATEGORY, DATE, ARRONDIS, QUART, DIVISION, PDQ,
         LONGITUDE, LATITUDE) -> data
#--------------------------------
# EDIT JUNE 15, 2021. replace NA values in LONGITUDE/LATITUDE with 1 so
# SAS can treat the whole column as numbers.
data %>%
  mutate(LONGITUDE = ifelse(is.na(LONGITUDE),1,LONGITUDE),
         LATITUDE  = ifelse(is.na(LATITUDE), 1,LATITUDE)) -> data
#----------------------------------
# Save to disk or load from desk if it's been saved earlier
write.csv(data, '../data/output/Police_Interventions_cleaned.csv',row.names = F)
#data = read.csv('../data/output/Police_Interventions_cleaned.csv')
#--------------------------------
# save a time-series version of the data
# as well as time-series per category.
data %>% 
  arrange(DATE) %>% 
  group_by(DATE) %>% 
  summarise(count = n()) %>% 
  write.csv('../data/output/ts_all_CATEGORIES.csv',row.names = FALSE)

for(cat in rownames(table(data$CATEGORY))){
  file.name = paste0('../data/output/ts_',
                     paste0(strsplit(cat,' ')[[1]],collapse = '_'),
                     '.csv')
  data %>%
    filter(CATEGORY==cat) %>%
    arrange(DATE) %>%
    group_by(DATE) %>%
    summarise(count = n()) %>%
    write.csv(file.name, row.names=FALSE)
}
rm(cat, file.name)
#-------------------------------------------
