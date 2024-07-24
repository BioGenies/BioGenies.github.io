# bib2df ------------------------------------------------------------------
library(bib2df)
library(tidyverse)

bib_dat <- bib2df("BIOgenies.bib", separate_names = TRUE)

test1 <- bib_dat %>% 
  select(BIBTEXKEY, AUTHOR, JOURNAL, TITLE, YEAR, DOI, PUBLISHER) 
  
authors <- lapply(test1$AUTHOR, function(x){
  x$full_name %>% str_flatten(collapse = ", ") %>% rbind()
}) %>%  
  tibble(authors = .) 

new_df <- cbind(authors, test1)


new_df$authors <- new_df$authors %>% 
  str_remove_all(., "[{}]")

new_df$TITLE <- new_df$TITLE %>% 
  str_remove_all(., "[{}]")






library(pubmedR)

query <- '("2014/01/01"[Date - Publication] : "3000"[Date - Publication]) AND ((Chilimoniuk J[Author]) OR (Burdukiewicz, M[Author]))'
res <- pmQueryTotalCount(query = query)

pub <- pmApiRequest(query = query, limit = res$total_count, api_key = NULL)

pub_df <- pmApi2df(pub)


library(openalexR)
library(tidyverse)
library(bibliometrix)

options(openalexR.mailto = "example@email.com")

test_oa <- oa_fetch(entity = "works",
                    # authorships.institutions.ror = "00y4ya841",
                    # from_publication_date = "2024-06-01",
                    # to_publication_date = "2024-06-02",
                    authorships.author.id = c("a5015968787", "a5072021711"),
                    output = "list",
                    # output = "tibble",
                    verbose = TRUE)  


dupa <- lapply(test_oa, function(x){
  # browser()
  auth <- x[["authorships"]]
  author <- lapply(auth, function(i){
    browser()
    i$author$display_name
    i$author_position
    i$is_corresponding
    i$institutions[[1]]$display_name
    i$raw_affiliation_strings %>% unlist()
  })
  
  
  x$authorships[[1]]$raw_author_name
  x$author_position
  x$affiliations[[1]]$raw_affiliation_string
})
