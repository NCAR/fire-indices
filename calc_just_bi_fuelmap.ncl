/;
2020, Copyright University Corporation for Atmospheric Research
;/

/;
 mc1, mc10, mc100, are the percent moisture content of 1-, 10-, 100-hour timelag
 climat is NFDRS climate class
 erc is energy release component
 bi is burning index
;/

;load "retrieve_constants.ncl"
load "get_fuel_model.ncl"

function calc_just_bi_fuelmap(mc1, mc10, mc100, erc, mcherb, mcwood, ws, lat, lon, fuelmod, climat)
local w1,w10,w100,w1000,wherb,wwood,depth,sg1,sg10,sg100,sg1000,sgherb,sgwood,mxd,hd,wndfc,hl,rhol,rhod,std,stl,sd,sl,fctcur,wherbc,w1p,sa1,sa10,sa100,sawood,saherb,sadead,salive,f1,f10,f100,wherbp,fdead,flive,fherb,fwood,sgbrd,sgbrl,wtotd,wtotl,wtot,sa1,sa10,sa100,sawood,saherb,w1n,w10n,w100n,wherbn,wwoodn,hn1,hn10,hn100,hnherb,hnwood,wrat,mclfe,sgbrt,rhobed,rhobar,wtmcd,wtmcl,mxl,gmamx,betbar,betop,ad,dedrt,fherb,livrt,gmaop,wdeadn,etasd,etamd,wliven,etasl,etaml,slope_angle,slpfct,c,e,b,ufact,ir,zeta,phislp,phiwnd,htsink,sc,bi

begin

;	constants = retrieve_constants(fuelmod)
/;
	w1 = constants(0)	; fuel model specified 1-hour class fuel loading
	w10 = constants(1)	; fuel model specified 10-hour class fuel loading
	w100 = constants(2)	; fuel model specified 100-hour class fuel loading
	w1000 = constants(3)	; fuel model specified 1000-hour class fuel loading
	wwood = constants(4)	; fuel model specified woody shrub fuel loading
	wherb = constants(5)	; fuel model specified herbaceous fuel loading
	sg1 = constants(6)	; specified surface area-to-volume ratio for 1-hour class of fuel model
	sg10 = constants(7)	; specified surface area-to-volume ratio for 10-hour class of fuel model
	sg100 = constants(8)	; specified surface area-to-volume ratio for 100-hour class of fuel model
	sgwood = constants(10)	; specified surface area-to-volume ratio for woody class of fuel model
	sgherb = constants(11)	; specified surface area-to-volume ratio for herbaceous class of fuel model
	hd = constants(12)	; specified dead-fuel heat of combustion of fuel model
	mxd = constants(14)	; specified dead-fuel moisture of extinction for fuel model
	depth = constants(15)	; effective fuel-bed depth measured, in feet
	wndfc = constants(16)	; fuel model specified wind reduction factor. wndfc is calculated under certain conditions.
;/
/;
	const_in = addfile("nfdrs_NAM-22i_laf_fuelmods.nc", "r")
	w1 = const_in->w1
	w10 = const_in->w10
	w100 = const_in->w100
	w1000 = const_in->w1000
	wwood = const_in->wwood
	wherb = const_in->wherb
	sg1 = const_in->sg1
	sg10 = const_in->sg10
	sg100 = const_in->sg100
	sg1000 = const_in->sg1000
	sgwood = const_in->sgwood
	sgherb = const_in->sgherb
	hd = const_in->hd
	mxd = const_in->mxd
	depth = const_in->depth
	wndfc = const_in->wndfc

	print(w1(107,268)+ " , " +w10(107,268)+ " , " +w100(107,268)+ " , " +w1000(107,268)+ " , " +wwood(107,268)+ " , " +wherb(107,268)+ " , " +sg1(107,268)+ " , " +sg10(107,268)+ " , " +sg100(107,268)+ " , " +sgwood(107,268)+ " , " +sgherb(107,268)+ " , " +hd(107,268)+ " , " +mxd(107,268)+ " , " +depth(107,268)+ " , " +wndfc(107,268))
