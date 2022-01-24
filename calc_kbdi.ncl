/;
2018, Copyright University Corporation for Atmospheric Research
;/

load "convert_temp.ncl"
load "convert_prec.ncl"
load "unit_handling.ncl"
load "check_time_length.ncl"

; daily data must be fed into the program

/; 
	prec is daily precipitation
	tmax is daily maximum temperature
	calendar is the string describing which calendar was used for prec, tmax. Supported calendars: gregorian, standard, 365_day, 366_day, 360_day, no_leap, all_leap
	iounits: integer array corresponding to units of tmax and prec

		   iounit(0)=-1 input tmax (metadata)
		   iounit(0)=0 input tmax (degC)
		   iounit(0)=1 input tmax (degK)
		   iounit(0)=2 input tmax (degF)

		   iounit(1)=-1 input prec (metadata)
		   iounit(1)=0 input prec (mm/day)
		   iounit(1)=1 input prec (inches/day)
		   iounit(1)=2 input prec (kg m-2 s-1)

;/
; Q is the initial (previous day's) KBDI
; annual_pr is the mean annual precipitation. read in in mm
; precip_acc is the accumulated precipitation over contiguous days


function calc_kbdi ( prec, tmax, calendar, iounits, opt )
local kbdi, precip_acc, Q, total_precip, ndaysyear, ndays, nyears, annual_pr, dQ, precip_adj

begin

size = dimsizes(iounits)

if(size .eq. 1) then
	if(iounits .eq. -1) then
		convert_temp("degF", tmax)                      ;convert to Fahrenheit
		convert_prec("inches/day", prec)
	else
		print("The iounits value "+ iounits +" is not recognized. To indicate that all input units should be taken from metadata, input the value -1. Otherwise, indicate units according to documentation in a vector of (/tmax, prec/).")
	end if
end if
if(size .gt. 1) then
	units = unit_handling((/"tmax", "prec"/), iounits)
	if(units(0) .ne. "metadata") then
		tmax@units = units(0)
	end if

	if(units(1) .ne. "metadata") then
		prec@units = units(1)
	end if

	convert_temp("degF", tmax)
	convert_prec("inches/day", prec)
end if

;Set up KBDI variable
kbdi = prec
kbdi = 0.0

precip_acc = prec(0, :, :)
precip_acc = 0.0
Q = kbdi(0, :, :)
Q = 100.0	;initial KBDI value, taken from Larry's code. Different sources have different starting points.

total_precip = dim_sum_n(prec, 0)

ndaysyear = 365.2425    ;gregorian or standard length of year

if(calendar .eq. "noleap" .or. calendar .eq. "365_day") then
        ndaysyear = 365.0
else if(calendar .eq. "all_leap" .or. calendar .eq. "366_day") then
        ndaysyear = 366.0
else if(calendar .eq. "360_day") then
        ndaysyear = 360.0
else if(calendar .eq. "gregorian" .or. calendar .eq. "standard") then
	ndaysyear = 365.2425
else
	print("calendar not recognized. Proceeding with gregorian/standard calendar.")
end if
end if
end if
end if

ndays = dimsizes(prec(:,0,0))             ; extracts number of days in a daily dataset
nyears = ndays/ndaysyear

check_time_length(ndays, ndaysyear * 30.0, opt)

annual_pr = total_precip / nyears

ndays = dimsizes(prec(:,0,0))

do i=0, ndays-1
	precip_d = prec(i, :, :)
	maxtemp = tmax(i, :, :)

	precip_adj = precip_d
	precip_adj = 0.         ;adjusted accumulated precipitation to account for evapotranspiration
	; assume the day before the beginning of the run did not have any precipitation

	precip_acc = where(precip_d .le. 0.0, 0.0, precip_acc + precip_d)       ; if no precip falls, reset precip_acc to 0
	precip_adj = (precip_acc - 0.2) > 0	; adjust rainfall to account for 0.2 inches of evapotranspiration. drought index is reduced 1 pt for every 0.01 inches of adjusted rainfall
	precip_acc = precip_acc < 8.0         ; soil is saturated at 8 inches of precip_acc

	;dQ is the incremental change in KBDI
	dQ = where(maxtemp .ge. 50.0, (800. - Q) * (0.968 * exp(0.0486 * maxtemp) - 8.3) / (1 + 10.88 * exp(-0.0441 * annual_pr)) * 0.001, 0)
	;dQ is adjusted to 0 when maxtemp < 50 deg F, otherwise is calculated according to KBDI original paper. Adjustment taken from Liu et al.

	Q = Q + dQ - (precip_adj * 100) ;drought index is reduced 1 point for every .01 inches of adjusted rainfall

	Q = Q < 800.0             ;maximum KBDI is 800
	Q = Q > 0.0               ;minimum KBDI is 0
	
	kbdi(i, :, :) = Q
end do

delete_VarAtts(kbdi, -1)   ; get rid of superfluous attributes
kbdi@long_name = "Keetch-Byram Drought Index"
varatts = (/"units", "missing_value", "_FillValue"/)
kbdi@$varatts(0)$ = "1"            ;KBDI is unitless

do i = 1, dimsizes(varatts)-1
        kbdi@$varatts(i)$ = prec@$varatts(i)$ ;@@@
end do

return(kbdi)

end

