# Figure x: Dotplot of ventilation broken down by ward type 

# Author: Chris LeBoa 
# Version: 2021-03-25

# Libraries
library(dplyr)
library(ggplot2)
library(reshape2)
library(haven)
library(knitr)
library(tableone)

# Parameters
data_location <- "/Users/ChrisLeBoa/Dropbox/COVID_aerosols/clean data/Final dataset/mergeddata_final.dta"

merged_data <- 
  read_dta(file = data_location) %>% 
  filter(ach < 40) %>%  ## removing sample point with really high ACH value 
  mutate(
    any_acon = if_else(numacon > 0 , "has air cond.", "no acon"),
    private =
      if_else(
        str_detect(
          hosp,
          "icddr|vercare|quare"), "private", "public"
      )
  )

merged_data$ventrateavg

merged_data %>% 
  mutate(
    vent_group = case_when(
      ventrateavg < 10 ~ "less than 10", 
      ventrateavg > 10 & ventrateavg < 30 ~ "10 to 30", 
      ventrateavg > 30 & ventrateavg < 50 ~ "30 to 50", 
      ventrateavg > 50 & ventrateavg < 60 ~ "50 to 60", 
      ventrateavg > 60 ~ "greater than 60",
    ), 
    vent_group = 
      factor(
        vent_group, levels = c("less than 10", "10 to 30", "30 to 50", "50 to 60", "greater than 60")
      )
  ) %>% 
  ggplot(aes(x = factor(locationtype), y = ventrateavg)) +
  stat_summary(fun = "median", size= 0.3, geom = "crossbar") +
  geom_dotplot(aes(fill = vent_group), binaxis = "y", stackdir = "center") + 
  geom_hline(yintercept=60, linetype='dotted', col = 'red')+
  annotate("text", x = "ICU", y = 60, label = "Adequate Natural Ventilation", vjust =  - 0.5, hjust = 0.2) +
  scale_fill_manual(values = c("red", "orange", "yellow", "light green", "green")) + 
  scale_y_log10() + 
  theme(
    legend.position = c(0.05, .97),
    legend.justification = c("left", "top"),
    legend.box.just = "left",
    legend.margin = margin(6, 6, 6, 6)
  ) +
  labs(
    title = "Figure x: Ventilation Rate of Samples", 
    y = "Ventilation Rate (L/s/p)", 
    x = "Room Type", 
    fill = ""
  )
