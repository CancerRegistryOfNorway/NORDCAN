

library("devtools")
library("git2r")

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
    url = "https://cran.r-project.org/bin/windows/contrib/4.0/data.table_1.13.0.zip"
    # url = "https://cran.r-project.org/src/contrib/data.table_1.13.0.tar.gz"
  ),
  data.frame(
    pkg_nm = github_support_pkg_nms,
    url = paste0(
      "git@github.com:WetRobot/", github_support_pkg_nms, ".git"
      )
  ),
  data.frame(
    pkg_nm = github_nordcan_pkg_nms,
    url = paste0(
      "git@github.com:CancerRegistryOfNorway/",
      github_nordcan_pkg_nms,
      ".git"
    )
  )
)

pkg_df[["file_nm"]] <- paste0(
  "pkg_", 1:nrow(pkg_df), "_", pkg_df[["pkg_nm"]],
  rep(c(".zip", ".tar.gz"), times = c(1L, nrow(pkg_df) - 1L))
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

ssh_folder <- readline("ssh_folder = ")
public_ssh_key <- paste0(ssh_folder, "id_rsa.pub")
private_ssh_key <- paste0(ssh_folder, "id_rsa")
stopifnot(
  dir.exists(ssh_folder),
  file.exists(public_ssh_key),
  file.exists(private_ssh_key)
)

invisible(lapply(1:nrow(pkg_df), function(file_no) {
  file_path <- pkg_df[["file_path"]][file_no]
  url <- pkg_df[["url"]][file_no]
  url_ext <- sub(".+\\.(?=[a-z]{3}$)", "", url, perl = TRUE)
  if (url_ext == "git") {
    repo_dir <- tempdir()
    if (dir.exists(repo_dir)) {
      unlink(repo_dir, recursive = TRUE, force = TRUE)
    }
    message("* cloning from ", url, " to ", repo_dir, "...")
    git2r::clone(
      url = url,
      local_path = repo_dir,
      credentials = git2r::cred_ssh_key(
        publickey = public_ssh_key,
        privatekey = private_ssh_key
      ),
      progress = FALSE
    )
    devtools::install_git(repo_dir, upgrade = "never")
    zip_path <- sub("\\Q.tar.gz\\E$", ".zip", file_path)
    devtools::build(repo_dir, path = zip_path, binary = TRUE)
    message(
      "* building windows binary of ", repo_dir, " to ", zip_path, "..."
    )
    unlink(repo_dir, recursive = TRUE, force = TRUE)
  } else {
    message("* downloading from ", url, " to ", file_path, "...")
    utils::download.file(
      url = url,
      destfile = file_path,
      quiet = TRUE
    )

    if (grepl("\\Q.tar.gz\\E", file_path)) {
      install.packages(file_path, repos = NULL, type = "source")
      zip_path <- sub("\\Q.tar.gz\\E$", ".zip", file_path)
      message(
        "* building windows binary of ", file_path, " to ", zip_path, "..."
      )
      devtools::build(
        pkg = file_path,
        path = zip_path,
        binary = TRUE,
        quiet = TRUE
      )
      file.remove(file_path)
    } else {
      # install.packages(file_path, repos = NULL, type = "win.binary")
    }

  }

  message("* done")
}))

if (dir.exists("wiki")) {
  unlink(x = "wiki", recursive = TRUE, force = TRUE)
}
dir.create("wiki")
git2r::clone(
  "https://github.com/CancerRegistryOfNorway/NORDCAN.wiki.git",
  local_path = "wiki"
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


