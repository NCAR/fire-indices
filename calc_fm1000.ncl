/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
        tmax: daily maximum temperature (in Fahrenheit)
        tmin: daily minimum temperature (in Fahrenheit)
        prec: 24 hour (daily) precipitation (in inches/day)
        rhmax: daily maximum relative humidity (in percent)
        rhmin: daily minimum relative humidity (in percent)
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

function calc_fm1000(tmax, tmin, prec, rhmax, rhmin, time, lat, lon, grid, iounits, opt)
local day_year, latlen, lonlen, emcmin, emcmax, climat, pptdur, startup, temp, bndryt, mc1000_r, divsev, tempbnd, bdybar, mc1000, ndays, fr1000, daylit, emcbar, varatts
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


	day_year = calc_julian_day(time)
	latlen = dimsizes(lat)
	lonlen = dimsizes(lon)

	emcmin = calc_emc(tmax, rhmin)
	emcmax = calc_emc(tmin, rhmax)

	climat = 3.     ;possible refinement: create a file with each gridcell assigned a class according to fuel moisture and such, as seen on the cover of The National Fire Danger Rating System: basic equations (1985)
	pptdur = calc_pduration(grid, prec, lat, lon)

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
	check_time_length(ndays, 365, opt)

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
	mc1000@standard_name = "nfdrs_1000_hour_fuel_moisture"
	varatts = (/"units", "missing_value", "_FillValue"/)
	mc1000@$varatts(0)$ = "1"

	do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
	   mc1000@$varatts(i)$ = prec@$varatts(i)$
	end do

	return(mc1000)

end
