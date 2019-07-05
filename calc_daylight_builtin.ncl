/;
2018, Copyright University Corporation for Atmospheric Research
;/


;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/crop.ncl"   ;the proper way
load "crop.ncl"                                         ;only for when path is not set correctly


/;
 This function uses a built in NCL function to calculate the number of daylight hours
 day is day of year
 lat is latitude
 lonlen is the number of longitude coordinates in the area of calculation
;/
function calc_daylight_builtin(day, lat, lonlen)
local latlen, daylight, daylight1, daylit, day
begin

	latlen = dimsizes(lat)

	daylight = daylight_fao56(day, lat)
	;daylight1 = daylight(0, :)
	daylit = conform_dims((/latlen, lonlen/), daylight, 0)

	return(daylit)

end

