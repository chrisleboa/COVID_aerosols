library(dplyr)
library(ggplot2)
library(haven)
library(viridis)
library(ggpubr)
source(here::here("configuration.R"))

#read in data
d <- read_dta(paste0(dropboxDir, "/clean data/Final dataset/mergeddata_final.dta"))

#clean mask usage data for obs with more masks than people
d <- d %>%
  mutate(nummasksstart = ifelse(nummasksstart > (numpeoplestart - numstaffstart), 
                                (numpeoplestart - numstaffstart), 
                                nummasksstart))

#calculate mean mask usage by hospital to impute missing data
mask.usage <- d %>% filter(locationtype == "OPD") %>% 
  group_by(hosp) %>% 
  summarize(meanmask = mean(nummasksstart/(numpeoplestart-numstaffstart), na.rm = TRUE))

for(i in 1:nrow(d)){
  if(d$locationtype[i] == "OPD" & is.na(d$nummasksstart[i])){
    d$nummasksstart[i] <- as.numeric((d$numpeoplestart[i] - d$numstaffstart[i]) * 
                                       mask.usage[which(mask.usage$hosp == d$hosp[i]),2])
  } 
}

d <- d %>% 
  #filter to only patient-facing locations
  filter(locationtype %in% c("Private room", "Open ward", "OPD", "ICU")) %>%
  #remove spaces with no estimated ventilation (due to no people in the space)
  filter(!is.na(Q)) %>%
  mutate(#assign COVID spaces the number of COVID patients in the room and 3% of 
         #non-staff for OPD, and 1 for non-COVID open wards(for hypothetical scenario)
         I.orig = as.numeric(ifelse(covidspace == "COVID", numcovidavg, 
             ifelse(locationtype == "OPD", (numpeopleavg - numstaffavg)*0.03, 1))),
         #round to nearest value for random draws
         I.round = round(I.orig, 0),
         #round up to 1 for values that were rounded to 0
         I = ifelse(I.round == 0, 1, I.round),
         mask.ratio = nummasksstart/(numpeoplestart - numstaffstart),
         #repiration rate (liters per hour)
         Qhour = Q * 60 * 60, 
         #combine location type assignments
         locationtype.new = ifelse(locationtype == "OPD", "Non-COVID OPD",
                            ifelse(locationtype == "Private room", "COVID Private room",
                            ifelse(locationtype == "ICU" , "COVID ICU",
                         ifelse(covidspace == "COVID", "COVID Open Ward", "Non-COVID Open ward")))))

d %>% group_by(locationtype.new) %>% summarize(median(I))

t <- seq(0, 40, 1) #time over 40 hours
p <- 360 #respiration rate for adults in liters per hour

#filter OPD and nonOPD to separate datasets to draw values of q
nonOPD <- d %>% 
  filter(locationtype != "OPD") %>%
  select(sampleid, locationtype.new, I, Qhour, result, mask.ratio)

OPD <- d %>%
  filter(locationtype == "OPD") %>%
  select(sampleid, locationtype.new, I, Qhour, result, mask.ratio)

#simulate
N.sim <- 1000
set.seed(123)
wre <- NULL
for (i in 1:N.sim){
  #randomly draw values of q for each potential infector in the room and take the mean for each simulation
  temp1 <- nonOPD
  for (j in 1:nrow(temp1)) {
    #draw value of q from resting/breathing distribution
    q <- rnorm(n = temp1$I[j], mean = -0.429, sd = 0.720)
    #remove 0.5 log10 for inpatients (on average 5 days further into disease course) 
    q <- q - 0.5
    #take mean as average value of all q
    temp1$q[j] <- mean(q)
    #exponentiate
    temp1$q[j] <- 10^(temp1$q[j])
  }
  
  temp2 <- OPD
  for (j in 1:nrow(temp2)) {
    #draw value of q from light activity/talking distribution
    q <- rnorm(n = temp2$I[j], mean = 0.698, sd = 0.720)
    #take mean as average value of all q
    temp2$q[j] <- mean(q)
    #exponentiate 
    temp2$q[j] <- 10^(temp2$q[j])
    #reduce q by % mask wearers and surgical mask efficacy
    temp2$q[j] <- temp2$q[j] * (1-(temp2$mask.ratio[j]*0.5))
  }
  #bind datasets back together
  temp <- rbind(temp1, temp2)
  
  #loop through each sampling space and obtain risk estimate per minute
  risk.list <- list(NULL)
  for(j in 1:nrow(temp)){
    risk.est <- data.frame(risk = 1 - exp(-(temp$I[j]*p*temp$q[j]*t)/temp$Qhour[j]),
                           sampleid = temp$sampleid[j],
                           locationtype = temp$locationtype.new[j],
                           t = t,
                           q = temp$q[j],
                           Q = temp$Qhour[j],
                           I = temp$I[j])
    
    #store each space in list
    risk.list[[j]] <- risk.est
  }
  
  #convert list to dataframe
  risk.df <- do.call(rbind, risk.list)
  
  #take mean of each location type (within 1 simulation)
  total <- risk.df %>%
    group_by(locationtype, t) %>%
    summarize(med.risk = median(risk)) %>%
    mutate(simulation = i)
  
  #bind each simulation together
  wre <- rbind(wre, total)
  
  #counter
  print(i)
}

