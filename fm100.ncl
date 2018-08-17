 err = NhlGetErrorObjectId()
  setvalues err
    "errLevel" : "Fatal"          ; only report Fatal errors
  end setvalues


;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/crop.ncl"	;the proper way
load "crop.ncl"						;only for when path is not set correctly
; Calculate fm100, of Fuel Moisture . It is an input to ERC, but is also a standalone fire index.

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

precip should be in inches
temperature should be in Fahrenheit
humidity should be on a 0 to 100 scale
;/


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 T is temperature
 H is humidity
 emc is equilibrium moisture content
;/
function calc_emc( T, H )
local emc
begin

emc = 2.22749 + 0.160107 * H - 0.014784 * T
emc = where(H .lt. 10., 0.03229 + .281073 * H - .000578 * T * H, emc)
emc = where(H .gt. 50., 21.0606 + 0.005565 * (H^2.0) - 0.00035 * H * T - 0.483199 * H, emc)

;return(flt2dble(emc))
return(emc)
end
 
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;give it time as is written in netCDF file and it returns the day of year
function calc_julian_day(time)
local opt, cal, cal1, day_year
begin

opt = 0         ; for cd_calendar, option 0 returns an array: year (cal(0)), month (cal(1)), day (cal(2)), hour, minute, second

cal = cd_calendar(time, opt)
;print(cal)
cal1 = tointeger(cal)
day_year = day_of_year(cal1(:,0), cal1(:,1), cal1(:,2))

return(day_year)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 day is day of year
 lat is latitude
 lonlen is the number of longitude coordinates in the area of calculation
;/
function calc_daylight_builtin(day, lat, lonlen)
local latlen, daylight, daylight1, daylit, day
begin

latlen = dimsizes(lat)

daylight = daylight_fao56(day, lat)
;daylight1 = daylight(0, :)
daylit = conform_dims((/latlen, lonlen/), daylight, 0)	;give each gridcell a value for later calculations

return(daylit)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 j_date is julian day or day of year
 lat is latitude
 lonlen is number of longitude coordinates in area of calculation
;/
function calc_daylight_manual(j_date, lat, lonlen)
local phi, decl, daylit, latlen, daylit1
begin

phi = lat * .01745
decl = .41008 * sin((j_date-82.) * .01745)
daylit=24*(1-acos(tan(phi)*tan(decl))/3.14159)
;daylit=real(daylit)

latlen = dimsizes(lat)
daylit1 = conform_dims((/latlen, lonlen/), daylit, 0)

return(daylit1)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/;
 z3 is a constant corresponding to latitude and longitude
 ppt is precipitation amount
 lat is latitude
 lon is longitude
;/

function calc_pduration(z3, ppt, lat, lon, mlat, mlon)       ;this function uses the methods presented by MATLAB code
local pdur, flat, flon, flat1, flon1, b
begin

flat = ind(abs(mlat - lat) .lt. (1./24.))
flon = ind(abs(mlon - lon) .lt. (1./24.))
flat1 = flat(0)
flon1 = flon(0)

b = z3(flon1, flat1)    ;!!may reorder variables later!!

pdur = 24. * (1. - exp(-b * ppt))
pdur = round(pdur, 0)
pdur = pdur < 8.
pdur = pdur > 0.
return(pdur)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 ppt is amount of precipitation
 lat and lon are latitude and longitude
 climat is NFDRS climate class
;/
function calc_paper_pduration(ppt, lat, lon, climat)
local pdur, wetrat
begin

;note that this is currently different than the calculations in the MATLAB code. This is what is done in the paper

wetrat = where(climat .eq. 1 .or. climat .eq. 2, 0.25, 0.05)
pdur = (ppt / wetrat) + .49
pdur = pdur < 8.        ;not allowed to exceed 8 hours 

return(pdur)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 emcbar is average equilibrium moisture content
 pptdur is precipitation duration
 yfm is yesterday's fm100 
 fr100 is a constant
;/
function calc_fm100(emcbar, pptdur, yfm, fr100)
local bndryh, fm100, fm_100
begin

