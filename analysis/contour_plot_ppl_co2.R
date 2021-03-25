# Ventilation Vis
    #A graph of ventilation, CO2 and number of people in a room 
# Author: Christopher LeBoa 
# Version: 2021-03-08

# Libraries
library(tidyverse)
library(haven)

# Parameters
data_location <- "/Users/ChrisLeBoa/Dropbox/COVID_aerosols/clean data/2 25 21/mergeddata_22521.dta"

merged_data <- read_dta(file = data_location)
#===============================================================================
#Code

dataset <- 
  tibble(
  num_people = seq(1,100,5),
  co2 = seq(500, 2400, 100)
)

dataset_expanded <- 
  expand.grid(dataset) %>% 
  mutate(
    co2 = as.double(co2), 
    num_people = as.double(num_people),
    density =  ((10^6 * 0.0052 *  num_people) / (co2 - 410)) 
  )

glimpse(dataset_expanded)



dataset_expanded %>% 
  ggplot(aes(num_people, co2, z = density)) +
  geom_contour_filled(breaks = c(0, 60, 120, 180, 500, 1000, 10000))


