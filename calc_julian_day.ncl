;give it time as is written in netCDF file and it returns the day of year
function calc_julian_day(time)
local opt, cal, cal1, day_year
begin

opt = 0         ; for cd_calendar, option 0 returns an array: year (cal(0)), month (cal(1)), day (cal(2)), hour, minute, second

cal = cd_calendar(time, opt)
cal1 = tointeger(cal)
day_year = day_of_year(cal1(:,0), cal1(:,1), cal1(:,2))

return(day_year)

end

