/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 w1d,w10d,w100d,w1000d,wherb,wwood,depth,sg1d,sg10d,sg100d,sg1000d,sgherb,sgwood,extmoi,hd are read in according to the fuel model
 fm1, fm10, fm100, fm1000 are the same as mc1, mc10, mc100, mc1000, the percent moisture content of 1-, 10-, 100-, 1000-hour timelag
 erc is energy release component
;/

load "retrieve_constants.ncl"

;function calc_just_erc(w1d,w10d,w100d,w1000d,wherb,wwood,mcherb,depth,sg1d,sg10d,sg100d,sg1000d,sgherb,sgwood,fm1,fm10,fm100,fm1000,fmwood,extmoi,hd)
function calc_just_erc_1fuelmod(mcherb,fm1,fm10,fm100,fm1000,fmwood,fuel_model)
local stdl, rhodl, sdl, etasdl, fctcur, wherbc, w1dp, wherbp, wtotd, wtotl, wtot, w1n, w10n, wherbn, wwoodn, wtotln, rhobed, rhobar, betbar, hnu1, hnu10, hnu100, hnherb, hnwood, wrat, fmff, extliv, sa1, sa10, sa100, sherbc, sawood, sadead, salive, fct1, fct10, fct100, fcherb, fcwood, fcded, fcliv, sgbrd, sgbrl, sgbrt, fct1e, fct10e, fct100e, fct1000e, fwoode, fhrbce, fcdede, fclice, wdedne, wlivne, sgbrde, sgbrle, sgbrte, betope, gmamxe, ade, gmapme, wftmde, wtfmle, dedrte, livrte, etamde, etamle, ire, tau, erc

begin

constants = retrieve_constants(fuel_model)
w1d=constants(0)
w10d=constants(1)
w100d=constants(2)
w1000d=constants(3)
wwood=constants(4)
wherb=constants(5)
sg1d=constants(6)
sg10d=constants(7)
sg100d=constants(8)
sg1000d=constants(9)
sgwood=constants(10)
sgherb=constants(11)
hd=constants(12)
extmoi=constants(14)
depth=constants(15)

c1 = 0.046

w1d = w1d * c1
w10d = w10d * c1
w100d = w100d * c1
w1000d = w1000d * c1
wherb = wherb * c1
wwood = wwood * c1              ; conversions from T/Ac to lbs/ft^2

stdl = 0.0555   ; used in place of std and stl, since both have the same value
rhodl = 32.     ; used in place of rhod and rhol, since both have the same value
sdl = 0.01      ; sd and sl
etasdl = 0.174 * sdl^(-.19)

fctcur = 1.33 - 0.0111 * mcherb
fctcur = fctcur > 0.
fctcur = fctcur < 1.
wherbc = fctcur * wherb         ;wherbc is never initialized as this in the MATLAB code, but is a useful intermediary variable
w1dp = w1d + wherbc
wherbp = wherb - wherbc         ;wherbp here is wherbc in MATLAB code
wtotd = w1dp + w10d + w100d + w1000d
wtotl = wwood + wherbp
wtot = wtotd + wtotl

;compute net fuel loading
w1n = w1dp * (1. - stdl)
w10n = w10d * (1. - stdl)
;w100n = w100d - (1. - stdl)
w100n = w100d * (1. - stdl)     ;THIS WAS CHANGED FROM w100n = w100d - (1. - stdl). THIS COULD ALTER RESULTS 2023/03/09
wherbn = wherbp * (1. - stdl)   ;wherbn is from paper. In MATLAB code this is the variable whernc
wwoodn = wwood * (1. - stdl)
wtotln = wtotl * (1. - stdl)

rhobed = (wtot - w1000d) / depth        ;bulk density of fuel bed
rhobar = ((wtotl * rhodl) + (wtotd * rhodl)) / wtot     ; particle density of weighted fuel
betbar = rhobed / rhobar        ; packing ratio

;if wtotln .gt. 0
;heating numbers
hnu1 = w1n * exp(-138. / sg1d)
if(sg10d .ne. 0.0) then
	hnu10 = w10n * exp( -138. / sg10d)
