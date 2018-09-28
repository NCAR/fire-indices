load "crop.ncl"		;for use when paths are not set up correctly (the quick and dirty fix)
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/crop.ncl"	;for use in any other situation, aka the proper way

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;Fo is the previous day's FFMC
;H is average relative humidity
;T is average temperature in Celsius
;W is wind speed in mph
;ro is daily rainfall, unadjusted

;NOTE! The return value is m, not FFMC, because m is required in later calculations. The final FFMC value is calculated in the main body of code
function FFMC(Fo, H, T, W, ro)		;FFMC is Fine Fuel Moisture Content
local mo, mr, rf, Ed, Ew, ko1, kdw, m, F
begin

mo = 147.2 * (101. - Fo) / (59.5 + Fo)
rf = where(ro .gt. .5, ro - .5, -1.)
;following line tests if there was precipitation, then modify mo to account for precip. There are also 2 options for what modification needs to be made, hence the nested where statements
mo = where(rf .gt. 0., where(mo .gt. 150., mo + 42.5 * rf * exp(-100./(251.-mo)) * (1- exp(-6.93 / rf)) + .0015 * ((mo - 150.)^2) * sqrt(rf), mo + 42.5* rf * exp(-100./(251.-mo)) * (1 - exp(-6.93/rf))), mo)

Ed = .942 * H^0.679 + 11 * exp((H - 100.)/10.) + 0.18 * (21.1 - T) * (1 - exp(-.115 * H))
Ew = .618 * H^.753 + 10 * exp((H-100.)/10.) + 0.18 * (21.1 - T) * (1 - exp(-.115 * H))

ko1 = where(mo .gt. Ed, 0.424 * (1 - (H / 100)^1.7)+ 0.0694 * sqrt(W) * (1 - (H / 100)^8.), 0.424 * (1 - ((100 - H) / 100)^1.7) + 0.0694 * sqrt(W) * (1 - ((100 - H) / 100)^8))
kdw = ko1 * 0.581 * exp(0.0365 * T)

m = where(mo .gt. Ed, Ed + (mo - Ed) * 10^(-kdw), mo)
m = where(mo .lt. Ew, Ew - (Ew - mo) * 10^(-kdw), m)

m = where(m .gt. 250., 250., m)
m = where(m .lt. 0., 0., m)

;F = 59.5 * (250. - m) / (147.2 + m)

return(m)

end
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;Po is the previous day's DMC
; Le is length of day/ amount of sunlight

function DMC(Po, T, ro, H, Le)			; DMC is Duff Moisture Code
local re, Mo, b, Mr, K, P
begin

re = where(ro .gt. 1.5, .92 * ro - 1.27, -1)	;adjust precip
Mo = 20. + exp(5.6348 - (Po / 43.43))
b = 14. - 1.3 * log(Po)
b = where(Po .gt. 65., 6.2 * log(Po) - 17.2, b)
b = where(Po .lt. 33., 100. / (.5 + .3 * Po) , b)
Mr = where(re .gt. 0, Mo + (1000. * re / (48.77 + b * re)), -1)	;only if there's precip
Po = where(re .gt. 0, 244.72 - 43.43 * log(Mr - 20.), Po)	;only if there's precip
Po = where(Po .lt. 0, 0, Po)
K = 1.894 * (T + 1.1) * (100 - H) * Le * 10^(-6)

P = Po + 100 * K

P = where(P .lt. 0., 0., P)

return(P)

end
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;Do is the previous day's DC
;Lf is an adjustment to length of day

function DC(ro, T, Do, Lf)			; DC is Drought Code
local rd, Qo, Qr, Dr, V, Drou
begin

rd = where(ro .gt. 2.8, 0.83 * ro - 1.27, -1)	;adjust precip

Qo = 800 * exp(-Do / 400.)
Qr = where(rd .gt. 0., Qo + (3.937 * rd), -1)		;only if precip
Dr = where(rd .gt. 0., 400. * log(800. / Qr), Do)	;only if precip
Dr = where(Dr .lt. 0., 0, Dr)

V = (.36 * (T + 2.8)) + Lf
V = where(V .lt. 0, 0, V)
Drou = Dr + .5 * V

Drou = where(Drou .lt. 0., 0., Drou)

return(Drou)

end
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;m is an intermediate step from FFMC

function ISI(W, m)			; ISI is Initial Spread Index
local fw, ff, r
begin

fw = exp(.05039 * W)
ff = 91.9 * exp(-0.1386 * m) * (1 + (m^5.31 / (4.93 * 10^7)))
r = 0.208 * fw * ff

r = where(r .lt. 0., 0., r)

return(r)

end
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;P is DMC, D is DC

function BUI(P, D)			; BUI is Build Up Index
local dfour, D1, P1, U
begin
D1 = where(P .eq. 0. .and. D .eq. 0., D@_FillValue, D)
P1 = where(P .eq. 0. .and. D .eq. 0., P@_FillValue, P)

dfour = .4 * D1

U = where(P1 .gt. dfour, P1 - (1. - .8 * D1 / (P1 + dfour)) * (.92 + (0.0114 * P1)^1.7), 0.8 * P1 * D1 / (P1 + dfour))
U = where(ismissing(D1), 0., U)
/;
check = any(U .lt. 0)
if(check) then
;	print(U)
	print("BUI is below 0. Reset BUI to 0.")
end if
;/

