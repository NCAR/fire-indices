 err = NhlGetErrorObjectId()
  setvalues err
    "errLevel" : "Fatal"          ; only report Fatal errors
  end setvalues


load "calc_emc.ncl"
load "calc_julian_day.ncl"
load "calc_daylight_builtin.ncl"
load "calc_daylight_manual.ncl"
load "calc_pduration.ncl"
load "calc_point_pduration.ncl"
load "calc_paper_pduration.ncl"
load "calc_fm100.ncl"
load "convert_temp.ncl"

; Calculates fm100, of Fuel Moisture . It is an input to ERC, but is also a standalone fire index.

/; 
The following variables should be specified as command-line arguments
 e.g.: ncl file=\"$file\" script.ncl

precip_in
tmpmax_in
tmpmin_in
rhmax_in
rhmin_in
z3_in
output (the file to be written to)

precip should be in mm
temperature should be in Celsius
humidity should be on a 0 to 100 scale
Alternatively, remove all conversions and read in precip in inches and temperature in Fahrenheit
;/

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

;read in tasmax and tasmin
;read in rhmax and rhmin
;read in precip
;read in precip coefficients

r_tempmax = addfile(tmpmax_in, "r")
r_tempmin = addfile(tmpmin_in, "r")
r_hummin = addfile(rhmin_in, "r")
r_hummax = addfile(rhmax_in, "r")
r_pr = addfile(precip_in, "r")
r_z3 = addfile(z3_in, "r")

system("rm -f "+output)
w_fm100 = addfile(output, "c")	;create output file

filedimdef(w_fm100, "time", -1, True) ; make time dimension unlimited

;copy/set global attributes
att_names = getvaratts(r_pr)

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  w_fm100@$att_names(i)$ = r_pr@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL scripts calc_emc.ncl, calc_julian_day.ncl, calc_daylight_builtin.ncl, calc_daylight_manual.ncl, calc_pduration.ncl, calc_fm100.ncl, and fm100_main.ncl, from source files "+precip_in+ ", "+tmpmax_in+ ", "+tmpmin_in+ ", "+rhmin_in+ ", "+ rhmax_in+", "+z3_in
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
convert_temp("degF", maxtemp)
mintemp = r_tempmin->tmin
convert_temp("degF", mintemp)

minhum = r_hummin->rhmin
maxhum = r_hummax->rhmax

pr = r_pr->prec
pr = pr / 24.5  ;convert to inches from mm

lat = r_tempmax->lat
lon = r_tempmax->lon

b = r_z3->Z3

climcl = 3.
fm100 = maxtemp         ;just to establish lat, lon etc
fm100 = -1.             ;to ensure that any values not calculated are obviously wrong
;yfm = 5. + 5. * climcl ;different initial value, the one used in the paper
yfm = maxtemp(0, :, :)  ;establish lat, lon for yfm (only holds one time step)
yfm = 10.0

emcmax = calc_emc(mintemp, maxhum)
emcmin = calc_emc(maxtemp, minhum)
day_year = calc_julian_day(time)        ;creates a vector of day of year that is as long as the model run
latlen = dimsizes(lat)
lonlen = dimsizes(lon)
pptdur = calc_pduration(b, pr, latlen, lonlen)


fr100 = 1.0 - 0.87 * exp(-0.24)         ; precalculating a constant

emcbar = emcmin(0, :, :)

ndays = dimsizes(time) - 1
do i = 0, ndays
        lonlen = dimsizes(lon)
        daylit = dble2flt(calc_daylight_manual(day_year(i), lat, lonlen))
;       daylit = dlbe2flt(calc_Daylight_builtin(day_year(i), lat, lonlen))
        emcbar = (daylit(0, :, :) * emcmin(i, :, :) + (24.0 - daylit(0, :, :)) * emcmax(i, :, :)) / 24.
        temp = calc_fm100(emcbar, pptdur(i, :, :), yfm, fr100)
        fm100(i, :, :) = (/temp/)
        yfm = (/fm100(i, :, :)/)
end do

delete_VarAtts(fm100, -1) ;get rid of superfluous attributes

fm100@long_name = "Percent Moisture Content for 100-hr timelag"   ; No convention for long names, just make it descriptive

varatts = (/"units", "missing_value", "_FillValue"/)

fm100@$varatts(0)$ = "%"

do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
   fm100@$varatts(i)$ = r_pr->prec@$varatts(i)$
end do

w_fm100->fm100 = fm100	;write fm100 data to file

end


