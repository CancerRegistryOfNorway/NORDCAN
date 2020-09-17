# NORDCAN

# PREAMBLE - YES WE NORDCAN ---------------------------------------------------
# this script guides you through the process of aggregating statistics for
# NORDCAN. the final result of the script is a bunch of tables that can be
# sent to the maintainer of the web platform. in the current beta test
# nothing will be sent anywhere. instead we only want to ensure that everything
# works as intended.

# before using the NORDCAN R framework, you should make sure you have the latest
# version of R installed and that you can install packages from .tar.gz files
# (so-called "tarballs").
# accompanying this script is a number of .tar.gz files which contain R packages
# necessary to go through the process. the code to install them all can be found
# below.

# we recommend that you have a separate folder somewhere on a hard drive for
# NORDCAN work, e.g. "C:/some/where/nordcan/". for clarity, you should set it as
# the the working directory using setwd() if necessary, so that anything and
# everything that is written to disk is written into the current working
# directory. you must also move all the contents of the instructions you were
# sent, including this script, to the same folder. the following checks that
# you have followed these instructions:
stopifnot(
  "nordcan.R" %in% dir(),
  readLines("nordcan.R", n = 1L) == "# NORDCAN"
)

# throughout this script, any errors (programme terminations) naturally mean that
# one cannot proceed and these should be reported. additionally, no warnings
# are tolerated either because a warning can signify that a programme may finish,
# but produce incorrect results, which is the worst possible outcome. so report
# any warnings as well. messages need not be reported.

# INSTALLING R PACKAGES -------------------------------------------------------

# let's install those R packages. they have a numbered order to ensure correct
# installation.
pkg_paths <- dir(
  path = "pkgs", pattern = "^pkg_[0-9]+_.+\\.zip$", full.names = TRUE
)
invisible(lapply(pkg_paths, function(pkg_path) {
  clean_pkg_path <- sub("pkg_[0-9]+_", "", pkg_path)
  file.rename(pkg_path, clean_pkg_path)
  pkg_nm <- gsub("(\\.zip)|(pkgs[\\/])", "", clean_pkg_path)
  install.packages(clean_pkg_path, repos = NULL, type = "win.binary")
  file.rename(clean_pkg_path, pkg_path)
}))

# it's best to restart R after installing the packages. you only need to install
# them once, unless patched versions of the packages are sent to you.

# NORDCAN CANCER RECORD DATASET ------------------------------------------------

# load your NORDCAN datasets prepared according to to the call for data
# specifications into R somehow. for clarity, use the names
# unprocessed_cancer_record_dataset, general_population_size_dataset, and
# national_population_life_table (+unprocessed_cancer_death_count_dataset,
# if applicable; at the time of writing this, Finland computes death counts
# using their cancer record dataset and does not have this dataset in advance)
# as the names of the objects in R.

# next you need to set global settings for the NORDCAN software so that e.g.
# statistics are only produced for the range of years that you know
# is possible or reasonable. the values in the function call below
# are examples and you should replace them with values that apply to
# your case. the exception is the work_dir: this is recommended to remain
# ".". this causes NORDCAN software to create directories under the
# work_dir to be used for storing files (temporarily) on-disk.
# for more information about the settings, enter this into console:
# ?nordcancore::nordcan_settings
nordcancore::set_global_nordcan_settings(
  work_dir = getwd(),
  participant_name = "Finland",
  stat_cancer_record_count_first_year = 1953L,
  stat_prevalent_subject_count_first_year = 1967L,
  stat_cancer_death_count_first_year = 1953L,
  stat_survival_follow_up_first_year = 1967L
)

# now we assume that you have the correct settings and
# you have the datasets in R as objects by the names given above.
# the command below checks and and adds new columns into your NORDCAN dataset.
# it uses results from IARC CRG Tools. the programme will write files for
# IARC CRG Tools into the folder "iarccrgtools", and you will use IARC CRG Tools
# manually according to the instructions given by the programme. the results
# of IARC CRG Tools will also appear in that folder. the results will be read
# into R by the programme after you give it permission. you need to know
# where the executable for IARC CRG Tools is; here we use an example location.
# the process can take a few minutes.

# if there are problems in your dataset, the original dataset will be returned
# with problematic rows marked clearly in the column named "problem". please
# fix the problems by modifying or dropping rows depending on the problem
# and then run the command again.
processed_cancer_record_dataset <- nordcanpreprocessing::nordcan_processed_cancer_record_dataset(
  x = unprocessed_cancer_record_dataset,
  iarccrgtools_exe_path = "C:/Program Files (x86)/IARCcrgTools/IARCcrgTools.EXE"
)

# it's best to save this on disk so if you come back to it later you don't need
# to re-run everything. but this is an optional step!
saveRDS(
  processed_cancer_record_dataset,
  "processed_cancer_record_dataset.rds"
)
# you can read this back into R using
# processed_cancer_record_dataset <- readRDS("processed_cancer_record_dataset.rds")

# at this point you may, if you wish, save some RAM by removing the
# unprocessed cancer dataset from memory. you do not need it anymore.
rm(list = "unprocessed_cancer_record_dataset")

# STATISTICS -------------------------------------------------------------------

# now you have the processed dataset. time to compute all the different
# statistics! first the counts of cancer deaths.

# You need to form `cancer_death_count_dataset` yourself using the raw data
# you have using one of two methods.
# If you have a dataset of cancer death counts as described in the call for
# data, do

cdcd <- nordcanpreprocessing::nordcan_processed_cancer_death_count_dataset(
  my_raw_cdcd
)

# where `my_raw_cdcd` is your dataset of cancer death counts as per the call
# for data.

# If you want to compute the counts using your cancer record dataset, do

cdcd <- nordcanepistats::nordcanstat_count(
  processed_cancer_record_dataset,
  by = c("sex", "entity", "yoi", "region", "agegroup"),
  subset = processed_cancer_record_dataset$died_from_cancer == TRUE
)
data.table::setnames(
  cdcd, c("N", "yoi"), c("death_count", "year")
)

# where `processed_cancer_record_dataset` is your cancer record dataset after
# processing
# (see [nordcanpreprocessing::nordcan_processed_cancer_record_dataset]),
# and in this example the information on who died of which cancer is identified
# in the logical vector `died_from_cancer`, which you need to define. It should
# be of length `nrow(processed_cancer_record_dataset)`. One person can
# naturally only die once, so there can be at most one `TRUE` value per person.

# now to produce the rest of the statistics.
# the output of the following will be a list, where each element
# of the list is a data.table for one type of statistic, e.g. one table
# for all cancer case counts, one for prevalent patients, etc.
# computing survival uses Stata, so you need to supply the path to your Stata
# executable. the one below is only an example.

# computing survival requires saving a few files into the directory "survival".
# this includes some log files. if you have problems computing survival,
# you will be asked to look at the files and logs there.

statistics <- nordcanepistats::nordcan_statistics_tables(
  cancer_record_dataset = processed_cancer_record_dataset,
  general_population_size_dataset = general_population_size_dataset,
  national_population_life_table = national_population_life_table,
  cancer_death_count_dataset = cancer_death_count_dataset,
  stata_exe_path = "C:/Program Files (x86)/Stata14/StataMP-64.exe"
)

# you may inspect the results as you wish. e.g. here's the table containing
# cancer case counts:
print(statistics[["cancer_case_count_dataset"]])


# and that's all for now. thanks for participating! in the official
# release the a .zuo file will also be created and sent to the maintainer of the
# NORDCAN website. instructions on how to do that will be given at that
# point.







