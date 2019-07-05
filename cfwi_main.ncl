/;
2018, Copyright University Corporation for Atmospheric Research
;/


load "calc_ffmc.ncl"
load "calc_dmc.ncl"
load "calc_dc.ncl"
load "calc_isi.ncl"
load "calc_bui.ncl"
load "convert_temp.ncl"
load "convert_prec.ncl"
load "convert_humid.ncl"
load "calc_cfwi.ncl"
load "check_time.ncl"
load "clip_time.ncl"

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

; main body of code (finally)
; command line inputs are: precfile = daily precipitation
;			hursfile = daily relative humidity
;			spdfile = wind speed in m/s
;			tmaxfile = daily maximum temperature

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

var_names = getfilevarnames(r_prec)

do i = 0, dimsizes(var_names)-1
	if(var_names(i) .ne. "prec") then
		w_cfwi->$var_names(i)$ = r_prec->$var_names(i)$
	end if
end do

pr = r_prec->prec
convert_prec("mm/day", pr)
humid = r_humid->hurs
;rhmax = r_rhmax->rhmax
;rhmin = r_rhmin->rhmin
;humid = (rhmin + rhmax) / 2
;humid@units = rhmax@units
convert_humid("%", humid)
windsp = r_wdsp->spd
temp = r_temp->tmax		;technically supposed to be noon temp, but max temperature is the closest
convert_temp( "degC", temp)	; convert anything into Celsius if not already
time = r_prec->time

lat = r_prec->lat
lon = r_prec->lon

cfwi = calc_cfwi(time, temp, humid, windsp, pr, lat, lon)

w_cfwi->cfwi = cfwi

end
