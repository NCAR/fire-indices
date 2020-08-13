/;
2018, Copyright University Corporation for Atmospheric Research
;/

load "extract_lat_lon.ncl"
;grid - string

function pjolly(grid, lat, lon)
local b, dblquote, r_z3
begin

	dblquote = integertochar(34)

	if(grid .eq. "NAM-22i") then
	        r_z3 = addfile("pdur_jolly_22i.nc", "r")
	;       r_z3 = addfile("$NCARG_ROOT/lib/ncarg/nclscripts/csm/data/pdur_jolly_22i.nc", "r") ;for use once officially contributed
	        b = extract_lat_lon(r_z3->Z3, lat, lon, r_z3->lat, r_z3->lon)
	else if (grid .eq. "NAM-44i") then
	        r_z3 = addfile("pdur_jolly_44i.nc", "r")
	;        r_z3 = addfile("$NCARG_ROOT/lib/ncarg/nclscripts/csm/data/pdur_jolly_44i.nc", "r")
		b = extract_lat_lon(r_z3->Z3, lat, lon, r_z3->lat, r_z3->lon)
	else
		if(fileexists(grid)) then
			r_z3 = addfile(grid, "r")
			b = extract_lat_lon(r_z3->Z3, lat, lon, r_z3->lat, r_z3->lon)
		else
		        print("No file matching that grid is currently available. Please see $NCARG_ROOT/lib/ncarg/nclscripts/csm/data/pdur_jolly.nc to modify it for your grid and input it on the command line as follows: z3file=\"+dblquote+"yourfile\"+dblquote)
		end if
	end if
	end if

	return(b)

end
