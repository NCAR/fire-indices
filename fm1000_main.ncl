 err = NhlGetErrorObjectId()
  setvalues err
    "errLevel" : "Fatal"          ; only report Fatal errors
  end setvalues


; Calculate fm1000. Independent fire index, also used as an input in ERC

load "calc_emc.ncl"
load "calc_julian_day.ncl"
load "calc_daylight_builtin.ncl"
load "calc_daylight_manual.ncl"
load "calc_pduration.ncl"
load "calc_point_pduration.ncl"
load "calc_paper_pduration.ncl"

/;
The following variables should be specified as command-line arguments
 e.g.: ncl file=\"$file\" script.ncl

precip_in
tmpmax_in
tmpmin_in
rhmax_in
rhmin_in
z3_in
output

precip should be in mm
temperature should be in Celsius
humidity should be on a 0 to 100 scale
Alternatively, discard conversions in script and read in precip in inches, temperature in Fahrenheit
;/

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

;read in all inputs
r_tempmax = addfile(tmpmax_in, "r")
r_tempmin = addfile(tmpmin_in, "r")
r_hummin = addfile(rhmin_in, "r")
r_hummax = addfile(rhmax_in, "r")
r_pr = addfile(precip_in, "r")
r_z3 = addfile(z3_in, "r")

system("rm -f "+output)
w_fm1000 = addfile(output, "c")	;create output file

filedimdef(w_fm1000, "time", -1, True) ; make time dimension unlimited

;copy/set global attributes
att_names = getvaratts(r_pr)

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  w_fm1000@$att_names(i)$ = r_pr@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL scripts calc_emc.ncl, calc_julian_day.ncl, calc_daylight_builtin.ncl, calc_daylight_manual.ncl, calc_pduration.ncl, and fm1000_main, from source files "+precip_in+ ", "+tmpmax_in+ ", "+tmpmin_in+", " + rhmax_in+", "+rhmin_in+", "+z3_in
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
maxtemp = maxtemp * 1.8 + 32.	; convert Celsius to Fahrenheit
;maxtemp = (maxtemp- 273.15) * 1.8 + 32.	;convert Kelvin to Fahrenheit

mintemp = r_tempmin->tmin
mintemp = mintemp * 1.8 + 32.
;mintemp = (mintemp - 273.15) * 1.8 + 32.

minhum = r_hummin->rhmin
maxhum = r_hummax->rhmax

pr = r_pr->prec
pr = pr / 24.5          ;mm to inches
lat = r_tempmax->lat
lon = r_tempmax->lon

day_year = calc_julian_day(time)
latlen = dimsizes(lat)
lonlen = dimsizes(lon)

emcmin = calc_emc(maxtemp, minhum)
emcmax = calc_emc(mintemp, maxhum)

climat = 3.	;possible refinement: create a file with each gridcell assigned a class according to fuel moisture and such, as seen on the cover of The National Fire Danger Rating System: basic equations (1985)
b = r_z3->Z3
pptdur = calc_pduration(b, pr, latlen, lonlen)

;spin-up conditions
startup = 10. + 5.0 * climat
temp = conform_dims((/7, latlen, lonlen/), startup, -1)
bndryt = temp
mc1000_r = bndryt

divsev = conform_dims((/latlen, lonlen/), 7., -1)
tempbnd = dim_cumsum_n_Wrap(bndryt, 0, 0)
bdybar = tempbnd(6, :, :)/divsev

mc1000 = pr

ndays = dimsizes(time)
fr1000 = 1 - 0.82 * exp(-0.168)

do i = 0, ndays-1
        daylit = calc_daylight_manual(day_year(i), lat, lonlen)
        emcbar = (daylit(0,:,:) * emcmin(i, :, :) + (24. - daylit(0,:,:)) * emcmax(i, :, :)) / 24.
        bndryt(0:5, :, :) = bndryt(1:6, :, :)
        bndryt(6, :, :) = dble2flt(((24 - pptdur(i, :, :)) * emcbar + (2.7 * pptdur(i, :, :) + 76.) * pptdur(i, :, :)) / 24.)
        tempbnd = dim_cumsum_n_Wrap(bndryt, 0, 0)
        bdybar = tempbnd(6, :, :) / divsev
        mc1000(i, :, :) = (/(mc1000_r(0, :, :) + (bdybar - mc1000_r(0, :, :)) * fr1000)/)
        mc1000_r(0:5, :, :) = mc1000_r(1:6, :, :)
;       mc1000_r(6, :, :) = dble2flt(mc1000(i, :, :))
        mc1000_r(6, :, :) = mc1000(i, :, :)
end do

delete_VarAtts(mc1000, -1) ;get rid of superfluous attributes

mc1000@long_name = "Percent Moisture Content for 1000-hr timelag"  

varatts = (/"units", "missing_value", "_FillValue"/)
mc1000@$varatts(0)$ = "1"

do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
   mc1000@$varatts(i)$ = r_pr->prec@$varatts(i)$
end do

w_fm1000->fm1000 = mc1000

end

