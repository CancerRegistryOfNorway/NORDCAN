
# libraries --------------------------------------------------------------------
library("git2r")
library("codedoc") # devtools::install_github("WetRobot/codedoc")

# packages ---------------------------------------------------------------------
pkg_nms <- c(
  "nordcancore",
  "nordcanpreprocessing",
  "basicepistats",
  "nordcansurvival",
  "nordcanepistats"
)
pkg_df <- read.csv("packages.csv")
stopifnot(
  pkg_nms %in% pkg_df[["pkg_nm"]]
)
pkg_df <- pkg_df[pkg_df[["pkg_nm"]] %in% pkg_nms, ]

# creds ------------------------------------------------------------------------
# put your ssh dir in this text file. it is ignored by git.
ssh_folder <- readLines("ssh_folder.txt", n = 1L)
public_ssh_key <- paste0(ssh_folder, "id_rsa.pub")
private_ssh_key <- paste0(ssh_folder, "id_rsa")
stopifnot(
  dir.exists(ssh_folder),
  file.exists(public_ssh_key),
  file.exists(private_ssh_key)
)
cred <- git2r::cred_ssh_key(
  publickey = public_ssh_key,
  privatekey = private_ssh_key
)

# clone repos ------------------------------------------------------------------
if (!dir.exists("codedoc")) {
  dir.create("codedoc")
}
invisible(lapply(1:nrow(pkg_df), function(pkg_no) {

  url <- pkg_df[["url"]][pkg_no]
  pkg_nm <- pkg_df[["pkg_nm"]][pkg_no]

  repo_dir <- paste0("codedoc/", pkg_nm)
  if (dir.exists(repo_dir)) {
    message("* pulling from ", url, " to ", repo_dir, "...")
    git2r::pull(repo_dir, credentials = cred)
  } else {
    message("* cloning from ", url, " to ", repo_dir, "...")
    git2r::clone(
      url = url,
      local_path = repo_dir,
      credentials = cred,
      progress = FALSE
    )
  }

  NULL

}))

# form docs --------------------------------------------------------------------
script_file_paths <- dir(
  "codedoc", pattern = "\\.[Rr]$", recursive = TRUE, full.names = TRUE
)
block_df <- codedoc::extract_keyed_comment_blocks_(
  text_file_paths = script_file_paths
)
codedoc_file_name <- "codedoc.html"
codedoc_file_path <- paste0("codedoc/", codedoc_file_name)
message("* building code docs to ", codedoc_file_path)
codedoc::render_codedoc_(
  block_df = block_df,
  template_file_path = NULL,
  render_arg_list = list(
    output_file = codedoc_file_name,
    output_dir = "codedoc",
    output_format = "html_document"
  )
)

