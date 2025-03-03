# whois_full_name <- "Michał"
# whois <- whois
# whois <- "Asia"

load("data/bg_df_data.RData")
source('R/resume_fun.R')

create_ppl_page <- function(whois_full_name, whois, file_name){

qmd_header <- paste0(
"---
title: '", whois_full_name, "'\n",
"sidebar: false
format:
  html:
    grid:
      sidebar-width: 0px
      body-width: 1500px
      margin-width: 300px
      gutter-width: 1.5rem
knitr:
  opts_chunk:
    out.width: '95%'
---
    
```{r, echo=FALSE, message=FALSE,include=FALSE}
load('../../data/bg_df_data.RData')
whois <- '", whois, "'\n\n",
"source('../../R/resume_fun.R')
openalex_id <- basic_info(whois)$openalex_id
library(fontawesome)
```
\n\n")


bio_txt <- if_else(basic_info(whois)$bio %>% is.na(), paste0("<!-- # 📝 **Bio** -->

<!-- ------------------------------------------------------------------------ -->

<!-- `r stringr::str_flatten(basic_info(whois)$bio)` -->", "\n")
, "# 📝 **Bio**
  
------------------------------------------------------------------------

`r stringr::str_flatten(basic_info(whois)$bio)`
\n")


contact_txt <- if_else((bio_df %>% filter(who == whois) %>% .[3:8] %>% janitor::remove_empty() %>% ncol()) != 0,
                       paste0(
"# 📱 **Contact**

------------------------------------------------------------------------

", stringr::str_flatten(contact_info(whois)$new_col), "\n"), 
paste0("<!-- # 📱 **Contact** -->

<!-- ------------------------------------------------------------------------ -->

<!-- stringr::str_flatten(contact_info(whois)$new_col) -->", "\n")
)


research_txt <- if_else((full_df %>% filter(who == whois & cat == "research stays") %>% nrow()) != 0, paste0(
"# 🚀 **Research stays**

------------------------------------------------------------------------

```{r, echo=FALSE, message=FALSE}
research_stay(whois)
```", "\n"), paste0(
"<!-- # 🚀 **Research stays** -->

<!-- ------------------------------------------------------------------------ -->

<!-- ```{r, echo=FALSE, message=FALSE} -->
<!-- research_stay(whois) -->
<!-- ``` -->", "\n"))


employment_txt <- if_else((full_df %>% filter(who == whois & cat == "employment") %>% nrow()) != 0, paste0(
"# 💻🧫 **Experience**

------------------------------------------------------------------------

```{r, echo=FALSE, message=FALSE}
work(whois)
```
\n"), paste0(
"<!-- # 💻🧫 **Experience** -->
  
<!-- ------------------------------------------------------------------------ -->
    
<!-- ```{r, echo=FALSE, message=FALSE} -->
<!-- work(whois) -->
<!-- ``` -->", "\n"
))



education_txt <- if_else((full_df %>% filter(who == whois & cat == "education") %>% nrow()) != 0, paste0(
"# 🎓 **Education**
  
------------------------------------------------------------------------

`r stringr::str_flatten(education(whois)$new_col)`
\n"), 
paste0(
"<!-- # 🎓 **Education** -->

<!-- ------------------------------------------------------------------------ -->

<!-- `r stringr::str_flatten(education(whois)$new_col)` -->", "\n"
))


conference_txt <- if_else((full_df %>% filter(who == whois & cat == "conferences") %>% nrow()) != 0, paste0(
"# 👏🏻 **Conferences, workshops, training schools** 🤝🏻 

------------------------------------------------------------------------

```{r, echo=FALSE, message=FALSE}
conf_work(whois)
```
\n"),
paste0(
"<!-- # 👏🏻 **Conferences, workshops, training schools** 🤝🏻  -->

<!-- ------------------------------------------------------------------------ -->

<!-- ```{r, echo=FALSE, message=FALSE} -->
<!-- conf_work(whois) -->
<!-- ``` -->", "\n"))


publication_txt <- if_else((openalexR::oa_fetch(entity ="works", author.id = basic_info(whois)$openalex_id) %>% try() %>% nrow()) != 0, paste0(
"#  📖 **Publications**

------------------------------------------------------------------------

```{r, echo=FALSE, message=FALSE, error=FALSE, warning=FALSE}
pubs(whois, openalex_id)
```
\n"),
paste0(
"<!-- #  📖 **Publications** -->

<!-- ------------------------------------------------------------------------ -->

<!-- ```{r, echo=FALSE, message=FALSE} -->
<!-- pubs(whois, openalex_id) -->
<!-- ``` -->", "\n"))


other_act_txt <- if_else((other_act(whois) %>% filter(who == whois) %>% nrow()) != 0, paste0(
"# 🧑🏻‍🔬 **Other activities**

------------------------------------------------------------------------

`r stringr::str_flatten(other_act(whois)$new_col)`
\n"), 
paste0("<!-- # 🧑🏻‍🔬 **Other activities** -->

<!-- ------------------------------------------------------------------------ -->

<!-- `r stringr::str_flatten(other_act(whois)$new_col)` -->", "\n"))


write_lines(c(qmd_header, bio_txt, contact_txt, research_txt, employment_txt, education_txt, conference_txt, publication_txt, other_act_txt), 
            file = paste0(file_name, ".qmd"))
}
