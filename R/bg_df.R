library(tidyverse)
library(googlesheets4)

# Create df ---------------------------------------------------------------

link <- "https://docs.google.com/spreadsheets/d/1UXBQs_tu0cRYN3XDEPsq3MxlUNvryPEnR-ClSp2uipo/edit?usp=sharing"

bio_df <- googlesheets4::read_sheet(link, sheet = "basic_info")
con <- googlesheets4::read_sheet(link, sheet = "conferences") %>% mutate(activity = "conferences")
edu <- googlesheets4::read_sheet(link, sheet = "edu") %>% mutate(activity = "education")
int <- googlesheets4::read_sheet(link, sheet = "internships") %>% mutate(activity = "research stays")
emp <- googlesheets4::read_sheet(link, sheet = "work") %>% mutate(activity = "employment")
team <- googlesheets4::read_sheet(link, sheet = "team")
other_act_df <- googlesheets4::read_sheet(link, sheet = "other_activities")

pub_overwrite <- googlesheets4::read_sheet(link, sheet = "pub_overwrite")

full_df <- full_join(con, edu, by = c("start_date", "end_date", "city", "country", "name", "who", "activity")) %>%
  full_join(., int, by = c("start_date", "end_date", "city", "country", "name", "who", "activity")) %>%
  full_join(., emp, by = c("start_date", "end_date", "city", "country", "name", "who", "group", "faculty", "activity")) %>%
  full_join(., team, by = c("who")) %>% 
  mutate(start_date = as.Date(start_date, "%d.%m.%Y"),
         start_date = if_else(is.na(start_date), today(), start_date),
         end_date = as.Date(end_date, "%d.%m.%Y"),
         end_date = if_else(is.na(end_date), today(), end_date),
         cat = as.factor(activity),
         type = as.factor(type),
         who = as.factor(who),
         full_name = if_else(full_name %>% is.na(), name, full_name))

remove(link)

save.image(file = 'data/bg_df_data.RData')
# load("data/bg_df_data.RData")