wre <- wre %>%
  #obtain median and CI of distribution of simulations by space for graph
  group_by(locationtype, t) %>%
  mutate(overall.med = median(med.risk),
         med.lower = quantile(med.risk, probs = 0.025),
         med.upper = quantile(med.risk, probs = 0.975))

ggplot(data = wre) +
  #each simulation
  geom_line(aes(x = t, y = med.risk, group = simulation), size = 0.5, alpha = 0.025) +
  #95% confidence interval for overall by space
  geom_line(aes(x = t, y = med.lower), linetype = "dotted", color = "black", size = 1) + 
  geom_line(aes(x = t, y = med.upper), linetype = "dotted", color = "black", size = 1) + 
  #median by space
  geom_line(aes(x = t, y = overall.med), color = "orangered2", size = 1) + 
  #format
  facet_wrap(~ locationtype, nrow = 1) +
  theme_minimal() +
  theme(axis.text = element_text(size = 10),
        strip.text = element_text(size = 10),
        axis.title = element_text(size = 12),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.line = element_line(color = "black"),
        panel.spacing.x = unit(7, "mm")) +
  labs(x = "Hours in space", y = "Risk") +
  scale_x_continuous(expand = c(0, 0)) + 
  scale_y_continuous(expand = c(0, 0), limits = c(0, 0.15)) 

ggsave(filename = "~/Documents/COVID/risk estimates_rev.jpg",
       width = 10, height = 5)
#text
text <- wre %>%
  filter(t == 40) %>%
  group_by(locationtype) %>%
  summarize(risk = signif(median(med.risk)*100, 3), 
            lower = signif(quantile(med.risk, probs = 0.025)*100,3),
            upper = signif(quantile(med.risk, probs = 0.975)*100,3))

###--------------------------------- by each sampling space
openarea.quant <- c(0, quantile(d$totalopenarea[d$totalopenarea>0], 
                                probs = c(0.25,0.5,0.75)))

d2 <- d %>%
  #filter(locationtype == "OPD") %>%
  select(sampleid, locationtype, locationtype.new, I, 
         Qhour, result, numpeopleavg, roomheight, 
         ventrateavg, totalopenarea, mask.ratio) %>%
  mutate(totalopenarea.new = case_when(totalopenarea == openarea.quant[1] ~ 1,
                    totalopenarea > openarea.quant[1] & totalopenarea <=openarea.quant[2] ~ 2,
                  totalopenarea > openarea.quant[2] & totalopenarea <=openarea.quant[3] ~ 3,
                 totalopenarea > openarea.quant[3] & totalopenarea <=openarea.quant[4] ~ 4,
                    TRUE ~ 5))

d2$totalopenarea.new <- factor(d2$totalopenarea.new, levels = c(1:5),
                               labels = c("0",">0 to 2.35",">2.35 to 3.13",">3.13 to 6.82",">6.82"))

