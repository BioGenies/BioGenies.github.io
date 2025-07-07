library(tidyverse)
library(ggalt)
library(patchwork)
library(RColorBrewer)

# full_df_mod <- full_df %>% filter(team == "main")

# prepare plots -----------------------------------------------------------

my_colors <- scale_fill_hue()$palette(full_df_mod$who %>% levels() %>% length()) 
names(my_colors) <- full_df_mod$who %>% levels()

p <- lapply(full_df_mod$cat %>% levels(), function(i){
  full_df_mod %>% 
    filter(activity == i) %>% 
    ggplot(., aes(y = name, color = who)) +
    geom_segment(aes(x = start_date, xend = end_date), linewidth = 2, position = ggstance::position_dodgev(height = 0.9)) +
    geom_point(aes(x = start_date, y = name), size = 3, position = ggstance::position_dodgev(height = 0.9)) +
    geom_point(aes(x = end_date, y = name), size = 3, position = ggstance::position_dodgev(height = 0.9)) +
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

full_df_longlat <- full_df_mod %>% 
  # select(full_name, city, country, who, activity) %>% 
  geocode(city = city, country = country)

world_visit <- world %>%
  ggplot() +
  geom_polygon(aes(x = long, y = lat, group = group),
               fill = "burlywood1",
               color = "navy",
               size = 0.05) +
  geom_point(data = full_df_longlat, 
             aes(x = long, y = lat, color = activity, text = paste0(full_name, "<br>", city, ", ", country, "<br>", who)), 
             # alpha = 0.6,
             size = 2,
             position = "jitter") +
  labs(title = "BioGenies in the world") +
  theme_map() +
  scale_size_continuous(guide = F) +
  scale_color_discrete(name = "Type") +
  theme(plot.title = element_text(size = 14, hjust = 0.5),
        legend.text = element_text(size=14))


inter_plot <- ggplotly(world_visit, tooltip = "text")
# inter_plot

