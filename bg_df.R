library(tidyverse)
library(googlesheets4)


# Create df ---------------------------------------------------------------

con <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1UXBQs_tu0cRYN3XDEPsq3MxlUNvryPEnR-ClSp2uipo/edit?gid=0#gid=0",
                                 sheet = "conferences") %>% mutate(activity = "conferences")
edu <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1UXBQs_tu0cRYN3XDEPsq3MxlUNvryPEnR-ClSp2uipo/edit?gid=0#gid=0",
                                 sheet = "edu") %>% mutate(activity = "education")
int <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1UXBQs_tu0cRYN3XDEPsq3MxlUNvryPEnR-ClSp2uipo/edit?gid=0#gid=0",
                                 sheet = "internships") %>% mutate(activity = "research stays")
emp <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1UXBQs_tu0cRYN3XDEPsq3MxlUNvryPEnR-ClSp2uipo/edit?gid=0#gid=0",
                                 sheet = "work") %>% mutate(activity = "employment")
team <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1UXBQs_tu0cRYN3XDEPsq3MxlUNvryPEnR-ClSp2uipo/edit?gid=0#gid=0",
                                  sheet = "team")

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