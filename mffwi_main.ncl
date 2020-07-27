/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
The following variables should be specified as command-line arguments
 e.g.: ncl file=\"$file\" script.ncl

        precfile (daily precipitation)
        tmaxfile (daily maximum temperature)
	hursfile (daily relative humidity)
	kbdifile (daily Keetch Byram Drought Index)
        output (the file to be written to)

Example of command-line to call mffwi_main:

ncl mffwi_main.ncl tmaxfile=\"tmax.METDATA.22i.1987-1988.nc\" hursfile=\"hurs.METDATA.22i.1987-1988.nc\" spdfile=\"spd.METDATA.22i.1987-1988.nc\" kbdifile=\"kbdi.METDATA.22i.1987-1988.nc\" output=\"mffwi.METDATA.22i.1987-1988.nc\"

;/

load "calc_mffwi.ncl"
load "check_time.ncl"
load "clip_time.ncl"

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

;read in from four files: surface wind, daily maximum temperature, daily average humidity, daily kbdi
; on command line, spdfile, tmaxfile, kbdifile, and hursfile must be specified, with "output" for file to write to
;if average humidity not available, input maximum and minimum humidity and do a simple average (currently set up to do this, but commented out)
r_wind = addfile(spdfile, "r")
r_temp = addfile(tmaxfile, "r")
r_humid = addfile(hursfile, "r")	;when average humidity available
;r_rhmax = addfile(rhmax_in, "r")
;r_rhmin = addfile(rhmin_in, "r")
r_kbdi = addfile(kbdifile, "r")	;open all data

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

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL scripts mffwi_main.ncl, calc_emc.ncl, calc_mffwi.ncl, convert_temp.ncl, convert_humid.ncl, check_time.ncl, and clip_time.ncl from source files "+spdfile+", "+tmaxfile+", "+hursfile+", and "+kbdifile
mffwi_out@history = history

var_names = getfilevarnames(r_temp)

do i = 0, dimsizes(var_names)-1		;read out 
	if (var_names(i) .ne. "tmax") then
                mffwi_out->$var_names(i)$ = r_temp->$var_names(i)$
        end if
end do

wind = r_wind->spd
hum = r_humid->hurs			; relative humidity
;rhmin = r_rhmin->rhmin
;rhmax = r_rhmax->rhmax
;hum = (rhmax + rhmin) / 2.0		; calculate average of rhmax and rhmin
;hum@units = rhmax@units
temp = r_temp->tmax			; assume that the index uses  maximum temperature of the day. Not specified in any paper
kbdi = r_kbdi->KBDI			; calculate KBDI before calculating mFFWI

;units = (/0, 0, -1/)	;(/ temp - degC, hum - %, wind - m/s /)
units = -1	; -1 corresponds to metadata

mffwi = calc_mffwi(temp, hum, wind, kbdi, units)

mffwi_out->mffwi = mffwi	;create mffwi variable, write mffwi values in output file

end