;/
	const_in = get_fuel_model(grid, fuelmod)
	ref_lat = const_in->lat
	ref_lon = const_in->lon
	w1 = extract_lat_lon(const_in->w1, lat, lon, ref_lat, ref_lon)
	w10 = extract_lat_lon(const_in->w10, lat, lon, ref_lat, ref_lon)
	w100 = extract_lat_lon(const_in->w100, lat, lon, ref_lat, ref_lon)
	w1000 = extract_lat_lon(const_in->w1000, lat, lon, ref_lat, ref_lon)
	wwood = extract_lat_lon(const_in->wwood, lat, lon, ref_lat, ref_lon)
	wherb = extract_lat_lon(const_in->wherb, lat, lon, ref_lat, ref_lon)
	sg1 = extract_lat_lon(const_in->sg1, lat, lon, ref_lat, ref_lon)
	sg10 = extract_lat_lon(const_in->sg10, lat, lon, ref_lat, ref_lon)
	sg100 = extract_lat_lon(const_in->sg100, lat, lon, ref_lat, ref_lon)
	sgwood = extract_lat_lon(const_in->sgwood, lat, lon, ref_lat, ref_lon)
	sgherb = extract_lat_lon(const_in->sgherb, lat, lon, ref_lat, ref_lon)
	hd = extract_lat_lon(const_in->hd, lat, lon, ref_lat, ref_lon)
	mxd = extract_lat_lon(const_in->mxd, lat, lon, ref_lat, ref_lon)
	depth = extract_lat_lon(const_in->depth, lat, lon, ref_lat, ref_lon)
	wndfc = extract_lat_lon(const_in->wndfc, lat, lon, ref_lat, ref_lon)
;	print(w1(107,268)+ " , " +w10(107,268)+ " , " +w100(107,268)+ " , " +w1000(107,268)+ " , " +wwood(107,268)+ " , " +wherb(107,268)+ " , " +sg1(107,268)+ " , " +sg10(107,268)+ " , " +sg100(107,268)+ " , " +sgwood(107,268)+ " , " +sgherb(107,268)+ " , " +hd(107,268)+ " , " +mxd(107,268)+ " , " +depth(107,268)+ " , " +wndfc(107,268))

	c1 = 0.046	; conversion factor for T/Ac to lbs/ft^2

	w1 = w1 * c1
	w10 = w10 * c1
	w100 = w100 * c1
	w1000 = w1000 * c1
	wwood = wwood * c1
	wherb = wherb * c1	; conversions from T/Ac to lbs/ft^2

	hl = hd		; specified live-fuel heat of combustion of fuel model

	rhol = 32.0	; particle density of live fuel
	rhod = 32.0	; particle density of dead fuel
	std = 0.0555	; proportion of inert mineral content of dead fuels
	stl = 0.0555	; proportion of inert mineral content of live fuels
	sd = 0.01	; proportion of silica-free mineral content of dead fuels
	sl = 0.01	; proportion of silica-free mineral content of live fuels


	fctcur = 1.33 - 0.0111 * mcherb	; fraction of fuel model herbaceous fuel loading transferred to 1-hour fuel class
	fctcur = fctcur < 1.0
	fctcur = fctcur > 0.0

	wherbc = fctcur * wherb		; amount of herbaceous fuel loading transferred to 1-hour class

	w1p = w1 + wherbc		; 1-hour fuel loading and transferred herbaceous loading

	sa1 = (w1p / rhod) * sg1		; surface area of 1-hour class fuels
	sa10 = (w10 / rhod) * sg10		; surface area of 10-hour class fuels
	sa100 = (w100 / rhod) * sg100		; surface area of 100-hour class fuels
	sawood = (wwood / rhol) * sgwood	; surface area of woody fuel class
	saherb = (wherb / rhol) * sgherb	; surface area of herbaceous fuel class

	sadead = sa1 + sa10 + sa100	; surface area of dead-fuel classes
	salive = saherb + sawood	; surface area of live-fuel classes

	f1 = sa1 / sadead	; proportion of dead-fuel surface area in 1-hour class
	f10 = sa10 / sadead	; proportion of dead-fuel surface area in 10-hour class
	f100 = sa100 / sadead	; proportion of dead-fuel surface area in 100-hour class
	; f1, f10, and f100 are used as weighting factors in the ros/sc calculation

	wherbp = wherb - wherbc			; amount of herbaceous floading left after transfer to 1-hour fuel loading
	fdead = sadead / (sadead + salive)	; proportion of total surface area in dead-fuel classes
	flive = salive / (sadead + salive)	; proportion of total surface area in live-fuel classes
	fherb = saherb / salive			; proportion of live surface area in herbaceous class
	fwood = sawood / salive			; proportion of live surface area in woody class

	sgbrd = (f1 * sg1) + (f10 * sg10) + (f100 * sg100)	; characteristic surface area-to-volume ratio of dead fuel, surface area weighted
	sgbrl = (fherb * sgherb) + (fwood * sgwood)		; characteristic surface area-to-volume ratio of live fuel, surface area weighted
	wtotd = w1p + w10 + w100 + w1000			; total dead-fuel loading
	wtotl = wherbp + wwood					; total live-fuel loading

	wtot = wtotd + wtotl	; total fuel loading

	w1n = w1p * (1.0 - std)		; net fuel loading of 1-hour class
	w10n = w10 * (1.0 - std)	; net fuel loading of 10-hour class
	w100n = w100 * (1.0 - std)	; net fuel loading of 100-hour class
	wherbn = wherbp * (1.0 - stl)	; net fuel loading of herbaceous class
	wwoodn = wwood * (1.0 - stl)	; net fuel loading of woody class
	wtotln = wtotl * (1 - stl)	; total live-fuel loading

	hn1 = w1n * exp( -138.0 / sg1)		; heating number of 1-hour class

	sg10@_FillValue = mc100@_FillValue
	hn10 = sg10
	hn10 = w10n * exp( -138.0 / where(sg10 .ne. 0.0, sg10, mc100@_FillValue))	; heating number of 10-hour class
	hn10 = where(sg10 .eq. 0.0, 0.0, hn10)	; in all areas where previous line would have resulted in a missing value, set hn10 to 0

	hn100 = sg10
	hn100 = w100n * exp( -138.0 / where( sg100 .ne. 0.0, sg100, mc100@_FillValue))	; heating number of 100-hour class
	hn100 = where(sg100 .eq. 0.0, 0.0, hn100)  ; in all areas where previous line would have resulted in a missing value, set hn100 to 0

	sgherb@_FillValue = mc100@_FillValue
	hnherb_exp = sgherb
	hnherb_exp = -500. / where(sgherb .ne. 0, sgherb, mc100@_FillValue)
	hnherb = where(hnherb_exp .lt. -180.218, 0., wherbn * exp(hnherb_exp))
	hnherb = where(sgherb .eq. 0., 0.0, hnherb)
	delete(hnherb_exp)

