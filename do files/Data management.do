clear all
cd "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\clean data\1 4 21"

*room area data
import excel "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\room area.xlsx", sheet("Table 1") firstrow clear

save roomarea, replace

*lab data
import delimited "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\1 4 21\lab data 1 4 21.csv", clear

rename ïsampleid sampleid
drop if sampleid == ""
rename sampletypetestnegcontrol sampletype
rename sarscov2detectedundetected result
rename rnaextractiondate rnadate
duplicates drop

replace result = "Detected" if result == "detected"

save labdata_1421, replace

*ward data
import delimited "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\1 4 21\ward data 1 4 21.csv", clear

drop ïstart end generalinformation 
rename dateofcollection colldate
sort colldate
rename outdoorco2level outdoorco2

rename hospitalname hosp
replace hosp = ifotherpleaselisthospitalname if hosp == "Other"
drop ifotherpleaselisthospitalname

rename samplinglocation samploc
replace samploc = ifotherpleasespecifysamplingloca if samploc == "Other"
drop ifotherpleasespecifysamplingloca

rename typeofsamplingspace loctype
replace loctype = ifotherpleasespecify if loctype == "Other"
drop ifotherpleasespecify

drop setupbiosamplerandpumpaccordingt collectionstart
order sampleid, before(colldate)

gen tempstart = ambienttemperaturec 
gen humiditystart = ambienthumidity
order tempstart humiditystart, after(starttime)

*swapping incorrect temp/humidity
replace tempstart = ambienthumidity if sampleid == "32_DMC1_R3" | sampleid == "36_DMC2_R7"
replace humiditystart = ambienttemperaturec  if sampleid == "32_DMC1_R3" | sampleid == "36_DMC2_R7"
drop ambienttemperaturec ambienthumidity
label var tempstart "Ambient temperature at start (C)"
label var humiditystart "Ambient humidity at start"

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

drop collectionmidpoint 

rename numberofcovidpatients15minutes numcovidmid 
rename numberofnoncovidpatients15minute numnoncovidmid
rename numberofstaff15minutes numstaffmid
rename v38 numothermid
rename people_midpoint numpeoplemid

drop ventilationmeasures

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
label var roomarea "Room area (ft cub)"

*merge in room area sheet 
merge 1:1 sampleid using roomarea

drop collectionend

rename v60 tempend
label var tempend "Ambient temperature at end (C)"
rename v62 humidityend
label var humidityend "Ambient humidity at end"
rename co2levelatendofcollectionppm co2end

drop co2measurements 
rename co2levelat5minutesppm co2_5min 
rename co2levelat10minutesppm co2_10min
rename co2levelat15minutesppm co2_15min
rename co2levelat20minutesppm co2_20min
rename co2levelat25minutesppm co2_25min

rename numberofcovidpatientsendpoint numcovidend 
rename numberofnoncovidpatientsendpoint numnoncovidend 
rename numberofstaffendpoint numstaffend 
rename v66 numotherend 
rename people_end peopleend 

drop turnoffbiosamplerandpumpfollowso takeaphotoofthedrawingoftheroomd __version__ _version_ _version__001 _uuid _validation_status _index

rename _submission_time submittime

*fix co2 levels
gen fixco2 = outdoorco2 - 410 if outdoorco2 > 430
replace fixco2 = 0 if fixco2 == .
gen co2startnew = co2start - fixco2
gen co2_5minnew = co2_5min - fixco2
gen co2_10minnew = co2_10min - fixco2
gen co2_15minnew = co2_15min - fixco2
gen co2_20minnew = co2_20min - fixco2
gen co2_25minnew = co2_25min - fixco2
gen co2endnew = co2end - fixco2

egen co2average = rmean(co2startnew-co2endnew)

save warddata_1421, replace

drop _merge
merge 1:1 sampleid using labdata_1421

drop v14-v29
save mergeddata_1421, replace

