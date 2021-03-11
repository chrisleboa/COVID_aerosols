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

merged_data %>% 
  ggplot(aes(numpeopleavg, co2average)) +
  geom_point()

merged_data %>% 
ggplot( aes(x=numpeopleavg, y=co2average, group=result, fill=result)) +
  geom_line(size=.5) + 
  geom_ribbon(aes(x=numpeopleavg,,ymax=co2average),ymin=0,alpha=0.3) +
  scale_fill_manual(name='', values=c("Detected" = "green4", "Undetected" = "red"))

((10^6 * 0.0052 * numpeopleavg)/(co2average - outdoorco2new))/numpeopleavg

f <- function(x,z) {
  (10^6 * 0.0052 * x) / (z - 400) / x
}

#f2 <- Vectorize(f, )

base <- ggplot()

base + 
  geom_function(fun = f, args = list(z=500)) +
 geom_function(fun = f, args = list(z=1000)) +
 geom_function(fun = f, args = list(z= 1500))
