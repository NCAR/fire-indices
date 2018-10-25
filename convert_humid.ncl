procedure convert_humid(unit, rh)
begin
if(unit .ne. rh@units) then
        if(unit .eq. "%") then
		if(rh@units .eq. "1") then
			rh = rh * 100
;			rh = rh < 100.0
		end if
		rh@units = "%"
	else if(unit .eq. "1") then
		if(rh@units .eq. "%") then
			rh = rh / 100
;			rh = rh < 1
		end if
		rh@units = "1"
	else
		print("Units are unrecognized. Conversions occur between units 1 and %, 0-1 and 1-100 scales respectively.")
	end if
	end if
end if

if(unit .eq. "1") then
	rh = rh < 1
	rh = rh > 0
else if(unit .eq. "%") then
	rh = rh < 100
	rh = rh > 0
end if 
end if

end
