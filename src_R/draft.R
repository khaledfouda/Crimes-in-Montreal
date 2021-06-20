data = read.csv('../data/output/Police_Interventions_cleaned.csv')

data %>%
  group_by(YEAR) %>%
  arrange(YEAR,PDQ, .by_group = T) %>%
  count(PDQ, sort=F) -> summ.pdq


summ.pdq %>% 
  filter(YEAR==2019) %>% 
  View()


data %>%
  filter(YEAR==2019) %>% 
  group_by(CATEGORY) %>%
  arrange(PDQ,CATEGORY, .by_group = T) %>%
  count(PDQ, sort=F) %>%
  filter(PDQ==20) %>%
  View()
