; daily data must be fed into the program
; precip_d is daily precipitation. read in in mm
; maxtemp is daily maximum temperature. read in in deg C
; Q is the initial (previous day's) KBDI
; annual_pr is the mean annual precipitation. read in in mm
; precip_acc is the accumulated precipitation over contiguous days

procedure calc_kbdi ( precip_d, maxtemp, Q, annual_pr, precip_acc )
local dQ, precip_adj

begin

;dP is precip_adj

precip_adj = precip_d   ;to transfer metadata to new variable
precip_adj = 0.         ;adjusted accumulated precipitation to account for evapotranspiration
; assume the day before the beginning of the run did not have any precipitation

precip_acc = where(precip_d .eq. 0.0, 0.0, precip_acc + precip_d)       ; if no precip falls, reset precip_acc to 0
precip_adj = ((precip_acc - 0.2) > 0 ) * 100	; adjust raonfall to account for 0.2 inches of evapotranspiration. drought index is reduced 1 pt for every 0.01 inches of adjusted rainfall
precip_acc = precip_acc < 8.0         ; soil is saturated at 8 inches of precip_acc

;dQ is the incremental change in KBDI
dQ = where(maxtemp .ge. 50.0, (800. - Q) * (0.968 * exp(0.0486 * maxtemp) - 0.83) / (1 + 10.88 * exp(-0.0441 * annual_pr)) * 0.001, 0)
;dQ is adjusted to 0 when maxtemp < 50 deg F, otherwise is calculated according to KBDI original paper. Adjustment taken from Liu et al.

;Q
;only Q is used instead of Q and Q0 to preserve metadata

Q = Q + dQ - precip_adj ;drought index is reduced 1 point for every .01 inches of adjusted rainfall

Q = Q < 800.0		;maximum KBDI is 800
Q = Q > 0.0	        ;minimum KBDI is 0

end

