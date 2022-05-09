/;
2018, Copyright University Corporation for Atmospheric Research
;/


/;
	takes in a letter A-U except for M (fuel model M does not seem to exist) in accordance with NFDRS fuel models

	returns vector of fuel model values in following order: (/w1, w10, w100, w1000, wwd, whrb, s1, s10, s100, s1000, swd, shrb, hd, scm, emo, dp, wnd/)
								(/0 , 1  , 2   , 3    , 4  , 5   , 6 , 7  , 8   , 9    , 10 , 11  , 12, 13 , 14 , 15, 16 /)
;/


function retrieve_constants(fuel_mod_letter)
local models, model
begin
	fuel_mod = -1

	if(fuel_mod_letter .eq. "A" .or. fuel_mod_letter .eq. "a") then	;western grasses (annual) 
		fuel_mod = 0
	end if
	if(fuel_mod_letter .eq. "B" .or. fuel_mod_letter .eq. "b") then ;Californa chaparral
	        fuel_mod = 1
	end if
	if(fuel_mod_letter .eq. "C" .or. fuel_mod_letter .eq. "c") then ;pine-grass savanna
	        fuel_mod = 2
	end if
	if(fuel_mod_letter .eq. "D" .or. fuel_mod_letter .eq. "d") then ;southern rough
	        fuel_mod = 3
	end if
	if(fuel_mod_letter .eq. "E" .or. fuel_mod_letter .eq. "e") then ;hardwood litter (winter)
	        fuel_mod = 4
	end if
	if(fuel_mod_letter .eq. "F" .or. fuel_mod_letter .eq. "f") then ;intermediate brush
	        fuel_mod = 5
	end if
	if(fuel_mod_letter .eq. "G" .or. fuel_mod_letter .eq. "g") then ;short needle (heavy dead)
	        fuel_mod = 6
	end if
	if(fuel_mod_letter .eq. "H" .or. fuel_mod_letter .eq. "h") then ;short needle (normal dead)
	        fuel_mod = 7
	end if
	if(fuel_mod_letter .eq. "I" .or. fuel_mod_letter .eq. "i") then ;heavy slash
	        fuel_mod = 8
	end if
	if(fuel_mod_letter .eq. "J" .or. fuel_mod_letter .eq. "j") then ;intermediate slash
	        fuel_mod = 9
	end if
	if(fuel_mod_letter .eq. "K" .or. fuel_mod_letter .eq. "k") then ;light slash
	        fuel_mod = 10
	end if
	if(fuel_mod_letter .eq. "L" .or. fuel_mod_letter .eq. "l") then ;western grasses (perennial)
	        fuel_mod = 11
	end if
	if(fuel_mod_letter .eq. "N" .or. fuel_mod_letter .eq. "n") then ;sawgrass
	        fuel_mod = 12
	end if
	if(fuel_mod_letter .eq. "O" .or. fuel_mod_letter .eq. "o") then ;high pocosin
	        fuel_mod = 13
	end if
	if(fuel_mod_letter .eq. "P" .or. fuel_mod_letter .eq. "p") then ;southern pine plantation
	        fuel_mod = 14
	end if
	if(fuel_mod_letter .eq. "Q" .or. fuel_mod_letter .eq. "q") then ;Alaskan black spruce
	        fuel_mod = 15
	end if
	if(fuel_mod_letter .eq. "R" .or. fuel_mod_letter .eq. "r") then ;hardwood litter (summer)
	        fuel_mod = 16
	end if
	if(fuel_mod_letter .eq. "S" .or. fuel_mod_letter .eq. "s") then ;tundra
	        fuel_mod = 17
	end if
	if(fuel_mod_letter .eq. "T" .or. fuel_mod_letter .eq. "t") then ;sagebrush-grass
	        fuel_mod = 18
	end if
	if(fuel_mod_letter .eq. "U" .or. fuel_mod_letter .eq. "u") then ;western pines
	        fuel_mod = 19
	end if

	if( fuel_mod .eq. -1) then
		print("You requested fuel model " + fuel_mod_letter + ", which is not supported. Valid fuel models are A-U, a-u except for M or m")
		exit()
	end if

	models = (/ (/0.2, 3.5, 0.4, 2, 1.5, 2.5, 2.5, 1.5, 12, 7, 2.5, 0.25, 1.5, 2, 1, 2, 0.5, 0.5, 1, 1.5/) , (/0, 4, 1, 1, 0.5, 2, 2, 1, 12, 7, 2.5, 0, 1.5, 3, 1, 2.5, 0.5, 0.5, 0.5, 1.5/) , (/0, 0.5, 0, 0, 0.25, 1.5, 5, 2, 10, 6, 2, 0, 0, 3, 0.5, 2, 0.5, 0.5, 0, 1/) , (/0, 0, 0, 0, 0, 0, 12, 2, 12, 5.5, 2.5, 0, 0, 2, 0, 1, 0, 0.5, 0, 0/) , (/0, 11.5, 0.5, 3, 0.5, 9, 0.5, 0.5, 0, 0, 0, 0, 2, 7, 0.5, 4, 0.5, 0.5, 2.5, 0.5/) , (/0.3, 0, 0.8, 0.75, 0.5, 0, 0.5, 0.5, 0, 0, 0, 0.5, 0, 0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5/) , (/3000, 700, 2000, 1250, 2000, 700, 2000, 2000, 1500, 1500, 1500, 2000, 1600, 1500, 1750, 1500, 1500, 1500, 2500, 1750/) , (/0, 109, 109, 109, 109, 109, 109, 109, 109, 109, 109, 0, 109, 109, 109, 109, 109, 106, 109, 109/) , (/0, 30, 30, 0, 30, 30, 30, 30, 30, 30, 30, 0, 0, 30, 30, 30, 30, 30, 0, 30/) , (/0, 8, 0, 0, 0, 0, 8, 8, 8, 8, 8, 0, 0, 8, 0, 8, 8, 8, 0, 0/) , (/0, 1250, 1500, 1500, 1500, 1250, 1500, 1500, 0, 0, 0, 0, 1500, 1500, 1500, 1200, 1500, 1200, 1500, 1200/) , (/3000, 0, 2500, 1500, 2000, 0, 2000, 2000, 0, 0, 0, 2000, 0, 1500, 2000, 1500, 2000, 1500, 2000, 2000/) , (/8000, 9500, 8000, 9000, 8000, 9500, 8000, 8000, 8000, 8000, 8000, 8000, 8700, 9000, 8000, 8000, 8000, 8000, 8000, 8000/) , (/301, 58, 32, 68, 25, 24, 30, 8, 65, 44, 23, 178, 167, 99, 14, 59, 6, 17, 96, 16/) , (/15, 15, 20, 30, 25, 15, 25, 20, 25, 25, 25, 15, 25, 30, 30, 25, 25, 25, 15, 20/) , (/0.8, 4.5, 0.75, 2, 0.4, 4.5, 1, 0.3, 2, 1.3, 0.6, 1, 3, 4, 0.4, 3, 0.25, 0.4, 1.25, 0.5/) , (/0.6, 0.5, 0.4, 0.4, 0.4, 0.5, 0.4, 0.4, 0.5, 0.5, 0.5, 0.6, 0.6, 0.5, 0.4, 0.4, 0.4, 0.6, 0.6, 0.4/) /)

	model = models(:, fuel_mod)

	return(model)

end
