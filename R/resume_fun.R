library(openalexR)
library(tidyverse)


# Keep every record in plain HTML, with recent items visible and history grouped by year.
cv_text <- function(value) {
  if (length(value) == 0 || is.na(value[1])) "" else as.character(value[1])
}

cv_year <- function(value) {
  value <- cv_text(value)
  if (grepl("^[0-9]{4}", value)) substr(value, 1, 4) else "Undated"
}

cv_date_range <- function(row) {
  values <- c(cv_text(row$start_date), cv_text(row$end_date))
  paste(unique(values[nzchar(values)]), collapse = " – ")
}

cv_year_archive <- function(rows, render, label) {
  if (nrow(rows) == 0) return(NULL)
  years <- vapply(seq_len(nrow(rows)), function(i) cv_year(rows$start_date[i]), character(1))
  groups <- lapply(unique(years), function(year) {
    indices <- which(years == year)
    htmltools::tags$details(class = "cv-year",
      htmltools::tags$summary(htmltools::tags$span(year),
        htmltools::tags$span(class = "cv-count", length(indices))),
      htmltools::div(class = "cv-year-content", do.call(htmltools::tagList, lapply(indices, function(i) render(rows[i, ])))))
  })
  htmltools::tags$details(class = "cv-archive",
    htmltools::tags$summary(paste0(label, " (", nrow(rows), ")")),
    do.call(htmltools::tagList, groups))
}

# Resolve relative to this source file, including CV pages nested two folders deep.
event_helper_paths <- file.path(c(".", "..", "../.."), "R", "event_cards.R")
bio_site_root <- dirname(dirname(normalizePath(event_helper_paths[file.exists(event_helper_paths)][1], winslash="/")))
source(file.path(bio_site_root, "R", "event_cards.R"))

cv_conferences <- function(rows, preview = 3L) {
  events <- conference_events(rows)
  if (!nrow(events)) return(NULL)
  htmltools::div(class="cv-conferences",
    htmltools::tags$p(class="cv-section-note", paste(nrow(events), "conference and training events")),
    conference_cards(events, preview, assets="../fig", profiles="../", show_people=FALSE, archive_label="Earlier activities"))
}

publication_bibliography <- function(publications, preview = NULL) {
  entries <- publications %>%
    filter(!is.na(doi), nzchar(doi), grepl("^https?://doi\\.org/", doi)) %>%
    distinct(doi, .keep_all = TRUE) %>%
    arrange(desc(publication_date))
  if (nrow(entries) == 0) return(NULL)
  render <- function(paper) {
    htmltools::tags$article(class = "cv-publication",
      htmltools::tags$a(class = "cv-paper-title", href = cv_text(paper$doi), cv_text(paper$title)),
      htmltools::tags$p(class = "cv-paper-meta", paste(Filter(nzchar, c(cv_text(paper$source_display_name), cv_text(paper$publication_date))), collapse = " · ")),
      htmltools::tags$details(class = "cv-paper-details",
        htmltools::tags$summary("Authors & citation details"),
        htmltools::tags$p(cv_text(paper[["authors"]])),
        if (nzchar(cv_text(paper[["authorship"]]))) htmltools::tags$p(paste("Authorship:", cv_text(paper[["authorship"]]))),
        htmltools::tags$a(href = cv_text(paper$doi), cv_text(paper$doi))))
  }
  if (is.null(preview)) {
    return(htmltools::tags$details(class = "research-citations",
      htmltools::tags$summary("Full publication bibliography"),
      do.call(htmltools::tagList, lapply(seq_len(nrow(entries)), function(i) render(entries[i, ])))))
  }
  visible <- seq_len(min(preview, nrow(entries)))
  earlier <- entries[-visible, , drop = FALSE]
  earlier$start_date <- earlier$publication_date
  htmltools::div(class = "cv-publications",
    htmltools::tags$p(class = "cv-section-note", paste(nrow(entries), "publications listed · most recent first")),
    do.call(htmltools::tagList, lapply(visible, function(i) render(entries[i, ]))),
    cv_year_archive(earlier, render, "Earlier publications"))
}

