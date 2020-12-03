




# info -------------------------------------------------------------------------
# this script assumes you have the latest nordcancore package installed.
# nordcancore::nordcan_metadata_nordcan_version() has to be correct.





# packages ---------------------------------------------------------------------
library("git2r")





# tag repos --------------------------------------------------------------------
pkg_df <- data.frame(
  pkg_nm = c(
    "nordcancore",
    "nordcanpreprocessing",
    "nordcansurvival",
    "nordcanepistats"
  )
)
pkg_df$url <- paste0(
  "git@github.com:CancerRegistryOfNorway/",
  pkg_df$pkg_nm,
  ".git"
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
ssh_cred <- git2r::cred_ssh_key(
  publickey = public_ssh_key,
  privatekey = private_ssh_key
)
nordcan_version <- nordcancore::nordcan_metadata_nordcan_version()
pkg_version <- utils::packageVersion("nordcancore")
nordcan_tag <- paste0("nordcan_", nordcan_version)
pkg_tag <- paste0("pkg_", pkg_version)
if (!dir.exists("tmp")) {
  dir.create("tmp")
}
# each repo is downloaded and the same tags are applied. note that this is done
# for the latest commit --- ensure that is what you actually want.
invisible(lapply(1:nrow(pkg_df), function(pkg_no) {
  pkg_nm <- pkg_df[["pkg_nm"]][pkg_no]
  message("* pkg_nm = ", pkg_nm)
  url <- pkg_df[["url"]][pkg_no]
  repo_dir <- paste0("tmp/", pkg_nm)
  if (dir.exists(repo_dir)) {
    unlink(repo_dir, recursive = TRUE, force = TRUE)
  }
  message("* cloning from ", url, " to ", repo_dir, "...")
  git2r::clone(
    url = url,
    local_path = repo_dir,
    credentials = ssh_cred,
    progress = FALSE
  )
  existing_tags <- names(git2r::tags(repo_dir))
  if (!nordcan_tag %in% existing_tags) {
    message("* applying nordcan_tag = ", nordcan_tag)
    git2r::tag(repo_dir, name = nordcan_tag)
    message("* pushing nordcan_tag = ", nordcan_tag)
    refspec <- paste0("refs/tags/", nordcan_tag)
    git2r::push(repo_dir, refspec = refspec, credentials = ssh_cred)
  } else {
    message("* nordcan_tag = ", nordcan_tag, " already existed, skipping")
  }
  if (!pkg_tag %in% existing_tags) {
    message("* applying pkg_tag = ", pkg_tag)
    git2r::tag(repo_dir, name = pkg_tag)
    message("* pushing pkg_tag = ", pkg_tag)
    refspec <- paste0("refs/tags/", pkg_tag)
    git2r::push(repo_dir, refspec = refspec, credentials = ssh_cred)
  } else {
    message("* pkg_tag = ", pkg_tag, " already existed, skipping")
  }
  NULL
}))
if (dir.exists("tmp")) {
  unlink("tmp", force = TRUE, recursive = TRUE)
}























