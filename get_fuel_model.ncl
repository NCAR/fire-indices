function get_fuel_model(grid, option)
local fuels, dblquote, r_constant
begin

        dblquote = integertochar(34)

        if(grid .eq. "NAM-22i") then
		if(option .eq. "laf") then
			r_constant = addfile("nfdrs_NAM-22i_laf_fuelmods.nc", "r")
		else if (option .eq. "hybrid") then
			r_constant = addfile("nfdrs_NAM-22i_hybrid_fuelmods.nc", "r")
		else
			print("your option is not supported. Valid options at this time are laf and hybrid")
		end if
		end if
	else
		if(fileexists(option)) then
			r_constant = addfile(option, "r")
		else
			print("No file matching that name was found. Please check the spelling if you have input a customized file, otherwise see $NCARG_ROOT/lib/ncarg/nclscripts/csm/data/nfdrsfuel_geog.nc to modify it for your grid.")
		end if
	end if

	return(r_constant)

end