cv_timeline <- function(rows, fields) {
  if (nrow(rows) == 0) return(NULL)
  render <- function(row) {
    values <- vapply(fields, function(field) {
      value <- as.character(row[[field]])
      if (length(value) == 0 || is.na(value)) "" else value
    }, character(1))
    values <- unique(values[nzchar(values)])
    dates <- c(as.character(row$start_date), as.character(row$end_date))
    dates <- dates[!is.na(dates) & nzchar(dates)]
    htmltools::tags$article(class = "cv-entry",
      institution_logo(row),
      htmltools::tags$p(class = "cv-date", paste(dates, collapse = " – ")),
      htmltools::tags$h3(if (length(values)) values[1] else "Research activity"),
      htmltools::tags$p(paste(values[-1], collapse = " · ")),
      record_place(row))
  }
  visible <- seq_len(min(3L, nrow(rows)))
  htmltools::div(class = "cv-timeline",
    do.call(htmltools::tagList, lapply(visible, function(i) render(rows[i, ]))),
    cv_year_archive(rows[-visible, , drop = FALSE], render, "Earlier records"))
}

research_stay <- function(whois) {
  rows <- full_df %>% filter(who == whois & cat == "research stays") %>%
    arrange(desc(start_date))
  cv_timeline(rows, c("group", "faculty", "name", "city", "country"))
}

work <- function(whois) {
  rows <- full_df %>% filter(who == whois & cat == "employment") %>%
    arrange(desc(start_date))
  cv_timeline(rows, c("position", "group", "faculty", "name"))
}

education <- function(whois) {
  rows <- full_df %>% filter(who == whois & cat == "education") %>% arrange(desc(start_date))
  rows$new_col <- vapply(seq_len(nrow(rows)), function(i) {
    row <- rows[i, ]
    years <- paste(unique(c(cv_year(row$start_date), if (cv_text(row$end_date) == "ongoing") "ongoing" else cv_year(row$end_date))), collapse = " – ")
    place <- paste(Filter(nzchar, c(cv_text(row$city), cv_text(row$country))), collapse = ", ")
    as.character(htmltools::tags$details(class = "cv-record cv-education",
      htmltools::tags$summary(
        htmltools::tags$span(class = "cv-record-date", years),
        institution_logo(row),
        htmltools::tags$span(class = "cv-record-title", cv_text(row$name)),
        htmltools::tags$span(class = "cv-badge", cv_text(row$degree))),
      htmltools::div(class = "cv-record-body",
        record_place(row),
        htmltools::tags$p(cv_text(row$major)),
        if (nzchar(cv_text(row$thesis_title))) htmltools::tags$p(htmltools::tags$strong("Thesis: "), cv_text(row$thesis_title)),
        htmltools::tags$p(paste(Filter(nzchar, c(cv_date_range(row), place)), collapse = " · ")))))
  }, character(1))
  rows
}

# A block result preserves nested HTML; inline Markdown interprets its indentation as code.
education_panel <- function(whois) {
  rows <- education(whois)
  do.call(htmltools::tagList, lapply(rows$new_col, htmltools::HTML))
}

education2 <- function(whois){
  full_df$name <- full_df$name %>% str_remove(., "\n")

  edu_df <- full_df %>%
    filter(who == whois & cat == "education") %>%
    arrange(desc(end_date)) %>%
    mutate(new_col = paste0("::: {.hero-strip}<span class='hero-pill'><h3>", "![](../fig/logo/", logo_name, "){width='50'} ", name, "</h3><span class='hero-pill'><h4><i class='bi bi-hourglass-split'>", start_date, " - ", end_date, "<br>",  "📍" , city, ", ", country, "</h4></span>", "<span class='hero-pill'>
<h4>",  major,"</h4></span><br><br>", "<span class='hero-pill-secondary'><strong>PhD thesis: </strong> **", thesis_title,"**", "</span> :::"
    ))
}


