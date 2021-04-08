library(ggplot2)
library(dplyr)

#import data
source(here::here("configuration.R"))
d <- read_dta(paste0(dropboxDir, "/clean data/Final dataset/mergeddata_final.dta"))
d[d == ""] <- NA

d <- d %>%
  mutate(ventratelog10 = log10(ventrateavg),
         Qlog10 = log10(Q)) 

#sample detection
ggplot(data = d, aes(x = result, y = Qlog10)) + 
  geom_boxplot(outlier.shape = NA) + geom_jitter(aes(color = covidspace)) +
  labs(x = "qPCR RNA detection", y = "Absolute ventilation (log10 L/s)", 
       color = "COVID designation \n for sampling space") +
  theme_minimal() +
  theme(legend.title = element_text(hjust = -1, size = 10),
        legend.position = "top")
