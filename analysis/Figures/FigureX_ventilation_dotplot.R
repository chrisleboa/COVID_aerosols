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
library(tidyverse)

# Parameters
data_location <- "/Users/ChrisLeBoa/Dropbox/COVID_aerosols/clean data/Final dataset/mergeddata_final.dta"

recode_rooms_key <- c(OPD = "Outpatient Department", Other = "Non-Patient Rooms")

plot_labels <-
  c(
  "Non Covid" = "Non-COVID",
  "Non-Patient Rooms" = "Non-Patient\nRoom",
  "Open ward" = "Open\nWard",
  "Outpatient Department" = "Outpatient\nDepartment", 
  "Private room" = "Private\nRoom"
  )

#Code

#Split data by public and private hospitals 
merged_data <- 
  read_dta(file = data_location) %>% 
  #filter(ach < 40) %>%  ## removing sample point with really high ACH value 
  mutate(
    any_acon = if_else(numacon > 0 , "has air cond.", "no acon"),
    private =
      if_else(
        str_detect(
          hosp,
          "icddr|vercare|quare"), "private", "public"
      ), 
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
      ), 
    locationtype = recode(locationtype, !!!recode_rooms_key),
    locationtype = 
      factor(
        locationtype, 
        levels = c("Open ward", "ICU", "Private room", "Outpatient Department", "Non-Patient Rooms"))
  ) 

#merged_data %>% 
 # filter(ventrateavg > 400)

data_covid_non <- 
  merged_data %>% 
  mutate(
    locationtype = covidspace,
    type = "COVID Designation"
    )

data_room <- 
  merged_data %>% 
  mutate(
    type = "Room Type"
  )


plot_data <- 
  bind_rows(data_covid_non, data_room)
  

# Combined data 
plot_data %>% 
  ggplot(aes(x = factor(locationtype), y = ventrateavg)) +
  stat_summary(aes(color = "Median"),fun = "median", size= 0.3, geom = "crossbar") +
  geom_hline(yintercept=60, linetype='dotdash', col = 'red', size = 2) +
  geom_dotplot(aes(fill = vent_group), binwidth = 8, binaxis = "y", dotsize = 1.2,  width = 0.5, stackdir = "center") + 
  #annotate("text", size = 6,  x = "Non COVID", y = 60, label = "Adequate Natural Ventilation", vjust =  - 0.5, hjust = 0.4) +
  scale_fill_manual(values = c("red", "orange", "yellow", "light green", "green")) + 
  facet_grid(.~type, scales = "free", space = "free") + 
  scale_x_discrete(labels = plot_labels) +
  theme_bw(base_size = 16) +
  theme(
    legend.position = "top",
    #axis.text.x = element_text(angle = 45, hjust = 1) 
    # legend.justification = c("left", "top"),
    # legend.box.just = "left",
    # legend.margin = margin(0, 6, 0, 0), 
  ) +
  labs(
    title = "Figure 1: Ventilation Rate by Space Type", 
    y = "Ventilation Rate (L/s/p)", 
    x = "Room Type", 
    fill = "", 
    colour = ""
  )