conf_work <- function(whois) {
  rows <- full_df %>% filter(who == whois & cat == "conferences")
  cv_conferences(rows)
}

# Retry transient OpenAlex connection failures without dropping publications.
oa_fetch_retry <- function(...) {
  for (attempt in seq_len(3L)) {
    result <- tryCatch(openalexR::oa_fetch(...), error = identity)
    if (!inherits(result, "error")) return(result)
    if (attempt == 3L) stop(result)
  }
}

pubs <- function(whois, openalex_id){
  pub <- oa_fetch_retry(entity ="works",
                             author.id = openalex_id)

  if (is.null(pub) || nrow(pub) == 0) {
    return(htmltools::tags$p("No publications are currently listed in OpenAlex for this researcher."))
  }

  pub <- pub[!(pub$doi %in% c("https://doi.org/10.1007/s00276-025-03680-2",
                              "https://doi.org/10.1007/10.1016/j.dss.2016.06.007",
                              "https://doi.org/10.1007/10.1016/j.dss.2016.06.007",
                              "https://doi.org/10.1007/10.2991/ifsa-eusflat-15.2015.94")), ]

  pub_mod <- pub$authorships %>%
    lapply(., function(x) {x$display_name %>% str_flatten(., collapse = ", ")}) %>%
    unlist() %>%
    tibble(authors = .) %>%
    cbind(pub, .)


  # OpenAlex can omit a requested author from an individual authorship record.
  # Keep one result per work instead of shortening the column with unlist().
  author_value <- function(authors, field, missing) {
    if (is.null(authors$id)) return(missing)
    matches <- which(sub(".*/", "", authors$id) == sub(".*/", "", openalex_id))
    if (!length(matches) || is.null(authors[[field]])) return(missing)
    value <- authors[[field]][matches[1]]
    if (!length(value)) missing else value
  }
  pub_mod$position <- vapply(pub_mod$authorships, author_value,
    character(1), field = "author_position", missing = NA_character_)
  pub_mod$corresponding <- vapply(pub_mod$authorships, author_value,
    logical(1), field = "is_corresponding", missing = NA)

  if((pub_overwrite %>% filter(who == whois & position == "first") %>% nrow()) > 0){
  for (i in pub_overwrite %>% filter(who == whois & position == "first") %>% select(doi) %>% as.vector()) {
    pub_mod <- pub_mod %>%
      mutate(position = if_else(str_detect(doi, i), "first", position))
  }}

  if((pub_overwrite %>% filter(who == whois & corresponding == TRUE) %>% nrow()) > 0){
  for (i in pub_overwrite %>% filter(who == whois & corresponding == TRUE) %>% select(doi) %>% as.vector()) {
    pub_mod <- pub_mod %>%
      mutate(corresponding = if_else(str_detect(doi, i), TRUE, corresponding))
  }}

  pub_mod <- pub_mod %>% filter(type != "dataset")
  pub_mod <- pub_mod %>% mutate(authorship = paste0(
    if_else(is.na(position), "", if_else(position == "middle", "coauthor", position)),
    if_else(!is.na(corresponding) & corresponding, ", corresponding", "")))
  publication_bibliography(pub_mod, preview = 3L)
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
      if_else(email1 %>% is.na(), "", paste0("[Email](mailto:", email1, ")\n")),
      if_else(email2 %>% is.na(), "", paste0("[Email](mailto:", email2, ")\n")),
      if_else(github %>% is.na(), "", paste0("[GitHub](https://github.com/", github, ")\n")),
      if_else(orcid %>% is.na(), "", paste0("[ORCID](https://orcid.org/", orcid, ")\n")),
      if_else(fb %>% is.na(), "", paste0("[Facebook](https://www.facebook.com/", fb, ")\n")),
      if_else(linkedin %>% is.na(), "", paste0("[LinkedIn](https://www.linkedin.com/in/", linkedin, "/)\n")),
      if_else(X %>% is.na(), "", paste0("[X](https://x.com/", X, ")\n"))
    ))
}
