
cran_pkg_nms <- "data.table"

github_support_pkg_nms <- c(
  "dbc",
  "iarccrgtools"
)

github_nordcan_pkg_nms <- c(
  "nordcancore",
  "nordcanpreprocessing",
  "basicepistats",
  "nordcansurvival",
  "nordcanepistats"
)

pkg_df <- rbind(
  data.frame(
    pkg_nm = cran_pkg_nms,
    url = "https://cran.r-project.org/bin/windows/contrib/4.0/data.table_1.13.0.tar.gz"
  ),
  data.frame(
    pkg_nm = github_support_pkg_nms,
    url = paste0(
      "https://github.com/WetRobot/",
      github_support_pkg_nms,
      "/tarball/release"
    )
  ),
  data.frame(
    pkg_nm = github_nordcan_pkg_nms,
    url = paste0(
      "https://github.com/CancerRegistryOfNorway/",
      github_nordcan_pkg_nms,
      "/tarball/release"
    )
  )
)

pkg_df[["file_nm"]] <- paste0(
  "pkg_", 1:nrow(pkg_df), "_", pkg_df[["pkg_nm"]], ".tar.gz"
)

if (!dir.exists("nordcan_participant_instructions")) {
  dir.create("nordcan_participant_instructions")
}
if (!dir.exists("nordcan_participant_instructions/pkgs/")) {
  dir.create("nordcan_participant_instructions/pkgs")
}
pkg_df[["file_path"]] <- paste0(
  "nordcan_participant_instructions/pkgs/", pkg_df[["file_nm"]]
)

invisible(lapply(1:nrow(pkg_df), function(file_no) {
  message("* downloading from ", pkg_df[["url"]][file_no], "...")
  utils::download.file(
    url = pkg_df[["url"]][file_no],
    destfile = pkg_df[["file_path"]][file_no],
    quiet = TRUE
  )
  message("* done")
}))

if (dir.exists("wiki")) {
  unlink(x = "wiki", recursive = TRUE, force = TRUE)
}
dir.create("wiki")
system(
  "git clone git@github.com:CancerRegistryOfNorway/NORDCAN.wiki.git --depth 1 wiki"
)
rmarkdown::render(
  input = "nordcan_call_for_data_manual.rmd",
  output_dir = "nordcan_participant_instructions",
  clean = TRUE,
  quiet = TRUE
)

utils::zip(
  zipfile = "nordcan_participant_instructions.zip",
  files = dir("nordcan_participant_instructions", full.names = TRUE, recursive = TRUE)
)