/;
	if((-500. / sgherb) .lt. -180.218) then
	        hnherb = conform_dims(dimsizes(wherbn), 0., -1)	; heating number of herbaceous class
	else
	        hnherb = wherbn * exp(-500. / sgherb)
	end if
;/

	sgwood@_FillValue = mc100@_FillValue
	hnwood_exp = sgwood
	hnwood = sgwood

	hnwood_exp = -500. / where(sgwood .ne. 0., sgwood, mc100@_FillValue)
	hnwood = where(hnwood .lt. -180.218, 0., wwoodn * exp(hnwood_exp))
	hnwood = where(sgwood .eq. 0.0, 0.0, hnwood)
	delete(hnwood_exp)

;	hnwood = where((-500. / sgwood) .lt. -180.218, 0., wwoodn * exp(-500. / sgwood))	; heating number of woody class

	wrat = hnherb
	wrat@_FillValue = mc100@_FillValue
	wrat = (hn1 + hn10 + hn100) / where((hnherb + hnwood) .ne. 0.0, hnherb + hnwood, mc100@_FillValue)	; ratio of dead-to-live heating numbers for calculation of live moisture of extinction (mxl). note that contributions from the 1000-hour class are omitted because their contributions are negligible
	mclfe = ((mc1 * hn1) + (mc10 * hn10) + (mc100 * hn100)) / (hn1 + hn10 + hn100)		; dead-fuel moisture content, weighted by heating number, for calculation of live moisture of extinction (mxl)

	sgbrt = (fdead * sgbrd) + (flive * sgbrl)		; characteristic surface area-to-volume ratio of fuel bed, surface area weighted
	rhobed = (wtot - w1000) / depth				; bulk density of fuel bed
	rhobar = ((wtotl * rhol) + (wtotd * rhod)) / wtot	; particle density of weighted fuel
	wtmcd = (f1 * mc1) + (f10 * mc10) + (f100 * mc100)	; surface area weighted dead-fuel moisture content
	wtmcl = (fherb * mcherb) + (fwood * mcwood)		; surface area weighted live-fuel moisture content

        mxl = where(wtotln .gt. 0, (2.9 * wrat * (1.0 - mclfe / mxd) - 0.226) * 100.0 > mxd, 0) ; calculated live-fuel moisture of extinction
        mxl = where(ismissing(wrat), 0., mxl)

	gmamx = (sgbrt^1.5) / (495.0 + 0.0594 * sgbrt^1.5)	; weighted maximum reaction velocity of surface area
	betbar = rhobed/rhobar					; packing ratio
	betop = 3.348 * sgbrt^(-0.8189)				; optimum packing ratio, surface area weighted
	ad = 133.0 * sgbrt^(-0.7913)				; exponent in gmaop equation

	dedrt = wtmcd / mxd	; ratio in calculation of etamd

	fherb = saherb / salive	; proportion of live surface area in herbaceous class

        livrt = wtmcl / where(mxl .eq. 0., mc100@_FillValue, mxl)       ; ratio in calculation of etaml
        livrt = where(mxl .eq. 0.0, 0.0, livrt)


	gmaop = gmamx * (betbar / betop)^ad * exp(ad * (1.0 + betbar / betop))	; weighted optimum reaction velocity of surface area
	wdeadn = (f1 * w1n) + (f10 * w10n) + (f100 * w100n)			; net loading of dead fuels, surface-area weighted
	etasd = 0.174 * sd^(-0.19)						; mineral damping coefficient of dead fuel
	etamd = 1.0 - (2.59 * dedrt) + (5.11 * (dedrt^2.0)) - (3.52 * (dedrt^3.0))	; surface area weighted dead-fuel moisture damping coefficient
	etamd = etamd > 0	;NEW LINE 3/9/2020
	etamd = etamd < 1	;NEW LINE 3/9/2020
	wliven = (fwood * wwoodn) + (fherb * wherbn)				; surface area weighted net loading of live fuels
	etasl = 0.174 * sl^(-0.19)						; live fuel mineral damping coefficient
	etaml = 1.0 - (2.59 * livrt) + (5.11 * (livrt^2.0)) - (3.52 * (livrt^3.0))	; surface area weighted live-fuel moisture damping coefficient
	etaml = etaml > 0       ;NEW LINE 3/9/2020
	etaml = etaml < 1       ;NEW LINE 3/9/2020 these four new lines are what make BI not break :)

	;slope angle depends on nfdrs slope class:
	slope_angles = (/12.67, 17.63, 24.23, 32.46, 41.99/)	; corresponding to NFDRS slope class (/1,2,3,4,5/) ****Not the same as NFDRS climate class**** 
	slope_class = 1	;default taken from MATLAB code. If better information can be found, replace this line.
	slope_angle = slope_angles(slope_class - 1)
	slpfct = 5.275 * (tan(slope_angle * get_pi("float") / 180.0)) ^ 2			; slope effect multiplier coefficient

	;wind effect multiplier coefficients/exponents
	c = 7.47 * exp( -0.133 * sgbrt^0.55)
	e = 0.715 * exp(-3.59 * 10^(-4) * sgbrt)
	b = 0.02526 * sgbrt^0.54
	ufact = c * (betbar / betop)^(-e)

	ir = gmaop * ((wdeadn * hd * etasd * etamd) + (wliven * hl * etasl * etaml))		; surface area weighted reaction intensity
	zeta = exp((0.792 + 0.681 * sgbrt^0.5) * (betbar + 0.1)) / (192.0 + 0.2595 * sgbrt)	; no wind propogating flux ratio
	phislp = slpfct * betbar^(-0.3)								; multiplier for slope effect

