
function unit_handling ( inputs, units )
local len_inputs, return_units

begin

len_inputs = dimsizes(inputs)
return_units = inputs

do i=0, len_inputs-1

	if(units(i) .eq. -1) then
		return_units(i) = "metadata"

	else if(inputs(i) .eq. "tas" .or. inputs(i) .eq. "tmin" .or. inputs(i) .eq. "tmax") then
		if(units(i) .eq. 0) then
			return_units(i) = "degC"
		else if(units(i) .eq. 1) then
			return_units(i) = "K"
		else if(units(i) .eq. 2) then
			return_units(i) = "degF"
		else
			print("The input number "+ units(i) +" is not recognized for temperature units. The options for temperature variables are -1 (metadata), 0 (degC), 1 (K), and 2 (degF). Now exiting...")
			exit()
		end if
		end if
		end if
	else if(inputs(i) .eq. "hurs" .or. inputs(i) .eq. "rhmax" .or. inputs(i) .eq. "rhmin") then
		if(units(i) .eq. 0) then
			return_units(i) = "%"
		else if(units(i) .eq. 1) then
			return_units(i) = "1"
		else
			print("The input number "+ units(i) +" is not recognized for humidity units. The options for humidity variables are -1 (metadata), 0 (%) or 1 (unitless). Now exiting...")
                        exit()
		end if
		end if
	else if(inputs(i) .eq. "prec") then
		if(units(i) .eq. 0) then
			return_units(i) = "mm/day"
		else if(units(i) .eq. 1) then
			return_units(i) = "inches/day"
		else if(units(i) .eq. 2) then
			return_units(i) = "kg m-2 s-1"
		else
			print("The input number "+ units(i) +" is not recognized for precipitation units. The options for precipitation variables are -1 (metadata), 0 (mm/day), 1 (inches/day), and 2 (kg m-2 s-1). Now exiting...")
                        exit()
		end if
		end if
		end if

	else if(inputs(i) .eq. "sfcWind" .or. inputs(i) .eq. "spd") then
		if(units(i) .eq. 0) then
			return_units(i) = "m s-1"
		else if(units(i) .eq. 1) then
			return_units(i) = "mph"
		else
			print("The unit number "+ units(i) +" is not recognized for wind speed units. The options for wind speed variables are -1 (metadata), 0 (m s-1) and 1 (mph). Now exiting...")
			exit()
		end if
		end if
	end if
	end if		
	end if
	end if
	end if

end do

return(return_units)

end
