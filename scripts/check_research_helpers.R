# Run from the project root with Rscript scripts/check_research_helpers.R.
source("R/resume_fun.R")
invisible(parse(file = "R/create_ppl_page.R"))
papers <- tibble::tibble(
  doi = c("https://doi.org/10.1234/example", "https://doi.org/10.1234/example", "javascript:alert(1)", NA_character_),
  title = c("A <test> & citation", "Duplicate", "Unsafe", "Missing"),
  authors = "Researcher <Example>",
  source_display_name = "Test Journal",
  publication_date = as.Date("2025-01-01")
)
html <- as.character(publication_bibliography(papers))
stopifnot(grepl('href="https://doi.org/10.1234/example"', html, fixed = TRUE))
stopifnot(grepl("A &lt;test&gt; &amp; citation", html, fixed = TRUE))
stopifnot(!grepl("Duplicate|javascript:|Missing", html))
stopifnot(is.null(publication_bibliography(papers[0, ])))
rows <- tibble::tibble(start_date = as.Date("2025-01-01"), end_date = NA_character_, position = "Researcher <test>", group = "BioGenies")
timeline <- as.character(cv_timeline(rows, c("position", "group")))
stopifnot(grepl("Researcher &lt;test&gt;", timeline, fixed = TRUE))
stopifnot(!grepl(">NA<", timeline, fixed = TRUE))
stopifnot(grepl("2025-01-01", timeline, fixed = TRUE))
stopifnot(is.null(cv_timeline(rows[0, ], c("position", "group"))))
cat("Research helper checks passed.\n")
# Seven publications: three visible, four preserved inside the archive, one copy each.
records <- tibble::tibble(
  doi = paste0("https://doi.org/10.1234/item", seq_len(7)),
  title = paste0("Paper ", seq_len(7)), authors = "A. Researcher",
  source_display_name = "Test Journal",
  publication_date = as.Date("2025-01-01") - seq_len(7) * 200
)
compact <- as.character(publication_bibliography(records, preview = 3L))
stopifnot(grepl("Earlier publications (4)", compact, fixed = TRUE))
stopifnot(length(regmatches(compact, gregexpr('class="cv-paper-title"', compact, fixed = TRUE))[[1]]) == 7)
stopifnot(!grepl("datatables", compact, fixed = TRUE))
activities <- tibble::tibble(
  start_date = as.Date("2025-01-01") - seq_len(7) * 180,
  end_date = NA_character_, type = "talk", full_name = paste0("Event ", seq_len(7)),
  title = "A <talk>", city = "City", country = "Country"
)
conference_html <- as.character(cv_conferences(activities))
stopifnot(grepl("Earlier activities (4)", conference_html, fixed = TRUE))
stopifnot(grepl("A &lt;talk&gt;", conference_html, fixed = TRUE))
stopifnot(length(regmatches(conference_html, gregexpr('class="event-card"', conference_html, fixed = TRUE))[[1]]) == 7)
source("R/mobility_summary.R")
activities$team <- "main"
activities$activity <- c(rep("conferences", 5), rep("research stays", 2))
activities$name <- activities$full_name
activities$whois_full_name <- "Researcher"
activities$group <- ""
summary_html <- as.character(team_mobility(activities))
stopifnot(grepl("Countries in our records", summary_html, fixed = TRUE))
stopifnot(!grepl("plotly|leaflet", summary_html))
stopifnot(grepl("Earlier events (2)", summary_html, fixed = TRUE))
cat("Compact CV and mobility checks passed.\n")
career <- tibble::tibble(
  start_date = as.Date("2025-01-01") - seq_len(7) * 200,
  end_date = NA_character_, position = paste("Role", seq_len(7)), group = "Institution"
)
career_html <- as.character(cv_timeline(career, c("position", "group")))
stopifnot(grepl("Earlier records (4)", career_html, fixed = TRUE))
stopifnot(length(regmatches(career_html, gregexpr('class="cv-entry"', career_html, fixed = TRUE))[[1]]) == 7)
cat("Career archive checks passed.\n")

