/;
2018, Copyright University Corporation for Atmospheric Research
;/

;prevents superfluous errors from clogging up printout during computations
 err = NhlGetErrorObjectId()
  setvalues err
    "errLevel" : "Fatal"          ; only report Fatal errors
  end setvalues

/; 
The following variables should be specified as command-line arguments
 e.g.: ncl file=\"$file\" script.ncl

	precfile (daily precipitation)
	tmaxfile (daily maximum temperature)
	tminfile (daily minimum temperature)
	rhmaxfile (daily maximum relative humidity)
	rhminfile (daily minimum relative humidity)
	grid (NAM-22i, NAM-44i, or custom file path)
	output (file to write out to)

Example of command-line to call fm100_main:

ncl fm100_main.ncl grid=\"NAM-22i\" tmaxfile=\"tmax.METDATA.22i.1987-1988.nc\" tminfile=\"tmin.METDATA.22i.1987-1988.nc\" rhmaxfile=\"rhmax.METDATA.22i.1987-1988.nc\" rhminfile=\"rhmin.METDATA.22i.1987-1988.nc\" precfile=\"prec.METDATA.22i.1987-1988.nc\" output=\"fm100.METDATA.22i.1987-1988.nc\"
(note: the two-year timespan includes a year of spinup -- only the second year is actually intended for use)
;/

load "calc_fm100.ncl"
load "check_time.ncl"
load "clip_time.ncl"

; Calculates fm100, of Fuel Moisture . It is an input to ERC, but is also a standalone fire index.


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

;read in tasmax and tasmin
;read in rhmax and rhmin
;read in precip
;read in precip coefficients

r_tempmax = addfile(tmaxfile, "r")
r_tempmin = addfile(tminfile, "r")
r_hummin = addfile(rhminfile, "r")
r_hummax = addfile(rhmaxfile, "r")
r_pr = addfile(precfile, "r")
;r_z3 = addfile(z3_in, "r")
;r_z3 = addfile("pdur_jolly_regrid.nc", "r")


/;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
timeTA = r_tempmax->time
timeTI = r_tempmin->time
timeHA = r_hummax->time
timeHI = r_hummin->time
timeP = r_pr->time

check = check_time("maximum temperature", "minimum temperature", timeTA, timeTI)
check = check + check_time("minimum temperature", "maximum relative humidity", timeTI, timeHA)
check = check + check_time("maximum relative humidity", "minimum relative humidity", timeHA, timeHI)
check = check + check_time("minimum relative humidity", "precipitation", timeHI, timeP)

maximum = timeTA(dimsizes(timeTA)-1)
minimum = timeTA(0)
if(check .lt. 4) then	;check should sum to 4 if all variables have same time limits
        clip_time(timeTI, minimum, maximum)	;procedure clip_time finds the largest minimum and smallest maximum to find a uniform timeframe across all source files
        clip_time(timeHA, minimum, maximum)
	clip_time(timeHI, minimum, maximum)
        clip_time(timeP, minimum, maximum)
        print("Overlapping time limits are " + minimum + " to " + maximum)
        exit()
end if

print("Time limits match on all variables")
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;/



system("rm -f "+output)
w_fm100 = addfile(output, "c")	;create output file

filedimdef(w_fm100, "time", -1, True) ; make time dimension unlimited

;copy/set global attributes
att_names = getvaratts(r_pr)

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  w_fm100@$att_names(i)$ = r_pr@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL scripts calc_emc.ncl, calc_julian_day.ncl, calc_daylight_builtin.ncl, calc_daylight_manual.ncl, calc_pduration.ncl, calc_fm100.ncl, and fm100_main.ncl, from source files "+precfile+ ", "+tmaxfile+ ", "+tminfile+ ", "+rhminfile+ ", "+ rhmaxfile
w_fm100@history = history

; copy variables

var_names = getfilevarnames(r_pr)

do i = 0, dimsizes(var_names)-1		;attach lat, lon, etc. to the output file
   if (var_names(i) .ne. "prec") then
       w_fm100->$var_names(i)$ = r_pr->$var_names(i)$
   end if
end do

time = r_tempmax->time

maxtemp = r_tempmax->tmax
mintemp = r_tempmin->tmin

minhum = r_hummin->rhmin
maxhum = r_hummax->rhmax

pr = r_pr->prec

;convert_temp("degF", maxtemp)
;convert_temp("degF", mintemp)
;convert_humid("%", minhum)
;convert_humid("%", maxhum)
;convert_prec("inches/day", pr)

lat = r_tempmax->lat
lon = r_tempmax->lon

;units=(/-1, -1, 0, -1, 0/)
units=-1

option = False
;option@suppressWarning = True
;b = r_z3->Z3

fm100 = calc_fm100(maxtemp, mintemp, pr, maxhum, minhum, time, lat, lon, grid, units, option)

w_fm100->fm100 = fm100	;write fm100 data to file
print("wrote out to " + output)
end


