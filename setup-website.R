system("quarto render")

files <- list.files(pattern = ".qmd$", recursive = TRUE)
files <- files[!grepl("_temp.qmd|fun.qmd", files)]

for (f in files) {
  rmarkdown::render(f, output_format = "all")
}

for (file in files) {
  rstudioapi::executeCommand("knitDocument", list(path = file))
}
