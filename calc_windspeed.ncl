;calculate windspeed from east/west and north/south components
;whatever units come in go out
;note that this function is only necessary if no sfcWind data is available and vas and uas are input instead.

function calc_windspeed ( ew, ns )
local windspd

begin

windspd = ew	;transfers attributes to windspd
windspd = ew^2 + ns^2
windspd = sqrt(windspd)
return ( windspd )

end
