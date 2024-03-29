/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 lat is latitude
 day is the julian day, or day of year (1 to 365)
 Z is elevation. If elevation unknown, input Z = 500
;/
function calc_potential_solar( lat, lon, day, Z )
local gsc, phi, phi1, dr, dr1, delta, delta1, omegas, Ra, maxsolar
begin

	latlen = dimsizes(lat)
	lonlen = dimsizes(lon)
	daylen = dimsizes(day)

	gsc = 0.082     ;solar constant, MJ m -2 min-1

	pi = get_pi("float")

	phi = pi * lat / 180
	phi1 = conform_dims((/daylen, latlen, lonlen/), phi, 1)

	dr = 1+ 0.033 * cos(2 * pi / 365 * day)
	dr1 = conform_dims((/daylen, latlen, lonlen/), dr, 0)

	delta = 0.409 * sin(2 * pi/365 * day - 1.39)
	delta1 = conform_dims((/daylen, latlen, lonlen/), delta, 0)

	omegas = acos(-tan(phi1) * tan(delta1))

;printVarSummary(Z)
;print(daylen +  ", " + latlen + ", " + lonlen)
	Zsqueeze = rm_single_dims(Z)
;printVarSummary(Zsqueeze)
	Z1 = conform_dims((/daylen, latlen, lonlen/), Zsqueeze, (/1,2/))

	ra = 24 * 60 * gsc / pi * dr1 * ( omegas * sin(phi1) * sin(delta1) + cos(phi1) * cos(delta1) * sin(omegas) )       ; FAO daily
	maxsolar = ra * (0.75 + 2 * 10^(-5) * Z1)

	maxsolar=maxsolar/.0864
;print("calculated maxsolar")
	return(maxsolar)

end


