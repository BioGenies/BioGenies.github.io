library(fontawesome)
library(tidyverse)
library(googlesheets4)
library(ggalt)
library(patchwork)
library(RColorBrewer)


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
         full_name = if_else(full_name %>% is.na(), name, full_name)) %>% 
  filter(team == "main")


# prepare plots -----------------------------------------------------------

my_colors <- scale_fill_hue()$palette(full_df$who %>% levels() %>% length()) 
names(my_colors) <- full_df$who %>% levels()

p <- lapply(full_df$cat %>% levels(), function(i){
  full_df %>% 
    filter(activity == i) %>% 
    ggplot(., aes(y = name, color = who)) +
    geom_segment(aes(x = start_date, xend = end_date), linewidth = 2, position = position_dodgev(height = 0.9)) +
    geom_point(aes(x = start_date, y = name), size = 3, position = position_dodgev(height = 0.9)) +
    geom_point(aes(x = end_date, y = name), size = 3, position = position_dodgev(height = 0.9)) +
    scale_fill_manual(values = my_colors, aesthetics = "color") + 
    labs(title = paste0("BioGenies ", i), x = "Year", y = "Destination") +
    theme_minimal() +
    xlab("Dates")
})


# pw_plot <- (p[[1]] & theme(legend.position = "bottom")) + ((p[[2]] / p[[3]] / p[[4]]) & theme(legend.position = "none")) + plot_layout(guides = "auto")

pw_plot <- (p[[1]] | (p[[2]] / p[[3]] / p[[4]] & theme(legend.position = "none")) + plot_layout(axes = "collect", axis_titles = "collect"))


# make a map --------------------------------------------------------------

library(gapminder)
library(tidygeocoder)
library(plotly)
library(ggthemes)

world <- map_data("world") %>%
  filter(region != "Antarctica")

gapminder_codes <- gapminder::country_codes
gapminder <- gapminder::gapminder_unfiltered

gapminder <- gapminder %>%
  inner_join(gapminder_codes, by= "country") %>%
  mutate(code = iso_alpha)

gapminder_data <- gapminder %>%
  inner_join(maps::iso3166 %>%
               select(a3, mapname), by= c(code = "a3")) %>%
  mutate(mapname = str_remove(mapname, "\\(.*"))

## cities <- lon & lat

full_df_longlat <- full_df %>% geocode(city = city, country = country)

world_visit <- world %>%
  ggplot() +
  geom_polygon(aes(x = long, y = lat, group = group),
               fill = "springgreen2",
               color = "deepskyblue1",
               size = 0.01) +
  geom_point(data = full_df_longlat, aes(x = long, y = lat, color = activity, text = paste0(activity, "<br>", full_name, "<br>", city, ", ", country, "<br>", who)), alpha = 0.6) +
  labs(title = "BioGenies in the world") +
  theme_map() +
  scale_size_continuous(guide = F) +
  scale_color_discrete(name = "Type") +
  theme(plot.title = element_text(size = 10, hjust = 0.5))


inter_plot <- ggplotly(world_visit, tooltip = "text")