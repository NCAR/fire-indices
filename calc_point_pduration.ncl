/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 z3 is a constant corresponding to latitude and longitude
 ppt is precipitation amount
 lat is latitude
 lon is longitude
;/
function calc_point_pduration(z3, ppt, lat, lon, mlat, mlon)    ;this function uses the methods presented by MATLAB code and runs when only one lat lon grid cell is input
local pdur, flat, flon, flat1, flon1, b
begin

	flat = ind(abs(mlat - lat) .lt. (1./24.))
	flon = ind(abs(mlon - lon) .lt. (1./24.))
	flat1 = flat(0)
	flon1 = flon(0)

	b = z3(flon1, flat1)    ;check the variable order in the z3 input file.

	pdur = 24. * (1. - exp(-b * ppt))
	pdur = round(pdur, 0)
	pdur = pdur < 8.
	pdur = pdur > 0.
	pdur = where(ppt .le. 0., 0, pdur)
	return(pdur)

end


