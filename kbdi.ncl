; daily data must be fed into the program
; precip_d is daily precipitation. read in in mm
; maxtemp is daily maximum temperature. read in in deg C
; Q is the initial (previous day's) KBDI
; annual_pr is the mean annual precipitation. read in in mm
; precip_acc is the accumulated precipitation over contiguous days

function kbdi_index ( precip_d, maxtemp, Q, annual_pr, precip_acc )
local dQ, precip_adj, QplusPr

begin

;dP is precip_adj

precip_adj = precip_d	;to transfer metadata to new variable
precip_adj = 0.		;adjusted accumulated precipitation to account for evapotranspiration
; assume the day before the beginning of the run did not have any precipitation

precip_acc = where(precip_d .eq. 0.0, 0.0, precip_acc + precip_d)	; if no precip falls, reset precip_acc to 0

precip_adj = where(precip_acc .gt. 0.2, precip_acc - 0.2, 0)	; adjust rainfall only when precip_acc over consecutive days >0.2

precip_acc = where(precip_acc .gt. 8.0, 8.0, precip_acc)	; soil is saturated at 8 inches of precip_acc

;dQ is the incremental change in KBDI
dQ = where(maxtemp .ge. 50.0, (800. - Q) * (0.968 * exp(0.0486 * maxtemp) - 0.83) / (1 + 10.88 * exp(-0.0441 * annual_pr)) * 0.001, 0)
;dQ is adjusted to 0 when maxtemp < 50 deg F, otherwise is calculated according to KBDI original paper. Adjustment taken from Liu et al.

;Q
;only Q is used instead of Q and Q0 to preserve metadata

precip_adj = precip_adj * 100

Q = Q + dQ - precip_adj	;drought index is reduced 1 point for every .01 inches of adjusted rainfall

Q = where(Q .gt. 800.0, 800.0, Q)	;maximum KBDI is 800
Q = where(Q .lt. 0.0, 0.0, Q)		;minimum KBDI is 0

QplusPr = (/Q,precip_acc/)

return(QplusPr)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

; precipitation is either pr or prec. Alter for whichever dataset is being used, lines have been marked with @@@ in comment

begin

; read in from 2 files: daily precipitation and daily maximum temperatures
; The following variables should be specified as command-line arguments (ncl file = \"$file\" script.ncl):
; precip_in = "some file"	read in
; temper_in = "some file"	read in
; output = "kbdi.nc"	write out

;assume for now that precip is read in in mm, any conversions can be added later

read_precip = addfile(precip_in, "r")
read_temper = addfile(temper_in, "r")

system("rm -f "+output)
KBDI_out = addfile(output, "c") ; create new file to store KBDI

filedimdef(KBDI_out, "time", -1, True)	;makes time dimension unlimited

; copy / set global attributes
att_names = getvaratts(read_precip)
do i = 0, dimsizes(att_names)-1				;transfer global attributes of precip onto KBDI
	KBDI_out@$att_names(i)$ = read_precip@$att_names$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL script from source files "+precip_in+" and "+temper_in
KBDI_out@history = history

var_names = getfilevarnames(read_precip)

do i = 0, dimsizes(var_names)-1			;attach all variables but precipitation onto KBDI (lat, long, time)
	if (var_names(i) .ne. "pr") then	;@@@
		KBDI_out->$var_names(i)$ = read_precip->$var_names(i)$
	end if
end do

;read in daily precipitation
daily_precip = read_precip->pr	;@@@
;if the units of precip are kg/m^2/s then convert to mm/day with following line
daily_precip = daily_precip * 60 * 60 * 24

;read in maximum daily temperature
tmax = read_temper->tasmax

missing = ismissing(daily_precip)	; find all missing values in daily_precip
daily_precip = where(missing, 2.54, daily_precip)	; mm of precip. Value taken from Larry's code (.1 in)

;calculate mean annual precipitation, save to variable mean_ann_precip
total_precip = sum(daily_precip)	; add all precipitation values together.
ndaysyear = 365.2425			;change according to "calendar" attribute for time (currently set for standard)
ndays = dimsizes(read_precip->time)		; extracts number of days in a daily dataset
nyears = ndays/ndaysyear
mean_ann_precip = total_precip / nyears		; note that this may need to be adjusted to account for ragged edges, worked for the sample file
;mean_ann_precip = mean_ann_precip / 25.4		; convert mean ann precip to inches from mm

pr = daily_precip(0,:,:)	;transfer metadata to pr
pr = 0.0			;pr is accumulated precipitation, assume the day before the start of the run did not have precipitation
Q0 = daily_precip(0,:,:)	;transfer metadata to Q0
Q0 = 100.0			;initial KBDI, taken from Larry's code it is 100, or 400 from atriplex. After KBDI hits 0 for the first time this no longer has effect

;convert temp and prec
;tmax = (tmax * (9. / 5.)) + 32.			;Celsius to Fahrenheit
tmax = 9. / 5. * (tmax - 273.15) + 32.0			;Kelvin to Fahrenheit
mean_ann_precip = mean_ann_precip / 25.4	;mm to inches
daily_precip = daily_precip / 25.4


; calculate first step of KBDI, using Q0
first_step = 0
QandPr = kbdi_index(daily_precip(first_step,:,:), tmax(first_step,:,:), Q0, mean_ann_precip, pr )

Q = daily_precip
Q = 0

Q(0,:,:) = (/QandPr(0,:,:)/)
pr = (/QandPr(1,:,:)/)

delete_VarAtts(Q, -1)	; get rid of superfluous attributes
Q@long_name = "Keetch-Byram Drought Index"
varatts = (/"units", "missing_value", "_FillValue"/)
Q@$varatts(0)$ = "1"		;KBDI is unitless

do i = 1, dimsizes(varatts)-1
	Q@$varatts(i)$ = read_precip->pr@$varatts(i)$	;@@@
end do

KBDI_out->KBDI = Q	

; calculate the rest of the time series of KBDI using previous Q as next Q
do i=1, ndays-1
	QandPr = kbdi_index(daily_precip(i,:,:), tmax(i,:,:), Q(i-1,:,:), mean_ann_precip, pr )
	Q(i,:,:) = (/QandPr(0,:,:)/)
	pr =(/QandPr(1,:,:)/)
	KBDI_out->time(i) = read_precip->time(i)	;append Q
	KBDI_out->KBDI(i,:,:) = (/Q(i,:,:)/)		
end do

end

