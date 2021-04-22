##############################
## Install NORDCAN packages ##
##############################

## This section includes 3 tasks:
## (1) Manually specify the path of installation (zip) file. 
## (2) Install NORDCAN packages 
## (3) verify the installation. 

## (1) Manually specify the path of installation (zip) file
path_nordcan_zip <- "P:/Dataflyt/nordcan/version/nordcan_9.0_framework_1.0.4_participant_instructions.zip"

## (2) Install NORDCAN packages.
##  Remove installed (old version) NORDCAN packages. 
nordcan_pkgs <-  c("nordcancore", 
                   "nordcanepistats", 
                   "nordcanpreprocessing", 
                   "nordcansurvival")
remove.packages(nordcan_pkgs)

##  unzip the installation packages to a temporary directory
dir_tmp <- tempdir()
zip::unzip(zipfile = path_nordcan_zip, exdir = dir_tmp)
setwd(paste(dir_tmp, "nordcan_participant_instructions", sep = "/"))

##  install the NORDCAN packages
pkg_paths <- sort(dir(path = "pkgs", pattern = "^pkg_.*.zip$", full.names = TRUE))
for (pkg_path in pkg_paths) {
  clean_pkg_path <- sub("pkg_[0-9]+_", "", pkg_path)
  file.copy(pkg_path, clean_pkg_path)
  install.packages(clean_pkg_path, repos = NULL, type = "win.binary")
  file.remove(clean_pkg_path)
}

## (3) Verify the installation
all_pkg_nms <- installed.packages()[, 1L]
nordcan_pkg_nms <- all_pkg_nms[grepl("^nordcan", all_pkg_nms)]
## Expected package version (take the version of 'nordcancore' as the expected)
expected_pkg_version <- utils::packageVersion("nordcancore")
print(sprintf("The version of 'nordcancore' is: %s", expected_pkg_version))
## version checking for other NORDCAN packages
for (pkg in nordcan_pkg_nms) {
  nordcan_pkg_version <- utils::packageVersion(pkg)
  if (nordcan_pkg_version != expected_pkg_version) {
    message(sprintf("The version of package '%s' is '%s', but should be '%s'!", 
                    pkg, nordcan_pkg_version, expected_pkg_version))
  }
}



#####################################
## NORDCAN data processing starts ...
#####################################

## The processing includes 5 sections:
## (1) Manually specify the paths of 'IARCcrgTools', 'STATA',  
##     raw data (cancer record, etc.), and set up NORDCAN global settings
## (2) Import raw data into R, and pre-process the cancer record (with IARCcrgTools)
##     & cancer death count data.
## (3) Generate the NORDCAN statistics tables. This section is time consuming.
## (4) Compare the new-calculated statistics tables with an older version.
## (5) Save result for archive and sending.


###########################################################
## (1) Manually specify the paths & NORDCAN global settings

path_IARC  <- "C:/Program Files (x86)/IARCcrgTools/IARCcrgTools.EXE"
path_STATA <- "S:/Prog64/STATA/Stata16MP/StataMP-64.exe"

## paths of raw dataset: 
file_incidence  <- "p:/Dataflyt/nordcan/data/2019/incidence_2019.csv"
file_lifetable  <- "p:/Dataflyt/nordcan/data/2019/life_table_2019.csv"
file_population <- "p:/Dataflyt/nordcan/data/2019/population_2019.csv"
file_mortality  <- "p:/Dataflyt/nordcan/data/2019/mortality_2019.csv"

## directory for saving the output of NORDCAN processing.
dir_result <- "p:/Dataflyt/nordcan/user/huti/test2019/"

## directory for holding the archived (.zip) result.
dir_archive <- "p:/Dataflyt/nordcan/user/huti/test2019/"

## path of previous archived result to compared with.
file_archived <- "p:/Dataflyt/nordcan/archive/nordcan_9.0.beta4_statistics_tables.zip"

## Set up global settings. Remember to modify the 'participant_name' and 'last_year_..'
nordcancore::set_global_nordcan_settings(
  work_dir = dir_result,
  participant_name = "Norway", 
  first_year_incidence = 1953L,
  first_year_mortality = 1953L,
  first_year_region    = 1953L,
  last_year_incidence  = 2019L,
  last_year_mortality  = 2019L,
  last_year_survival   = 2019L
)

setwd(dir_result)
nordcan_version <-  nordcancore::nordcan_metadata_nordcan_version()

## Show global setting 
gns <- nordcancore::get_global_nordcan_settings()
gns[c("participant_name", 
      "work_dir", "survival_work_dir", "iarccrgtools_work_dir", 
      "first_year_incidence", "first_year_mortality", "first_year_prevalence", 
      "first_year_region", "first_year_survival", 
      "last_year_incidence", "last_year_mortality", "last_year_survival")]



################################################
## (2) Import raw data into R, and pre-processing

## Read raw data into R
general_population_size_dataset        <- data.table::fread(file_population)
national_population_life_table         <- data.table::fread(file_lifetable)
unprocessed_cancer_record_dataset      <- data.table::fread(file_incidence)
unprocessed_cancer_death_count_dataset <- data.table::fread(file_mortality)

## Pre-process cancer record dataset together with IARCcrgTools.
cancer_record_dataset <- nordcanpreprocessing::nordcan_processed_cancer_record_dataset(
  x = unprocessed_cancer_record_dataset, iarccrgtools_exe_path = path_IARC)

## save to disk.
saveRDS(cancer_record_dataset, "cancer_record_dataset.rds")

## Import above saved 'cancer_record_dataset' from disk for saving time.
# cancer_record_dataset <- data.table::setDT(readRDS("cancer_record_dataset.rds"))


