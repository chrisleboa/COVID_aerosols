# Descriptive table 1 stratifying by room location. This spits out a table one as a CSV reporting all the medians and IQU of each sample Type 

# Author: Chris LeBoa 
# Version: 2021-03-25

# Libraries
library(dplyr)
library(ggplot2)
library(reshape2)
library(haven)
library(knitr)
library(tableone)
library(tidyverse)

# Parameters
data_location <- "/Users/ChrisLeBoa/Dropbox/COVID_aerosols/clean data/Final dataset/mergeddata_final.dta"

#table(merged_data$private)
list <-
  c(
    "roomvol",
    "floorarea", 
    "roomheight",
    "popdensityavg",
    "openwinarea",
    "opendoorarea",
    "fan_on",
    "acon_on", 
    "crossvent", 
    "co2average", 
    "Q",
    "ach",
    "ventrateavg"
  )

list_cat <- 
  c("fan_on",
    "acon_on", 
    "crossvent"
    )

list_notnormal <- 
  c(
    "roomvol",
    "floorarea", 
    "roomheight",
    "popdensityavg",
    "openwinarea",
    "opendoorarea",
    "numfanon",
    "numacon", 
    "co2average", 
    "Q",
    "ach",
    "ventrateavg"
  )
#===============================================================================
#Code

merged_data <- 
  read_dta(file = data_location) %>% 
  #filter(ach < 40) %>%  ## removing sample point with really high ACH value 
  mutate(
    any_acon = if_else(numacon > 0 , "has air cond.", "no acon"),
    acon_on =  if_else(numacon > 0 , 1, 0),
    fan_on =  if_else(numfanon > 0 , 1, 0),
    private =
      if_else(
        str_detect(
          hosp,
          "icddr|vercare|quare"), "private", "public"
      ), 
    percent_window_open = (numwinopen / numwintotal *100)
  )


# stratify by locationtype
table_1_locationtype <- CreateTableOne(vars = list,  factorVars = list_cat, strata = "locationtype", data = merged_data)
tab_1_locationtype <- print(table_1_locationtype, nonnormal = list_notnormal, formatOptions = list(big.mark = ","))

# stratify by covidspace
table_1_covidspace <- CreateTableOne(vars = list, strata = "covidspace", data = merged_data)
tab_1_covidspace <- print(table_1_covidspace, nonnormal = list_notnormal, formatOptions = list(big.mark = ","))

# stratify by result
table_1_result <- CreateTableOne(vars = list, factorVars = list_cat, strata = "result", data = merged_data)
tab_1_result <- print(table_1_result, nonnormal = list_notnormal, formatOptions = list(big.mark = ","))

write.csv(tab_1_locationtype, file = "output/tab_1_locationtype.csv")
write.csv(tab_1_covidspace, file = "output/tab_1_covidspace.csv")
write.csv(tab_1_result, file = "output/tab_1_result.csv")

merged_data %>% 
  filter(ventrateavg > 60) %>% 
  count()
