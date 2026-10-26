# One edition per event, with contributions and attendees retained underneath.
team_mobility <- function(data) {
  rows <- data %>% dplyr::filter(!is.na(team), team != "other", activity %in% c("conferences", "research stays")) %>% dplyr::arrange(dplyr::desc(start_date))
  if (!nrow(rows)) return(NULL)
  rows$country <- normal_country(rows$country)
  events <- conference_events(rows %>% dplyr::filter(activity == "conferences"))
  stays <- rows %>% dplyr::filter(activity == "research stays")
  countries <- sort(unique(rows$country[nzchar(rows$country) & rows$country != "Online"]))
  stat <- function(number,label) htmltools::div(class="mobility-stat",htmltools::tags$strong(number),htmltools::tags$span(label))
  stay <- function(row) htmltools::tags$article(class="mobility-record stay-card",
    institution_logo(row,"fig"),
    htmltools::div(htmltools::tags$p(class="event-date",cv_date_range(row)),
      htmltools::tags$strong(cv_text(row$name)),
      htmltools::tags$p(cv_text(row$whois_full_name)),record_place(row,"fig"),
      if (nzchar(cv_text(row$group))) htmltools::tags$p(cv_text(row$group))))
  visible <- seq_len(min(3L,nrow(stays)))
  htmltools::div(class="mobility-overview",
    htmltools::div(class="mobility-stats",stat(length(countries),"Countries in our records"),stat(nrow(events),"Conference & workshop editions"),stat(nrow(stays),"Research stays")),
    htmltools::div(class="destination-list",lapply(countries,function(country)htmltools::tags$span(class="destination-chip",country_flag(country,"fig"),country))),
    htmltools::tags$h3("Meeting the research community"),
    htmltools::tags$p("One card per event edition, with everyone who attended listed together. Includes current and former members and collaborators."),
    conference_cards(events,preview=3L),
    htmltools::tags$h3("Research stays & exchanges"),
    do.call(htmltools::tagList,lapply(visible,function(i)stay(stays[i,,drop=FALSE]))),
    cv_year_archive(stays[-visible,,drop=FALSE],stay,"Earlier research stays"))
}