#simulate
N.sim <- 1000
set.seed(123)
wre3 <- NULL
total <- list(NULL)
for(j in 1:nrow(d2)){
  risk.list <- list(NULL)
  for (i in 1:N.sim){
  #randomly draw values of q
    if (d2$locationtype[j] == "OPD"){
      q <- rnorm(n = d2$I[j], mean = 0.698, sd = 0.720)
      q <- mean(q)
      q <- 10^q
      q <- q * (1-(d2$mask.ratio[j]*0.5))
    } else {
      q <- rnorm(n = d2$I[j], mean = -0.429, sd = 0.720)
      q <- q - 0.5
      q <- mean(q)
      q <- 10^q
    }
    risk.est <- cbind(risk = 1 - exp(-(d2$I[j]*p*q*t)/d2$Qhour[j]),
                           sampleid = d2$sampleid[j],
                           locationtype = d2$locationtype.new[j],
                           t = t,
                           q = d2$q[j],
                           Q = d2$Qhour[j],
                           I = d2$I[j],
                           hosp = d2$hosp[j],
                           result = d2$result[j],
                           numpeople = d2$numpeopleavg[j],
                           roomheight = d2$roomheight[j],
                           ventrate = d2$ventrateavg[j],
                           totalopenarea = d2$totalopenarea.new[j],
                           simulation = paste(i))
    
    risk.list[[i]] <- risk.est
  }
  
  risk.df <- do.call(rbind, risk.list)
  risk.df <- as.data.frame(risk.df)
  risk.df <- risk.df %>%
    #convert time to hours for graph
    mutate (t = as.numeric(t),
            risk = as.numeric(risk)) %>%
    #obtain median of all simulations by space for graph
    group_by(sampleid, locationtype, t, result, 
             numpeople, roomheight, ventrate, totalopenarea) %>%
    summarize(med.risk = median(risk))
  
  total[[j]] <- risk.df
  print(j)
}

wre3 <- do.call(rbind, total)

wre4 <- wre3 %>%
  mutate(numpeople = as.numeric(numpeople),
         #totalopenarea= as.numeric(totalopenarea),
         #ventrate2 = as.integer(ventrate > 6.63),
         roomheight2 = ifelse(roomheight >= 2.75, "Ceiling height >= 2.75m", "Ceiling height <2.75m")) %>%
  mutate(totalopenarea = factor(totalopenarea, levels = c(1:5),
                            labels = c("0",">0 to 2.35",">2.35 to 3.13",">3.13 to 6.82",">6.82")))

ggplot(data = wre4) +
  #geom_vline(xintercept = 8, linetype = "dashed", color = "gray50", size = 0.25) +
  #geom_vline(xintercept = 16, linetype = "dashed", color = "gray50", size = 0.25) +
  #geom_vline(xintercept = 24, linetype = "dashed", color = "gray50", size = 0.25) +
  #geom_vline(xintercept = 32, linetype = "dashed", color = "gray50", size = 0.25) +
  #geom_vline(xintercept = 40, linetype = "dashed", color = "gray50", size = 0.25) +
  #geom_ribbon(aes(x = t, ymin = lower, ymax = upper), fill = "gray", alpha = 0.6) + 
  geom_line(aes(x = as.numeric(t), y = med.risk, group = sampleid, color = totalopenarea)) + 
  facet_grid(locationtype~roomheight2) +
  labs(color = expression("Total open\nwindow and\ndoor area"*(m^{"2"})),
       x = "Hours in space", y = "Risk") +
  #geom_line(aes(x = t, y = overall.med), color = "red", size = 1) + 
  theme_minimal() +
  scale_x_continuous(expand = c(0, 0)) + 
  scale_y_continuous(expand = c(0, 0)) +
  theme(axis.text = element_text(size = 10),
        strip.text = element_text(size = 10),
        axis.title = element_text(size = 12),
        #panel.grid.major = element_blank(),
        #panel.grid.minor = element_blank(),
        axis.line = element_line(color = "black"),
        panel.spacing = unit(5, "mm")) +
  scale_color_viridis(discrete = T)

ggsave(filename = "~/Documents/COVID/risk ceiling height_rev.jpg",
       width = 6, height = 9)

#---assessing drivers--#
test <- d %>% 
  select(locationtype.new, sampleid, Qhour, I, mask.ratio, Q) %>%
  mutate(
    q = round(ifelse(locationtype.new == "Non-COVID OPD", (10^0.698 * (1-(mask.ratio*0.5))), 10^(-0.429 - 0.5)), 2),
    risk = 1 - exp(-(I*360*q*40)/Qhour),
    q2 = ifelse(locationtype.new == "Non-COVID OPD", q, NA)) %>%
  filter(Q < 9000)

ggplot(data = test) +
  geom_point(aes(x = Q, y = risk, color = I)) +
  facet_wrap(~locationtype.new) +
  scale_color_viridis() +
  labs(x = "Q (L/s)", y = "Risk", color = "Number of infectious individuals") +
  geom_text(aes(label=q2, x = Q, y = risk),hjust=-0.5, vjust=0.5)
