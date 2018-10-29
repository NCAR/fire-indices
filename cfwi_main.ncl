load "~/github/fire_indices/fire-indices/calc_ffmc.ncl"
load "~/github/fire_indices/fire-indices/calc_dmc.ncl"
load "~/github/fire_indices/fire-indices/calc_dc.ncl"
load "~/github/fire_indices/fire-indices/calc_isi.ncl"
load "~/github/fire_indices/fire-indices/calc_bui.ncl"
load "~/github/fire_indices/fire-indices/convert_temp.ncl"
load "~/github/fire_indices/fire-indices/convert_prec.ncl"
load "~/github/fire_indices/fire-indices/convert_humid.ncl"
load "~/github/fire_indices/fire-indices/calc_cfwi.ncl"

load "crop.ncl"		;for use when paths are not set up correctly (the quick and dirty fix)
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/crop.ncl"	;for use in any other situation, aka the proper way

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

; main body of code (finally)
; command line inputs are: precip_in = daily precipitation in mm
;			humid_in = daily relative humidity
;			windsp_in = wind speed in m/s
;			temper_in = daily maximum temperature in Celsius

begin

r_prec = addfile(precip_in, "r")
;r_humid = addfile(humid_in, "r")
r_rhmax = addfile(rhmax_in, "r")
r_rhmin = addfile(rhmin_in, "r")
r_wdsp = addfile(windsp_in, "r")
r_temp = addfile(tmpmax_in, "r")

system("rm -f "+output)
w_cfwi = addfile(output, "c")

filedimdef(w_cfwi, "time", -1, True)

att_names = getvaratts(r_prec)

do i = 0, dimsizes(att_names) -1 
	w_cfwi@$att_names(i)$ = r_prec@$att_names(i)$
end do

history = "Create " + systemfunc("date") + " by " + systemfunc("whoami") + "@" + systemfunc("hostname") + " using NCL scripts calc_ffmc.ncl, calc_dmc.ncl, calc_dc.ncl, calc_isi.ncl, calc_bui.ncl, and cfwi_main.ncl from source files " + precip_in + ", " + rhmax_in + ", " + rhmin_in + ", " + windsp_in + ", " + tmpmax_in
w_cfwi@history = history

var_names = getfilevarnames(r_prec)

do i = 0, dimsizes(var_names)-1
	if(var_names(i) .ne. "prec") then
		w_cfwi->$var_names(i)$ = r_prec->$var_names(i)$
	end if
end do

pr = r_prec->prec
convert_prec("mm/day", pr)
;humid = r_humid->hurs
rhmax = r_rhmax->rhmax
rhmin = r_rhmin->rhmin
humid = (rhmin + rhmax) / 2
humid@units = rhmax@units
convert_humid("%", humid)
windsp = r_wdsp->spd
temp = r_temp->tmax		;technically supposed to be noon temp, but max temperature is the closest
convert_temp( "degC", temp)	; convert anything into Celsius if not already
time = r_prec->time

ffmc = pr(0, :, :)		;set up correctly sized arrays with latitude, longitude attached
dmc = pr(0, :, :)
dc = pr(0, :, :)
ffmc = 85.0
dmc = 6.0
dc = 15.0

Lf = (/-1.6, -1.6, -1.6, .9, 3.8, 5.8, 5.8, 6.4, 5.0, 2.4, .4, -1.6, -1.6/)	;"Day length factors" for deeper in the soil... according to month, Jan-Dec

lat = r_prec->lat
lon = r_prec->lon

cfwi = pr
cfwi = 0.0

ndays = dimsizes(time)-1
opt = 0		; for cd_calendar, option 5 returns an array: year (cal(0)), month (cal(1)), day (cal(2)), hour, minute, second

latlen = dimsizes(lat)
lonlen = dimsizes(lon)

delete_VarAtts(cfwi, -1)
cfwi@longname = "Canadian Fire Weather Index"
varatts = (/"units", "missing_value", "_FillValue"/)
cfwi@$varatts(0)$ = "1"		; cfwi is unitless

do i = 1, dimsizes(varatts)-1
	cfwi@$varatts(i)$ = pr@$varatts(i)$
end do

ffmc_temp = ffmc
m = pr(0,:,:)
m = 0.0

;loop runs over one time step, all of space
do i = 0, ndays
	cal = cd_calendar(time(i), opt)
	cal1 = tointeger(cal(0,:))
	cal1@calendar = time@calendar
	day_year = day_of_year(cal1(0), cal1(1), cal1(2))
	Le = daylight_fao56(day_year, lat)
	Le1 = Le(0, :)
	Le2 = conform_dims((/latlen, lonlen/), Le1, 0)
	tempdmc = temp(i, :, :)
	tempdmc = tempdmc > -1.1	;multiple adjustments made to temp according to which index is being calculated. tempdmc and tempdc are separate
	tempdc = temp(i, :, :)
	tempdc = tempdc > -2.8 

	m = (/calc_ffmc(ffmc_temp, humid(i, :, :), temp(i, :, :), windsp(i, :, :), pr(i, :, :))/)	;ffmc is calculated and passed by reference
	ffmc = ffmc_temp
	dmc = (/calc_dmc(dmc, tempdmc, pr(i, :, :), humid(i, :, :), Le2)/)
	dc = (/calc_dc(pr(i, :, :), tempdc, dc, Lf(cal1(1)-1))/)
	isi = (/calc_isi(windsp(i, :, :), m)/)
	bui = (/calc_bui(dmc, dc)/)
	cfwi(i, :, :) = (/calc_cfwi(bui, isi)/)
end do

w_cfwi->cfwi = cfwi

end
