/;
 ppt is amount of precipitation
 lat and lon are latitude and longitude
 climat is NFDRS climate class
;/
function calc_paper_pduration(ppt, lat, lon, climat)
local pdur, wetrat
begin

;note that this is different than the calculations in the MATLAB code. This is what is done in the paper

wetrat = where(climat .eq. 1 .or. climat .eq. 2, 0.25, 0.05)
pdur = (ppt / wetrat) + .49
pdur = pdur < 8.        ;not allowed to exceed 8 hours

return(pdur)

end


