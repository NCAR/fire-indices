/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 mc1 is 1 hour fuel moisture
 mcherbi is mcherb the day before greenup with maximum 30 percent
 mc1000 is 1000 hour fuel moisture
 ym1000 is yesterday's 1000 hour fuel moisture
 herbga, herbgb, annta, anntb, perta, pertb are constants
 hveg is vegetation stage
 grnday is number of days since greenup sequence began
 climat is the nfdrs climate class, initialized as 3
 igrass signals annuals or perennials
 x1000 is a somewhat intermediary step used in calculations
 ymherb is yesterday's mcherb
;/
function calc_mcherb(mc1, mcherbi, mc1000, ym1000, grnday, climat, hveg, igrass, x1000, ymherb, gren)
local herbgas, herbgbs, anntas, anntbs, pertas, pertbs, mcherb, fherbf, ymherb
begin

	; annuals and perennials when green (fherbc > 120%)
	herbgas = (/-70.0,-100.0,-137.5,-185.0/)
	herbgbs = (/12.8,14.0,15.5,17.4/)

	; annuals during transition (30% < fherbc < 120%)
	anntas = (/-150.5,-187.7,-245.2,-305.2/)         ;hcurta in MATLAB code
	anntbs = (/18.4,19.6,22.0,24.3/)         ;hcurtb in MATLAB code

	; perennials during transition
	pertas = (/11.2,-10.3,-42.7,-93.5/)      ;hlivta in MATLAB code
	pertbs = (/7.4,8.3,9.8,12.2/)            ;hlitb in MATLAB code

	herbga = herbgas(climat - 1)
	herbgb = herbgbs(climat - 1)
	annta = anntas(climat - 1)
	anntb = anntbs(climat - 1)
	perta = pertas(climat - 1)
	pertb = pertbs(climat - 1)

	mcherb = mc1    ;pregreen stage

	fherbf = herbga + herbgb * x1000 < 250
	mcherb = where(hveg .eq. "greenup", (mc1 + (fherbf - mc1) / 100 * gren) < 250 , mcherb)               ; this version from MATLAB code
	mcherb = where(hveg .eq. "green", (herbga + herbgb * x1000) < 250, mcherb)

	ymherb = where(hveg .eq. "green" .and. ymherb .lt. 0., mcherb, ymherb)

	mcherb = where(hveg .eq. "green" .and. igrass .eq. "perennial", mcherb < ymherb, mcherb)        ;only found in MATLAB code, not paper

	ymherb = where(hveg .eq. "transition" .and. ymherb .lt. 0, annta + anntb * x1000, ymherb)

	;mcherb = where(hveg .eq. "transition", where(igrass .eq. "perennial", (perta + pertb * x1000), (annta + anntb * x1000) < ymherb), mcherb)              where statements are used in the situation that igrass is not a scalar
	if(igrass .eq. "perennial") then
	        mcherb = where(hveg .eq. "transition", perta + pertb * x1000, mcherb)
	else
	        mcherb = where(hveg .eq. "transition", (annta + anntb * x1000) < ymherb, mcherb)
	end if

	;mcherb = where(igrass .eq. "perennial" .and. hveg .eq. "transition", mcherb > 30, mcherb)      ;perennials are not allowed to go below 30%
	if(igrass .eq. "perennial") then
	        mcherb = where(hveg .eq. "transition", mcherb > 30., mcherb)	;perennials must stay in the range 30%-150% in transition and in curing
		mcherb = where(hveg .eq. "transition", mcherb < 150., mcherb) ;NEW LINE
	end if

	;mcherb = where(hveg .eq. "cured", where(igrass .eq. "annual", perta + pertb * x1000, mc1), mcherb)
	if(igrass .eq. "perennial")
	        mcherb = where(hveg .eq. "cured", (perta + pertb * x1000) > 30, mcherb)
		mcherb = where(hveg .eq. "cured", mcherb < 150, mcherb)	;NEW LINE
	else
	        mcherb = where(hveg .eq. "cured", mc1, mcherb)
	end if

	return(mcherb>30)	;herbaceous fuel moisture cannot be below 30%, in accordance with NFDRS2016. Verified w/ John Abatzoglou, implemented 3/16/2020

end

