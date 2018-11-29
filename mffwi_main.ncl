/;
2018, Copyright University Corporation for Atmospheric Research
;/


load "calc_emc.ncl"
load "calc_mffwi.ncl"
load "convert_temp.ncl"
load "convert_humid.ncl"
load "check_time.ncl"
load "clip_time.ncl"

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

;read in from four files: surface wind, daily maximum temperature, daily average humidity, daily kbdi
; on command line, windsp_in, temper_in, kbdi_in, and humid_in must be specified, with "output" for file to write to
;if average humidity not available, input maximum and minimum humidity and do a simple average (currently set up to do this)
r_wind = addfile(windsp_in, "r")
r_temp = addfile(tmpmax_in, "r")
r_humid = addfile(humid_in, "r")	;when average humidity available
;r_rhmax = addfile(rhmax_in, "r")
;r_rhmin = addfile(rhmin_in, "r")
r_kbdi = addfile(kbdi_in, "r")	;open all data

timeW = r_wind->time
timeT = r_temp->time
timeH = r_humid->time
timeK = r_kbdi->time

check = check_time("windspeed", "temperature", timeW, timeT)
check = check + check_time("temperature", "relative humidity", timeT, timeH)
check = check + check_time("relative humidity", "kbdi", timeH, timeK)

maximum = timeW(dimsizes(timeW)-1)
minimum = timeW(0)
if(check .lt. 3) then           ;procedure clip_time finds the largest minimum and smallest maximum to find a uniform timeframe across all source files
        clip_time(timeT, minimum, maximum)
	clip_time(timeH, minimum, maximum)
	clip_time(timeK, minimum, maximum)
        print("Overlapping time limits are " + minimum + " to " + maximum)
        exit()
end if

print("Time limits match on all variables")

system("rm -f " + output)
mffwi_out = addfile(output, "c")	; create output file

filedimdef(mffwi_out, "time", -1, True)	; makes time dimension unlimited

;copy/set global attributes
att_names = getvaratts(r_temp)
do i = 0, dimsizes(att_names)-1
	mffwi_out@$att_names$ = r_temp@$att_names$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL scripts mffwi_main.ncl, from source files "+windsp_in+", "+tmpmax_in+", "+humid_in+", and "+kbdi_in
mffwi_out@history = history

var_names = getfilevarnames(r_temp)

do i = 0, dimsizes(var_names)-1
	if (var_names(i) .ne. "tmax") then
                mffwi_out->$var_names(i)$ = r_temp->$var_names(i)$
        end if
end do

wind = r_wind->spd
wind = wind * 2.23694			; convert m/s to mph
hum = r_humid->hurs			; relative humidity
;rhmin = r_rhmin->rhmin
;rhmax = r_rhmax->rhmax
;hum = (rhmax + rhmin) / 2.0		; calculate average of rhmax and rhmin
;hum@units = rhmax@units
convert_humid("%", hum)
temp = r_temp->tmax			; assume that the index uses  maximum temperature of the day. Not specified in any paper
convert_temp("degF", temp)		; convert anything to degrees Fahrenheit
kbdi = r_kbdi->KBDI			; calculate KBDI before calculating mFFWI
emc = calc_emc(temp, hum)		; equilibrium moisture content

mffwi = calc_mFFWI(wind, hum, temp, kbdi, emc)

delete_VarAtts(mffwi, -1)		;get rid of superfluous attributes
mffwi@long_name = "modified Fosberg Fire Weather Index"
varatts = (/"units","missing_value","_FillValue"/)
mffwi@$varatts(0)$ = "1"	;mFFWI is unitless

do i = 1, dimsizes(varatts) -1
	mffwi@$varatts(i)$ = r_temp->tmax@$varatts(i)$
end do

mffwi_out->mffwi = mffwi	;create mffwi variable, write mffwi values in output file

end
