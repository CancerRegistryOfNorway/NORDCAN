
library("git2r")
library("codedoc")
# devtools::install_github("WetRobot/codedoc")

# stop("WIP")

github_nordcan_pkg_nms <- c(
  "nordcancore",
  "nordcanpreprocessing",
  "basicepistats",
  "nordcansurvival",
  "nordcanepistats"
)

pkg_df <- data.frame(
  pkg_nm = github_nordcan_pkg_nms,
  url = paste0(
    "git@github.com:CancerRegistryOfNorway/",
    github_nordcan_pkg_nms,
    ".git"
  )
)

# put your ssh dir in this text file. it is ignored by git.
ssh_folder <- readLines("ssh_folder.txt", n = 1L)
public_ssh_key <- paste0(ssh_folder, "id_rsa.pub")
private_ssh_key <- paste0(ssh_folder, "id_rsa")
stopifnot(
  dir.exists(ssh_folder),
  file.exists(public_ssh_key),
  file.exists(private_ssh_key)
)

if (!dir.exists("codedoc")) {
  dir.create("codedoc")
}

invisible(lapply(1:nrow(pkg_df), function(pkg_no) {

  url <- pkg_df[["url"]][pkg_no]

  repo_dir <- tempdir()
  if (dir.exists(repo_dir)) {
    unlink(repo_dir, recursive = TRUE, force = TRUE)
  }
  on.exit(unlink(repo_dir, recursive = TRUE, force = TRUE))
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
  script_file_paths <- dir(
    repo_dir, pattern = "\\.R$", recursive = TRUE, full.names = TRUE
  )
  block_df <- codedoc::extract_keyed_comment_blocks_(
    text_file_paths = script_file_paths
  )
  codedoc_file_name <- paste0(pkg_df[["pkg_nm"]][pkg_no], ".md")
  codedoc_file_path <- paste0("codedoc/", codedoc_file_name)
  message("* building code docs to ", codedoc_file_path)
  codedoc::render_codedoc_(
    block_df = block_df,
    template_file_path = NULL,
    render_arg_list = list(
      output_file = codedoc_file_name,
      output_dir = "codedoc",
      output_format = "md_document"
    )
  )
  NULL

}))