bndryh = ((24. - pptdur) * emcbar + pptdur * (0.5 * pptdur + 41.0)) / 24.
fm100 = (bndryh - yfm) * fr100 + yfm
fm_100 = dble2flt(fm100)
fm_100!0 = "lat"
fm_100!1 = "lon"
return(fm_100)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

;read in tasmax and tasmin
;read in rhmax and rhmin
;read in precip

r_tempmax = addfile(tmpmax_in, "r")
r_tempmin = addfile(tmpmin_in, "r")
r_hummin = addfile(rhmin_in, "r")
r_hummax = addfile(rhmax_in, "r")
r_pr = addfile(precip_in, "r")
r_z3 = addfile(z3_in, "r")

system("rm -f "+output)
w_fm100 = addfile(output, "c") 

;filedimdef(w_fm100, "time", -1, True) ; make time dimension unlimited

;copy/set global attributes

att_names = getvaratts(r_pr)

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  w_fm100@$att_names(i)$ = r_pr@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL script from source files "+precip_in+ ", "+tmpmax_in+ ", "+tmpmin_in+ ", "+rhmin_in+ ", "+ rhmax_in
w_fm100@history = history

; copy variables

var_names = getfilevarnames (r_pr)

do i = 0, dimsizes(var_names)-1       ;get all variable attributes except for precip attached to spi, not sure if all th$
   if (var_names(i) .ne. "precipitation_amount") then
       w_fm100->$var_names(i)$ = r_pr->$var_names(i)$
   end if
end do

;time = r_tempmax->time
time = r_tempmax->day

maxtemp = r_tempmax->air_temperature
;maxtemp = maxtemp * 1.8 + 32
maxtemp = (maxtemp - 273.15) * 1.8 + 32.
mintemp = r_tempmin->air_temperature
;mintemp = mintemp * 1.8 + 32.	; convert from Celsius to Fahrenheit
mintemp = (mintemp - 273.15) * 1.8 + 32.	;convert from Kelvin to Fahrenheit

minhum = r_hummin->relative_humidity
maxhum = r_hummax->relative_humidity

pr = r_pr->precipitation_amount
pr = pr / 24.5	;convert to inches from mm

lat = r_tempmax->lat
lon = r_tempmax->lon

b = r_z3->Z3

climcl = 3.
fm100 = maxtemp		;just to establish lat, lon etc
fm100 = -1.		;to ensure that any values not calculated are obviously wrong
;yfm = 5. + 5. * climcl	;different initial value, the one used in the paper
yfm = maxtemp(0, :, :)	;establish lat, lon
yfm = 10.0

emcmax = calc_emc(mintemp, maxhum)
emcmin = calc_emc(maxtemp, minhum)
day_year = calc_julian_day(time)	;creates a vector of day of year that is as long as the model run

mlat = r_z3->lat
mlon= r_z3->lon
pptdur = calc_pduration(b, pr, lat, lon, mlat, mlon)


fr100 = 1.0 - 0.87 * exp(-0.24)		; precalculating a constant

emcbar = emcmin(0, :, :)

ndays = dimsizes(time) - 1
do i = 0, ndays
	lonlen = dimsizes(lon)
	daylit = dble2flt(calc_daylight_manual(day_year(i), lat, lonlen))
;	daylit = dlbe2flt(calc_Daylight_builtin(day_year(i), lat, lonlen))
	emcbar = (daylit * emcmin(i, :, :) + (24.0 - daylit) * emcmax(i, :, :)) / 24.
	temp = calc_fm100(emcbar, pptdur(i, :, :), yfm, fr100)
	fm100(i, :, :) = (/temp/)
	yfm = (/fm100(i, :, :)/)
end do

delete_VarAtts(fm100, -1) ;get rid of superfluous attributes

fm100@long_name = "Percent Moisture Content for 100-hr timelag"   ; No convention for long names, just make it descriptive

varatts = (/"units", "missing_value", "_FillValue"/)

fm100@$varatts(0)$ = "1"

do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
   fm100@$varatts(i)$ = r_pr->prec@$varatts(i)$
end do

w_fm100->fm100 = fm100


end
