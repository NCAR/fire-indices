/;
2018, Copyright University Corporation for Atmospheric Research
;/


procedure clip_time(time, minimum, maximum)
local length
begin

	length = dimsizes(time)
	minimum = time(0) > minimum
	maximum = time(length-1) < maximum


end
