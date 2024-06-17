/;

combine reference and future bins into a single vector

;/

function append_bins(refbins, futbins, matchbin)
local nextra, fullbins
begin

nextra = 100 - matchbin

if(nextra .eq. 0) then
	if(max(futbins) .gt. max(refbins)) then
		fullbins = conform_dims((/102/), -1000., -1)
		fullbins(0:100) = refbins
		fullbins(101) = max(futbins)
	else
		fullbins = refbins
	end if
else
	nbins = 101 + nextra
	fullbins = conform_dims((/nbins/), -1000., -1)
	fullbins(0:100) = refbins
	do i=1, nextra
		fullbins(100 + i) = futbins(100 - nextra + i) ; REMEMBER 0-START INDEXING
	end do
end if

return(fullbins)

end