else
	hnu10 = 0.0
end if

if(sg100d .ne. 0.0) then	;this was changed from [ if(sg1000d .ne. 0.0) then ]
	hnu100 = w100n * exp( -138. / sg100d)
else
	hnu100 = 0.0
end if

;hnherb = where((-500. / sgherb) .lt. -180.218, 0., wherbn * exp(-500. / sgherb))
if(sgherb .ne. 0.0) then
	if((-500. / sgherb) .lt. -180.218) then
        	hnherb = conform_dims(dimsizes(wherbn), 0., -1)
	else
        	hnherb = wherbn * exp(-500. / sgherb)
	end if	
else
	hnherb = conform_dims(dimsizes(wherbn), 0., -1)
end if
			
;hnwood = where((-500. / sgwood) .lt. -180.218, 0., wwoodn * exp(-500. / sgwood))
;these 3 lines added on 2023/07/18

sgwood@_FillValue = fm100@_FillValue
hnwood_exp = sgwood
hnwood = sgwood

hnwood_exp = -500. / where(sgwood .ne. 0.0, sgwood, fm100@_FillValue)   ;ALTERED 2023/03/14 to have this be an intermediate variable, hnwood_exp, to make this clearer
hnwood = where(hnwood_exp .lt. -180.218, 0., wwoodn * exp(hnwood_exp))
hnwood = where(sgwood .eq. 0.0, 0.0, hnwood)
delete(hnwood_exp)
/;
hnwood = -500. / where(sgwood .ne. 0.0, sgwood, fm100@_FillValue)
hnwood = where(sgwood .eq. 0.0, 0.0, hnwood)
hnwood = where(hnwood .lt. -180.218, 0., wwoodn * exp(-500. / where(sgwood .ne. 0, sgwood, fm100@_FillValue)))
hnwood = where(sgwood .eq. 0.0, 0.0, hnwood)
;/

wrat = hnherb
wrat@_FillValue = fm100@_FillValue
;wrat = where((hnherb + hnwood) .eq. 0., 0., (hnu1 + hnu10 + hnu100) / (hnherb + hnwood))
wrat = (hnu1 + hnu10 + hnu100) / where((hnherb + hnwood) .eq. 0.0, fm100@_FillValue, hnherb + hnwood)
;wrat = where((hnherb + hnwood) .eq. 0.0, 0.0, wrat)	;keep wrat as a missing value where hnherb and hnwood are both 0

fmff = ((fm1 * hnu1) + (fm10 * hnu10) + (fm100 * hnu100)) / (hnu1 + hnu10 + hnu100)     ; fine dead fuel moisture content
extliv = where(wtotln .gt. 0, ((2.9 * wrat * (1 - fmff / extmoi) - 0.226) * 100) > extmoi, 0.)  ;extmoi is moisture of extinction of the dead fuels from the fuel model. extliv is moisture of extinction of live fuels, which is calculated.
;extliv cannot be less than extmoi
extliv = where(ismissing(wrat), 0., extliv)	;ALTERED 2023/07/14 to accompany wrat being a missing value where hnherb, hnwood are both 0

;weighting factors for rate-of-spread by surface area
sa1 = (w1dp / rhodl) * sg1d
sa10 = (w10d / rhodl) * sg10d
sa100 = (w100d / rhodl) * sg100d
sherbc = (wherbp / rhodl) * sgherb
sawood = (wwood / rhodl) * sgwood

; total surface area of dead and live fuel categories by surface area
sadead = sa1 + sa10 + sa100
salive = sawood + sherbc

; weighting factors for dead and live fuel classes by surface area
fct1 = sa1 / sadead
fct10 = sa10 / sadead
fct100 = sa100 / sadead

fcherb = where(wtotl .gt. 0., sherbc / where(salive .eq. 0., fm100@_FillValue, salive), 0.)	;where the surface area of live fuels is 0, then the weighting factor for herbaceous fuel should be 0
fcherb = where(wtotl .gt. 0., where(salive .eq. 0., 0., fcherb), 0.)
fcwood = where(wtotl .gt. 0., sawood / where(salive .eq. 0., fm100@_FillValue, salive), 0.)	;where the surface area of live fuels is 0, then the weighting factor for woody fuel should be 0
fcwood = where(wtotl .gt. 0., where(salive .eq. 0., 0., fcwood), 0.)


