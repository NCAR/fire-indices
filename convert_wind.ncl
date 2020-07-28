; unit is the wind scale to convert to. wind is an array of wind values

procedure convert_wind( unit, wind )
begin

if(unit .ne. wind@units) then
	if(unit .eq. "m/s" .or. unit .eq. "m s-1") then
		if(wind@units .eq. "mph") then
			wind = wind / 2.23694
		end if
		wind@units = unit
	end if
	
	if (unit .eq. "mph") then
		if(wind@units .eq. "m/s" .or. wind@units .eq. "m s-1") then
			wind = wind * 2.23694
		end if
		wind@units = unit
	end if

	if((unit .ne. "mph") .and. (unit .ne. "m/s") .and. (unit .ne. "m s-1")) then
		print("options for input unit are mph, m/s, and m s-1")
	end if
end if

end