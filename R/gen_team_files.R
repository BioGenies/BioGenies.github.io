source('R/create_ppl_page.R')

for (i in team %>% filter(team == "main") %>% .$who) {
  print(i)
  temp_df <- team %>% filter(who == i)
  whois <- i
  whois_full_name <- temp_df$whois_full_name
  file_name <- paste0("subsite/team/", temp_df$file_name)
  
  create_ppl_page(whois_full_name, whois, file_name)
}


for (i in team %>% filter(team == "colab") %>% .$who) {
  print(i)
  temp_df <- team %>% filter(who == i)
  whois <- i
  whois_full_name <- temp_df$whois_full_name
  file_name <- paste0("subsite/colab/", temp_df$file_name)
  
  create_ppl_page(whois_full_name, whois, file_name)
}
