/;

takes the variable and the bins and assigns a value 0 to 100+x to each timestep of the variable.
1D data only!

;/

function assign_binning(var, bins)
local nbins, normvar, lowerbound, upperbound
begin

nbins = dimsizes(bins)

normvar = var
normvar = -1000.

do i=0, nbins-2

	lowerbound = bins(i)
	upperbound = bins(i+1)

	;print("bin = " + lowerbound + " to " + upperbound)
	normvar = where(var .ge. lowerbound .and. var .le. upperbound, i + 1, normvar)	;note that this means anything exactly on the upper bound will be replaced on the next loop, but this logic does allow for the absolute maximum to be assigned

end do

return(normvar)

end
