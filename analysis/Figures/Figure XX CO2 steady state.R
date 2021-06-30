#import data
source(here::here("configuration.R"))

#library(SmartEDA)
library(reshape2)
library(ggplot2)
library(dplyr)

d <- read_dta(paste0(dropboxDir, "/clean data/Final dataset/mergeddata_final.dta"))
d[d == ""] <- NA

d.long <- d %>%
  mutate(time0 = 0,
         time1 = co2_5minnew - co2startnew, 
         time2 = co2_10minnew - co2_5min,
         time3 = co2_15minnew - co2_10min,
         time4 = co2_20minnew - co2_15min,
         time5 = co2_25minnew - co2_20min,
         time6 = co2endnew - co2_25min) %>%
  select(sampleid, locationtype, time0, time1, time2, time3, time4, time5, time6)

d.long <- melt(d.long, id.vars = c("sampleid", "locationtype"))
d.long$variable <- str_remove(d.long$variable, "time")
d.long$variable <- as.numeric(d.long$variable)
d.long$variable <- (d.long$variable - 1) * 5

ggplot(data = d.long) + 
  geom_line(aes(x = variable, y = value, group = sampleid, color = locationtype)) +
  scale_color_brewer(palette = "Set1") +
  theme_minimal() +
  labs(x = "Time in minutes", y = "Difference in CO2 from t(0)", color = "Sampling \nspace")

ggsave(filename = "~/Documents/COVID/co2.jpg",
       width = 10, height = 5)  

