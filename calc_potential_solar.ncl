/;
 lat is latitude
 day is the julian day, or day of year (1 to 365)
 Z is elevation. If elevation unknown, input Z = 0
;/
function calc_potential_solar( lat, day, Z )
local gsc, phi, phi1, dr, dr1, delta, delta1, omegas, Ra, maxsolar
begin

latlen = dimsizes(lat)
daylen = dimsizes(day)

gsc = 0.082     ;solar constant, MJ m -2 min-1

phi = get_pi("float") * lat / 180
phi1 = conform_dims((/daylen, latlen/), phi, 1)

dr = 1+ 0.033 * cos(2 * get_pi("float") / 365 * day)
dr1 = conform_dims((/daylen, latlen/), dr, 0)

delta = 0.409 * sin(2 * get_pi("float")/365 * day - 1.39)
delta1 = conform_dims((/daylen, latlen/), delta, 0)

omegas = acos(-tan(phi1) * tan(delta1))

ra = 24 * 60 * gsc / get_pi("float") * dr1 * ( omegas * sin(phi1) * sin(delta1) + cos(phi1) * cos(delta1) * sin(omegas) )       ; FAO daily
maxsolar = ra * (0.75 + 2 * 10^(-5) * Z)

maxsolar=maxsolar/.0864

return(maxsolar)

end


