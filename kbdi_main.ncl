; kbdi main
; precipitation is either pr or prec. Alter for whichever dataset is being used, lines have been marked with @@@ in comment.

; read in from 2 files: daily precipitation and daily maximum temperatures
; The following variables should be specified as command-line arguments (ncl file = \"$file\" script.ncl):
; precip_in = \"some file\"	read in
; tmpmax_in = \"some file\"	read in
; output = \"kbdi.nc\"	write out

load "calc_kbdi.ncl"
load "convert_temp.ncl"
load "convert_prec.ncl"
load "check_time.ncl"
load "clip_time.ncl"

begin

read_precip = addfile(precip_in, "r")
read_temper = addfile(tmpmax_in, "r")

timeP = read_precip->time
timeT = read_temper->time
check = check_time("precipitation", "temperature", timeP, timeT)

maximum = timeP(dimsizes(timeP)-1)
minimum = timeP(0)
if(check .eq. 0) then		;procedure clip_time finds the largest minimum and smallest maximum to create a uniform timeframe across all source files
	clip_time(timeT, minimum, maximum)
	print("Overlapping time limits are " + minimum + " to " + maximum)
	exit()
end if


system("rm -f "+output)
KBDI_out = addfile(output, "c") ; create new file to store KBDI
filedimdef(KBDI_out, "time", -1, True)	;makes time dimension unlimited

; copy / set global attributes
att_names = getvaratts(read_precip)
do i = 0, dimsizes(att_names)-1				;transfer global attributes of precip onto KBDI
	KBDI_out@$att_names(i)$ = read_precip@$att_names$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL scripts check_time.ncl, clip_time.ncl, concert_prec.ncl, concert_temp.ncl, calc_kbdi.ncl, and kbdi_main.ncl from source files "+precip_in+" and "+tmpmax_in
KBDI_out@history = history

var_names = getfilevarnames(read_precip)

do i = 0, dimsizes(var_names)-1			;attach all variables but precipitation onto KBDI (lat, long, time)
	if (var_names(i) .ne. "prec") then	;@@@
		KBDI_out->$var_names(i)$ = read_precip->$var_names(i)$
	end if
end do


;read in daily precipitation
daily_precip = read_precip->prec	;@@@

;read in maximum daily temperature
tmax = read_temper->tmax

;calculate mean annual precipitation, save to variable mean_ann_precip
total_precip = dim_sum_n(daily_precip,0)	; add all precipitation values together by location (one value per lat,lon coordinate)

calendar = read_precip->time@calendar
ndaysyear = 365.2425	;gregorian or standard length of year

if(calendar .eq. "noleap" .or. calendar .eq. "365_day") then
	ndaysyear = 365.0
else if(calendar .eq. "all_leap" .or. calendar .eq. "366_day") then
	ndaysyear = 366.0
else if(calendar .eq. "360_day") then
	ndaysyear = 360.0
end if
end if
end if

ndays = dimsizes(read_precip->time)		; extracts number of days in a daily dataset
nyears = ndays/ndaysyear
mean_ann_precip = total_precip / nyears		; note that this may need to be adjusted to account for ragged edges, worked for the sample file
mean_ann_precip@units = daily_precip@units

;convert temp and prec
convert_temp("degF", tmax)			;convert to Fahrenheit
convert_prec("inches/day", mean_ann_precip)
convert_prec("inches/day", daily_precip)

kbdi = calc_kbdi(daily_precip, tmax, mean_ann_precip)

KBDI_out->KBDI = kbdi

end

