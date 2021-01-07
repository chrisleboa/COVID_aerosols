#libraries
library(dataMaid)
library(dplyr)
library(haven)

#import data
d <- read_dta(file = "~/Dropbox/COVID aerosols/clean data/1 4 21/mergeddata_1421.dta")

#filtering to test data only
test <- d %>% filter(sampletype == "TEST")

#make codebook
makeCodebook(test, file = "~/Dropbox/COVID aerosols/codebook/COVID_aerosols_codebook.Rmd", reportTitle = "COVID Aerosols - Merged Data Codebook", replace = T)
