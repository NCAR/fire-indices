/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
        tmax: daily maximum temperature
	prec: 24 hour precipitation
        hurs: daily relative humidity
        spd: daily wind speed
        time: time series of all variables
        lat: latitude coordinates for all variables
        lon: longitude coordinates for all variables
        iounits: integer array corresponding to units of tmax, prec, hurs, spd

		  iounit(0)=-1 input tmax (metadata)
		  iounit(0)=0 input tmax (degC)
		  iounit(0)=1 input tmax (degK)
		  iounit(0)=2 input tmax (degF)

		  iounit(1)=-1 input prec (metadata)
		  iounit(1)=0 input prec (mm/day)
		  iounit(1)=1 input prec (inches/day)
		  iounit(1)=2 input prec (kg m-2 s-1)

		  iounit(2)=-1 input rhmax (metadata)
		  iounit(2)=0 input rhmax (%)
		  iounit(2)=1 input rhmax (1)

		  iounit(3)=-1 input spd (metadata)
		  iounit(3)=0 input spd (m s-1)
		  iounit(3)=1 input spd (mph)

;/


load "calc_ffmc.ncl"
load "calc_dmc.ncl"
load "calc_dc.ncl"
load "calc_isi.ncl"
load "calc_bui.ncl"
load "convert_temp.ncl"
load "convert_prec.ncl"
load "convert_humid.ncl"
load "convert_wind.ncl"
load "unit_handling.ncl"
load "check_time_length.ncl"

function calc_cfwi(tmax, prec, hurs, spd, time, lat, lon, iounits, opt)
local fd, B, cfwi, ffmc, dmc, dc, Lf, latlen, lonlen, ndays, cal, cal1, day_year, Le, Le1, Le2, tmaxdmc, tmaxdc, m, ffmc, dmc, dc, isi, bui, fd, B, varatts, size
begin

size = dimsizes(iounits)

if(size .eq. 1) then
        if(iounits .eq. -1) then
                convert_humid("%", hurs)
		convert_prec("mm/day", prec)
                convert_temp("degC", tmax)
                convert_wind("m/s", spd)
	else
                print("The iounits value "+ iounits +" is not recognized. To indicate that all input units should be taken from metadata, input the value -1. Otherwise, indicate units according to documentation in a vector of (/tmax, prec, hurs, spd/).")
        end if
end if
if(size .gt. 1) then
        units = unit_handling((/"tmax", "prec", "hurs", "spd"/), iounits)

	if(units(0) .ne. "metadata") then
        	tmax@units = units(0)
	end if
	if(units(1) .ne. "metadata") then
		prec@units=units(1)
	end if
        if(units(2) .ne. "metadata") then
        	hurs@units = units(2)
	end if
        if(units(3) .ne. "metadata") then
        	spd@units = units(3)
	end if
	
        convert_humid("%", hurs)
	convert_prec("mm/day", prec)
        convert_temp("degC", tmax)
        convert_wind("m/s", spd)
end if

ffmc = prec(0, :, :)
dmc = prec(0, :, :)
dc = prec(0, :, :)
m = prec(0, :, :)
ffmc = 85.0
dmc = 6.0
dc = 15.0
m = 0.0

Lf = (/-1.6, -1.6, -1.6, .9, 3.8, 5.8, 5.8, 6.4, 5.0, 2.4, .4, -1.6, -1.6/)     ;"Day length factors" for deeper in the soil... according to month, Jan-Dec

cfwi = prec
cfwi = 0.0


latlen = dimsizes(lat)
lonlen = dimsizes(lon)
ndays = dimsizes(time)

check_time_length(ndays, 365, opt)

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
cfwi@long_name = "Canadian Fire Weather Index"
cfwi@standard_name = "canadian_fire_weather_index"
varatts = (/"units", "missing_value", "_FillValue"/)
cfwi@$varatts(0)$ = "1"         ; cfwi is unitless

do i = 1, dimsizes(varatts)-1
        cfwi@$varatts(i)$ = prec@$varatts(i)$
end do

return(cfwi)

end

