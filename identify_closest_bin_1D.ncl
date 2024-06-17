/;

function that identifies the closest bin in the future for the maximum bin in the past.
likely to return something between 90-100 for this specific purpose in calculating SFDI.
this is only for 1D data

;/

function identify_closest_bin(ref, fut)
local dimsref, refmaxbin, closestbin
begin

	dimsref = dimsizes(ref)

	refmaxbin = ref(dimsref-1)

	closestbin = closest_val(refmaxbin, fut)

	;print("closestbin = " + closestbin)

	return(closestbin)

end
