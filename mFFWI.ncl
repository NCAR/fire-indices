;calculate windspeed from east/west and north/south components
;whatever units come in go out
/;
function windspeed ( ew, ns )
local windspd

begin

windspd = ew	;transfers attributes to windspd
windspd = ew^2 + ns^2
windspd = sqrt(windspd)
return ( windspd )

end
;/

;Calculate modified Fosberg Fire Weather Index
;daily index
;U is windspeed in mph
;h is relative humidity in percent
;T is temperature in degrees Fahrenheit
;Q is KBDI

function mFFWI_index ( U, h, T, Q )
local mFFWI, FFWI, FAF, bf, eta, M, d00, d01, d10, d11, d20, em0, em, c1, c2, c3
;mFFWI is modified FFWI, FFWI is Fosberg Fire Weather Index, FAF is Fuel Availability Factor
begin

d00 = where(h .lt. 10., 0.03229, 2.22749)
d00 = where(h .gt. 50., 21.0606, d00)

d10 = where(h .lt. 10., 0.281073, 0.160107)
d10 = where(h .gt. 50., -0.483199, d10)

d01 = where(h .lt. 10., 0.0, -0.01478)
d01 = where(h .gt. 50., 0.0, d01)

d11 = where(h .lt. 10., -0.000578, 0.0)
d11 = where(h .gt. 50., 0.00035, d11)

d20 = where(h .gt. 50., 0.005565, 0.0)

c1 = 1.0
c2 = 1.5
c3 = -0.5

em0 = 0.72
em = 0.000002

bf = 1. / 0.3002

M = h
M = d00 + (d10 * h) + (d01 * T) + (d11 * h * T) + (d20 * (h^2.))
;eta = 1 + (c1 * M) + (c2 * (M^2.)) + (c3 *(M^3.))

eta = 1 - 2 * (M / 30) + c2 * (M / 30) ^ 2 + c3 * (M / 30) ^ 3

FFWI = U
FFWI = bf * eta * (1 + U^2.)^0.5

FAF = Q
FAF = em0 + (em * Q^2.)

mFFWI = Q
mFFWI = FAF * FFWI

return(mFFWI)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

;read in from four files: sfcWind tasmax hurs kbdi
; on command line,windsp_in, temper_in, kbdi_in, and humid_in must be specified, with "output" for file to write to
r_wind = addfile(windsp_in, "r")
r_temp = addfile(temper_in, "r")
r_humid = addfile(humid_in, "r")
r_kbdi = addfile(kbdi_in, "r")	;open all data

system("rm -f " + output)
mffwi_out = addfile(output, "c")	; create output file

filedimdef(mffwi_out, "time", -1, True)	; makes time dimension unlimited

;copy/set global attributes
att_names = getvaratts(r_temp)
do i = 0, dimsizes(att_names)-1
	mffwi_out@$att_names$ = r_temp@$att_names$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL script from source files "+windsp_in+", "+temper_in+", "+humid_in+", and "+kbdi_in
mffwi_out@history = history

var_names = getfilevarnames(r_temp)

do i = 0, dimsizes(var_names)-1
	if (var_names(i) .ne. "tas") then
                mffwi_out->$var_names(i)$ = r_temp->$var_names(i)$
        end if
end do

wind = r_wind->sfcWind		
wind = wind * 2.23694			; convert m/s to mph
hum = r_humid->hurs			; relative humidity
temp = r_temp->tas			; assume that the index uses  maximum temperature of the day. Not specified in any paper
;temp = (temp * (9./5.)) + 32		; convert degrees C to degrees F
temp = 9. / 5. * (temp - 273.15) + 32.0		;convert K to degrees F
kbdi = r_kbdi->KBDI			; not found with rest of data, calculate KBDI before calculating mFFWI

mffwi = mFFWI_index(wind, hum, temp, kbdi)

delete_VarAtts(mffwi, -1)		;get rid of superfluous attributes
mffwi@long_name = "modified Fosberg Fire Weather Index"
varatts = (/"units","missing_value","_FillValue"/)
mffwi@$varatts(0)$ = "1"	;mFFWI is unitless

do i = 1, dimsizes(varatts) -1
	mffwi@$varatts(i)$ = r_temp->tas@$varatts(i)$
end do

mffwi_out->mffwi = mffwi	;create mffwi variable, write mffwi values in output file

end
