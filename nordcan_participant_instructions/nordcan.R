# NORDCAN

# PREAMBLE - YES WE NORDCAN ---------------------------------------------------
# this script guides you through the process of aggregating statistics for
# NORDCAN. the final result of the script is a bunch of tables that can be
# sent to the maintainer of the web platform. in the current beta test
# nothing will be sent anywhere. instead we only want to ensure that everything
# works as intended.

# before using the NORDCAN R framework, you should make sure you have the latest
# version of R installed and that you can install packages from .zip files.
# accompanying this script is a number of .zip files which contain R packages
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

# you should have a separate directory for storing .zip files
# containing statistics tables from previous releases. we assume you have the
# directory "nordcan_archive" in the same directory under which the current
# directory is, i.e. if "nordcan" is at "C:/path/to/nordcan/"
# then "nordcan_archive" would be at "C:/path/to/nordcan_archive/"
stopifnot(
  dir.exists("../nordcan_archive")
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

# if you have trouble installing any of the packages, the tried and true method
# is to restart all R sessions you have and try again.

# at this point you should have all the packages installed. this checks
# that the version is correct in each NORDCAN package.
all_pkg_nms <- installed.packages()[, 1L]
nordcan_pkg_nms <- all_pkg_nms[grepl("^nordcan", all_pkg_nms)]
invisible(lapply(nordcan_pkg_nms, function(nordcan_pkg_nm) {
  nordcan_pkg_version <- utils::packageVersion(nordcan_pkg_nm)
  expected_pkg_version <- "1.0.3"
  if (nordcan_pkg_version != expected_pkg_version) {
    stop("Package ", deparse(nordcan_pkg_nm), " has version ", nordcan_pkg_version,
         " but should have version ", expected_pkg_version, "; make sure ",
         "you have used the correct .zip of instructions and that the R ",
         "packages have been installed correctly in the code above. ",
         "best way to try again is to restart R, reinstall, restart R, ",
         "and then try to continue.")
  }
}))

# DATASETS ---------------------------------------------------------------------

# load your NORDCAN datasets prepared according to the call for data
# specifications into R somehow. if you have .csv files, we recommend
# data.table::fread. for clarity, use the names
# unprocessed_cancer_record_dataset, general_population_size_dataset, and
# national_population_life_table  as the names of the objects in R.
# (+unprocessed_cancer_death_count_dataset,
# if applicable; at the time of writing this, Finland computes death counts
# using their cancer record dataset and does not have this dataset in advance)

# so if you are reading in .csv files, the reading in of your datasets into R
# might look like this (and to be clear, .csv files are NOT required and
# you can read your datasets into R any way you want; just please use the
# same names for objects):
# unprocessed_cancer_record_dataset <- data.table::fread(
#   "path/to/unprocessed_cancer_record_dataset.csv"
# )
# general_population_size_dataset <- data.table::fread(
#   "path/to/general_population_size_dataset.csv"
# )
# national_population_life_table <- data.table::fread(
#   "path/to/national_population_life_table.csv"
# )
# unprocessed_cancer_death_count_dataset <- data.table::fread(
#   "path/to/unprocessed_cancer_death_count_dataset.csv"
# )

# SETTINGs ----------------------------------------------------------------

# next you need to set global settings for the NORDCAN software so that e.g.
# statistics are only produced for the range of years that you know
# is possible or reasonable. the values in the function call below
# are examples and you should replace them with values that apply to
# your case. the exception is the work_dir: this is recommended to remain
# as it is. this causes NORDCAN software to create directories under the
# work_dir to be used for storing files (temporarily) on-disk.
# for more information about the settings, enter this into console:
# ?nordcancore::set_global_nordcan_settings
nordcancore::set_global_nordcan_settings(
  work_dir = getwd(),
  participant_name = "Finland",
  stat_cancer_record_count_first_year = 1953L,
  stat_cancer_death_count_first_year = 1953L,
  regional_data_first_year = 1953L,
  last_year = 2019L
)

# PREPROCESSING -----------------------------------------------------------

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
# processed_cancer_record_dataset <- data.table::setDT(readRDS(
#   "processed_cancer_record_dataset.rds"
# ))

# at this point you may, if you wish, save some RAM by removing the
# unprocessed cancer dataset from memory. you do not need it anymore.
rm(list = "unprocessed_cancer_record_dataset")

# STATISTICS - CANCER DEATH COUNT DATASET --------------------------------------

# now you have the processed dataset. time to compute all the different
# statistics! first the counts of cancer deaths.

cancer_death_count_dataset <- nordcanpreprocessing::nordcan_processed_cancer_death_count_dataset(
  unprocessed_cancer_death_count_dataset
)


# STATISTICS --------------------------------------------------------------

# now to produce the rest of the statistics.
# the output of the following will be a list, where each element
# of the list is a data.table for one type of statistic, e.g. one table
# for all cancer case counts, one for prevalent patients, etc.
# computing survival uses Stata, so you need to supply the path to your Stata
# executable. the one below is only an example.

# computing survival requires saving a few files into the directory "survival".
# this includes some log files. if you have problems computing survival,
# you will be asked to look at the files and logs there.

# you don't need to compute survival if you do not intend to send that in the
# call for data. if you wish to compute everything do this:
statistics <- nordcanepistats::nordcan_statistics_tables(
  cancer_record_dataset = processed_cancer_record_dataset,
  general_population_size_dataset = general_population_size_dataset,
  national_population_life_table = national_population_life_table,
  cancer_death_count_dataset = cancer_death_count_dataset,
  stata_exe_path = "C:/Program Files (x86)/Stata14/StataMP-64.exe"
)

# if you do not wish to compute survival, do this:
statistics <- nordcanepistats::nordcan_statistics_tables(
  cancer_record_dataset = processed_cancer_record_dataset,
  general_population_size_dataset = general_population_size_dataset,
  national_population_life_table = national_population_life_table,
  cancer_death_count_dataset = cancer_death_count_dataset,
  stata_exe_path =  "C:/Program Files (x86)/Stata14/StataMP-64.exe",
  output_objects = setdiff(
    nordcanepistats::nordcan_statistics_tables_output_object_space(),
    c("stata_info", "survival_statistics_example",
      "survival_statistics_period_5_dataset",
      "survival_statistics_period_10_dataset")
  )
)


# if any individual table of statistics was not possible to compute, the
# corresponding result will be the error that was encountered. the following
# code will alert you if any statistics table was not produced.

invisible(lapply(names(statistics), function(elem_nm) {
  elem <- statistics[[elem_nm]]
  if (inherits(elem, "error")) {
    message("ERROR: could not produce result ", deparse(elem_nm), "; please ",
            "report the error printed below to the NORDCAN R framework ",
            "maintainers (unless you can see that you have made some mistake)")
    str(elem)
    NULL
  }
}))

# report anything printed by the above command to the maintainers.

# you can look at individual results at this point as you wish, but next up
# is comparing the results to a previous version automatically, which should
# reduce the amount of manual work considerably.

# e.g. here's the table containing cancer case counts:
print(statistics[["cancer_record_count_dataset"]])


# you should save these results so you can come back to them if you need to
# restart R for some reason. this saves the results:
nordcan_version <-  nordcancore::nordcan_metadata_nordcan_version()
saveRDS(
  object = statistics,
  file = paste0("nordcan_", nordcan_version, "_statistics.rds")
)

# uncomment the following to read the results back into R.
# nordcan_version <-  nordcancore::nordcan_metadata_nordcan_version()
# statistics <- readRDS(paste0("nordcan_", nordcan_version, "_statistics.rds"))

# COMPARING STATISTICS TO PREVIOUS VERSION -------------------------------------

# we want to automate inspecting the statistics as much as possible. in what
# follows we compare the newly computed statistics in object "statistics" to
# those from a previous version of NORDCAN.
#
# you will need to know the path to a .zip of a previous NORDCAN version of
# the statistics. this path refers to the zip for version 8.2.
old_statistics <- nordcanepistats::read_nordcan_statistics_tables(
  "../nordcan_archive/nordcan_statistics_tables_8.2.zip"
)

# need to massage the data a bit because of differences between the versions.
ds_nms <- c("cancer_death_count_dataset", "cancer_record_count_dataset",
            "prevalent_patient_count_dataset")
ds_nms <- intersect(names(statistics), ds_nms)
ds_nms <- intersect(names(old_statistics), ds_nms)
statistics_comp <- lapply(statistics[ds_nms], function(dt) {
  dt <- data.table::copy(dt)
  dt_stratum_col_nms <- intersect(
    names(dt),
    nordcancore::nordcan_metadata_column_name_set(
      "column_name_set_stratum_column_name_set"
    )
  )
  if ("agegroup" %in% names(dt)) {
    count_col_nm <- names(dt)[grepl("count", names(dt))]
    stratum_col_nms <- setdiff(names(dt), count_col_nm)
    stopifnot(length(count_col_nm) == 1L)
    dt <- dt[
      j = lapply(.SD, sum),
      .SDcols = count_col_nm,
      keyby = setdiff(stratum_col_nms, "agegroup")
    ]
  }

  return(dt[])
})

old_statistics_comp <- lapply(old_statistics[ds_nms], function(dt) {
  dt <- data.table::copy(dt)
  if ("agegroup18" %in% names(dt)) {
    data.table::setnames(dt, "agegroup18", "agegroup")
  }
  if (is.integer(dt[["full_years_since_entry"]])) {
    dt[, "full_years_since_entry" := factor(
      dt$full_years_since_entry,
      levels = c(1L, 3L, 5L, 10L, 0L),
      labels = c("0", "0 - 2", "0 - 4", "0 - 9", "0 - 999")
    )]
  }
  if ("agegroup" %in% names(dt)) {
    count_col_nm <- names(dt)[grepl("count", names(dt))]
    stratum_col_nms <- setdiff(names(dt), count_col_nm)
    stopifnot(length(count_col_nm) == 1L)
    dt <- dt[
      j = lapply(.SD, sum),
      .SDcols = count_col_nm,
      keyby = setdiff(stratum_col_nms, "agegroup")
    ]
  }
  # 456 incorrect in 8.2
  dt <- dt[entity != 456L, ]
  dt[]
})

comparison <- nordcanepistats::compare_nordcan_statistics_table_lists(
  statistics_comp[ds_nms],
  old_statistics_comp[ds_nms]
)

# the comparison has limitations. if the "old_statistics" does not have
# information for the newest year in "statistics", then that year will not have
# been compared to anything. additionally, statistics produced by 5-year periods
# will all be incomparable in such a situation (e.g. if the latest year is
# 2018 vs. 2019 in the old and current versions, then all the periods are
# different in the two).
#
# the approach taken to detect "substantial" differences is based on statistical
# testing, i.e. the p-value (after adjusting for multiple testing using the
# BH method; see ?p.adjust). this can also have its shortcomings. statistical
# tests may also not even be defined for all the possible statistics
# (at the time of writing this in 2020-10-02, there are no p-values for
# comparing survivals). even if there are no p-values defined for some of
# the comparisons, differences are still calculated and summarised.
#
# you can see an overall summary of all comparisons in
comparison$summary

# a good way of inspecting results is plotting. look at the produced .png files.
nordcanepistats::plot_nordcan_statistics_table_comparisons(comparison)

# you must also look at the individual comparisons and report any suspicious
# ones. e.g.
comparison$comparisons$cancer_record_count_dataset
# contains the individual cancer_record_count comparisons. you can find
# suspicious instances by filtering by adjusted p-value or the difference
# statistic:
comparison$comparisons$cancer_record_count_dataset[
  p_value_bh < 0.05 | abs(stat_value) > 20,
  ]

# at a minimum you should inspect suspcious results as follows:
top_region <- nordcancore::nordcan_metadata_participant_info()[["topregion_number"]]
comparison$comparisons$cancer_record_count_dataset[
  region == top_region & (p_value_bh < 0.01 | (abs(stat_value) > 100L)),
]
# and
comparison$comparisons$cancer_death_count_dataset[
  region == top_region & (p_value_bh < 0.01 | (abs(stat_value) > 100L)),
]
# and
comparison$comparisons$prevalent_patient_count_dataset[
  region == top_region & (p_value_bh < 0.01 | (abs(stat_value) > 100L)) &
    full_years_since_entry == "0 - 999",
]

# note that we did not compare to 8.2 survival here. you'll have to do that
# using the old-fashioned eyeball method.

# INFO TO MAINTAINERS ----------------------------------------------------------

# you should deliver this zip to the maintainers of the NORDCAN software
# after examining your results as proof that everything (that has been tested
# at least) is alright.
nordcanepistats::write_maintainer_summary_zip(comparison)

# SAVING RESULTS FOR ARCHIVE ---------------------------------------------------

# the object "statistics" must be saved so that in a future release you have
# something to compare to (among other reasons). each NORDCAN participant
# must therefore have an archive of previous NORDCAN results as computed
# into the object "statistics". we recommend having a directory outside of the
# current one, i.e. if your current working directory is "nordcan", we recommend
# you have directory "nordcan_archive" for storing previous results in the
# parent directory of "nordcan", e.g. if "nordcan" is at "C:/path/to/nordcan/"
# then "nordcan_archive" would be at "C:/path/to/nordcan_archive/".
#
# you should write the current results into a .zip file using
nordcanepistats::write_nordcan_statistics_tables_for_archive(
  statistics
)
# which creates a .zip file into the current NORDCAN working directory. you
# should move it into your archive directory and give it a suitable
# version number. you can use this code to do that:
archive_zip_src_file_path <- "nordcan_statistics_tables.zip"
archive_zip_tgt_dir <- "../nordcan_archive/"
if (!dir.exists(archive_zip_tgt_dir)) {
  stop("you don't have the nordcan_archive dir this code assumed, so you ",
       "need to copy the file yourself. just be sure to use the same file name",
       "as created below.")
}
archive_zip_tgt_file_name <- paste0(
  "nordcan_",
  nordcancore::nordcan_metadata_nordcan_version(),
  "_statistics_tables.zip"
)
archive_zip_tgt_file_path <- paste0(
  archive_zip_tgt_dir, archive_zip_tgt_file_name
)
if (file.exists(archive_zip_tgt_file_path)) {
  stop("file already exists: ", archive_zip_tgt_file_path)
} else {
  file.copy(from = archive_zip_src_file_path, to = archive_zip_tgt_file_path)
}

# SAVING RESULTS FOR SENDING ---------------------------------------------------

# the zip created by this function should be sent to IARC. instructions on how
# to do that will be supplied separately.
nordcanepistats::write_nordcan_statistics_tables_for_sending(
  statistics
)

# END --------------------------------------------------------------------------

# that's all folks! thank you for participating!







