##############################
## Install NORDCAN packages ##
##############################

## This section includes 3 tasks:
## (1) Manually specify the path of unzipped installation folder.
## (2) Install NORDCAN packages
## (3) verify the installation.

## (1) Manually specify the path of unzipped installation folder.
path_nordcan <- "path/to/nordcan_participant_instructions"
setwd(path_nordcan)

## (2) Install NORDCAN packages.
##  Remove installed (old version) NORDCAN packages.
nordcan_pkgs <-  c("nordcancore",
                   "nordcanepistats",
                   "nordcanpreprocessing",
                   "nordcansurvival")
remove.packages(nordcan_pkgs)

##  Install the NORDCAN packages
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

## Note: recommend restart RStudio to ensure that the packages work as expected!!


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

## To run survival analysis, the disk where STATA is installed should has 2GB
## free space at the minimum!

###########################################################
## (1) Manually specify the paths & NORDCAN global settings

path_IARC  <- "path/to/IARCcrgTools/IARCcrgTools.EXE"
path_STATA <- "path/to/StataMP-64.exe"

## paths of raw dataset 
file_incidence  <- "path/to/incidence_2020.csv"
file_lifetable  <- "path/to/life_table_2020.csv"
file_population <- "path/to/population_2020.csv"
file_mortality  <- "path/to/mortality_2020.csv"

## path of population projection data 
## (if there is no such file, just leave it as it is). 
file_pop_proj   <- "path/to/general_population_projection_dataset.csv"

## directory for saving the output of NORDCAN processing.
dir_result <- "path/to/nordcan2020/"

## directory for holding the archived (.zip) result.
dir_archive <- "path/to/nordcan_archive/"

## path of previous archived statistics result (.zip) to compared with.
stats_archived <- "path/to/previous_statistics_tables.zip"

## Set up global settings. 
## Remember to modify the 'participant_name' and 'last_year_..'
nordcancore::set_global_nordcan_settings(
  work_dir = dir_result,
  participant_name = "Norway", # need to be modified
  first_year_incidence = 1953L,
  first_year_mortality = 1953L,
  first_year_region    = 1953L,
  last_year_incidence  = 2020L,
  last_year_mortality  = 2020L,
  last_year_survival   = 2020L
)

setwd(dir_result)
nordcan_version <-  nordcancore::nordcan_metadata_nordcan_version()

## Show global settings
gns <- nordcancore::get_global_nordcan_settings()
gns[c("participant_name", "work_dir", "survival_work_dir", "iarccrgtools_work_dir",
      "first_year_incidence", 
      "first_year_mortality",
      "first_year_prevalence",
      "first_year_region", 
      "first_year_survival",
      "last_year_incidence", 
      "last_year_mortality", 
      "last_year_survival")]

## Checking whether the directory is empty.
nordcanepistats::dir_check(dir_result, dir_archive)


################################################
## (2) Import raw data into R, and pre-processing

## Read raw data into R.
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
    x = unprocessed_cancer_death_count_dataset)

## Export undefined ICD version & codes.
nordcanepistats::export_undefined() 

## Remove data sets which will not be used in further for saving computer's memory.
rm(list = c("unprocessed_cancer_record_dataset",
            "unprocessed_cancer_death_count_dataset")); 
gc();


##############################################################################
## (3) Generate the NORDCAN statistics tables. This section is time consuming.

## Run one of the following commands (a, b, c) to set what will be calculated.
## a) Run the following line if you *don't* want to calculate survival statistics.
output_objects <- c("session_info",
                    "cancer_death_count_dataset",
                    "general_population_size_dataset",
                    "cancer_record_count_dataset",
                    "prevalent_patient_count_dataset",
                    "imp_quality_general_statistics_dataset",
                    "imp_quality_exclusion_statistics_dataset" )

