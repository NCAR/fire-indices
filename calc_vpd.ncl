/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 tmax is maximum daily temperature, in Celsius
 tmin is the minimum daily temperature, in Celsius
 sph is specific humidity
 rh is relative humidity at 13:00
 Z is elevation
 VPD is vapor pressure deficit
;/
function calc_vpd(tmax, tmin, sph, rh, Z)
local e1, Td, ew, fw, ew_tmin, ew_tmax, ew_tdew, vpd
begin

P=1013.25 * (1 - .0001 * Z)

sph = sph / .622
sph = sph * P
e1 = log( sph / 6.112)
Td = 243.5 * e1 / (17.67 - e1)

; solve for vapor pressure at minimum temp
ew = 10 ^ ((0.7859 + (0.03477 * tmin)) / (1 + (0.00412 * tmin)))
fw = 1 + 10^(-6) * P * (4.5 + (0.0006 * (tmin^2)))
ew_tmin = fw * ew

; solve for vapor pressure at maximum temp
ew = 10 ^ ((0.7859 + (0.03477 * tmax)) / (1 + (0.00412 * tmax)))
fw = 1 + 10^(-6) * P * (4.5 + 0.0006 * (tmax^2))
ew_tmax = fw * ew

; solve for vapor pressure at dewtemp
ew = 10^((0.7859 + (0.03477 * Td)) / (1 + (0.00412 * Td)))
fw = 1 + 10^(-6) * P * (4.5 + (0.0006 * (Td^2)))
ew_tdew = fw * ew

vpd = ((ew_tmax / 2) + (ew_tmin / 2)) - ew_tdew             ; saturation vapor pressure in millibars
vpd = vpd / 10.               ; convert from mb to kPa

return(vpd)

end

