;repmiss can be inserted as a check into any script where missing values may exist in a set. It replaces missing values with a two week average (one week back, one week forward).
;If more than 3 contiguous datapoints are missing, it quits.

procedure repmiss(var)
local miss, average, range, low, high, id, length
begin

miss = ismissing(var)	;search for any and all missing values
range = 7	;1/2 the size of the range you want to average over
length = dimsizes(var)

if(any(miss)) then
	print("There are missing data points. Missing data will be replaced with a 2 week average.")
	index = ind(miss)
	print("There is a missing data point at index = " + index)
	id = 0
	val = 1
	do i=0, dimsizes(index)-1
		if((index(i) - id) .eq. 1) then
			val = val + 1
		else
			val = 1
		end if

		if(val .gt. 3) then
			print("More than 3 consecutive missing data points have been found. Exiting.")
			exit
		end if

		id = index(i)
		low = (id - range) > 0
		high = (id + range) < (length - 1)
		average = avg(var(low : high))
		var(id) = average
	end do
end if

end
