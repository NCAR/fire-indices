/;
2018, Copyright University Corporation for Atmospheric Research
;/

; daily data must be fed into the program
; precip_d is daily precipitation in inches/day
; maxtemp is daily maximum temperature in Fahrenheit
; annual_pr is the mean annual precipitation in inches/day

function calc_kbdi ( daily_precip, tmax, annual_pr )
local dQ, precip_adj

begin

;Set up KBDI variable
kbdi = daily_precip
kbdi = 0.0

precip_acc = daily_precip(0, :, :)
precip_acc = 0.0
Q = kbdi(0, :, :)	;serves as temporary kbdi variable in loop
Q = 100.0	;initial KBDI value, taken from Larry's code. Different sources have different starting points.

ndays = dimsizes(daily_precip(:,0,0))

do i=0, ndays-1
	precip_d = daily_precip(i, :, :)
	maxtemp = tmax(i, :, :)

	precip_adj = precip_d
	precip_adj = 0.         ;adjusted accumulated precipitation to account for evapotranspiration
	; assume the day before the beginning of the run did not have any precipitation
	
	;precip_acc is accumulated precipitation
	precip_acc = where(precip_d .le. 0.0, 0.0, precip_acc + precip_d)       ; if no precip falls, reset precip_acc to 0
	precip_adj = (precip_acc - 0.2) > 0	; adjust rainfall to account for 0.2 inches of evapotranspiration. drought index is reduced 1 pt for every 0.01 inches of adjusted rainfall
	precip_acc = precip_acc < 8.0         ; soil is saturated at 8 inches of precip_acc

	;dQ is the incremental change in KBDI
	dQ = where(maxtemp .ge. 50.0, (800. - Q) * (0.968 * exp(0.0486 * maxtemp) - 0.83) / (1 + 10.88 * exp(-0.0441 * annual_pr)) * 0.001, 0)
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
        kbdi@$varatts(i)$ = daily_precip@$varatts(i)$ ;@@@
end do

return(kbdi)

end

