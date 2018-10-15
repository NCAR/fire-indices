; unit is the temperature scale to convert to. temp is an array of temperature values

procedure convert_temp( unit, temp )
begin

if(unit .ne. temp@units) then
	if(unit .eq. "K") then
		if(temp@units .eq. "degC") then
			temp = temp + 273.15
		else if(temp@units .eq. "degF") then
			temp = (temp - 32.) / 1.8 + 273.15
		end if
		end if
		temp@units = "K"
	end if
	
	if (unit .eq. "degC") then
		if(temp@units .eq. "K") then
			temp = temp - 273.15
		else if(temp@units .eq. "degF") then
			temp = (temp - 32.) * 5. / 9.
		end if
		end if
		temp@units = "degC"
	end if

	if (unit .eq. "degF") then
		if(temp@units .eq. "K") then
			temp = (temp - 273.15) * 1.8 + 32.
		else if(temp@units .eq. "degC") then
			temp = temp * 1.8 + 32.
		end if
		end if
		temp@units = "degF"
	end if
	
	if((unit .ne. "degF") .and. (unit .ne. "degC") .and. (unit .ne. "K")) then
		print("options for input unit are degC, degF, and K")
	end if
end if
end
