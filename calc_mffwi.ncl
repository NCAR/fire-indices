/;
;2018, Copyright University Corporation for Atmospheric Research
;/

/;
	tmax: daily maximum temperature
	rh: daily relative humidity
	spd: daily wind speed
	kbdi: daily Keetch Byram Drought Index
	iounits: integer array corresponding to units of tmax, rh, and spd

		   iounit(0)=-1 input tmax (metadata)
		   iounit(0)=0 input tmax (degC)
		   iounit(0)=1 input tmax (degK)
		   iounit(0)=2 input tmax (degF)

		   iounit(1)=-1 input rh (metadata)
		   iounit(1)=0 input rh (%)
		   iounit(1)=1 input rh (1)

		   iounit(2)=-1 input spd (metadata)
		   iounit(2)=0 input spd (m s-1)
		   iounit(2)=1 input spd (mph)

;/

load "calc_emc.ncl"
load "unit_handling.ncl"
load "convert_temp.ncl"
load "convert_humid.ncl"
load "convert_wind.ncl"

;Calculate modified Fosberg Fire Weather Index

function calc_mffwi(tmax, rh, spd, kbdi, iounits)
local mFFWI, FFWI, FAF, bf, eta, em0, em, c1, c2, c3, emc
;mFFWI is modified FFWI, FFWI is Fosberg Fire Weather Index, FAF is Fuel Availability Factor
begin

size = dimsizes(iounits)

if(size .eq. 1) then
        if(iounits .eq. -1) then
	        convert_humid("%", rh)
        	convert_temp("degF", tmax)
		convert_wind("mph", spd)
	else
                print("The iounits value "+ iounits +" is not recognized. To indicate that all input units should be taken from metadata, input the value -1. Otherwise, indicate units according to documentation in a vector of (/tmax, hurs, spd/).")
	end if
end if
if(size .gt. 1) then
        units = unit_handling((/"tmax", "hurs", "spd"/), iounits)

	if(units(0) .ne. "metadata") then
	        tmax@units = units(0)
	end if
	if(units(1) .ne. "metadata") then
        	rh@units = units(1)
	end if
	if(units(2) .ne. "metadata") then
		spd@units = units(2)
	end if
	
	convert_humid("%", rh)
	convert_temp("degF", tmax)
	convert_wind("mph", spd)
end if

c1 = 1.0
c2 = 1.5
c3 = -0.5

em0 = 0.72
em = 0.000002

bf = 1. / 0.3002

emc = calc_emc(tmax, rh) ;equilibrium moisture content

eta = 1 - 2 * (emc / 30) + c2 * (emc / 30) ^ 2 + c3 * (emc / 30) ^ 3

FFWI = bf * eta * (1 + spd^2.)^0.5

FAF = em0 + (em * kbdi^2.)

mFFWI = kbdi
mFFWI = FAF * FFWI

delete_VarAtts(mFFWI, -1)               ;get rid of superfluous attributes
mFFWI@long_name = "modified Fosberg Fire Weather Index"
mFFWI@standard_name = "modified_fosberg_fire_weather_index"
varatts = (/"units","missing_value","_FillValue"/)
mFFWI@$varatts(0)$ = "1"        ;mFFWI is unitless

do i = 1, dimsizes(varatts) -1
        mFFWI@$varatts(i)$ = tmax@$varatts(i)$
end do

return(mFFWI)

end
