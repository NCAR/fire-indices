/;
2018, Copyright University Corporation for Atmospheric Research
;/


;repmiss can be used where missing values may exist in a set. It replaces missing values with a two week average (one week back, one week forward).
;If more than 3 contiguous datapoints are missing, it quits.

procedure repmiss(var)
local miss, average, range, low, high, id, length
begin

miss = ismissing(var)	;search for any and all missing values
range = 7	;1/2 the size of the range you want to average over
length = dimsizes(var(:, 0, 0))		; length time

if(any(miss)) then
	prev = 0
	val = 1
	hit = 0
	do i=0, length-1
		if(all(miss(i, :, :))) then
		        print("There is a missing day of data at index " + i + ". Missing data will be replaced with a 2 week average.")
			hit = i
		end if

		if((hit - prev) .eq. 1) then
			val = val + 1
		else
			val = 1
		end if

		if(val .gt. 3) then
			print("More than 3 consecutive missing days have been found. Exiting.")
			exit
		end if

		low = (i - range) > 0
		high = (i + range) < (length - 1)
		if(all(miss(i, :, :))) then
			av = dim_avg_n_Wrap(var(low : high, :, :), 0)
			var(i, :, :) = av
		end if
		
		prev = i
	end do
end if


end
