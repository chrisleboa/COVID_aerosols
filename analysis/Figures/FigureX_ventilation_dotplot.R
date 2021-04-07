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
    type = "COVID Patients"
    )

data_room <- 
  merged_data %>% 
  mutate(
    type = "Room Type"
  )


plot_data <- 
  bind_rows(data_covid_non, data_room)
  
# Dotplot by Room Type 
merged_data %>% 
  ggplot(aes(x = factor(locationtype), y = ventrateavg)) +
  stat_summary(aes(color = "Median"),fun = "median", size= 0.3, geom = "crossbar") +
  geom_hline(yintercept=60, linetype='dotdash', col = 'red', size = 2) +
  geom_dotplot(aes(fill = vent_group), binwidth = 10, binaxis = "y", dotsize = 0.8,  width = 0.5, stackdir = "center") + 
  annotate("text", size = 6,  x = "ICU", y = 60, label = "Adequate Natural Ventilation", vjust =  - 0.5, hjust = 0.4) +
  scale_fill_manual(values = c("red", "orange", "yellow", "light green", "green")) + 
  #scale_y_log10() + 
  theme_grey(base_size = 22) +
  theme(
    legend.position = "top",
    # legend.justification = c("left", "top"),
    # legend.box.just = "left",
    # legend.margin = margin(0, 6, 0, 0), 
  ) +
  labs(
    title = "Figure x: Ventilation Rate of Samples", 
    y = "Ventilation Rate (L/s/p)", 
    x = "Room Type", 
    fill = "", 
    colour = ""
  )

#Dotplot by covid space or not 
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
      ), 
    locationtype = recode(locationtype, !!!recode_rooms_key),
    locationtype = factor(locationtype, levels = c("Open ward", "ICU", "Private room", "Outpatient Department", "Non-Patient Rooms"))
  ) %>% 
  ggplot(aes(x = factor(covidspace), y = ventrateavg)) +
  stat_summary(fun = "median", size= 0.3, geom = "crossbar", color = "gray50") +
  geom_hline(yintercept=60, linetype='dotdash', col = 'red', size = 2) +
  geom_dotplot(aes(fill = vent_group), binaxis = "y", stackdir = "center") + 
  annotate("text", size = 7,  x = "Non COVID", y = 60, label = "Adequate Natural Ventilation", vjust =  - 0.5, hjust = 0.4) +
  scale_fill_manual(values = c("red", "orange", "yellow", "light green", "green")) + 
  scale_y_log10() + 
  theme(
    legend.position = c(0.05, .97),
    legend.justification = c("left", "top"),
    legend.box.just = "left",
    legend.margin = margin(6, 6, 6, 6)
  ) +
  theme_grey(base_size = 22) +
  labs(
    title = "Figure x: Ventilation Rate of Samples", 
    y = "Ventilation Rate (L/s/p)", 
    x = "Room Type", 
    fill = "" 
  )


# Combined data 
plot_data %>% 
  ggplot(aes(x = factor(locationtype), y = ventrateavg)) +
  stat_summary(aes(color = "Median"),fun = "median", size= 0.3, geom = "crossbar") +
  geom_hline(yintercept=60, linetype='dotdash', col = 'red', size = 2) +
  geom_dotplot(aes(fill = vent_group), binwidth = 8, binaxis = "y", dotsize = .9,  width = 0.5, stackdir = "center") + 
  #annotate("text", size = 6,  x = "Non COVID", y = 60, label = "Adequate Natural Ventilation", vjust =  - 0.5, hjust = 0.4) +
  scale_fill_manual(values = c("red", "orange", "yellow", "light green", "green")) + 
  facet_grid(.~type, scales = "free", space = "free") + 
  theme_bw(base_size = 12) +
  theme(
    legend.position = "top",
    axis.text.x = element_text(angle = 45, hjust = 1) 
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

#Send Ashley locations where ventrate > 75 

merged_data %>% 
  filter(ventrateavg >75) %>% 
  write_csv("output/vent_rate_high.csv")
