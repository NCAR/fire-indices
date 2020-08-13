function extract_lat_lon(var, sublat, sublon, reflat, reflon)
local latlength, lonlength, lat_index, lon_index, subset_var
begin

	latlength = dimsizes(sublat)
	lonlength = dimsizes(sublon)

	;test if the reference file lat and lon match the subset lat and lon

	if(latlength .eq. dimsizes(reflat) .and. lonlength .eq. dimsizes(reflon)) then
		match_lat = where(sublat .eq. reflat, True, False) 
		match_lon = where(sublon .eq. reflon, True, False)
		if(all(match_lat) .and. all(match_lon)) then
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

		lat_index = conform_dims(latlength, tointeger(-(10^3)), -1)
		lon_index = conform_dims(lonlength, tointeger(-(10^3)), -1)

		do i=0, latlength-1
			lat_index(i) = ind(reflat .eq. sublat(i)) 
		end do  

		do j=0, lonlength-1
			lon_index(j) = ind(reflon .eq. sublon(j))
		end do

		subset_var = var(lat_index, lon_index)
	end if

	return(subset_var)
end
