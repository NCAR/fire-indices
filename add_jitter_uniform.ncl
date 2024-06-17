/;
this is a modification to SFDI calculations to address an artifact that occurs when calculating percentiles, the large number of exact values falling on border values in binning.
however, this is a generic function that will add uniform noise to any data, so it could probably be used in other circumstances
;/


function add_jitter_uniform(var)
local jitteredvar, vardims, jitter
begin

	jitteredvar = var

	vardims = dimsizes(jitteredvar)

	random_setallseed(9876543210, 987654321) ;note that these are two very random numbers with the intention of producing the same "random" values every time it is run.
	jitter = random_uniform(0, 1, vardims)

	jitteredvar = var + jitter

	return(jitteredvar)


end
