# Shared visual identity and event aggregation for CVs and group pages.
normal_country <- function(x) {
  x <- trimws(as.character(x)); x[is.na(x)] <- ""
  x[tolower(x) == "polska"] <- "Poland"
  x[tolower(x) == "online"] <- "Online"
  x
}
country_flag <- function(country, assets = "../fig") {
  country <- normal_country(cv_text(country))
  codes <- c(Belgium="be", Canada="ca", Cyprus="cy", `Czech Republic`="cz", Denmark="dk", France="fr", Germany="de", Greece="gr", Hungary="hu", Italy="it", Japan="jp", Lithuania="lt", Mexico="mx", Netherlands="nl", Poland="pl", Portugal="pt", Slovakia="sk", Spain="es", Sweden="se", Switzerland="ch", `United Kingdom`="gb", USA="us")
  code <- unname(codes[country])
  if (!length(code) || is.na(code)) return(NULL)
  # Country is written next to the flag; avoid repeating it for screen readers.
  htmltools::tags$img(class="country-flag", src=paste0(assets,"/flags/",code,".svg"), alt="", `aria-hidden`="true", loading="lazy")
}
institution_logo <- function(row, assets = "../fig") {
  name <- gsub("\\s+", " ", cv_text(row[["name"]]))
  logos <- c(`University of Warsaw`="UW_logo.png", `University of Wrocław`="UWr_logo.png", `Medical University of Białystok`="MUB_logo.png", `Vilnius University`="VU_logo.png", `Warsaw University of Technology`="PW_logo.png", `Brandenburg University of Technology Cottbus-Senftenberg`="BTU_logo.png", `Autonomous University of Barcelona`="UAB_logo.png", `Universitat Autònoma de Barcelona`="UAB_logo.png", `Universitat de Girona`="UdG_logo.png", `Institute of Biochemistry and Biophysics`="IBB_logo.png")
  logo <- cv_text(row[["logo_name"]])
  if (!nzchar(logo)) logo <- cv_text(unname(logos[name]))
  if (!nzchar(logo)) return(NULL)
  htmltools::tags$img(class="institution-logo", src=paste0(assets,"/logo/",logo), alt=paste(name,"logo"), loading="lazy")
}
record_place <- function(row, assets="../fig") {
  country <- normal_country(cv_text(row[["country"]]))
  place <- paste(Filter(nzchar,c(cv_text(row[["city"]]),country)),collapse=", ")
  if (!nzchar(place)) return(NULL)
  htmltools::tags$span(class="record-place", country_flag(country,assets),place)
}
event_date <- function(x) {
  text <- as.character(x)
  result <- as.Date(text, format="%Y-%m-%d")
  missing <- is.na(result)
  result[missing] <- as.Date(text[missing], format="%d.%m.%Y")
  result
}
conference_events <- function(rows) {
  if (!nrow(rows)) return(rows)
  if (!"name" %in% names(rows)) rows$name <- rows$full_name
  if (!"whois_full_name" %in% names(rows)) rows$whois_full_name <- ""
  rows$country <- normal_country(rows$country)
  clean <- function(x) { x <- trimws(gsub("\\s+"," ",as.character(x))); x[is.na(x)] <- ""; tolower(x) }
  event_name <- ifelse(is.na(rows$full_name) | !nzchar(trimws(rows$full_name)),as.character(rows$name),as.character(rows$full_name))
  rows$full_name <- event_name
  base <- paste(clean(event_name),substr(rows$start_date,1,4),clean(rows$city),clean(rows$country),sep="|")
  # Overlapping date intervals allow for slightly different attendance dates.
  # Separate editions in the same city/year remain separate events.
  groups <- list()
  for (key in unique(base)) {
    idx <- which(base == key); idx <- idx[order(rows$start_date[idx],na.last=TRUE)]
    current <- integer(); finish <- as.Date(NA)
    for (i in idx) {
      start <- event_date(rows$start_date[i]); end <- event_date(rows$end_date[i])
      if (is.na(end)) end <- start
      overlaps <- length(current) && !is.na(start) && !is.na(finish) && start <= finish
      if (length(current) && !overlaps) { groups[[length(groups)+1L]] <- current; current <- integer() }
      current <- c(current,i)
      finish <- if (is.na(end)) start else if (overlaps) max(finish,end) else end
    }
    groups[[length(groups)+1L]] <- current
  }
  events <- lapply(groups,function(idx) {
    event <- rows[idx[1],,drop=FALSE]
    dates <- event_date(rows$start_date[idx]); ends <- event_date(rows$end_date[idx])
    if (any(!is.na(dates))) event$start_date <- min(dates,na.rm=TRUE)
    if (any(!is.na(c(dates,ends)))) event$end_date <- as.character(max(c(dates,ends),na.rm=TRUE))
    event$records <- list(rows[idx,,drop=FALSE]); event
  })
  dplyr::bind_rows(events) %>% dplyr::arrange(dplyr::desc(start_date))
}
# Keep official marks and their edition constraints separate from CV data.
conference_logo <- function(event) {
  file <- file.path(bio_site_root, "data", "conference-logos.json")
  if (!file.exists(file)) return(NULL)
  catalog <- jsonlite::fromJSON(file, simplifyVector=FALSE)
  matches <- Filter(function(entry) {
    cv_text(event$name) %in% unlist(entry$names) &&
      (is.null(entry$year) || cv_text(entry$year) == cv_year(event$start_date))
  }, catalog)
  if (!length(matches)) return(NULL)
  specific <- which(vapply(matches, function(entry) !is.null(entry$year), logical(1)))
  matches[[if (length(specific)) specific[1] else 1]]
}
conference_mark <- function(event, assets="fig") {
  logo <- conference_logo(event)
  if (!is.null(logo)) return(htmltools::tags$a(href=logo$url,
    class="event-logo-link", title=logo$alt,
    htmltools::tags$img(class=if (identical(logo$fit, "left-square")) "event-logo-left" else "event-logo",
      src=paste0(assets,"/logo/",logo$image),alt=logo$alt,loading="lazy")))
  short <- cv_text(event$name)
  if (!nzchar(short)) short <- "Event"
  if (nchar(short) > 16) short <- paste0(substr(strsplit(short," +")[[1]][seq_len(min(4,length(strsplit(short," +")[[1]])))],1,1),collapse="")
  htmltools::tags$span(short)
}
conference_card <- function(event, assets="fig", profiles="", show_people=TRUE) {
  records <- event$records[[1]]
  short <- cv_text(event$name)
  if (!nzchar(short)) short <- "Event"
  logo <- conference_logo(event)
  mark <- conference_mark(event, assets)
  people <- unique(as.character(records$whois_full_name)); people <- people[!is.na(people)&nzchar(people)]
  attendee <- function(person) {
    row <- records[which(records$whois_full_name == person)[1],,drop=FALSE]
    path <- cv_text(row[["file_name"]])
    path <- sub("^subsite/", "", sub("\\.qmd$", "", path))
    if (grepl("^[a-z0-9]+$",path)) path <- paste0(if (cv_text(row[["team"]]) == "colab") "colab/" else "team/",path)
    if (grepl("^(team|colab)/[a-z0-9]+$",path) && file.exists(file.path(bio_site_root,"subsite",paste0(path,".qmd")))) htmltools::tags$a(class="attendee-chip",href=paste0(profiles,path,".html"),person) else htmltools::tags$span(class="attendee-chip",person)
  }
  contributions <- lapply(seq_len(nrow(records)),function(i) {
    row <- records[i,]; kind <- cv_text(row[["type"]])
    htmltools::tags$li(
      if (show_people && nzchar(cv_text(row[["whois_full_name"]]))) htmltools::tags$strong(paste0(cv_text(row[["whois_full_name"]])," · ")),
      htmltools::tags$span(class="contribution-type",tools::toTitleCase(kind)),
      if(nzchar(cv_text(row[["title"]]))) htmltools::tags$p(cv_text(row[["title"]])))
  })
  htmltools::tags$article(class="event-card",
    htmltools::div(class=if (is.null(logo)) "event-mark" else "event-mark has-logo",mark),
    htmltools::div(class="event-content",
      htmltools::tags$p(class="event-date",cv_date_range(event)),
      htmltools::tags$h3(cv_text(event$full_name)), record_place(event,assets),
      if (show_people && length(people)) htmltools::div(class="event-attendees",htmltools::tags$span(class="attendee-label","Attended by"),do.call(htmltools::tagList,lapply(people,attendee))),
      htmltools::tags$details(class="event-contributions",htmltools::tags$summary(paste0("Talks, posters & participation (",nrow(records),")")),do.call(htmltools::tags$ul,contributions))))
}
conference_cards <- function(events, preview=6L, assets="fig", profiles="", show_people=TRUE, archive_label="Earlier events") {
  if (!nrow(events)) return(NULL)
  render <- function(row) conference_card(row,assets,profiles,show_people)
  visible <- seq_len(min(preview,nrow(events)))
  htmltools::div(class="conference-events",
    do.call(htmltools::tagList,lapply(visible,function(i)render(events[i,,drop=FALSE]))),
    cv_year_archive(events[-visible,,drop=FALSE],render,archive_label))
}
