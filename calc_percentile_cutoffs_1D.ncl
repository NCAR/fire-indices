/;

this function calculates the values that delineate bins to assign percentile values to with however much input data it gets. The more the better, in general. At least several hundred.

;/


function calc_percentile_cutoffs(var)
local cutofffile, calc_cutoff, var_sorted, vardims, cutoffs, ntimesteps
begin

var_sorted = var
var_sorted_vector = dim_pqsort_n(var_sorted, 2, 0) ;sort var on the 0th dimension. Sort in increasing order.

var_sorted_nomissing = var_sorted(ind(.not.ismissing(var_sorted)))

vardims = dimsizes(var_sorted_nomissing)

cutoffs = conform_dims((/101/), var@_FillValue, -1)

ntimesteps = vardims(0)

cutoffs(0) = 0

do i=1, 100

	n = min((/tointeger(ceil(tofloat(i) / 100. * ntimesteps)), ntimesteps-1/))
	;print("n = " + n + str_get_tab() + (tofloat(i) / 100 * ntimesteps))
	;print("n=" + n + str_get_tab() + "var_sorted_nomissing(n) = " + var_sorted_nomissing(n))
	cutoffs(i) = var_sorted_nomissing(n)
	;print("cutoffs(" + i + ") = " + cutoffs(i))
end do

/;if(printdebug) then
	pctl99 = tointeger(ntimesteps * .99)
	print("index of 99th percentile = " + pctl99 + " out of " + ntimesteps) 
	print(var_sorted_nomissing((pctl99-15):(pctl99+15)))

end if
;/

cutoffs!0 = "percentiles"

cutoffs&percentiles = ispan(0,100,1)

return(cutoffs)

end
