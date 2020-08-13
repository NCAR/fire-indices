procedure print_error(time_days, acceptable_days)
local time_years, acceptable_years
begin

	time_years = time_days / 365.
	acceptable_years = floor(acceptable_days / 365.)

	if(time_days .lt. acceptable_days) then
		print("Warning: the number of years inputted into this function, "+ time_years + " (" + time_days + " days) is fewer than is recommended to ensure accuracy. A minimum of " + acceptable_years + " year(s) (" + floor(acceptable_days) + " days) is recommended.")
	end if

end


procedure check_time_length(time_days, acceptable_days, opt)
begin

	if(opt .eq. False) then
	        print_error(time_days, acceptable_days)
	else
	        if(isatt(opt, "suppressWarning")) then
	                if(opt@suppressWarning .ne. True) then
	                        print_error(time_days, acceptable_days)
	                end if
	        end if
	end if

end
