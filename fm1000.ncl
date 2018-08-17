 err = NhlGetErrorObjectId()
  setvalues err
    "errLevel" : "Fatal"          ; only report Fatal errors
  end setvalues


; Calculate fm1000. Highly useful fire index, also used as an input in ERC

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


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

opt = 0         ; for cd_calendar, option 0 returns an array: year (cal(0)), month (cal(1)), day (cal(2))

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
 lon is longitude
;/
function calc_daylight_builtin(day, lat, lonlen)
local latlen, daylight, daylight1, daylit, day
begin

latlen = dimsizes(lat)

daylight = daylight_fao56(day, lat)
;daylight1 = daylight(0, :)
daylit = conform_dims((/latlen, lonlen/), daylight, 0)

return(daylit)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 j_date is day of year
 lat is latitude
;/
function calc_daylight_manual(j_date, lat, lonlen)
local phi, decl, daylit, daylit1, latlen
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
pdur = pdur < 8.	;not allowed to exceed 8 hours

return(pdur)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

r_tempmax = addfile(tmpmax_in, "r")
r_tempmin = addfile(tmpmin_in, "r")
r_hummin = addfile(rhmin_in, "r")
r_hummax = addfile(rhmax_in, "r")
r_pr = addfile(precip_in, "r")
r_z3 = addfile(z3_in, "r")

system("rm -f "+output)
w_fm1000 = addfile(output, "c")

;filedimdef(w_fm1000, "day", -1, True) ; make time dimension unlimited

;copy/set global attributes

att_names = getvaratts(r_pr)

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  w_fm1000@$att_names(i)$ = r_pr@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL script from source files "+precip_in+ ", "+tmpmax_in+ ", "+tmpmin_in+", " + rhmax_in+", "+rhmin_in
w_fm1000@history = history

; copy variables

var_names = getfilevarnames (r_pr)

do i = 0, dimsizes(var_names)-1       
   if (var_names(i) .ne. "precipitation_amount") then
       w_fm1000->$var_names(i)$ = r_pr->$var_names(i)$
   end if
end do

time = r_tempmax->day
maxtemp = r_tempmax->air_temperature
;maxtemp = maxtemp * 1.8 + 32.
maxtemp = (maxtemp- 273.15) * 1.8 + 32.

mintemp = r_tempmin->air_temperature
;mintemp = mintemp * 1.8 + 32.
mintemp = (mintemp - 273.15) * 1.8 + 32.

minhum = r_hummin->relative_humidity
maxhum = r_hummax->relative_humidity

pr = r_pr->precipitation_amount
pr = pr / 24.5		;mm to inches
lat = r_tempmax->lat
lon = r_tempmax->lon

day_year = calc_julian_day(time)
latlen = dimsizes(lat)
lonlen = dimsizes(lon)

emcmin = calc_emc(maxtemp, minhum)
emcmax = calc_emc(mintemp, maxhum)

climat = 3.

b = r_z3->Z3
mlat = r_z3->lat
mlon= r_z3->lon
pptdur = calc_pduration(b, pr, lat, lon, mlat, mlon)

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
	emcbar = (daylit * emcmin(i, :, :) + (24. - daylit) * emcmax(i, :, :)) / 24.
	bndryt(0:5, :, :) = bndryt(1:6, :, :)
	bndryt(6, :, :) = dble2flt(((24 - pptdur(i, :, :)) * emcbar + (2.7 * pptdur(i, :, :) + 76.) * pptdur(i, :, :)) / 24.)
	tempbnd = dim_cumsum_n_Wrap(bndryt, 0, 0)
	bdybar = tempbnd(6, :, :) / divsev
	mc1000(i, :, :) = (/(mc1000_r(0, :, :) + (bdybar - mc1000_r(0, :, :)) * fr1000)/)
	mc1000_r(0:5, :, :) = mc1000_r(1:6, :, :)
;	mc1000_r(6, :, :) = dble2flt(mc1000(i, :, :))
        mc1000_r(6, :, :) = mc1000(i, :, :)
end do

delete_VarAtts(mc1000, -1) ;get rid of superfluous attributes

mc1000@long_name = "Percent Moisture Content for 1000-hr timelag"   ; No convention for long names, just make it descriptive

varatts = (/"units", "missing_value", "_FillValue"/)

mc1000@$varatts(0)$ = "1"

do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
   mc1000@$varatts(i)$ = r_pr->prec@$varatts(i)$
end do

w_fm1000->fm1000 = mc1000

end
