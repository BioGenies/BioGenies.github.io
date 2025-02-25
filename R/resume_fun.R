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
    mutate(new_col = paste0("<h3>", "![](../fig/logo/", logo_name, "){width='50'} ", name, "</h3>\n", "<h4> ", major, "</h4> [ ", start_date, " - ", end_date, " ]", "{style='float:right;'}", "<br> ", if_else(thesis_title %>% is.na, " ", paste0(degree, " thesis: **", thesis_title, "** ")), "[ 📍 ", city, ", ", country, " ]{style='float:right;'}"
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
  
  
  pub_mod <- pub_mod$author %>% 
    lapply(., function(x){
      number <- x$au_id %>% str_detect(openalex_id) %>% which()
      position <-  x$author_position[number]
        }) %>% 
    unlist(.) %>%
    tibble(position = .) %>% 
    cbind(pub_mod, .)
  
  # for (i in pub_overwrite %>% filter(who == whois) %>% select(doi) %>% as.vector()) {
  #   pub_mod <- pub_mod %>% 
  #       mutate(position = if_else(str_detect(doi, i), "first", position))
  #   }
    
    
  pub_mod <- pub_mod$author %>% 
    lapply(., function(x){
      number <- x$au_id %>% str_detect(openalex_id) %>% which(.)
      corresponding <-  x$is_corresponding[number]
    }) %>% 
    unlist(.) %>%
    tibble(corresponding = .) %>% 
    cbind(pub_mod, .)
  
  # for (i in pub_overwrite %>% filter(who == whois) %>% select(doi) %>% as.vector()) {
  #   pub_mod <- pub_mod %>% 
  #     mutate(corresponding = if_else(str_detect(doi, i), TRUE, corresponding))
  # }
  
  pub_mod %>% 
    filter(type != "dataset") %>% 
    # select(title, authors, doi, publication_date, type, so, host_organization) %>% 
    mutate(authorship = paste0(
      if_else(position == "middle", "coauthor", position),
      if_else(corresponding == TRUE, ",\n corresponding", "")
    )) %>% 
    select(title, authors, doi, publication_date, type, so, host_organization, authorship) %>% 
    drop_na(., doi) %>%
    mutate(doi = paste0('<a  target=_blank href=', doi, '>', doi %>% str_remove(., "https://doi.org/"),'</a>'),
           journal = so %>% as.factor(),
           publisher = host_organization %>% as.factor(),
           type = type %>% as.factor(),
           `publication date` = publication_date %>% as_date()
    ) %>% 
    select(!c(so, host_organization, publication_date)) %>% 
    arrange(desc(`publication date`)) %>%
    DT::datatable(., escape = F, extensions = 'Buttons', options = list(dom = 'tp', buttons = c('copy', 'csv', 'excel')))
}


other_act <- function(whois){
  temp_df <- other_act_df %>% 
    filter(who == whois) %>% 
    mutate(new_col = paste0("* ", activity, "\n"
    ))
}

basic_info <- function(whois){
  temp_df <- bio_df %>% 
    filter(who == whois)
}

contact_info <- function(whois){
  basic_info(whois) %>% 
    mutate(new_col = paste0(
      if_else(email1 %>% is.na(), "", paste0("[`r fontawesome::fa('envelope', prefer_type = 'regular', fill = 'pink', height = '3em')`](mailto:", email1, ")\n")),
      if_else(email2 %>% is.na(), "", paste0("[`r fontawesome::fa('envelope', prefer_type = 'regular', fill = 'grey', height = '3em')`](mailto:", email2, ")\n")),
      if_else(github %>% is.na(), "", paste0("[`r fontawesome::fa('github', fill = '#24292e', height = '3em')`](https://github.com/", github, ")\n")),
      if_else(orcid %>% is.na(), "", paste0("[`r fontawesome::fa('orcid', fill = '#A6CE39', height = '3em')`](https://orcid.org/", orcid, ")\n")),
      if_else(fb %>% is.na(), "", paste0("[`r fontawesome::fa('facebook', fill = '#304f85', height = '3em')`](https://www.facebook.com/", fb, ")\n")),
      if_else(linkedin %>% is.na(), "", paste0("[`r fontawesome::fa('linkedin', fill = '#0077b5', height = '3em')`](https://www.linkedin.com/in/", linkedin, "/)\n")),
      if_else(X %>% is.na(), "", paste0("[`r fontawesome::fa('x-twitter', fill = '#24292e', height = '3em')`](https://x.com/", X, ")\n"))
    ))
}
