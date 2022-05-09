/;
2018, Copyright University Corporation for Atmospheric Research
;/


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

Example of command-line to call fm1000_main:

ncl fm1000_main.ncl grid=\"NAM-22i\" tmaxfile=\"tmax.METDATA.22i.1987-1988.nc\" tminfile=\"tmin.METDATA.22i.1987-1988.nc\" rhmaxfile=\"rhmax.METDATA.22i.1987-1988.nc\" rhminfile=\"rhmin.METDATA.22i.1987-1988.nc\" precfile=\"prec.METDATA.22i.1987-1988.nc\" output=\"fm1000.METDATA.22i.1987-1988.nc\"
(note: the two-year timespan includes a year of spinup -- only the second year is actually intended for use)
;/

; Calculate fm1000. Independent fire index, also used as an input in ERC

load "check_time.ncl"
load "clip_time.ncl"
load "calc_fm1000.ncl"


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

;read in all inputs
r_tempmax = addfile(tmaxfile, "r")
r_tempmin = addfile(tminfile, "r")
r_hummin = addfile(rhminfile, "r")
r_hummax = addfile(rhmaxfile, "r")
r_pr = addfile(precfile, "r")
;r_z3 = addfile(z3_in, "r")
/;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
if(check .lt. 4) then   ;check should sum to 4 if all variables have same time limits
        clip_time(timeTI, minimum, maximum)     ;procedure clip_time finds the largest minimum and smallest maximum to find a uniform timeframe across all source files
        clip_time(timeHA, minimum, maximum)
        clip_time(timeHI, minimum, maximum)
        clip_time(timeP, minimum, maximum)
        print("Overlapping time limits are " + minimum + " to " + maximum)
        exit()
end if

print("Time limits match on all variables")
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;/
system("rm -f "+output)
w_fm1000 = addfile(output, "c")	;create output file

filedimdef(w_fm1000, "time", -1, True) ; make time dimension unlimited

;copy/set global attributes
att_names = getvaratts(r_pr)

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  w_fm1000@$att_names(i)$ = r_pr@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL scripts calc_emc.ncl, calc_julian_day.ncl, calc_daylight_builtin.ncl, calc_daylight_manual.ncl, calc_pduration.ncl, and fm1000_main, from source files "+precfile+ ", "+tmaxfile+ ", "+tminfile+", " + rhmaxfile+", "+rhminfile
w_fm1000@history = history

; copy variables
var_names = getfilevarnames(r_pr)

do i = 0, dimsizes(var_names)-1
   if (var_names(i) .ne. "prec") then
       w_fm1000->$var_names(i)$ = r_pr->$var_names(i)$
   end if
end do

time = r_tempmax->time
maxtemp = r_tempmax->tmax
mintemp = r_tempmin->tmin

minhum = r_hummin->rhmin
maxhum = r_hummax->rhmax

pr = r_pr->prec

lat = r_tempmax->lat
lon = r_tempmax->lon

;b = r_z3->Z3

;units=(/0, 0, 0, 0, 0/)
units=-1

option = False
;option@suppressWarning = True

mc1000 = calc_fm1000(maxtemp, mintemp, pr, maxhum, minhum, time, lat, lon, grid, units, option)

w_fm1000->fm1000 = mc1000
print("wrote out to " + output)
end