## b) Run the following line if you want to calculate survival analysis *only*.
output_objects <- c(
  "survival_statistics_standardised_survivaltime_05_period_05",
  "survival_statistics_standardised_survivaltime_05_period_10",
  "survival_statistics_standardised_survivaltime_10_period_05",
  "survival_statistics_standardised_survivaltime_10_period_10",
  
  "survival_statistics_agespecific_survivaltime_05_period_05",
  "survival_statistics_agespecific_survivaltime_05_period_10",
  "survival_statistics_agespecific_survivaltime_10_period_05",
  "survival_statistics_agespecific_survivaltime_10_period_10"
)

## c) Run the following line will generate *all* statistics tables!
output_objects <- NULL


## set "survival_test_sample" to "TRUE" will calculate survival based on a small 
## sample data to get through the calculation quickly.
## You need to set it to "FALSE" to conduct calculation on full dataset. 
survival_test_sample <- TRUE

statistics <- nordcanepistats::nordcan_statistics_tables(
  cancer_record_dataset           = cancer_record_dataset,
  general_population_size_dataset = general_population_size_dataset,
  national_population_life_table  = national_population_life_table,
  cancer_death_count_dataset      = cancer_death_count_dataset,
  stata_exe_path = path_STATA,
  output_objects = output_objects, 
  survival_test_sample = survival_test_sample
)


## Save result to disk, so you can import it later without re-run above codes.
stats_current <- paste0("nordcan_", nordcan_version, "_statistics.rds")
saveRDS(object = statistics, file = stats_current)
## load saved statistics from disk.
# statistics <- readRDS(stats_current)


#############################################################
## (4) comparing statistics tables to an older version

## list which dataset will be compared.
ds_nms <- c("cancer_death_count_dataset",
            "cancer_record_count_dataset",
            "prevalent_patient_count_dataset")

comparison <- nordcanepistats::compare_nordcan_statistics(
  stats_current  = stats_current, 
  stats_archived = stats_archived, 
  ds_nms = ds_nms)

## An overall summary of all comparisons
comparison$summary

## Plot the comparison in figures (.pdf).
nordcanepistats::plot_nordcan_statistics_table_comparisons(comparison)


## An example showing the full comparison details
comparison$comparisons$cancer_record_count_dataset
## showing the comparison by filtering the 'p_value_bh' or 'stat_value'.
comparison$comparisons$cancer_record_count_dataset[p_value_bh < 0.05 | abs(stat_value) > 20,]
## At a minimum you should inspect suspicious results as follows:
top_region <- nordcancore::nordcan_metadata_participant_info()[["topregion_number"]]
comparison$comparisons$cancer_record_count_dataset[
  region == top_region & (p_value_bh < 0.01 | (abs(stat_value) > 100L)),]
## and
comparison$comparisons$cancer_death_count_dataset[
  region == top_region & (p_value_bh < 0.01 | (abs(stat_value) > 100L)),]
## and
comparison$comparisons$prevalent_patient_count_dataset[
  region == top_region & (p_value_bh < 0.01 | (abs(stat_value) > 100L)) & full_years_since_entry == "0 - 999",]


## You should deliver this zipped file to the maintainers of the NORDCAN software
## after checking your results as proof that everything (that has been tested
## at least) is correct.
nordcanepistats::write_maintainer_summary_zip(comparison)



##############################################
## (5) Saving results for archive & sending

## Add population projection file to nordcan statistics tables.
statistics$general_population_projection_dataset <- 
  nordcanepistats::evaluate_population_projection(file_pop_proj)


## Save result into a .zip file 
nordcanepistats::write_nordcan_statistics_tables_for_archive(statistics)
## and move it to 'dir_archive'.
nordcanepistats::move_statistic_tables_zip_to_dir_archive(dir_result, dir_archive)


## Saving results for sending. The zip file created by this function should be sent to IARC.
nordcanepistats::write_nordcan_statistics_tables_for_sending(statistics)


# remove sensitive data in 'dir_result' after running the above line.
nordcanepistats::clean_results()

## END OF NORDCAN JOURNEY ##
