/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
The following variables should be specified as command-line arguments
 e.g.: ncl file=\"$file\" script.ncl

        precfile (daily precipitation)
        tmaxfile (daily maximum temperature)
        hursfile (daily relative humidity)
	spdfile (daily wind speed)
        output (the file to be written to)

Example of command-line to call cfwi_main:

ncl cfwi_main.ncl tmaxfile=\"tmax.METDATA.22i.1987-1988.nc\" hursfile=\"hurs.METDATA.22i.1987-1988.nc\" spdfile=\"spd.METDATA.22i.1987-1988.nc\" precfile=\"prec.METDATA.22i.1987-1988.nc\" output=\"cfwi.METDATA.22i.1987-1988.nc\"
(note: the two-year timespan includes a year of spinup -- only the second year is actually intended for use)
;/

load "calc_cfwi.ncl"
load "check_time.ncl"
load "clip_time.ncl"

;these are now automatically loaded with versions of NCL 6.5 and up
;load "crop.ncl"		;for use when paths are not set up correctly (the quick and dirty fix)
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/crop.ncl"	;for use in any other situation, aka the proper way

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

begin

r_prec = addfile(precfile, "r")
r_humid = addfile(hursfile, "r")
;r_rhmax = addfile(rhmaxfile, "r")
;r_rhmin = addfile(rhminfile, "r")
r_wdsp = addfile(spdfile, "r")
r_temp = addfile(tmaxfile, "r")

timeW = r_wdsp->time
timeT = r_temp->time
timeH = r_humid->time
timeP = r_prec->time

check = check_time("windspeed", "temperature", timeW, timeT)
check = check + check_time("temperature", "relative humidity", timeT, timeH)
check = check + check_time("relative humidity", "precipitation", timeH, timeP)

maximum = timeW(dimsizes(timeW)-1)
minimum = timeW(0)
if(check .lt. 3) then	;3 is sum of all checks, if any returned 0 then time limits don't match
        clip_time(timeT, minimum, maximum)	;procedure clip_time finds the largest minimum and smallest maximum to find a uniform timeframe across all source files
        clip_time(timeH, minimum, maximum)
        clip_time(timeP, minimum, maximum)
        print("Overlapping time limits are " + minimum + " to " + maximum)
        exit
end if

print("Time limits match on all variables")

system("rm -f "+output)
w_cfwi = addfile(output, "c")

filedimdef(w_cfwi, "time", -1, True)

att_names = getvaratts(r_prec)

do i = 0, dimsizes(att_names) -1 
	w_cfwi@$att_names(i)$ = r_prec@$att_names(i)$
end do

history = "Create " + systemfunc("date") + " by " + systemfunc("whoami") + "@" + systemfunc("hostname") + " using NCL scripts calc_ffmc.ncl, calc_dmc.ncl, calc_dc.ncl, calc_isi.ncl, calc_bui.ncl, and cfwi_main.ncl from source files " + precfile + ", " + hursfile + ", " + spdfile + ", " + tmaxfile
w_cfwi@history = history

;write out variables like lat, lon, time 
var_names = getfilevarnames(r_prec)

do i = 0, dimsizes(var_names)-1
	if(var_names(i) .ne. "prec") then
		w_cfwi->$var_names(i)$ = r_prec->$var_names(i)$
	end if
end do

pr = r_prec->prec
humid = r_humid->hurs

;rhmax = r_rhmax->rhmax		;when hurs (average humidity) is not available, load rhmax and rhmin, and then calculate the simple average
;rhmin = r_rhmin->rhmin
;humid = (rhmin + rhmax) / 2
;humid@units = rhmax@units	;assign metadata for units, which is used in unit conversion

windsp = r_wdsp->spd
;windsp = r_wdsp->sfcWind
temp = r_temp->tmax		;technically supposed to be noon temp, but max temperature is the closest
;temp = r_temp->tasmax
time = r_prec->time

lat = r_prec->lat
lon = r_prec->lon

;units=(/-1, -1, -1, -1/)      ;(/ temp, prec, hum, wind/) (all -1 indicates units taken from metadata)
units= -1	; -1 corresponds to metadata units

option = False
;option@suppressWarning = True

cfwi = calc_cfwi(temp, pr, humid, windsp, time, lat, lon, units, option)

w_cfwi->cfwi = cfwi

end
