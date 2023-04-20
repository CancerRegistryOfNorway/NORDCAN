##############################################################################
## (3) Generate the NORDCAN statistics tables. This section is time consuming.

## For the computer with limited memory size (RAM), split this section into two
## steps: 
## 1) generate tables containing no survival analysis.
## 2) generate tables containing survival analysis only. 
##
## After running the first step, user need to restart the R (or Rstudio) to release
## computer memory, then escape "step 1", and run "step 2".


## The following 3-line commands need be run for both steps.
output_objects_all <- nordcanepistats::nordcan_statistics_tables_output_object_space()
output_objects_survival <- c("survival_statistics_standardised_survivaltime_05_period_05",
                             "survival_statistics_standardised_survivaltime_05_period_10",
                             "survival_statistics_standardised_survivaltime_10_period_05",
                             "survival_statistics_standardised_survivaltime_10_period_10",
                             
                             "survival_statistics_agespecific_survivaltime_05_period_05",
                             "survival_statistics_agespecific_survivaltime_05_period_10",
                             "survival_statistics_agespecific_survivaltime_10_period_05",
                             "survival_statistics_agespecific_survivaltime_10_period_10")

output_objects_others <- output_objects_all[-which(output_objects_all %in% output_objects_survival)]

##########
## Step 1. 
statistics <- nordcanepistats::nordcan_statistics_tables(
  cancer_record_dataset           = cancer_record_dataset,
  general_population_size_dataset = general_population_size_dataset,
  national_population_life_table  = national_population_life_table,
  cancer_death_count_dataset      = cancer_death_count_dataset,
  stata_exe_path = path_STATA, 
  output_objects = output_objects_others
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


##########
## Step 2. 
statistics <- nordcanepistats::nordcan_statistics_tables(
  cancer_record_dataset           = cancer_record_dataset,
  general_population_size_dataset = general_population_size_dataset,
  national_population_life_table  = national_population_life_table,
  cancer_death_count_dataset      = cancer_death_count_dataset,
  stata_exe_path = path_STATA, 
  output_objects = output_objects_survival
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

## Import pre-saved statistic tables.
statistics_other <- readRDS(paste0("nordcan_", nordcan_version, "_statistics.rds"))
## combine all statistic tables together.
statistics <- c(statistics_other[output_objects_others], statistics)
## Save result to disk, so you can import it later without re-run above codes.
saveRDS(object = statistics, file = paste0("nordcan_", nordcan_version, "_statistics.rds"))
