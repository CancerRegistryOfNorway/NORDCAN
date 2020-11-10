

# based on .xlsx files received here:
# https://github.com/CancerRegistryOfNorway/nordcancore/issues/6


# libraries --------------------------------------------------------------------
library("data.table")
library("readxl")

# entity_8.2_vs_9.0.csv --------------------------------------------------------
dt_82_v_90 <- data.table::setDT(readxl::read_xlsx(
  "specifications/Entity.8.2.vs.9.0.xlsx"
))
data.table::setnames(dt_82_v_90, c("value_code", "in 8.2", "in 9.0", "Comment"),
                     c("entity", "in_8.2", "in_9.0", "comment"))
data.table::fwrite(dt_82_v_90, file = "specifications/entity_8.2_vs_9.0.csv",
                   sep = ";")

# icd10_vs_icd67_icd8_icd9.csv -------------------------------------------------
icd_version_dt <- data.table::setDT(readxl::read_xlsx(
  "specifications/ICD10.-.ICD6-7._.ICD8._.ICD9_2020-11-10.xlsx"
))
data.table::setnames(icd_version_dt, c("icd10 term", "icd6-7"),
                     c("icd10_term", "icd67"))
icd_version_dt[, "icd10" := toupper(sub("\\.", "", icd10))]
data.table::fwrite(
  icd_version_dt,
  file = "specifications/icd10_vs_icd67_icd8_icd9.csv",
  sep = ";"
)

# icd10_to_entity_columns.csv --------------------------------------------------
icd_entity_dt <- data.table::setDT(readxl::read_xlsx(
  "specifications/ICD10.-.Entitet_2020-11-10.xlsx"
))
icd_entity_dt[, "icd10" := toupper(sub("\\.", "", icd10))]
data.table::fwrite(
  icd_entity_dt,
  file = "specifications/icd10_to_entity_columns.csv",
  sep = ";"
)

# entity_usage_info.csv --------------------------------------------------------
entity_usage_dt <- data.table::setDT(readxl::read_xlsx(
  "specifications/entity_level_displayorder_2020-11-10.xlsx"
))
data.table::setnames(
  entity_usage_dt,
  names(entity_usage_dt),
  c("entity", "level", "grouping", "display_order", "sex",
    "incidence/prevalence", "mortality", "survival")
)
data.table::fwrite(
  entity_usage_dt,
  file = "specifications/entity_usage_info.csv",
  sep = ";"
)







