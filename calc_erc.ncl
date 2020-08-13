/;
2018, Copyright University Corporation for Atmospheric Research
;/

load "convert_temp.ncl"
load "convert_prec.ncl"
load "convert_humid.ncl"
load "unit_handling.ncl"
load "calc_julian_day.ncl"
load "calc_vpd.ncl"
load "calc_gsi.ncl"
load "normalize.ncl"
load "find_first.ncl"
load "adjust.ncl"
load "calc_potential_solar.ncl"
load "calc_sow_daily.ncl"
load "calc_pduration.ncl"
load "calc_point_pduration.ncl"
load "calc_paper_pduration.ncl"
load "calc_emc.ncl"
load "calc_x1000.ncl"
load "calc_mcherb.ncl"
load "calc_mcwood.ncl"
load "calc_vegstage.ncl"
load "calc_just_erc_1fuelmod.ncl"
load "calc_just_erc_fuelmap.ncl"
load "check_time_length.ncl"
;load "extract_lat_lon.ncl"

/;
        tmax: daily maximum temperature
        tmin: daily minimum temperature
        prec: 24 hour (daily) precipitation
        rhmax: daily maximum relative humidity
        rhmin: daily minimum relative humidity
	rsds: solar radiation (Downwelling shortwave radiation, in W m-2)
	huss: specific humidity (in kg/kg)
	fm100: percent moisture content for 100-hr timelag (in percent)
	fm1000: percent moisture content for 100-hr timelag (in percent)
	grid: string argument consisting of either the name of a grid ("NAM-22i" or "NAM-44i") or the name of a custom file that contains array of constants over latitude and longitude, used in the determination of the duration of precipitation
        time: time series of all variables
        lat: latitude coordinates for all variables
        lon: longitude coordinates for all variables
        grid: string argument consisting of either the name of a grid ("NAM-22i" or "NAM-44i") or the name of a custom file that contains array of constants over latitude and longitude, used in the determination of the duration of precipitation
	fuel_mod: a letter A-U excluding M which signifies a fuel model as in the NFDRS paper
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

function calc_erc(tmax, tmin, prec, rhmax, rhmin, rsds, huss, fm100, fm1000, time, lat, lon, grid, fuel_mod, iounits, opt)
local units_list, b, elev, latlen, lonlen, timelen, day_year, tempsolar, maxsolar, sow, annperen, climat, pptdur, fuel_mod, w1d, w10d, w100d, w1000d, wherb, wwood, depth, sg1d, sg10d,sg100d,sg1000d,sgherb,sgwood,extmoi,hd,c1,hveg,greendays,colddays,ymherb,ymwood,rh1,vpd,maxt,mint,gsi,gsi_norm,temp1,greenup,yx1000,ym1000, pregrns,pregrn,tmpprm,rhprm,emcprm,fm1,fm10,mcwodi,mcherbi,erc,ndays,year,j_green,x1000,gren,mcherb,greendays,mcwood,hveg,varatts

