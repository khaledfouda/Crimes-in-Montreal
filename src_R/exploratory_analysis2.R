require(lubridate)
require(rstatix)
require(ggpubr)
require(tidyverse)
data = read.csv('../data/output/Police_Interventions_cleaned.csv')
data %>% 
  filter(!YEAR==2021) %>%
  mutate(YEAR=year(DATE),
         MONTH=month(DATE)) -> data
#--------------------------------------------
# cateory
data %>% 
  count(CATEGORY = factor(CATEGORY)) %>%
  mutate(pct = prop.table(n)) %>%
  ggplot(aes(reorder(CATEGORY,-n),n, fill=CATEGORY, label = scales::percent(pct))) + 
  geom_col(position = 'dodge',show.legend = FALSE) + 
  geom_text(position = position_dodge(width = .9),    # move to center of bars
            vjust = -0.5,    # nudge above top of bar
            size = 3)  +
  labs(x="Category", y="Count")
#----------------------------
# arrondissements 
data %>% 
  count(ARRONDIS = (ARRONDIS), id=(ARRONDIS)) %>% 
  mutate(pct = prop.table(n)) %>% 
  filter(pct>=.03) %>% 
  mutate(ARRONDIS = factor(ARRONDIS), id = factor(id), 
         n=as.numeric(n), pct=as.numeric(pct)) %>%
  ggplot(aes(reorder(id,-n) ,n, fill=reorder(ARRONDIS,-n), 
             label = paste0(round(pct*100,1),'%')))+
  geom_col(position = 'dodge',show.legend = T) + 
  geom_text(position = position_dodge(width = .9),    # move to center of bars
            vjust = -0.5,    # nudge above top of bar
            size = 3)  +
  labs(x="arrondissement", y="Count", 
       title="Neighbourhood that contributes to at least 3% of the crimes.
       \n contributing to total 77.6% of total crimes") + 
  theme(axis.text.x=element_blank()) 
 
 
#scale_y_continuous(labels = scales::percent)
#----------------------
# category month
data %>% 
  count(MONTH = factor(MONTH), CATEGORY=factor(CATEGORY),c=MONTH) %>%
  mutate(pct = prop.table(n),c=as.numeric(MONTH)) %>% 
  #arrange(c) %>%
  mutate(MONTH = month.abb[c]) %>%
  ggplot(aes(reorder(MONTH,c),n,fill=CATEGORY, label = scales::percent(pct))) + 
  geom_col(position = 'identity',show.legend = F) + 
  facet_wrap(~CATEGORY, scales='free') +
  labs(x="", y="Count")
#------------------------------------------------
# category - year
 data %>% 
  count(YEAR = factor(YEAR), CATEGORY=factor(CATEGORY),c=YEAR) %>%
  mutate(pct = prop.table(n),c=as.numeric(YEAR)) %>% 
  ggplot(aes(reorder(YEAR,c),n,fill=CATEGORY, label = scales::percent(pct))) + 
  geom_col(position = 'identity',show.legend = F) + 
  facet_wrap(~CATEGORY, scales='free') +
  labs(x="", y="Count")
#------------------------------------------------------
# category - quartly
data %>% 
  
  count(QUART = factor(QUART), CATEGORY=factor(CATEGORY)) %>%
  mutate(pct = prop.table(n)) %>% 
  ggplot(aes(QUART,n,fill=CATEGORY, label = scales::percent(pct))) + 
  geom_col(position = 'identity',show.legend = F) + 
  facet_wrap(~CATEGORY, scales='free') +
  labs(x="", y="Count")


#------------
## ARRONdissment - Yearly and Quartly

data %>% 
  count(ARRONDIS = (ARRONDIS), id=(ARRONDIS)) %>% 
  mutate(pct = prop.table(n)) %>% 
  filter(pct>=.03) %>% 
  mutate(ARRONDIS = factor(ARRONDIS), id = factor(id), 
         n=as.numeric(n), pct=as.numeric(pct)) %>%
  arrange(desc(pct)) %>% pull(ARRONDIS) -> top3Arrond

data %>% 
  filter(ARRONDIS %in% top3Arrond) %>%
  count(YEAR = factor(YEAR), ARRONDIS=factor(ARRONDIS),c=YEAR) %>%
  mutate(pct = prop.table(n),c=as.numeric(YEAR), inc=round(((n/lag(n))-1)*100,1)) %>% 
  ggplot(aes(reorder(YEAR,c),n,fill=ARRONDIS)) + 
  geom_col(position = 'identity',show.legend = F) + 
  facet_wrap(~factor(ARRONDIS,levels=top3Arrond), scales='free') +
  labs(x="", y="Count") 


data %>% 
  
  count(QUART = factor(QUART), ARRONDIS=factor(ARRONDIS)) %>%
  filter(ARRONDIS %in% top3Arrond) %>%
  mutate(pct = prop.table(n)) %>% 
  ggplot(aes(QUART,n,fill=ARRONDIS, label = scales::percent(pct))) + 
  geom_col(position = 'identity',show.legend = F) + 
  facet_wrap(~factor(ARRONDIS,levels=top3Arrond), scales='free') +
  labs(x="", y="Count")



#-----------------------------------------------------
#  Arrondissment  -  YEARLY - ICREMENT

data %>%
  filter(ARRONDIS %in% top3Arrond) %>%
  arrange(ARRONDIS, YEAR) %>%
  count(YEAR = factor(YEAR), ARRONDIS=factor(ARRONDIS),c=YEAR) %>%
  group_by(ARRONDIS) %>%
  summarise(inc=round(((n/lag(n))-1)*100,1)) %>%
  mutate(typ = replace_na(ifelse(inc>0,1,-1),0), inc=replace_na(as.character(inc),'')) %>%
  select(inc,typ)  -> top3_yr_inc



data %>% 
  filter(ARRONDIS %in% top3Arrond) %>%
  #mutate()
  count(YEAR = factor(YEAR), ARRONDIS=factor(ARRONDIS),c=YEAR) %>%
  arrange(ARRONDIS, YEAR) %>%
  mutate(pct = prop.table(n),c=as.numeric(YEAR),inc=top3_yr_inc$inc, typ=factor(top3_yr_inc$typ)) %>% 
  ggplot(aes(reorder(YEAR,c),n,fill=ARRONDIS)) +
  scale_colour_manual(values = c("0" = "white","1" = "red", "-1" = "green")) +
  geom_col(position = 'identity',show.legend = F) + 
  facet_wrap(~factor(ARRONDIS,levels=top3Arrond), scales='free') +
  labs(x="", y="Count") +
  geom_label(aes(label=inc,color=typ),fill='grey', fontface = "bold",vjust=2,show.legend = F)
    

#----------------------------------------------------------
#-----------------------------------------------------
#  Category  -  YEARLY - ICREMENT

data %>%
  arrange(CATEGORY, YEAR) %>%
  count(YEAR = factor(YEAR), CATEGORY=factor(CATEGORY),c=YEAR) %>%
  group_by(CATEGORY) %>%
  summarise(inc=round(((n/lag(n))-1)*100,1)) %>%
  mutate(typ = replace_na(ifelse(inc>0,1,-1),0), inc=replace_na(as.character(inc),'')) %>%
  select(inc,typ)  -> top3_yr_inc



data %>% 
  count(YEAR = factor(YEAR), CATEGORY=factor(CATEGORY),c=YEAR) %>%
  arrange(CATEGORY, YEAR) %>%
  mutate(pct = prop.table(n),c=as.numeric(YEAR),inc=top3_yr_inc$inc, typ=factor(top3_yr_inc$typ)) %>% 
  ggplot(aes(reorder(YEAR,c),n,fill=CATEGORY)) +
  scale_colour_manual(values = c("0" = "white","1" = "red", "-1" = "green")) +
  geom_col(position = 'identity',show.legend = F) + 
  facet_wrap(~CATEGORY, scales='free') +
  labs(x="", y="Count") +
  geom_label(aes(label=inc,color=typ),fill='grey', fontface = "bold",vjust=2,show.legend = F)


#----------------------------------------------------------
# divison 
data %>% 
  count(DIVISION = (DIVISION), id=(DIVISION)) %>% 
  mutate(pct = prop.table(n)) %>% 
  filter(pct>=.03) %>% 
  mutate(DIVISION = factor(DIVISION), id = factor(id), 
         n=as.numeric(n), pct=as.numeric(pct)) %>%
  ggplot(aes(reorder(id,-n) ,n, fill=reorder(DIVISION,-n), 
             label = paste0(round(pct*100,1),'%')))+
  geom_col(position = 'dodge',show.legend = T) + 
  geom_text(position = position_dodge(width = .9),    # move to center of bars
            vjust = -0.5,    # nudge above top of bar
            size = 3)  +
  labs(x="arrondissement", y="Count", 
       title="Neighbourhood that contributes to at least 3% of the crimes.
       \n contributing to total 77.6% of total crimes") + 
  theme(axis.text.x=element_blank()) 









# 
# 
# 
# data.summ = data.frame()
# data %>% 
#   group_by(YEAR,CATEGORY) %>%
#   summarise(count=n()) %>%
#   group_by(YEAR) %>%
#   mutate(i1 = row_number()) %>%
#   spread(YEAR,count) %>% 
#   select(-i1) %>%
#   as.data.frame() -> data.summ
# 
# data %>% 
#   group_by(YEAR) %>% 
#   summarise('0'=n()) %>%
#   t %>%
#   as.data.frame %>%
#   `colnames<-` (.[1,]) %>%
#   .[-1,] %>%
#   mutate(CATEGORY="ALL") %>%
#   relocate(CATEGORY,1) %>%
#   rbind(data.summ) %>%
#   select(-"2021")-> data.summ
# 
# data.summ
# #----------------------------------------
# 
# data.summ  %>% 
#   .[-1,] %>%
#   melt() %>% 
#   ggplot(aes(x=variable, y=log(value))) +
#   geom_line(aes(color=CATEGORY, group=CATEGORY))
