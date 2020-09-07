# NORDCAN

# this script guides you through the process of aggregating statistics for
# NORDCAN. the final result of the script is a bunch of tables that will be
# sent to the maintainer of the web platform.

# before using the NORDCAN R framework, you should make sure you have the latest
# version of R installed and that you can install packages from .tar.gz files
# (so-called "tarballs").
# accompanying this script is a number of .tar.gz files which contain R packages
# necessary to go through the process. the code to install them all can be found
# below.

# we recommend that you have a separate folder somewhere on a hard drive for
# NORDCAN work, e.g. "C:/some/where/nordcan/". you should create
# a sub-folder "iarccrgtools" to be used by IARC CRG Tools (e.g.
# "C:/some/where/nordcan/iarccrgtools/"), and "stata_survival" to be used to store
# data for computing survival using Stata (e.g.
# "C:/some/where/nordcan/stata_survival/"). you could use any folder, including
# Windows temporary directories, but this is the way that is the easiest to
# follow, and you can make sure nothing sensitive is written anywhere you
# don't know about.

# in what follows, this script assumes that you have some separate folder for
# NORDCAN work with the sub-directories "iarccrgtools" and "stata_survival", that your
# NORDCAN folder is the current working directory, and that this script and all
# other files that came with it is in your NORDCAN folder.
stopifnot(
  "nordcan.R" %in% dir(),
  dir.exists("iarccrgtools"),
  dir.exists("stata_survival"),
  readLines("nordcan.R", n = 1L) == "# NORDCAN"
)

# INSTALLING R PACKAGES

# let's install those R packages. they have a numbered order to ensure correct
# installation.
pkg_paths <- dir(
  path = "pkgs", pattern = "^pkg_[0-9]+_.+\\.tar\\.gz$", full.names = TRUE
)
install.packages(pkg_paths, repos = NULL)

# it's best to restart R after installing the packages.

# NORDCAN CANCER RECORD DATASET

# load your NORDCAN datasets prepared according to to the call for data
# specifications into R somehow. for clarity, use the names
# unprocessed_cancer_record_dataset, general_population_size_dataset, and
# general_population_survival_dataset (+general_population_death_count_dataset,
# if applicable; at the time of writing this, Finland computes death counts
# using their cancer record dataset and does not have this dataset in advance)
# as the names of the objects in R.

# now we assume you have the datasets in R as objects by the names given above.
# the command below checks and and adds new columns into your NORDCAN dataset.
# it uses results from IARC CRG Tools. the programme will write files for
# IARC CRG Tools into the folder "iarccrgtools", and you will use IARC CRG Tools
# manually according to the instructions given by the programme. the results
# of IARC CRG Tools will also appear in that folder. the results will be read
# into R by the programme after you give it permission. you need to know
# where the executable for IARC CRG Tools is; here we use an example location.
# the process can take a few minutes.
#
# if there are problems in your dataset, the original dataset will be returned
# with problematic rows marked clearly in the column named "problem". please
# fix the problems by modifying or dropping rows depending on the problem
# and then run the command again.
processed_cancer_record_dataset <- nordcanpreprocessing::nordcan_processed_cancer_record_dataset(
  x = unprocessed_cancer_record_dataset,
  iarccrgtools_exe_path = "C:/Program Files (x86)/IARCcrgTools/IARCcrgTools.EXE",
  iarccrgtools_work_dir = "iarccrgtools"
)

# now you have the processed dataset. time to compute all the different
# statistics! the output of the following will be a list, where each element
# of the list is a data.table for one type of statistic, e.g. one table
# for all cancer case counts, one for prevalent patients, etc.
# computing survival uses Stata, so you need to supply the path to your Stata
# executable. the one below is only an example.
# we also supply a working directory for (temporarily) storing data for Stata
# as well as its output. notice that if you don't have a pre-aggregated
# general_population_death_count_dataset, then simply omit it from the list
# of datasets.
statistics <- nordcanepistats::nordcan_statistics(
  datasets = list(
    processed_cancer_record_dataset = processed_cancer_record_dataset,
    general_population_size_dataset = general_population_size_dataset,
    general_population_survival_dataset = general_population_survival_dataset,
    general_population_death_count_dataset = general_population_death_count_dataset
  ),
  stata_exe_path = "C:/Program Files/Stata/stata.exe",
  stata_work_dir = "stata_survival"
)

# you may inspect the results as you wish. e.g. here's the table containing
# cancer case counts:
print(statistics[["cancer_case_count_dataset"]])

# the final step is to create a .zip file containing all the statistics and
# some basic information about your system, R, and R packages (and
# no sensitive information whatsoever, not even hard drive paths)
nordcanepistats::write_nordcan_statistics(
  statistics = statistics,
  file_path = "nordcan_statistics_finland_2020.zip"
)

# and that's all for now. thanks for participating! in the official
# release the resulting .zip file will also be sent to the maintainer of the
# NORDCAN website. instructions on how to do that will be given at that
# point.