begin


     	;unit conversions for precip, temperature, and humidity
        size = dimsizes(iounits)

        if(size .eq. 1) then
                if(iounits .eq. -1) then

                        convert_temp("degC", tmax)
                        convert_temp("degC", tmin)
                        convert_humid("%", rhmax)
                        convert_humid("%", rhmin)
                        convert_prec("inches/day", prec)

                end if

        else if(size .eq. 5) then
                units_list = unit_handling((/"tmax", "tmin", "prec", "rhmax", "rhmin"/), iounits)
                if(units_list(0) .ne. "metadata") then
                        tmax@units = units_list(0)
                end if
                if(units_list(1) .ne. "metadata") then
                        tmin@units = units_list(1)
                end if
                if(units_list(2) .ne. "metadata") then
                        prec@units=units_list(2)
                end if
                if(units_list(3) .ne. "metadata") then
                        rhmax@units = units_list(3)
                end if
                if(units_list(4) .ne. "metadata") then
                        rhmin@units = units_list(4)
                end if

                convert_temp("degC", tmax)
                convert_temp("degC", tmin)
                convert_humid("%", rhmax)
                convert_humid("%", rhmin)
                convert_prec("inches/day", prec)

        else
            	print("The length of the iounits vector is 5, corresponding to the units for (/tmax, tmin, prec, rhmax, rhmin/)")
        end if
	end if


	elev = 500.

	latlen = dimsizes(lat)
	lonlen = dimsizes(lon)
	timelen = dimsizes(time)	

	day_year = calc_julian_day(time)
	tempsolar = calc_potential_solar(lat,day_year, elev)
	maxsolar = conform_dims((/timelen, latlen, lonlen/), tempsolar, (/0,1/))
	sow = calc_sow_daily(rsds, prec, maxsolar)

	annperen = "perennial"     ; in MATLAB code, 1 == annual, 2 == perennial
	climat = 3      ;climat is NFDRS Climate class
	pptdur = calc_pduration(grid, prec, lat, lon)        ; if not using z3 as an input, use calc_paper_pduration.

	hveg = conform_dims((/latlen, lonlen/), "pregreen", -1)                ; pregreen, greenup, green, transition, cured, frozen
	greendays = prec(0, :, :)
	greendays = 0.
	colddays = prec(0, :, :)
	colddays = 0.
	ymherb = prec(0, :, :)
	ymherb = 50.
	ymwood = ymherb

	rh1 = rhmin + 2.

	vpd = calc_vpd(tmax, tmin, huss, rh1, elev)           ;the vpd function requires Celsius
	
	maxt = tmax * 1.8 + 32.	;convert Celsius to Fahrenheit for rest of calculations
	mint = tmin * 1.8 + 32.

	gsi = calc_gsi(mint, lat, vpd, day_year, lonlen)
	gsi_norm = normalize(gsi)

	temp1 = maxt - 2.

	greenup = find_first(gsi_norm, day_year, latlen, lonlen)

	yx1000 = fm1000(0, :, :)
	ym1000 = fm1000(0, :, :)

	pregrns = (/50.0,60.0,70.0,80.0/)
	pregrn = pregrns(climat -1)

	tmpprm = temp1
	rhprm = rh1
	adjust(tmpprm, rhprm, sow)      ;this is adjusted temperature and humidity at the fuel-atmosphere interface, as opposed to what is measured at a weather station
	emcprm = calc_emc(tmpprm, rhprm)        ;emcprm is equilibrium moisture content at the fuel-atm interface

	fm1 = where(sow .gt. 4, 35.0, 1.03 * emcprm)
	fm10 = where(sow .gt. 4, 35., 1.28 * emcprm)

	mcwodi = ymherb
	mcwodi = (/pregrn/)
	mcherbi = fm1

	erc = prec      ;establishes lat, lon, etc.
	erc = 0.0
	ndays = dimsizes(time)
	check_time_length(ndays, 365, opt)

	do i=0, ndays - 1

	        year = tointeger(floor(i / 365.2425))
	        j_green = greenup(year, :, :)

	        x1000 = calc_x1000(fm1000(i, :, :), ym1000, yx1000, maxt(i, :, :), mint(i, :, :), hveg)

	        gren = where(hveg .eq. "greenup", 100. * greendays / (7 * climat), -1.0)

	        mcherb  = calc_mcherb(fm1(i, :, :), mcherbi(i, :, :), fm1000(i, :, :), ym1000, greendays, climat, hveg, annperen, x1000, ymherb, gren)
	        greendays = where(hveg .eq. "greenup", greendays + 1, greendays)
	        mcwood = calc_mcwood(pregrn, mcwodi, fm1000(i, :, :), climat, hveg, gren, ymwood)

	        hveg = calc_vegstage(colddays, maxt(i, :, :), mint(i, :, :), day_year(i), j_green, gren, mcherb, hveg)
	        
		if((fuel_mod .eq. "laf") .or. (fuel_mod .eq. "LAF") .or. (fuel_mod .eq. "hybrid") .or. (fuel_mod .eq. "HYBRID"))
			erc(i, :, :) = (/calc_just_erc_fuelmap(mcherb, fm1(i, :, :), fm10(i, :, :), fm100(i, :, :), fm1000(i, :, :), mcwood, lat, lon, fuel_mod, grid)/)
		else
			erc(i, :, :) = (/calc_just_erc_1fuelmod(mcherb, fm1(i, :, :), fm10(i, :, :), fm100(i, :, :), fm1000(i, :, :), mcwood, fuel_mod)/)
		end if

	        colddays = where(hveg .eq. "curing" .and. mint(i, :, :) .lt. 32., colddays + 1, colddays)
	        colddays = where(hveg .eq. "frozen", 0, colddays)
	        yx1000 = (/x1000/)
	        ymherb = (/mcherb/)
	        ymwood = (/mcwood/)

	end do

	delete_VarAtts(erc, -1) ;get rid of superfluous attributes

	erc@long_name = "Energy Release Component"   ; No convention for long names, just make it descriptive

	varatts = (/"units", "missing_value", "_FillValue"/)

	erc@$varatts(0)$ = "1"

	do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
	   erc@$varatts(i)$ = prec@$varatts(i)$
	end do

	return(erc)

end
