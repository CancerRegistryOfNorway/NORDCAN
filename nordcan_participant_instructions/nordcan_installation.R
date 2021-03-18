##############################
## Install NORDCAN packages ##
##############################

## User need to specify the path to the unziped folder of 
## 'nordcan_participant_instructions'
path_instr <- "C:/Users/huti/Downloads/nordcan_participant_instructions"
setwd(path_instr)

## packages in order;
pkg_paths <- sort(dir(path = "pkgs", pattern = "^pkg_.*.zip$", full.names = TRUE))

## Install packages.
for (pkg_path in pkg_paths) {
  clean_pkg_path <- sub("pkg_[0-9]+_", "", pkg_path)
  file.copy(pkg_path, clean_pkg_path)
  install.packages(clean_pkg_path, repos = NULL, type = "win.binary")
  file.remove(clean_pkg_path)
}


##################################
## version consistance checking ##
##################################

## NORDCAN packages
all_pkg_nms <- installed.packages()[, 1L]
nordcan_pkg_nms <- all_pkg_nms[grepl("^nordcan", all_pkg_nms)]

## Expected package version
expected_pkg_version <- utils::packageVersion("nordcancore")

## version checking
for (pkg in nordcan_pkg_nms) {
  nordcan_pkg_version <- utils::packageVersion(pkg)
  if (nordcan_pkg_version != expected_pkg_version) {
    message(sprintf("The version of package '%s' is '%s', but should be '%s'!", 
                pkg, nordcan_pkg_version, expected_pkg_version))
  }
}