# One edition, multiple attendees and contributions; distinct editions stay separate.
same <- activities[rep(1, 4), ]
same$full_name <- "Shared event"
same$name <- "SE"
same$start_date <- as.Date(c("2025-06-01", "2025-06-02", "2025-10-01", "2026-06-01"))
same$end_date <- c("2025-06-04", "2025-06-03", "2025-10-03", "2026-06-04")
same$country <- c("Polska", "Poland", "Poland", "Online")
same$whois_full_name <- c("Alice", "Bob", "Alice", "Alice")
same$title <- paste("Contribution", 1:4)
events <- conference_events(same)
stopifnot(nrow(events) == 3, sum(vapply(events$records, nrow, integer(1))) == 4)
shared <- events[vapply(events$records, nrow, integer(1)) == 2, ]
shared_html <- as.character(conference_card(shared))
stopifnot(grepl("Alice", shared_html), grepl("Bob", shared_html))
stopifnot(grepl("Contribution 1", shared_html), grepl("Contribution 2", shared_html))
stopifnot(grepl("/flags/pl.svg", shared_html, fixed=TRUE))
stopifnot(normal_country("Polska") == "Poland", normal_country("online") == "Online")
# Different locations do not merge even when names and dates overlap.
other_place <- same[1:2, ]; other_place$city <- c("Warsaw", "Białystok")
stopifnot(nrow(conference_events(other_place)) == 2)
cat("Event aggregation checks passed.\n")

# Incomplete dates are retained without crashing Quarto's render.
undated <- same[1, ]; undated$start_date <- as.Date(NA); undated$end_date <- "ongoing"
stopifnot(nrow(conference_events(undated)) == 1)
stopifnot(is.na(event_date("ongoing")), event_date("18.09.2026") == as.Date("2026-09-18"))
cat("Incomplete event dates handled.\n")

# Attendees with real CV pages link to them, while unknown profiles stay plain text.
linked <- same[1, ]; linked$file_name <- "jc"; linked$team <- "main"
linked_html <- as.character(conference_card(conference_events(linked)))
stopifnot(grepl('href="team/jc.html"', linked_html, fixed=TRUE))
linked$file_name <- "no_such_profile"
stopifnot(!grepl('href=', as.character(conference_card(conference_events(linked))), fixed=TRUE))

# Education must use knitr's HTML-preserving block output, not inline Markdown.
load("data/bg_df_data.RData")
education_html <- as.character(education_panel("Michał"))
stopifnot(grepl('class="record-place"', education_html, fixed=TRUE))
stopifnot(grepl("n-gram analysis of biological sequences", education_html, fixed=TRUE))
knit_education <- knitr::knit(text=c("```{r, echo=FALSE}", 'education_panel("Michał")', "```"), quiet=TRUE)
stopifnot(grepl("<!--html_preserve-->", knit_education, fixed=TRUE))
cat("Education HTML block checks passed.\n")

# Edition-specific conference marks must not leak onto other years.
mark_2024 <- conference_logo(list(name="ISMB",start_date=as.Date("2024-07-12")))
mark_2019 <- conference_logo(list(name="ISMB",start_date=as.Date("2019-07-21")))
stopifnot(mark_2024$year == "2024", is.null(mark_2019$year))
stopifnot(grepl("ismb-2024",mark_2024$image), !grepl("ismb-2024",mark_2019$image))
stopifnot(is.null(conference_logo(list(name="Unknown event",start_date=as.Date("2024-01-01")))))
catalog <- jsonlite::fromJSON(file.path(bio_site_root,"data/conference-logos.json"),simplifyVector=FALSE)
stopifnot(all(vapply(catalog,function(x)file.exists(file.path(bio_site_root,"subsite/fig/logo",x$image)),logical(1))))
cat("Conference logo edition and asset checks passed.\n")
