/;
2018, Copyright University Corporation for Atmospheric Research
;/

;Calculate modified Fosberg Fire Weather Index
;daily index

/;
	spd is windspeed in mph
	hurs is relative humidity in percent
	tmax is temperature in degrees Fahrenheit
	kbdi is Keetch Byram Drought Index
;/

load "calc_emc.ncl"

function calc_mFFWI( spd, hurs, tmax, kbdi)
local mFFWI, FFWI, FAF, bf, eta, em0, em, c1, c2, c3, emc
;mFFWI is modified FFWI, FFWI is Fosberg Fire Weather Index, FAF is Fuel Availability Factor
begin

	c1 = 1.0
	c2 = 1.5
	c3 = -0.5
	em0 = 0.72
	em = 0.000002
	bf = 1. / 0.3002

	emc = calc_emc(tmax, hurs) ;equilibrium moisture content
	eta = 1 - 2 * (emc / 30) + c2 * (emc / 30) ^ 2 + c3 * (emc / 30) ^ 3
	FFWI = bf * eta * (1 + spd^2.)^0.5
	FAF = em0 + (em * kbdi^2.)
	mFFWI = kbdi
	mFFWI = FAF * FFWI

	delete_VarAtts(mFFWI, -1)               ;get rid of superfluous attributes
	mFFWI@long_name = "modified Fosberg Fire Weather Index"
	varatts = (/"units","missing_value","_FillValue"/)
	mFFWI@$varatts(0)$ = "1"        ;mFFWI is unitless

	do i = 1, dimsizes(varatts) -1
	        mFFWI@$varatts(i)$ = tmax@$varatts(i)$
	end do

	return(mFFWI)

end
