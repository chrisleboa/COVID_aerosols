library(ggplot2)
library(dplyr)
library(cowplot)
library(gridExtra)
library(ggpubr)

#import data
source(here::here("configuration.R"))
d <- read_dta(paste0(dropboxDir, "/clean data/Final dataset/mergeddata_final.dta"))
d[d == ""] <- NA

d <- d %>%
  mutate(ventratelog10 = log10(ventrateavg),
         Qlog10 = log10(Q)) 

get_legend<-function(myggplot){
  tmp <- ggplot_gtable(ggplot_build(myggplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}

#sample detection
q <- ggplot(data = d, aes(x = result, y = Qlog10)) + 
  geom_boxplot(outlier.shape = NA) + 
  geom_jitter(aes(color = covidspace)) +
  scale_color_manual(values = c("dodgerblue4", "darkorange2")) +
  labs(x = "qPCR RNA detection", y = "Absolute ventilation (log10 L/s)", 
       color = "COVID designation \n for sampling space") +
  theme_bw() +
  theme(legend.title = element_text(hjust = -1, size = 13),
        legend.position = "right",
        legend.text = element_text(size = 13),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 13))

legend <- get_legend(q)
q <- q + theme(legend.position = "none")

ventrate <- ggplot(data = d, aes(x = result, y = ventratelog10)) + 
  geom_boxplot(outlier.shape = NA) + 
  geom_jitter(aes(color = covidspace)) +
  scale_color_manual(values = c("dodgerblue4", "darkorange2")) +
  labs(x = "qPCR RNA detection", y = "Ventilation Rate (log10 L/s/p)", 
       color = "COVID designation \n for sampling space") +
  theme_bw() +
  theme(legend.title = element_text(hjust = -1, size = 13),
        legend.position = "none",
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 13))

ggarrange(q, ventrate, legend, nrow = 1, widths=c(2.3, 2.3, 0.8))

ggsave(filename = "~/Documents/COVID/detection boxplot.jpg",
       width = 11, height = 6)

