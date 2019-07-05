/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
	time: time series for all variables
	tmax: daily maximum temperature in Celsius
	hurs: daily average relative humidity in percent
	spd: daily average windspeed in m/s
	prec: 24 hour (daily) precipitation in mm/day
	lat: latitude for all variables
	lon: longitude for all variables
;/

function calc_cfwi(time, tmax, hurs, spd, prec, lat, lon)
local fd, B, cfwi, ffmc, dmc, dc, Lf, latlen, lonlen, ndays, cal, cal1, day_year, Le, Le1, Le2, tmaxdmc, tmaxdc, m, ffmc, dmc, dc, isi, bui, fd, B, varatts
begin

	ffmc = prec(0, :, :)	;fine fuel moisture content
	dmc = prec(0, :, :)	;duff moisture code
	dc = prec(0, :, :)	;drought code
	m = prec(0, :, :)	;related to ffmc
	ffmc = 85.0		;inital values for ffmc, dmc, dc, and m
	dmc = 6.0
	dc = 15.0
	m = 0.0

	Lf = (/-1.6, -1.6, -1.6, .9, 3.8, 5.8, 5.8, 6.4, 5.0, 2.4, .4, -1.6, -1.6/)     ;"Day length factors" for deeper in the soil... according to month, Jan-Dec

	cfwi = prec
	cfwi = 0.0


	latlen = dimsizes(lat)
	lonlen = dimsizes(lon)


	ndays = dimsizes(time)

	do i = 0, ndays-1

	        cal = cd_calendar(time(i), 0)
	        cal1 = tointeger(cal(0,:))
	        cal1@calendar = time@calendar
	        day_year = day_of_year(cal1(0), cal1(1), cal1(2))
	        Le = daylight_fao56(day_year, lat)
	        Le1 = Le(0, :)
	        Le2 = conform_dims((/latlen, lonlen/), Le1, 0)
		
		m = (/ calc_ffmc(ffmc, hurs(i, :, :), tmax(i, :, :), spd(i, :, :), prec(i, :, :) ) /)	
		ffmc = 59.5 * (250. - m) / (147.2 + m)
		dmc = (/ calc_dmc(dmc, tmax(i, :, :), prec(i, :, :), hurs(i, :, :), Le2) /)
		dc = (/ calc_dc(prec(i, :, :), tmax(i, :, :), dc, Lf(cal1(1)-1)) /)
		isi = (/ calc_isi(spd(i, :, :), m) /)
		bui = (/ calc_bui(dmc, dc) /)

		fd = where(bui .gt. 80., 1000. / (25. + 108.64 * exp(-0.023 * bui)), 0.626 * bui^0.809 + 2)
		B = 0.1 * isi * fd
		cfwi(i, :, :) = where(B .gt. 1., exp(2.72 * (.434 * log(B))^.647), B)

		cfwi(i, :, :) = cfwi(i, :, :) > 0.0

	end do

	delete_VarAtts(cfwi, -1)
	cfwi@longname = "Canadian Fire Weather Index"
	varatts = (/"units", "missing_value", "_FillValue"/)
	cfwi@$varatts(0)$ = "1"         ; cfwi is unitless

	do i = 1, dimsizes(varatts)-1
	        cfwi@$varatts(i)$ = prec@$varatts(i)$
	end do

	return(cfwi)

end

