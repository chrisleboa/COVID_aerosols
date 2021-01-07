cd "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\clean data\1 4 21"
clear all

import delimited "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\1 4 21\lab data 1 4 21.csv"

rename ïsampleid sampleid
drop if sampleid == ""
gen dataset1 = "Lab"
duplicates drop

save labdata_1421, replace

clear all
import delimited "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\1 4 21\ward data 1 4 21.csv"

gen dataset2 = "Ward"

merge 1:1 sampleid using labdata_1421

keep sampleid dataset1 dataset2 sampletypetestnegcontrol dateofcollection
sort sampleid
br

export excel using ///
"\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\sample id merge 12 31.xls", ///
	firstrow(variables) replace
