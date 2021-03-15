
#-------------------------------------
# COVID Aerosols analysis

# configure data directories
# source base functions
# load libraries
#-------------------------------------

library(tidyverse)
library(haven)
library(here)

dropboxDir <- NULL
if(dir.exists("/Users/caitlinhemlock/Dropbox/COVID aerosols/")){ 
  dropboxDir <- "/Users/caitlinhemlock/Dropbox/COVID aerosols/"
}
