/;
2018, Copyright University Corporation for Atmospheric Research
;/


 err = NhlGetErrorObjectId()
  setvalues err
    "errLevel" : "Fatal"          ; only report Fatal errors
  end setvalues


; Calculate fm1000. Independent fire index, also used as an input in ERC

load "convert_temp.ncl"
load "convert_prec.ncl"
load "convert_humid.ncl"
load "check_time.ncl"
load "clip_time.ncl"
load "calc_fm1000.ncl"

/;
The following variables should be specified as command-line arguments
 e.g.: ncl file=\"$file\" script.ncl

precfile
tmaxfile
tminfile
rhmaxfile
rhminfile
grid
output

;/

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
var_names = getfilevarnames (r_pr)

do i = 0, dimsizes(var_names)-1
   if (var_names(i) .ne. "prec") then
       w_fm1000->$var_names(i)$ = r_pr->$var_names(i)$
   end if
end do

time = r_tempmax->time
maxtemp = r_tempmax->tmax
convert_temp("degF", maxtemp)
mintemp = r_tempmin->tmin
convert_temp("degF", mintemp)

minhum = r_hummin->rhmin
maxhum = r_hummax->rhmax
convert_humid("%", minhum)
convert_humid("%", maxhum)

pr = r_pr->prec
convert_prec("inches/day", pr)

lat = r_tempmax->lat
lon = r_tempmax->lon

;b = r_z3->Z3

mc1000 = calc_fm1000(time, pr, maxtemp, mintemp, maxhum, minhum, lat, lon, grid)

w_fm1000->fm1000 = mc1000

end

