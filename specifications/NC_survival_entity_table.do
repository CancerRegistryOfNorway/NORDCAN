version 17

log using NC_survival_entity_table.log , text replace

clear

local URL https://raw.githubusercontent.com/CancerRegistryOfNorway/NORDCAN/master/specifications/entity_usage_info.csv

insheet using "`URL'", delim(";")

keep if survival == "true" 

assert incidenceprevalence == "true"
assert mortality == "true"

isid entity

drop incidenceprevalence mortality survival

gen str3 entity_str = string(entity,"%03.0f")
assert !mi(entity_str)
tempfile entity_usage_info
sort entity

rename level entity_level
replace entity_level = "entity_" + entity_level  

levelsof entity_level
local levels = subinstr(ustrregexra(`"`r(levels)'"', "[^\d\s]+",""), " ", ", ", .)
label var entity_level "{ entity_level_`levels' }"

rename grouping entity_group 
levelsof entity_group 
local levels = subinstr(ustrregexra(`"`r(levels)'"', "['`]", ""), char(34)+char(32), char(34)+", ",.)
label var entity_group `"{ `levels' }"'

assert inlist(sex, 0, 1, 2)
lab var sex "{ 0=both, 1=male, 2=female }" 

order entity entity_str entity_description_en
compress
sort entity
isid entity

char define _dta[source] `"`URL'"'

compress
datasignature set

save "NC_survival_entity_table.dta" , replace

log close

exit 















