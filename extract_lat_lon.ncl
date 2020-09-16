function extract_lat_lon(var, sublat, sublon, reflat, reflon)
local latlength, lonlength, match_lon_360, reflon1, sublon1, lat_index, lon_index, subset_var
begin

	latlength = dimsizes(sublat)
	lonlength = dimsizes(sublon)

	;in case of mismatching units on longitude...
	reflon1 = where(reflon .lt. 0, reflon + 360, reflon)
	sublon1 = where(sublon .lt. 0, sublon + 360, sublon)

	;test if the reference file lat and lon match the subset lat and lon

	if(latlength .eq. dimsizes(reflat) .and. lonlength .eq. dimsizes(reflon)) then

		match_lat = where(sublat .eq. reflat, True, False) 
		match_lon = where(sublon .eq. reflon, True, False)
		match_lon_360 = where( sublon1 .eq. reflon1, True, False) ;this is in case longitude units differ between the reference file and subset file, but the ranges still match

		if(all(match_lat) .and. (all(match_lon) .or. all(match_lon_360))) then
			match_flag = True
		else
			match_flag = False
		end if
	else
		match_flag = False
	end if

	if(match_flag) then	;if the subset lat and lon match the reference lat and lon, no need to search the entire file
		subset_var = var
	else

		;check if requested lat and lon are within range of the file
		if((min(sublat) .lt. min(reflat)) .or. max(sublat) .gt. max(reflat)) then
			print("The range of latitude does not match available reference files. The latitude range in the inputted reference file is "+min(reflat) + " to " + max(reflat) +". The latitude range in the variable files is "+ min(sublat) + " to " + max(sublat))
		end if

		if((min(sublon1) .lt. min(reflon1)) .or. max(sublon1) .gt. max(reflon1)) then
                        print("The range of longitude does not match available reference files. The longitude range in the inputted reference file is "+min(reflon) + " to " + max(reflon) + ". The latitude range in the variable files is "+ min(sublon) + " to " + max(sublon))
                end if

		lat_index = conform_dims(latlength, tointeger(-(10^3)), -1)
		lon_index = conform_dims(lonlength, tointeger(-(10^3)), -1)

		do i=0, latlength-1
			lat_index(i) = ind(reflat .eq. sublat(i)) 
		end do  

		do j=0, lonlength-1
			lon_index(j) = ind(reflon1 .eq. sublon1(j))
		end do

		subset_var = var(lat_index, lon_index)
	end if

	return(subset_var)
end
