library(openalexR)
library(tidyverse)


research_stay <- function(whois){
  full_df %>% 
    filter(who == whois & cat == "research stays") %>% 
    select(group, faculty, name, start_date, end_date, city, country) %>% 
    arrange(desc(end_date)) %>% 
    DT::datatable(., options = list(dom = 'tp'))
}
  

work <- function(whois){
  full_df %>% 
    filter(who == whois & cat == "employment") %>% 
    select(group, faculty, name, start_date, end_date, position) %>% 
    arrange(desc(end_date)) %>% 
    DT::datatable(., options = list(dom = 'tp'))
}


education <- function(whois){
  full_df$name <- full_df$name %>% str_remove(., "\n")
  
  edu_df <- full_df %>% 
    filter(who == whois & cat == "education") %>% 
    arrange(desc(end_date)) %>% 
    mutate(new_col = paste0("<h3>", "![](../fig/logo/", logo_name, "){width='50'} ", name, "</h3>\n", "<h4> ", major, "</h4> [ ", start_date, " - ", end_date, " ]", "{style='float:right;'}", "<br> ", if_else(thesis_title %>% is.na, " ", paste0("Thesis: **", thesis_title, "** ")), "[ 📍 ", city, ", ", country, " ]{style='float:right;'}"
    ))
}


conf_work <- function(whois){
  full_df %>% 
    filter(who == whois & cat == "conferences") %>% 
    select(type, full_name, title, city, country, start_date, end_date) %>% 
    arrange(desc(end_date)) %>%
    mutate(type = case_when(
      type == "poster" ~ "📊 poster",
      type == "talk" ~ "🗣️ talk",
      type == "keynote" ~ "🎤 keynote",
      type == "workshops" ~ "🧑🏻‍💻 workshops"
    )) %>% 
    DT::datatable(., options = list(dom = 'tp'))
}


pubs <- function(whois, openalex_id){
  pub <- openalexR::oa_fetch(entity ="works",
                             author.id = openalex_id)
  
  pub_mod <- pub$author %>% 
    lapply(., function(x) {x$au_display_name %>% str_flatten(., collapse = ", ")}) %>% 
    unlist() %>% 
    tibble(authors = .) %>% 
    cbind(pub, .)
  
  pub_mod %>% 
    filter(type != "dataset") %>% 
    select(title, authors, doi, publication_date, type, so, host_organization) %>% 
    drop_na(., doi) %>%
    mutate(doi = paste0('<a  target=_blank href=', doi, '>', doi %>% str_remove(., "https://doi.org/"),'</a>'),
           journal = so %>% as.factor(),
           publisher = host_organization %>% as.factor(),
           type = type %>% as.factor(),
           `publication date` = publication_date %>% as_date()
    ) %>% 
    select(!c(so, host_organization, publication_date)) %>% 
    arrange(desc(`publication date`)) %>%
    DT::datatable(., escape = F, options = list(dom = 'tp'))
}


