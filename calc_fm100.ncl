/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 emcbar is average equilibrium moisture content
 pptdur is precipitation duration
 yfm is yesterday's fm100
 fr100 is a constant
;/
;function calc_fm100(emcbar, pptdur, yfm, fr100)
function calc_fm100(time, prec, tmax, tmin, rhmax, rhmin, lat, lon, b)
local climcl, fm100, yfm, emcmax, emcmin, day_year, latlen, lonlen, pptdur, fr100, emcbar, ndays, daylit, bndryh1, bndryh, varatts
begin

climcl = 3.
fm100 = tmax
fm100 = -1.
yfm = tmax(0, :, :)
yfm = 10.

emcmax = calc_emc(tmin, rhmax)
emcmin = calc_emc(tmax, rhmin)
day_year = calc_julian_day(time)

latlen = dimsizes(lat)
lonlen = dimsizes(lon)
pptdur = calc_pduration(b, prec, latlen, lonlen)

fr100 = 1.0 - 0.87 * exp(-0.24)

emcbar = emcmin(0, :, :)

ndays = dimsizes(time)
do i = 0, ndays-1

	daylit = dble2flt(calc_daylight_manual(day_year(i), lat, lonlen))
	emcbar = (daylit(0, :, :) * emcmin(i, :, :) + (24.0 - daylit(0, :, :)) * emcmax(i, :, :)) / 24.

	bndryh1 = ((24. - pptdur(i, :, :)) * emcbar + pptdur(i, :, :) * (0.5 * pptdur(i, :, :) + 41.0)) / 24.
	bndryh = dble2flt(bndryh1)
	fm100(i, :, :) = (bndryh - yfm) * fr100 + yfm
	
	yfm = fm100(i, :, :)

end do

delete_VarAtts(fm100, -1) ;get rid of superfluous attributes
fm100@long_name = "Percent Moisture Content for 100-hr timelag"   ; No convention for long names, just make it descriptive
varatts = (/"units", "missing_value", "_FillValue"/)
fm100@$varatts(0)$ = "%"

do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
   fm100@$varatts(i)$ = prec@$varatts(i)$
end do

return(fm100)

end


