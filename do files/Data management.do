clear all
cd "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\clean data\2 25 21"

*room area data
import excel "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\room area.xlsx", sheet("Table 1") firstrow clear

rename roomarea floorarea
label var floorarea "Floor area (sq ft)"
label var wallarea "Surface area of wall (sq ft)"
drop if sampleid == ""
save roomarea, replace

*room type data
import excel "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\room types.xlsx", firstrow clear

rename iscovid covidspace
rename loctype2 locationtype
drop samploc loctype

save newroomtype, replace

*lab data
import delimited "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\2 25 21\lab data 2 25 21.csv", clear

rename sampletypetestnegcontrol sampletype
rename sarscov2detectedundetected result
rename sarscov2detectedundetectedforn1 n1result
rename sarscov2detectedundetectedn2 n2result
rename rnaextractiondate rnadate

drop if sampleid == "" | sampleid == "Negative control:"
duplicates drop

save labdata_22521, replace

*window data
import delimited "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\2 25 21\windows 2 25 21.csv", clear

rename _submission__id dataid
rename widthofopenwindowwindow_serialin width
replace width = width/12
rename heightofopenwindowwindow_seriali height
replace height = height/12

gen area = width*height
egen openwinarea = sum(area), by(dataid)
label var openwinarea "Total surface area of open windows (sq ft)"

egen tag = tag(dataid)
drop if tag == 0
drop ïwindow_serial width height _index _parent_table_name _parent_index _submission__uuid _submission__submission_time _submission__validation_status area tag

save windows_21721, replace

*door data
import delimited "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\2 25 21\doors 2 25 21.csv", clear

rename _submission__id dataid
rename widthofopendoordoor_serialinches width
replace width = width/12
rename heightofopendoordoor_serialinche height
replace height = height/12

gen area = width*height
egen opendoorarea = sum(area), by(dataid)
label var opendoorarea "Total surface area of open doors (sq ft)"

egen tag = tag(dataid)
drop if tag == 0
drop ïdoor_serial width height _index _parent_table_name _parent_index _submission__uuid _submission__submission_time _submission__validation_status area tag

save doors_21721, replace

*ward data
import delimited "\\Client\C$\Users\caitlinhemlock\Dropbox\COVID aerosols\raw data\2 25 21\ward data 2 25 21.csv", clear

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
rename v60 humidityend
rename v62 tempend
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
replace sampleid = "87_ICD2_R6" if sampleid == "87_IC2_R6"
merge 1:1 sampleid using roomarea
replace floorarea = roomwidth*roomlength if floorarea == .
gen roomvol = floorarea * roomheight
label var roomvol "Room volume (ft cub)"
replace wallarea = ((roomwidth*roomheight)*2) + ((roomlength*roomheight)*2) if wallarea == .
gen surfacearea = wallarea + (floorarea*2)
label var surfacearea "Total area of surfaces in room (sq ft)"
drop _merge

*merge in room type sheet
merge 1:1 sampleid using newroomtype
drop samploc loctype _merge

*merge in windows and doors 
rename _id dataid
merge 1:1 dataid using windows_22521
drop _merge

merge 1:1 dataid using doors_22521
drop _merge dataid

*fix one co2 data entry error 
replace co2end = 427 if co2end == 247

*fix co2 levels
gen fixco2 = outdoorco2 - 410 if outdoorco2 > 430
replace fixco2 = 0 if fixco2 == .
label var fixco2 "Adjustment made to interior CO2 measurements from calibration check"
gen outdoorco2new = outdoorco2 - fixco2
gen co2startnew = co2start - fixco2
gen co2_5minnew = co2_5min - fixco2
gen co2_10minnew = co2_10min - fixco2
gen co2_15minnew = co2_15min - fixco2
gen co2_20minnew = co2_20min - fixco2
gen co2_25minnew = co2_25min - fixco2
gen co2endnew = co2end - fixco2

label var outdoorco2new "Clean outdoor CO2 measurement"
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

*create people average
egen numpeopleavg = rmean(numpeoplestart numpeoplemid numpeopleend)
label var numpeopleavg "Average numer of people in room over sampling period"

*create population density variable
gen popdensitystart = numpeoplestart/roomvol
gen popdensitymid = numpeoplemid/roomvol
gen popdensityend = numpeopleend/roomvol
egen popdensityavg = rmean(popdensitystart popdensitymid popdensityend)
label var popdensitystart "People per cubic foot at start of sample collection"
label var popdensitymid "People per cubic foot at 15 minutes"
label var popdensityend "People per cubic foot at end of sample collection"
label var popdensityavg "Average people per cubic foot over sampling period"

*creation ventilation rate variable
gen ventrate = ((10^6 * 0.0052 * numpeopleavg)/(co2average - outdoorco2new))/numpeopleavg
gen ventrate2 = ((10^6 * 0.0052)/(co2average - outdoorco2new))

*sort by date of collection
sort colldate

*order variables
order roomwidth-roomheight roomvol outdoorco2 co2start /// 
		co2_5min-co2_25min co2end fixco2 co2startnew-co2average, after(loctype)
order starttime endtime, before(notes)
order numcovidmid-numpeoplemid, after(numpeoplestart)
order numcovidend-numpeopleend, after(numpeoplemid)
order numpeopleavg, after(numpeopleend)
order tempstart humiditystart, before(tempend)
order popdensitystart-popdensityavg, after(numpeopleavg)
order openwinarea, after(numwinopen)
order opendoorarea, after(numdooropen)
order floorarea-surfacearea, after(roomvol)
*save separate ward dataset
save warddata_21721, replace

*merge in lab data
merge 1:1 sampleid using labdata_21721
drop collectionsite roomtype collectiondate _merge
drop if colldate == ""

*save merged dataset
save mergeddata_21721, replace