;	if((ws * 88.0 *wndfc) .gt. 0.9 * ir) then
;		phiwnd = ufact * ((0.9 * ir)^b)	; wind effect multiplier
;	else
;		phiwnd = ufact * ((ws * 88.0 * wndfc)^b)
;	end if

	phiwnd = where((ws * 88.0 * wndfc) .gt. (0.9 * ir), ufact * ((0.9 * ir)^b), ufact * ((ws * 88.0 * wndfc)^b))
;	phiwnd = where((ws * 88.0 * wndfc) .gt. (0.9 * ir), ufact * ((0.9 * ir)), 1)

	; all *_div variables are to avoid divisions by 0 in htsink calculations.
/;
	sg10_div = -138.0 / where(sg10 .ne. 0.0, sg10, mc100@_FillValue)
	sg10_div = where(sg10 .eq. 0.0, 0.0, sg10_div)

	sg100_div = -138.0 / where(sg100 .ne. 0.0, sg100, mc100@_FillValue)
	sg100_div = where(sg100 .eq. 0.0, 0.0, sg100_div)

	sgherb_div = -138.0 / where(sgherb .ne. 0.0, sgherb, mc100@_FillValue)
	sgherb_div = where(sgherb .eq. 0.0, 0.0, sgherb_div)

	sgwood_div = -138.0 / where(sgwood .ne. 0.0, sgwood, mc100@_FillValue)
	sgwood_div = where(sgwood .eq. 0.0, 0.0, sgwood_div)
