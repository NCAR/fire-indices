function check_time( name1, name2, time1, time2)
local flag, size1, size2, time_diff, time1, time2
begin

flag = 1

size1 = dimsizes(time1)
size2 = dimsizes(time2)
if(size1 .ne. size2) then
	print("The dimensions of the variables do not align. " + name1 + " is of length " + size1 + " and " + name2 + " is of length " + size2)
	flag = 0
end if
time_diff = time1(0) - time2(0)

if(time_diff .ge. 1 .or. time_diff .le. -1) then
	print("The starting date of the variables does not align within a day. Start date of " + name1 + " is " + time1(0) + " and start date of " + name2 + " is " + time2(0))
	flag = 0
end if

time_diff = time1(size1-1) - time2(size2-1)

if(time_diff .ge. 1 .or. time_diff .le. -1) then
        print("The ending date of the variables does not align within a day. End date of " + name1 + " is " + time1(size1-1) + " and end date of " + name2 + " is " + time2(size2-1))
	flag = 0
end if

return(flag)

end
