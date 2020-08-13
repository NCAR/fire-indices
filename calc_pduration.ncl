/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 z3 is a constant corresponding to latitude and longitude
 ppt is precipitation amount
;/

load "pjolly.ncl"

function calc_pduration(grid, ppt, lat, lon)    ;this function uses the methods presented by MATLAB code and runs over all of CONUS
local z3, timelen, z3_1, pdur
begin

	latlen = dimsizes(lat)
	lonlen = dimsizes(lon)
	z3 = pjolly(grid, lat, lon)

	timelen = dimsizes(ppt(:, 0,0))
	z3_1 = conform_dims((/timelen, latlen, lonlen/), z3, (/1,2/))

	pdur = 24. * (1. - exp(-z3_1 * ppt))
	pdur = round(pdur, 0)
	pdur = pdur < 8.
	pdur = pdur > 0.
	pdur = where(ppt .le. 0., 0, pdur)

	return(pdur)

end


