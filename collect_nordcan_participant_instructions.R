# Import libraries
library("devtools")
library("git2r")

# This assertion because NORDCAN participants must have R 4.x.x,
# and packages built with an older version R 3.x.x do not work in R 4.x.x
stopifnot(as.integer(R.Version()[["major"]]) >= 4L)

# package data frame 
pkg_df <- read.csv("packages.csv")
pkg_df <- read.csv("packages_gitlab.csv") # specially for norway 

if (!dir.exists("nordcan_participant_instructions")) {
  dir.create("nordcan_participant_instructions")
}
if (dir.exists("nordcan_participant_instructions/pkgs")) {
  unlink("nordcan_participant_instructions/pkgs", recursive = TRUE)
}
dir.create("nordcan_participant_instructions/pkgs")
pkg_df$file_path <- paste0(
  "nordcan_participant_instructions/pkgs/", pkg_df[["file_nm"]]
)

# create "ssh_folder.txt" which contains the folder for your ssh files 
# "ssh_folder.txt" is ignored by git (see .gitignore), so it will not 
# appear on GitHub.
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


# download (+build) packages ---------------------------------------------------
nordcan_version <- NULL 


for (file_no in 1:nrow(pkg_df))  {
  print(file_no)
  file_path <- pkg_df$file_path[file_no]
  zip_path <- sub("\\Q.tar.gz\\E$", ".zip", file_path)
  url <- as.character(pkg_df$url[file_no])
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
      credentials = cred,
      progress = FALSE
    )
    devtools::build(repo_dir, path = zip_path, binary = TRUE, quiet = TRUE)
    message(
      "* building windows binary of ", repo_dir, " to ", zip_path, "..."
    )
    if (grepl("nordcan", url)) {
      Des <- readLines(paste0(repo_dir, "\\DESCRIPTION"))
      ver <- Des[grep("Version: ", Des)]
      v <- gsub("Version: ", "", ver)
      nordcan_version <- c(nordcan_version, v)
    }
    unlink(repo_dir, recursive = TRUE, force = TRUE)
  } else {
    message("* downloading from ", url, " to ", file_path, "...")
    utils::download.file(
      url = url,
      destfile = file_path,
      quiet = TRUE
    )

    if (grepl("\\Q.tar.gz\\E", file_path)) {
      message(
        "* building windows binary of ", file_path, " to ", zip_path, "..."
      )
      repo_dir <- tempdir()
      if (dir.exists(repo_dir)) {
        unlink(repo_dir, recursive = TRUE, force = TRUE)
      }
      dir.create(repo_dir)
      
      devtools::build(
        pkg = file_path,
        path = zip_path,
        binary = TRUE,
        quiet = TRUE
      )
      file.remove(file_path)
    }
  }

  message("* done")
}



if (length(unique(nordcan_version)) != 1) {
  stop("The versions of some NORDCAN package are not consistant!")
}


# compile docs from wiki -------------------------------------------------------
if (dir.exists("wiki")) {
  unlink(x = "wiki", recursive = TRUE, force = TRUE)
}
dir.create("wiki")
git2r::clone(
  "https://github.com/CancerRegistryOfNorway/NORDCAN.wiki.git",
  local_path = "wiki",
  progress = FALSE
)




# If the following block failed, open the rmd file, and run knit in Rstudio
# will do the same work.
# Rememeber to move the html file to correct folder.
repo_dir <- tempdir(); dir.create(repo_dir)
rmarkdown::render(
  input = "nordcan_call_for_data_manual.rmd",
  output_dir = "nordcan_participant_instructions",
  clean = TRUE,
  quiet = FALSE
)

# create release .zip ----------------------------------------------------------
zip::zip(
  zipfile = sprintf(
    "releases/nordcan_%s_%s.zip",
    nordcancore::nordcan_metadata_nordcan_version(),
    unique(nordcan_version)
  ),
  files = dir(
    "nordcan_participant_instructions", full.names = TRUE, recursive = TRUE
  )
)


