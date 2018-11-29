/;
2018, Copyright University Corporation for Atmospheric Research
;/


procedure convert_prec(unit, pr)
begin
if(unit .ne. pr@units) then
        if(unit .eq. "kg m-2 s-1") then
		if(pr@units .eq. "mm/day") then
			pr = pr / 86400
		else if(pr@units .eq. "inches/day") then
                        pr = pr * 25.4 / 86400
                end if
		end if
		pr@units = "kg m-2 s-1"
	else if(unit .eq. "mm/day") then
		if(pr@units .eq. "kg m-2 s-1") then
			pr = pr * 86400
		else if(pr@units .eq. "inches/day") then
			pr = pr * 25.4
		end if
		end if
		pr@units = "mm/day"
	else if(unit .eq. "inches/day") then
		if(pr@units .eq. "kg m-2 s-1") then 
			pr = pr * 86400 / 25.4
		else if(pr@units .eq. "mm/day") then
			pr = pr / 25.4
		end if
		end if
		pr@units = "inches/day"
	else
		print("Requested precipication conversion units are unrecognized. Conversions are between units mm/day, inches/day, and kg m-2 s-1.")
	end if
	end if
	end if
end if

end
