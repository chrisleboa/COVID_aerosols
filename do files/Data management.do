clear all
cd "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\clean data\1 4 21"

*room area data
import excel "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\room area.xlsx", sheet("Table 1") firstrow clear

save roomarea, replace

*lab data
import delimited "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\1 4 21\lab data 1 4 21.csv", clear

rename ïsampleid sampleid

rename sampletypetestnegcontrol sampletype
rename sarscov2detectedundetected result
rename rnaextractiondate rnadate

drop if sampleid == ""
duplicates drop

save labdata_1421, replace

*ward data
import delimited "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\1 4 21\ward data 1 4 21.csv", clear

order sampleid, before(dateofcollection)

drop ïstart end generalinformation turnoffbiosamplerandpumpfollowso takeaphotoofthedrawingoftheroomd __version__ _version_ _version__001 _uuid _validation_status _index setupbiosamplerandpumpaccordingt collectionstart collectionmidpoint ventilationmeasures collectionend co2measurements 

rename dateofcollection colldate
rename outdoorco2level outdoorco2
rename hospitalname hosp
rename samplinglocation samploc
rename typeofsamplingspace loctype
rename co2levelatstartofcollectionppm co2start
rename numberofcovidpatients numcovidstart
rename numberofnoncovidpatients numnoncovidstart
rename numberofstaff numstaffstart
rename numberofpeopleotherthanpatientso numotherstart
rename numberofpeoplewearingmasks nummasksstart
rename people_start numpeoplestart
rename numberofpatientsusingnasalcannul numnasal 
rename numberofpatientsusingoxygenmasks numoxymask 
rename numberofpatientsusingcpapnoninva numcpap 
rename numberofpatientsintubated numintub
rename distanceofairsamplerfromnearestp distpatient
rename distanceofairsamplerfromnearestw distwindow 
rename isthenearestwindowopenorclosed nearwindowopen 
rename distanceofairsamplerfromnearestd distdoor
rename isthenearestdooropenorclosed neardooropen
rename numberofcovidpatients15minutes numcovidmid 
rename numberofnoncovidpatients15minute numnoncovidmid
rename numberofstaff15minutes numstaffmid
rename v38 numothermid
rename people_midpoint numpeoplemid
rename numberofwindowsfullyopen numwinfullopen 
rename numberofwindowspartiallyopen numwinpartopen 
rename numberofwindowsclosed numwinclosed
rename windows_open numwinopen 
rename windows_total numwintotal 
rename numberofdoorsfullyopendoorsleadi numdoorfullopen
rename numberofdoorspartiallyopendoorsl numdoorpartopen 
rename numberofdoorscloseddoorsleadingt numdoorclosed 
rename doors_total numdoortotal 
rename doors_open numdooropen
rename totalnumberoffans totfan 
rename numberoffansinoperation numfanon 
rename numberofairconditioningunitsinop numacon 
rename roomwidthfeetconvertinchestodeci roomwidth 
rename roomlengthfeetconvertinchestodec roomlength 
rename roomheightfeetconvertinchestodec roomheight 
rename room_area roomarea
rename v60 tempend
rename v62 humidityend
rename co2levelatendofcollectionppm co2end
rename co2levelat5minutesppm co2_5min 
rename co2levelat10minutesppm co2_10min
rename co2levelat15minutesppm co2_15min
rename co2levelat20minutesppm co2_20min
rename co2levelat25minutesppm co2_25min
rename numberofcovidpatientsendpoint numcovidend 
rename numberofnoncovidpatientsendpoint numnoncovidend 
rename numberofstaffendpoint numstaffend 
rename v66 numotherend 
rename people_end numpeopleend 
rename _submission_time submittime

label var numwinopen "Total number of windows open"
label var numwintotal "Total number of windows"
label var numdooropen "Total number of doors open"
label var numdoortotal "Total number of doors"
label var numpeoplestart "Total number of people in room at start"
label var numpeoplemid "Total number of people in room at midpoint"
label var numpeopleend "Total number of people in room at end"
label var submittime "Time of form submission"
label var tempend "Ambient temperature at end (C)"
label var humidityend "Ambient humidity at end"
label var starttime "Start time of air sampling"
label var endtime "End time of air sampling"

replace hosp = ifotherpleaselisthospitalname if hosp == "Other"
drop ifotherpleaselisthospitalname

replace samploc = ifotherpleasespecifysamplingloca if samploc == "Other"
drop ifotherpleasespecifysamplingloca

replace loctype = ifotherpleasespecify if loctype == "Other"
drop ifotherpleasespecify

*swapping incorrect temp/humidity
gen tempstart = ambienttemperaturec 
gen humiditystart = ambienthumidity
replace tempstart = ambienthumidity if sampleid == "32_DMC1_R3" | sampleid == "36_DMC2_R7"
replace humiditystart = ambienttemperaturec  if sampleid == "32_DMC1_R3" | sampleid == "36_DMC2_R7"
drop ambienttemperaturec ambienthumidity
label var tempstart "Ambient temperature at start (C)"
label var humiditystart "Ambient humidity at start"

*merge in room area sheet 
merge 1:1 sampleid using roomarea
rename roomarea roomvol
label var roomvol "Room volume (ft cub)"
drop _merge

*fix co2 levels
gen fixco2 = outdoorco2 - 410 if outdoorco2 > 430
replace fixco2 = 0 if fixco2 == .
label var fixco2 "Adjustment made to interior CO2 measurements from calibration check"
gen co2startnew = co2start - fixco2
gen co2_5minnew = co2_5min - fixco2
gen co2_10minnew = co2_10min - fixco2
gen co2_15minnew = co2_15min - fixco2
gen co2_20minnew = co2_20min - fixco2
gen co2_25minnew = co2_25min - fixco2
gen co2endnew = co2end - fixco2

label var co2startnew "Clean CO2 measurement at start of sample collection"
label var co2_5minnew "Clean CO2 measurement at 5 minutes"
label var co2_10minnew "Clean CO2 measurement at 10 minutes"
label var co2_15minnew "Clean CO2 measurement at 15 minutes"
label var co2_20minnew "Clean CO2 measurement at 20 minutes"
label var co2_25minnew "Clean CO2 measurement at 25 minutes "
label var co2endnew "Clean CO2 measurement at end of sample collection"
*create co2 average variable
egen co2average = rmean(co2startnew-co2endnew)
label var co2average "Average CO2 measurement over sampling period (using clean measurements)"
*sort by date of collection
sort colldate

*order variables
order outdoorco2 co2start co2_5min-co2_25min co2end fixco2 ///
		co2startnew-co2average , after(loctype)
order starttime endtime, before(notes)
order numcovidmid-numpeoplemid, after(numpeoplestart)
order numcovidend-numpeopleend, after(numpeoplemid)
order tempstart humiditystart, before(tempend)
*save separate ward dataset
save warddata_1421, replace

*merge in lab data
merge 1:1 sampleid using labdata_1421
drop collectionsite roomtype collectiondate _merge

*save merged dataset
save mergeddata_1421, replace