U = where(U .lt. 0., 0., U)		;not a check explicitly stated in the paper, but prevents calculations that result in non-real numbers

return(U)

end
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;R is ISI
;U is BUI

function CFWI(U, R)			; Finally, CFWI is Canadian Fire Weather Index!
local fd, B, S
begin

fd = where(U .gt. 80., 1000. / (25. + 108.64 * exp(-0.023 * U)), 0.626 * U^0.809 + 2)
B = 0.1 * R * fd
S = where(B .gt. 1., exp(2.72 * (.434 * log(B))^.647), B)

S = where(S .lt. 0., 0., S)

return(S)

end

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

; main body of code (finally)
; command line inputs are: precip_in = daily precipitation in mm
;			humid_in = daily relative humidity
;			windsp_in = wind speed in m/s
;			temper_in = daily maximum temperature in Celsius !!CHECK FOR KELVIN!!

begin

r_prec = addfile(precip_in, "r")
r_humid = addfile(humid_in, "r")
r_wdsp = addfile(windsp_in, "r")
r_temp = addfile(temper_in, "r")

system("rm -f "+output)
w_cfwi = addfile(output, "c")

filedimdef(w_cfwi, "time", -1, True)

att_names = getvaratts(r_prec)

do i = 0, dimsizes(att_names) -1 
	w_cfwi@$att_names(i)$ = r_prec@$att_names(i)$
end do

history = "Create " + systemfunc("date") + " by " + systemfunc("whoami") + "@" + systemfunc("hostname") + " using NCL Script from source files " + precip_in + ", " + humid_in + ", " + windsp_in + ", " + temper_in
w_cfwi@history = history

var_names = getfilevarnames(r_prec)

do i = 0, dimsizes(var_names)-1
	if(var_names(i) .ne. "prec") then
		w_cfwi->$var_names(i)$ = r_prec->$var_names(i)$
	end if
end do

pr = r_prec->prec
humid = r_humid->hurs
humid = humid * 100		; convert to percentage 0 to 100
humid = humid < 100.
humid = humid > 0.		; account for supersaturation at low temperatures or high pressures
windsp = r_wdsp->sfcWind
temp = r_temp->tasmax		;technically supposed to be noon temp, but tasmax is the closest thing
temp = temp - 273.15		; only because I'm dealing with KELVIN jklfdsjfklds
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

;retrieve day of year
cal = cd_calendar(time(0), opt)
cal1 = tointeger(cal(0,:))		; remove degenerate dimension
day_year = day_of_year(cal1(0), cal1(1), cal1(2))

;retrieve maximum sunlight
Le = daylight_fao56(day_year, lat)
Le1 = Le(0, :)
Le2 = conform_dims((/latlen, lonlen/), Le1, 0) 

tempdmc = temp(0, :, :)				; set up bottom limits for temperature for dmc and dc
tempdmc = where(tempdmc .lt. -1.1, -1.1, tempdmc)
tempdc = temp(0, :, :)
tempdc = where(tempdc .lt. -2.8, -2.8, tempdc)

m = FFMC(ffmc, humid(0, :, :), temp(0, :, :), windsp(0, :, :), pr(0, :, :))
ffmc = 59.5 * (250. - m) / (147.2 + m)
dmc = (/DMC(dmc, tempdmc, pr(0, :, :), humid(0, :, :), Le2)/)
dc = (/DC(pr(0, :, :), tempdc, dc, Lf(cal1(1)-1))/)
isi = (/ISI(windsp(0, :, :), m)/)
bui = (/BUI(dmc, dc)/)
cfwi(0, :, :) = (/CFWI(bui, isi)/)

delete_VarAtts(cfwi, -1)
cfwi@longname = "Canadian Fire Weather Index"
varatts = (/"units", "missing_value", "_FillValue"/)
cfwi@$varatts(0)$ = "1"		; cfwi is unitless

do i = 1, dimsizes(varatts)-1
	cfwi@$varatts(i)$ = pr@$varatts(i)$
end do

w_cfwi->cfwi = cfwi

;loop runs over one time step, all of space
do i = 1, ndays-1
	cal = cd_calendar(time(i), opt)
	cal1 = tointeger(cal(0,:))
	day_year = day_of_year(cal1(0), cal1(1), cal1(2))
	Le = daylight_fao56(day_year, lat)
	Le1 = Le(0, :)
	Le2 = conform_dims((/latlen, lonlen/), Le1, 0)
	tempdmc = temp(i, :, :)
	tempdmc = where(tempdmc .lt. -1.1, -1.1, tempdmc)	;multiple adjustments made to temp according to which index is being calculated. tempdmc and tempdc are separate
	tempdc = temp(i, :, :)
	tempdc = where(tempdc .lt. -2.8, -2.8, tempdc)

	m = FFMC(ffmc, humid(i, :, :), temp(i, :, :), windsp(i, :, :), pr(i, :, :))
	ffmc = 59.5 * (250. - m) / (147.2 + m)
	dmc = (/DMC(dmc, tempdmc, pr(i, :, :), humid(i, :, :), Le2)/)
	dc = (/DC(pr(i, :, :), tempdc, dc, Lf(cal1(1)-1))/)
	isi = (/ISI(windsp(i, :, :), m)/)
	bui = (/BUI(dmc, dc)/)
	cfwi(i, :, :) = (/CFWI(bui, isi)/)

	w_cfwi->cfwi(i, :, :) = (/cfwi(i, :, :)/)
end do


end