;weighting factors for dead, live fuel categories
fcded = sadead / (sadead + salive)
fcliv = salive / (sadead + salive)

; weighted surface area to volume ratios of dead and live fuel categories
sgbrd = fct1 * sg1d + fct10 * sg10d + fct100 *sg100d
sgbrl = fcwood * sgwood + fcherb * sgherb

;characteristic surface area to volume ratio
sgbrt = sgbrd * fcded + sgbrl * fcliv

;weighting factors for dead and live fuel classes by load
fct1e = w1dp / wtotd
fct10e = w10d / wtotd
fct100e = w100d / wtotd
fct1000e = w1000d / wtotd

;fwoode = where(wtotl .gt. 0, wwood / wtotl, 0)
fwoode = wwood / where(wtotl .eq. 0., fm100@_FillValue, wtotl)	;if wtotl = 0, wwood must be 0. 0/0 is undefined. If the woody fuel and live fuels do not exist, the woody fuel weighting factor should be 0.
fwoode = where(wtotl .gt. 0., fwoode, 0.)

;fhrbce = where(wtotl .gt. 0, wherbp / wtotl, 0)
fhrbce = wherbp / where(wtotl .eq. 0., fm100@_FillValue, wtotl)	;if wtotl = 0, wherbp must be 0. 0/0 is undefined. If the herbaceous fuel and live fuels do not exist, the woody fuel weighting factor should be 0.
fhrbce = where(wtotl .gt. 0., fhrbce, 0.)

;weighting factors for dead and live fuel categories by load
fcdede = wtotd / wtot
fclive = wtotl / wtot
wdedne = wtotd * (1 - stdl)
wlivne = wtotl * (1 - stdl)

sgbrde = (fct1e * sg1d) + (fct10e * sg10d) + (fct100e * sg100d) + (fct1000e * sg1000d)
sgbrle = (fwoode * sgwood) + (fhrbce * sgherb)
sgbrte = sgbrde * fcdede + sgbrle * fclive
betope = 3.348 * (sgbrte^(-0.8189))

gmamxe = (sgbrte^1.5) / (495 + 0.0594 * (sgbrte^1.5))   ; weighted max reaction velocity of loading
ade = 133 * (sgbrte^(-0.7913))
gmapme = gmamxe * ((betbar / betope)^ade) * exp(ade * (1 - (betbar/ betope))) ;weighted optimum reaction velocity of loading (gmaope)

;weighted moisture content of dead, live fuel categories
wtfmde = fct1e * fm1 + fct10e * fm10 + fct100e * fm100 + fct1000e * fm1000
wtfmle = fwoode * fmwood + fhrbce * mcherb

dedrte = wtfmde / extmoi
livrte = wtfmle / where(extliv .eq. 0., fm100@_FillValue, extliv)	;a ratio of weighted moisture content divided by moisture of extinction for live fuels
livrte = where(extliv .eq. 0., 0., livrte)

;moisture damping coefficients of live and dead fuels
etamde = 1 - 2 * dedrte + 1.5 * (dedrte^2) - 0.5 * (dedrte^3)
etamde = etamde < 1
etamde = etamde > 0

etamle = 1 - 2 * livrte + 1.5 * (livrte^2) - 0.5 * (livrte^3)	; if livrte = 0, etamle = 1
etamle = etamle < 1
etamle = etamle > 0

;reaction intensity
ire = fcdede * wdedne * hd * etasdl * etamde            ;note in MATLAB code there is an hd and hl, but they are equal
ire = gmapme * (ire + (fclive * wlivne * hd * etasdl * etamle))	; if etamle = 1, then it has no effect on this calculation

;residence time of the flaming front
tau = 384. / sgbrt

erc = 0.04 * ire * tau

return(erc)

end
