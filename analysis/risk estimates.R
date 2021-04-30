library(dplyr)
library(ggplot2)
library(haven)
source(here::here("configuration.R"))

#read in data
d <- read_dta(paste0(dropboxDir, "/clean data/Final dataset/mergeddata_final.dta"))

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
         #repiration rate (liters per minute)
         Qmin = Q * 60, 
         #combine location type assignments
         locationtype.new = ifelse(locationtype == "OPD", "Non-COVID OPD",
                            ifelse(locationtype == "Private room", "COVID Private room",
                            ifelse(locationtype == "ICU" , "COVID ICU",
                         ifelse(covidspace == "COVID", "COVID Open Ward", "Non-COVID Open ward")))))

d %>% group_by(locationtype.new) %>% summarize(median(I))
t <- seq(0, 5*8*60, 1) #time over 40 hours in minutes
p <- 360/60 #respiration rate for adults in liters per minute

#filter OPD and nonOPD to separate datasets to draw values of q
nonOPD <- d %>% 
  filter(locationtype != "OPD") %>%
  select(sampleid, locationtype.new, I, Qmin, result)

OPD <- d %>%
  filter(locationtype == "OPD") %>%
  select(sampleid, locationtype.new, I, Qmin, result)

#simulate
N.sim <- 1000
set.seed(123)
wre <- NULL
for (i in 1:N.sim){
  #randomly draw values of q for each potential infector in the room and take the mean for each simulation
  temp1 <- nonOPD
  for (j in 1:nrow(temp1)) {
    q <- rnorm(n = temp1$I[j], mean = -0.429, sd = 0.720)
    temp1$q[j] <- mean(q)
  }
  
  temp2 <- OPD
  for (j in 1:nrow(temp2)) {
    q <- rnorm(n = temp2$I[j], mean = 0.698, sd = 0.720)
    temp2$q[j] <- mean(q)
  }
  #bind datasets back together
  temp <- rbind(temp1, temp2)
  
  #convert q from log10 normal (per minute)
  temp$q <- (10^(temp$q))/60
  
  #loop through each sampling space and obtain risk estimate per minute
  risk.list <- list(NULL)
  for(j in 1:nrow(temp)){
    risk.est <- data.frame(risk = 1 - exp(-(temp$I[j]*p*temp$q[j]*t)/temp$Qmin[j]),
                           sampleid = temp$sampleid[j],
                           locationtype = temp$locationtype.new[j],
                           t = t,
                           q = temp$q[j],
                           Q = temp$Qmin[j],
                           I = temp$I[j])
    
    #store each space in list
    risk.list[[j]] <- risk.est
  }
  
  #convert list to dataframe
  risk.df <- do.call(rbind, risk.list)
  
  #take mean of each location type per simulation
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
  #convert time to hours for graph
  mutate (t = t/60) %>%
  #obtain median of all simulations by space for graph
  group_by(locationtype, t) %>%
  mutate(overall.med = median(med.risk),
         med.lower = quantile(med.risk, probs = 0.025),
         med.upper = quantile(med.risk, probs = 0.975))

summary <- wre %>%
  summarize(overall.med = median(med.risk),
            med.lower = quantile(med.risk, probs = 0.025),
            med.upper = quantile(med.risk, probs = 0.975))

ggplot(data = wre) +
  #each simulation
  geom_line(aes(x = t, y = med.risk, group = simulation), size = 0.5, alpha = 0.04) +
  #95% confidence interval for overall by space
  geom_ribbon(aes(x = t, ymin = med.lower, ymax = med.upper), 
              fill = "yellow",
              alpha = 0.2) + 
  #median by space
  geom_line(aes(x = t, y = overall.med), color = "yellow", size = 0.5) + 
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
  scale_y_continuous(expand = c(0, 0)) 

 #text
text <- wre %>%
  filter(t == 40) %>%
  group_by(locationtype) %>%
  summarize(risk = signif(median(med.risk)*100, 3), 
            lower = signif(quantile(med.risk, probs = 0.025)*100,3),
            upper = signif(quantile(med.risk, probs = 0.975)*100,3))

#Extra
#
#
#
#
#
#
#
#

#randomly draw values of q based on OPD vs. not
set.seed(123)
N.sim <- 1000
for (j in 1:nrow(nonOPD)) {
  q.est1 <- NULL
  for(i in 1:N.sim){  
    q <- rnorm(n = nonOPD$I[j], mean = -0.429, sd = 0.720)
    q.est1 <- rbind(q.est1, mean(q))
  }
  mean.q <- mean(q.est1)
  nonOPD$q[j] <- mean.q
}

for (j in 1:nrow(OPD)) {
  q.est1 <- NULL
  for(i in 1:N.sim){  
    q <- rnorm(n = OPD$I[j], mean = 0.698, sd = 0.720)
    q.est1 <- rbind(q.est1, mean(q))
  }
  mean.q <- mean(q.est1)
  OPD$q[j] <- mean.q
}

total <- rbind(OPD, nonOPD)
total <- total %>%
  mutate(q = (10^q)/60) %>%
  mutate(risk = 1 - exp(-(I*6*q*2400)/Qmin))

ggplot(data = total) +
  geom_boxplot(aes(x = result, y = risk)) + 
  geom_jitter(aes(x = result, y = risk))


###--------------------------------- by hospital
nonOPD <- d2 %>% 
  filter(locationtype != "OPD") %>%
  select(sampleid, locationtype.new, I, Qmin, hosp, result)

OPD <- d2 %>%
  filter(locationtype == "OPD") %>%
  select(sampleid, locationtype.new, I, Qmin, hosp, result)

#simulate
N.sim <- 100
set.seed(123)
wre <- NULL
for (i in 1:N.sim){
  #randomly draw values of q based on OPD vs. not
  temp1 <- nonOPD
  for (j in 1:nrow(temp1)) {
    q <- rnorm(n = temp1$I[j], mean = -0.429, sd = 0.720)
    temp1$q[j] <- mean(q)
  }
  
  temp2 <- OPD
  for (j in 1:nrow(temp2)) {
    q <- rnorm(n = temp2$I[j], mean = 0.698, sd = 0.720)
    temp2$q[j] <- mean(q)
  }
  
  temp <- rbind(temp1, temp2)
  temp$q <- (10^(temp$q))/60 #quanta per minute
  
  risk.list <- list(NULL)
  for(j in 1:nrow(temp)){
    risk.est <- cbind(risk = 1 - exp(-(temp$I[j]*p*temp$q[j]*t)/temp$Qmin[j]),
                           sampleid = temp$sampleid[j],
                           locationtype = temp$locationtype.new[j],
                           t = t,
                           q = temp$q[j],
                           Q = temp$Qmin[j],
                           I = temp$I[j],
                           hosp = temp$hosp[j],
                           result = temp$result[j])
    
    risk.list[[j]] <- risk.est
  }
  
  risk.df <- do.call(rbind, risk.list)
  
  wre <- rbind(wre, risk.df)
  print(i)
}

wre <- as.data.frame(wre)
wre <- wre %>%
  mutate (t = as.numeric(t),
          risk = as.numeric(risk),
          t = t/60) %>%
  group_by(sampleid, hosp, result, locationtype, t) %>%
  summarize(med.risk = median(risk))

ggplot(data = wre) +
  #geom_vline(xintercept = 8, linetype = "dashed", color = "gray50", size = 0.25) +
  #geom_vline(xintercept = 16, linetype = "dashed", color = "gray50", size = 0.25) +
  #geom_vline(xintercept = 24, linetype = "dashed", color = "gray50", size = 0.25) +
  #geom_vline(xintercept = 32, linetype = "dashed", color = "gray50", size = 0.25) +
  #geom_vline(xintercept = 40, linetype = "dashed", color = "gray50", size = 0.25) +
  #geom_ribbon(aes(x = t, ymin = lower, ymax = upper), fill = "gray", alpha = 0.6) + 
  geom_line(aes(x = as.numeric(t), y = med.risk, group = sampleid, color = result)) +
  #geom_line(aes(x = t, y = overall.med), color = "red", size = 1) + 
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
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_brewer(palette = "Set1")
