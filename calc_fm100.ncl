/;
2018, Copyright University Corporation for Atmospheric Research
;/

load "convert_temp.ncl"
load "convert_prec.ncl"
load "convert_humid.ncl"
load "unit_handling.ncl"
load "calc_emc.ncl"
load "calc_julian_day.ncl"
load "calc_daylight_builtin.ncl"
load "calc_daylight_manual.ncl"
load "calc_pduration.ncl"
load "calc_point_pduration.ncl"
load "calc_paper_pduration.ncl"
load "check_time_length.ncl"

/;
        tmax: daily maximum temperature
        tmin: daily minimum temperature
        prec: 24 hour daily precipitation
        rhmax: daily maximum relative humidity
        rhmin: daily minimum relative humidity
        time: time series of all variables
        lat: latitude coordinates for all variables
        lon: longitude coordinates for all variables
        grid: string argument consisting of either the name of a grid ("NAM-22i" or "NAM-44i") or the name of a custom file that contains array of constants over latitude and longitude, used in the determination of the duration of precipitation
	iounits: integer array corresponding to units of tmax, tmin, prec, rhmax, and rhmin

		  iounit(0)=-1 input tmax (metadata)
		  iounit(0)=0 input tmax (degC)
		  iounit(0)=1 input tmax (degK)
		  iounit(0)=2 input tmax (degF)

		  iounit(1)=-1 input tmin (metadata)
		  iounit(1)=0 input tmin (degC)
		  iounit(1)=1 input tmin (degK)
		  iounit(1)=2 input tmin (degF)

		  iounit(2)=-1 input prec (metadata)
		  iounit(2)=0 input prec (mm/day)
		  iounit(2)=1 input prec (inches/day)
		  iounit(2)=2 input prec (kg m-2 s-1)

		  iounit(3)=-1 input rhmax (metadata)
		  iounit(3)=0 input rhmax (%)
		  iounit(3)=1 input rhmax (1)

		  iounit(4)=-1 input rhmin (metadata)
		  iounit(4)=0 input rhmin (%)
		  iounit(4)=1 input rhmin (1)

;/

function calc_fm100(tmax, tmin, prec, rhmax, rhmin, time, lat, lon, grid, iounits, opt)
local climcl, fm100, yfm, emcmax, emcmin, day_year, latlen, lonlen, pptdur, fr100, emcbar, ndays, daylit, bndryh1, bndryh, varatts
begin

	;unit conversions for precip, temperature, and humidity
	size = dimsizes(iounits)

	if(size .eq. 1) then
	        if(iounits .eq. -1) then

			convert_temp("degF", tmax)
			convert_temp("degF", tmin)
			convert_humid("%", rhmax)
			convert_humid("%", rhmin)
			convert_prec("inches/day", prec)

		else
                	print("The iounits value "+ iounits +" is not recognized. To indicate that all input units should be taken from metadata, input the value -1. Otherwise, indicate units according to documentation in a vector of (/tmax, tmin, prec, rhmax, rhmin/).")
	        end if
	
	else if(size .eq. 5) then
	        units = unit_handling((/"tmax", "tmin", "prec", "rhmax", "rhmin"/), iounits)
		if(units(0) .ne. "metadata") then
		        tmax@units = units(0)
		end if
		if(units(1) .ne. "metadata") then
		        tmin@units = units(1)
                end if
                if(units(2) .ne. "metadata") then
		        prec@units=units(2)
                end if
                if(units(3) .ne. "metadata") then
		        rhmax@units = units(3)
                end if
                if(units(4) .ne. "metadata") then
		        rhmin@units = units(4)
		end if

	 	convert_temp("degF", tmax)
		convert_temp("degF", tmin)
		convert_humid("%", rhmax)
		convert_humid("%", rhmin)
		convert_prec("inches/day", prec)

	else
		print("The length of the iounits vector is 5, corresponding to the units for (/tmax, tmin, prec, rhmax, rhmin/)")
	end if
	end if


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
	pptdur = calc_pduration(grid, prec, lat, lon)

	fr100 = 1.0 - 0.87 * exp(-0.24)

	emcbar = emcmin(0, :, :)

	ndays = dimsizes(time)
	check_time_length(ndays, 365, opt)

	do i = 0, ndays-1

		daylit = dble2flt(calc_daylight_manual(day_year(i), lat, lonlen))
		emcbar = (daylit(0, :, :) * emcmin(i, :, :) + (24.0 - daylit(0, :, :)) * emcmax(i, :, :)) / 24.		;emcbar is average equilibrium moisture content

		bndryh1 = ((24. - pptdur(i, :, :)) * emcbar + pptdur(i, :, :) * (0.5 * pptdur(i, :, :) + 41.0)) / 24.
		bndryh = dble2flt(bndryh1)
		fm100(i, :, :) = (bndryh - yfm) * fr100 + yfm
		
		yfm = fm100(i, :, :)

	end do

	delete_VarAtts(fm100, -1) ;get rid of superfluous attributes
	fm100@long_name = "Percent Moisture Content for 100-hr timelag"   ; No convention for long names, just make it descriptive
	fm100@standard_name = "nfdrs_100_hour_fuel_moisture"
	varatts = (/"units", "missing_value", "_FillValue"/)
	fm100@$varatts(0)$ = "%"

	do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
	   fm100@$varatts(i)$ = prec@$varatts(i)$
	end do

	return(fm100)

end


