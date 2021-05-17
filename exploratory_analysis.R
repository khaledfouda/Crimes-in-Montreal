require(dplyr)
require(lubridate)
require(ggplot2)

data = read.csv('./data/Last/Police_Interventions_cleaned.csv')
data$X = NULL

data.summ = data.frame()
data %>% 
  group_by(YEAR,CATEGORIE) %>%
  summarise(count=n()) %>%
  group_by(YEAR) %>%
  mutate(i1 = row_number()) %>%
  spread(YEAR,count) %>% 
  select(-i1) %>%
  as.data.frame() -> data.summ

data %>% 
  group_by(YEAR) %>% 
  summarise('0'=n()) %>%
  t %>%
  as.data.frame %>%
  `colnames<-` (.[1,]) %>%
  .[-1,] %>%
  mutate(CATEGORIE="ALL") %>%
  relocate(CATEGORIE,1) %>%
  rbind(data.summ) %>%
  select(-"2021")-> data.summ

data.summ
#----------------------------------------

data.summ  %>% 
  .[-1,] %>%
  melt() %>% 
  ggplot(aes(x=variable, y=log(value))) +
  geom_line(aes(color=CATEGORIE, group=CATEGORIE))