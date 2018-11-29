/;
2018, Copyright University Corporation for Atmospheric Research
;/


/;
 This function is an alternative to the built in NCL function to calculate the number of daylight hours
 j_date is day of year
 lat is latitude
 lonlen is the number of longitude coordinates in the area of calculation
;/
function calc_daylight_manual(j_date, lat, lonlen)
local phi, decl, daylit, latlen, daylit1
begin

daylen = dimsizes(j_date)
latlen = dimsizes(lat)

phi = lat * .01745
phi1 = conform_dims((/daylen, latlen/), phi, 1)

decl = .41008 * sin((j_date-82.) * .01745)
decl1 = conform_dims((/daylen, latlen/), decl, 0)

daylit=24*(1-acos(tan(phi1)*tan(decl1))/3.14159)

daylit1 = conform_dims((/daylen, latlen, lonlen/), daylit, (/0, 1/))

return(daylit1)

end