;/
;	htsink = rhobed * (fdead * ( f1 * exp(-138.0 / sg1) * (250.0 * 11.16 * mc1) + f10 * exp(-138.0 / sg10) * (250.0 * 11.16 * mc10) + f100 * exp(-138.0 / sg100) * (250.0 * 11.16 * mc100))) + (flive * (fherb * exp(-138.0 / sgherb) * ( 250.0 + 11.16 * mcherb) + fwood * exp(-138.0 / sgwood) * ( 250.0 + 11.16 * mcwood)))	; heat sink
;	htsink = rhobed * (fdead * ( f1 * exp(-138.0 / sg1) * (250.0 * 11.16 * mc1) + f10 * exp(sg10_div) * (250.0 * 11.16 * mc10) + f100 * exp(sg100_div) * (250.0 * 11.16 * mc100))) + (flive * (fherb * exp(sgherb_div) * ( 250.0 + 11.16 * mcherb) + fwood * exp(sgwood_div) * ( 250.0 + 11.16 * mcwood)))	; heat sink
;	htsink = rhobed * ((fdead * ( f1 * exp(-138.0 / sg1) * (250.0 * 11.16 * mc1) + f10 * exp(sg10_div) * (250.0 * 11.16 * mc10) + f100 * exp(sg100_div) * (250.0 * 11.16 * mc100))) + (flive * (fherb * exp(sgherb_div) * ( 250.0 + 11.16 * mcherb) + fwood * exp(sgwood_div) * ( 250.0 + 11.16 * mcwood))))	; heat sink

	;segment the calculation of htsink into manageable pieces. NOTE that the calculations have been changed significantly due to a typo discovered 2023/07/23
	ht1 = f1 * exp(-138.0 / sg1) * (250.0 + 11.16 * mc1)
	ht10 = f10 * exp(-138.0 / where(sg10 .eq. 0., mc100@_FillValue, sg10)) * (250.0 + 11.16 * mc10)
	ht10 = where(sg10 .eq. 0., 0., ht10)
	ht100 = f100 * exp(-138.0 / where(sg100 .eq. 0., mc100@_FillValue, sg100)) * (250.0 + 11.16 * mc100)
	ht100 = where(sg100 .eq. 0., 0., ht100)

	htherb = fherb * exp(-138.0 / where(sgherb .eq. 0., mc100@_FillValue, sgherb)) * (250.0 + 11.16 * mcherb)
	htherb = where(sgherb .eq. 0., 0., htherb)

	htwood = fwood * exp(-138.0 / where(sgwood .eq. 0., mc100@_FillValue, sgwood)) * (250.0 + 11.16 * mcwood)
	htwood = where(sgwood .eq. 0., 0., htwood)

	htsink = rhobed * ((fdead * (ht1 + ht10 + ht100)) + (flive * (htherb + htwood)))

	;the following calculation is technically a variable called ros, or Rate of Spread. However, sc is just a rounding of ros.
	sc = ir * zeta * (1 + phislp + phiwnd) / htsink	; spread component

	bi = 3.01 * ((sc * erc)^0.46)	; burning index

	return(bi)
end
