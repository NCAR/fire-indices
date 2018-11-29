/;
2018, Copyright University Corporation for Atmospheric Research
;/


; kbdi main
; precipitation is either pr or prec. Alter for whichever dataset is being used, lines have been marked with @@@ in comment. additionally, pr needs the conversion line

; read in from 2 files: daily precipitation and daily maximum temperatures
; The following variables should be specified as command-line arguments (ncl file = \"$file\" script.ncl):
; precip_in = \"some file\"	read in
; tmpmax_in = \"some file\"	read in
; output = \"kbdi.nc\"	write out

;final calculations require precipitation in inches and temperature in Fahrenheit. Currently, the program expects rain in mm and temperature in Kelvin as inputs

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

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL script from source files "+precip_in+" and "+tmpmax_in
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

;check for missing values and fill them
miss_tmax = any(ismissing(tmax))
miss_prec = any(ismissing(daily_precip))

if(miss_prec) then
	missing = ismissing(daily_precip)       ; find all missing values in daily_precip
	daily_precip = where(missing, .1, daily_precip)       ; mm of precip. Value taken from Larry's code (.1 in)
end if

;calculate mean annual precipitation, save to variable mean_ann_precip
total_precip = sum(daily_precip)	; add all precipitation values together.
ndaysyear = 365.2425			;change according to "calendar" attribute for time (currently set for standard)
ndays = read_precip->time		; extracts number of days in a daily dataset
nyears = ndays/ndaysyear
mean_ann_precip = total_precip / nyears		; note that this may need to be adjusted to account for ragged edges, worked for the sample file
mean_ann_precip@units = daily_precip@units

pr = daily_precip(0,:,:)	;transfer metadata to pr
pr = 0.0			;pr is accumulated precipitation, assume the day before the start of the run did not have precipitation
Q0 = daily_precip(0,:,:)	;transfer metadata to Q0
Q0 = 100.0			;initial KBDI, taken from Larry's code it is 100, or 400 from atriplex. After KBDI hits 0 for the first time this no longer has effect

;convert temp and prec
convert_temp("degF", tmax)			;convert to Fahrenheit
convert_prec("inches/day", mean_ann_precip)
convert_prec("inches/day", daily_precip)
missing = ismissing(daily_precip)       ; find all missing values in daily_precip
daily_precip = where(missing, .1, daily_precip)       ; mm of precip. Value taken from Larry's code (.1 in)

; calculate first step of KBDI, using Q0
first_step = 0
Q = daily_precip
Q = 0.0

calc_kbdi(daily_precip(first_step,:,:), tmax(first_step,:,:), Q0, mean_ann_precip, pr )

Q(0,:,:) = Q0

delete_VarAtts(Q, -1)	; get rid of superfluous attributes
Q@long_name = "Keetch-Byram Drought Index"
varatts = (/"units", "missing_value", "_FillValue"/)
Q@$varatts(0)$ = "1"		;KBDI is unitless

do i = 1, dimsizes(varatts)-1
	Q@$varatts(i)$ = read_precip->prec@$varatts(i)$	;@@@
end do

Q_temp = Q(0, :, :)

; calculate the rest of the time series of KBDI using previous Q as next Q
do i=1, ndays-1
	calc_kbdi(daily_precip(i,:,:), tmax(i,:,:), Q_temp, mean_ann_precip, pr )
	Q(i,:,:) = Q_temp
end do

KBDI_out->KBDI = Q

end

