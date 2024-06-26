/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
The following variables should be specified as command-line arguments
 e.g.: ncl file=\"$file\" script.ncl

        precfile (daily precipitation)
        tmaxfile (daily maximum temperature)
        tminfile (daily minimum temperature)
        rhmaxfile (daily maximum relative humidity)
        rhminfile (daily minimum relative humidity)
	hussfile (daily specific humidity with units kg/kg)
	rsdsfile (daily downwelling shortwave radiation with units W m-2)
	fm100file (daily 100-hour timelag fuel moisture)
	fm1000file (daily 1000-hour timelag fuel moisture)
	fuel_model (laf or any various letter models)
        grid (NAM-22i, NAM-44i, or custom file path)
        output (file to write out to)

Example of command-line to call erc_main:

ncl erc_main.ncl tmaxfile=\"tmax.METDATA.22i.1987-1988.nc\" tminfile=\"tmin.METDATA.22i.1987-1988.nc\" rhmaxfile=\"rhmax.METDATA.22i.1987-1988.nc\" rhminfile=\"rhmin.METDATA.22i.1987-1988.nc\" precfile=\"prec.METDATA.22i.1987-1988.nc\" hussfile=\"huss.METDATA.22i.1987-1988.nc\" fm100file=\"fm100.METDATA.22i.1987-1988.nc\" fm1000file=\"fm1000.METDATA.22i.1987-1988.nc\" rsdsfile=\"rsds.METDATA.22i.1987-1988.nc\" grid=\"NAM-22i\" fuel_model=\"G\" output=\"erc.METDATA.22i.1987-1988.nc\"
(note: the two-year timespan includes a year of spinup -- only the second year is actually intended for use)
;/

load "calc_erc.ncl"
load "check_time.ncl"
load "clip_time.ncl"

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

print(output)

r_pr = addfile(precfile, "r")
r_rad = addfile(rsdsfile, "r")
r_rhmax = addfile(rhmaxfile, "r")
r_rhmin = addfile(rhminfile, "r")
r_tmax = addfile(tmaxfile, "r")
r_tmin = addfile(tminfile, "r")
r_fm1000 = addfile(fm1000file, "r")
r_fm100 = addfile(fm100file, "r")
r_huss = addfile(hussfile, "r")
r_elev = addfile(orogfile, "r")
;r_const = addfile("erc_constants.nc", "r")	; must be in right directory!!

; if fm100 and fm1000 have been calculated, temperature, precipitation, and humidity must already match in every dimension. Only need to check time for specific humidity, solar radiation compared to fm100
timeSH = r_huss->time
timeR = r_rad->time
time100 = r_fm100->time
/;
check = check_time("specific humidity", "solar radiation", timeSH, timeR)
check = check + check_time("solar radiation", "FM100", timeR, time100)

maximum = time100(dimsizes(time100)-1)
minimum = time100(0)
if(check .lt. 2) then           ;procedure clip_time finds the largest minimum and smallest maximum to find a uniform timeframe across all source files
	clip_time(timeSH, minimum, maximum)
	clip_time(timeR, minimum, maximum)
        print("Overlapping time limits are " + minimum + " to " + maximum)
        exit()
end if

print("Time limits match on all variables")

;/

system("rm -f "+output)
w_erc = addfile(output, "c") ;create new file to store erc

filedimdef(w_erc, "time", -1, True) ; make time dimension unlimited

;copy/set global attributes
att_names = getvaratts(r_pr)

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  w_erc@$att_names(i)$ = r_pr@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL scripts erc_main.ncl, calc_julian_day.ncl, calc_vpd.ncl, calc_gsi.ncl, normalize.ncl, find_first.ncl, adjust.ncl, calc_potential_solar.ncl, calc_sow_daily.ncl, calc_pduration.ncl, calc_point_pduration.ncl, calc_paper_pduration.ncl, calc_emc.ncl, calc_x1000.ncl, calc_mcherb.ncl, calc_mcwood.ncl, calc_vegstage.ncl, calc_just_erc.ncl, retrieve_constants.ncl, and calc_erc.ncl, from source file "+precfile+ ", "+rsdsfile+ ", "+rhmaxfile+ ", "+rhminfile+ ", "+tmaxfile+ ", "+tminfile+ ", "+fm1000file+ ", "+fm100file+", "+"pdur_jolly_regrid.nc"+", "+hussfile
w_erc@history = history

; copy variables
var_names = getfilevarnames(r_pr)

do i = 0, dimsizes(var_names)-1
   if (var_names(i) .ne. "prec") then
       w_erc->$var_names(i)$ = r_pr->$var_names(i)$
   end if
end do


; initialize inputs
lat = r_pr->lat
lon = r_pr->lon
time = r_pr->time

maxtC = r_tmax->tmax	;NOTE: temperature is actually needed in Celsius AND Fahrenheit!
mintC = r_tmin->tmin

maxrh = r_rhmax->rhmax
minrh = r_rhmin->rhmin

prec = r_pr->prec
rad = r_rad->rsds
fm1000 = r_fm1000->fm1000       ;calculated in a different file
fm100 = r_fm100->fm100
huss = r_huss->huss
;b = r_z3->Z3
;elev = r_elev->elevation
;elev = r_elev->orog
elev = r_elev->elev
;elev = 500.
;grid = "NAM-22i"
units=-1
;units=(/0,0,0,0,0/)

option = False
;option@suppressWarning = True

erc = calc_erc(maxtC, mintC, prec, maxrh, minrh, rad, huss, fm100, fm1000, elev, time, lat, lon, grid, fuel_model, units, option)

w_erc->erc = erc	;transfer erc data into file

end



