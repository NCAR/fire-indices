/;
2018, Copyright University Corporation for Atmospheric Research
;/
function calc_fm1000(time, prec, tmax, tmin, rhmax, rhmin, lat, lon, b)
local day_year, latlen, lonlen, emcmin, emcmax, climat, pptdur, startup, temp, bndryt, mc1000_r, divsev, tempbnd, bdybar, mc1000, ndays, fr1000, daylit, emcbar, varatts
begin

day_year = calc_julian_day(time)
latlen = dimsizes(lat)
lonlen = dimsizes(lon)

emcmin = calc_emc(tmax, rhmin)
emcmax = calc_emc(tmin, rhmax)

climat = 3.     ;possible refinement: create a file with each gridcell assigned a class according to fuel moisture and such, as seen on the cover of The National Fire Danger Rating System: basic equations (1985)
pptdur = calc_pduration(b, prec, latlen, lonlen)

;spin-up conditions
startup = 10. + 5.0 * climat
temp = conform_dims((/7, latlen, lonlen/), startup, -1)
bndryt = temp
mc1000_r = bndryt

divsev = conform_dims((/latlen, lonlen/), 7., -1)
tempbnd = dim_cumsum_n_Wrap(bndryt, 0, 0)
bdybar = tempbnd(6, :, :)/divsev

mc1000 = prec

ndays = dimsizes(time)
fr1000 = 1 - 0.82 * exp(-0.168)

do i = 0, ndays-1
        daylit = calc_daylight_manual(day_year(i), lat, lonlen)
        emcbar = (daylit(0,:,:) * emcmin(i, :, :) + (24. - daylit(0,:,:)) * emcmax(i, :, :)) / 24.
        bndryt(0:5, :, :) = bndryt(1:6, :, :)
        bndryt(6, :, :) = dble2flt(((24 - pptdur(i, :, :)) * emcbar + (2.7 * pptdur(i, :, :) + 76.) * pptdur(i, :, :)) / 24.)
        tempbnd = dim_cumsum_n_Wrap(bndryt, 0, 0)
        bdybar = tempbnd(6, :, :) / divsev
        mc1000(i, :, :) = (/(mc1000_r(0, :, :) + (bdybar - mc1000_r(0, :, :)) * fr1000)/)
        mc1000_r(0:5, :, :) = mc1000_r(1:6, :, :)
;       mc1000_r(6, :, :) = dble2flt(mc1000(i, :, :))
        mc1000_r(6, :, :) = mc1000(i, :, :)
end do

delete_VarAtts(mc1000, -1) ;get rid of superfluous attributes

mc1000@long_name = "Percent Moisture Content for 1000-hr timelag"  

varatts = (/"units", "missing_value", "_FillValue"/)
mc1000@$varatts(0)$ = "1"

do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
   mc1000@$varatts(i)$ = prec@$varatts(i)$
end do

return(mc1000)

end
