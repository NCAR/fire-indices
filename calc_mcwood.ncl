/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 prgrn is a constant selected based on climat
 mc1000 is the 1000 hour fuel moisture
 hveg is the vegetation stage
 climat is the NFDRS climate class (1-4)
 ymwood is yesterday's mcwood
;/
function calc_mcwood(pregrn, mcwodi, mc1000, climat, hveg, gren, ymwood)
local mcwood, woodgas, woodga, woodgb
begin

	; shrubs over entire range of fmwood
	woodgas = (/12.5,-5.0,-22.5,-45.0/)      ; wooda in MATLAB code
	woodgbs = (/7.5,8.2,8.9,9.8/)            ; woodb in MATLAB code

	; pre-season and post-freeze values for fmwood

	woodga = woodgas(climat - 1)
	woodgb = woodgbs(climat - 1)
	mcwodi = where(ymwood .gt. pregrn, ymwood, mcwodi)
	mcwodp = woodga + woodgb * mc1000
	mcwood = mcwodp < 200           ; true during green stage. This corresponds to the hveg values green, transition, and cured
	mcwood = mcwood > pregrn
	mcwood = where(hveg .eq. "pregreen" .or. hveg .eq. "frozen", pregrn, mcwood)
	mcwood = where(hveg .eq. "greenup", mcwodi + (mcwodp - mcwodi) * gren / 100., mcwood)   ;mcwodi = pregrn

	mcwood = mcwood > 70	;woody fuel moisture cannot be below 70%, in accordance with NFDRS2016. Verified w/ John Abatzoglou, implemented 3/16/2020

	return(mcwood > pregrn)

end