## process cancer death count 
cancer_death_count_dataset <- 
  nordcanpreprocessing::nordcan_processed_cancer_death_count_dataset(
    x = unprocessed_cancer_death_count_dataset
  )

## Export undefined ICD version & codes
if (exists("._undefined")) {
  write.table(._undefined, file = "undefined_icd_version_and_codes.csv", 
              row.names = FALSE, sep = ";")
}

## Export raw records with undefined ICD version & codes
if (exists("._undefined")) {
  names_order <- names(unprocessed_cancer_death_count_dataset)
  tmp <- merge(unprocessed_cancer_death_count_dataset, ._undefined, 
               by = c("icd_version", "icd_code"), all.y = TRUE)
  fn <- "unprocessed_cancer_death_count_dataset_with_undefined_icd_version_and_codes.csv"
  write.table(tmp[, ..names_order], file = fn, row.names = FALSE, sep = ";")
}

## Remove data sets which will not be used in further for saving computer's memory. 
rm(list = c("unprocessed_cancer_record_dataset", 
            "unprocessed_cancer_death_count_dataset"))
gc()



##############################################################################
## (3) Generate the NORDCAN statistics tables. This section is time consuming.

## Run one of the following commands (a, b, c) to set what will be calculated.
## a) Run the following line if you *don't* want to calculate survival statistics. 
output_objects <- c("session_info",
                    "cancer_death_count_dataset",
                    "general_population_size_dataset",
                    "cancer_record_count_dataset",
                    "prevalent_patient_count_dataset",
                    "imp_quality_statistics_dataset" )

## b) Run the following line if you want to calculate survival analysis *only*.
output_objects <- c("survival_statistics_period_5_dataset", 
                    "survival_statistics_period_10_dataset")

## c) Run the following line will generate *all* statistics tables!
output_objects <- NULL

## After choosing one of above 3 output_objects, run the following to start... 
statistics <- nordcanepistats::nordcan_statistics_tables(
  cancer_record_dataset           = cancer_record_dataset,
  general_population_size_dataset = general_population_size_dataset,
  national_population_life_table  = national_population_life_table,
  cancer_death_count_dataset      = cancer_death_count_dataset,
  stata_exe_path = path_STATA, 
  output_objects = output_objects
)

## Checking whether there is any error in 'statistics table'
for (elem_nm in names(statistics))  {
  elem <- statistics[[elem_nm]]
  if (inherits(elem, "error")) {
    message("ERROR: could not produce result ", deparse(elem_nm), "; please ",
            "report the error printed below to the NORDCAN R framework ",
            "maintainers (unless you can see that you have made some mistake)")
    str(elem)
    NULL
  }
}

## Save result to disk, so you can import it later without re-run above codes.
saveRDS(object = statistics, file = paste0("nordcan_", nordcan_version, "_statistics.rds"))



#############################################################
## (4) comparing statistics tables to an older version 

## import old and new version of statistics tables
old_statistics <- nordcanepistats::read_nordcan_statistics_tables(file_archived)

## Read above saved results back into R. 
statistics <- readRDS(paste0("nordcan_", nordcan_version, "_statistics.rds"))

## Define which dataset will be compared. 
ds_nms <- c("cancer_death_count_dataset",
            "cancer_record_count_dataset",
            "prevalent_patient_count_dataset")

## Start the comparison
comparison <- nordcanepistats::compare_nordcan_statistics_table_lists(
  current_stat_table_list = statistics[ds_nms], 
  old_stat_table_list = old_statistics[ds_nms]
)

## An overall summary of all comparisons
comparison$summary

## Plot the comparison in figures (.png). 
nordcanepistats::plot_nordcan_statistics_table_comparisons(comparison)

## An example showing the full comparison details
comparison$comparisons$cancer_record_count_dataset

## showing the comparison by filtering the 'p_value_bh' or 'stat_value'.
comparison$comparisons$cancer_record_count_dataset[p_value_bh < 0.05 | abs(stat_value) > 20,]

## At a minimum you should inspect suspicious results as follows:
top_region <- nordcancore::nordcan_metadata_participant_info()[["topregion_number"]]
comparison$comparisons$cancer_record_count_dataset[
  region == top_region & (p_value_bh < 0.01 | (abs(stat_value) > 100L)),
]
## and
comparison$comparisons$cancer_death_count_dataset[
  region == top_region & (p_value_bh < 0.01 | (abs(stat_value) > 100L)),
]
## and
comparison$comparisons$prevalent_patient_count_dataset[
  region == top_region & (p_value_bh < 0.01 | (abs(stat_value) > 100L)) &
    full_years_since_entry == "0 - 999",
]

## You should deliver this zip to the maintainers of the NORDCAN software
## after examining your results as proof that everything (that has been tested
## at least) is alright.
nordcanepistats::write_maintainer_summary_zip(comparison)



##############################################
## (5) Saving results for archive & sending 

## Save result into a .zip file and move it to 'dir_archive'.
nordcanepistats::write_nordcan_statistics_tables_for_archive(statistics)
## target archive file name
tgt_file_name <- paste0("nordcan_", nordcan_version, "_statistics_tables.zip")
path_src_file <- paste0(dir_result, "nordcan_statistics_tables.zip")
path_tgt_file <- paste0(dir_archive, tgt_file_name)
## move the zip file for archiving. 
if (file.exists(path_tgt_file)) {
  stop("File already exists: ", path_tgt_file)
} else {
  file.rename(from = path_src_file, to = path_tgt_file)
}


## Saving results for sending. The zip created by this function should be sent to IARC.
nordcanepistats::write_nordcan_statistics_tables_for_sending(statistics)





## END OF NORDCAN JOURNEY ##
