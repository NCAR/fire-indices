/; 
The following variables should be specified as command-line arguments
 e.g.: ncl file=\"$file\" script.ncl

precip_in
solrad_in
rhmax_in
rhmin_in
tmpmax_in
tmpmin_in
fm1000_in
fm100_in
output
const_in

optionally:
elev_in
z3_in	; this is a coefficient for converting precipitation amount to precipitation duration

;/


;Calculate ERC with these inputs:
/;
precipitation
solar radiation
maximum and minimum relative humidity
maximum and minimum temperature
optionally, altitude

secondarily,
latitude
longitude
time
;/

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;give it time as is written in netCDF file and it returns the day of year
function calc_julian_day(time)
local opt, cal, cal1, day_year
begin

opt = 0         ; for cd_calendar, option 0 returns an array: year (cal(0)), month (cal(1)), day (cal(2)), hour, minute, second

cal = cd_calendar(time, opt)
;print(cal)
cal1 = tointeger(cal)
day_year = day_of_year(cal1(:,0), cal1(:,1), cal1(:,2))

return(day_year)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 lat is latitude
 day is the julian day, or day of year (1 to 365)
 Z is elevation. If elevation unknown, input Z = 0
;/
function calc_potential_solar( lat, day, Z )
local gsc, phi, phi1, dr, dr1, delta, delta1, omegas, Ra, maxsolar
begin

latlen = dimsizes(lat)
daylen = dimsizes(day)

gsc = 0.082	;solar constant, MJ m -2 min-1

phi = get_pi("float") * lat / 180
phi1 = conform_dims((/daylen, latlen/), phi, 1)

dr = 1+ 0.033 * cos(2 * get_pi("float") / 365 * day)
dr1 = conform_dims((/daylen, latlen/), dr, 0)

delta = 0.409 * sin(2 * get_pi("float")/365 * day - 1.39)
delta1 = conform_dims((/daylen, latlen/), delta, 0)

omegas = acos(-tan(phi1) * tan(delta1))

Ra = 24 * 60 * gsc / get_pi("float") * dr1 * ( omegas * sin(phi1) * sin(delta1) + cos(phi1) * cos(delta1) * sin(omegas) )	; FAO daily
maxsolar = Ra * (0.75 + 2 * 10^(-5) * Z)

maxsolar=maxsolar/.0864

return(maxsolar)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 day is day of year
 lat is latitude
 lonlen is the number of longitude coordinates in the area of calculation
;/
function calc_daylight_builtin(day, lat, lonlen)
local latlen, daylight, daylight1, daylit, day
begin

latlen = dimsizes(lat)

daylight = daylight_fao56(day, lat)
;daylight1 = daylight(0, :)
daylit = conform_dims((/latlen, lonlen/), daylight, 0)

return(daylit)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 j_date is day of year
 lat is latitude
 lonlen is the number of longitude coordinates in the area of calculation
;/
function calc_daylight_manual(j_date, lat, lonlen)
local phi, decl, daylit, latlen, daylit1
begin

daylen = dimsizes(j_date)
latlen = dimsizes(lat)

phi = lat * .01745
phi1 = conform_dims((/daylen, latlen/), phi, 1)

decl = .41008 * sin((j_date-82.) * .01745)
decl1 = conform_dims((/daylen, latlen/), decl, 0)

daylit=24*(1-acos(tan(phi1)*tan(decl1))/3.14159)
;daylit=real(daylit)

daylit1 = conform_dims((/daylen, latlen, lonlen/), daylit, (/0, 1/))

return(daylit1)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 tmax is maximum daily temperature, in Celsius
 tmin is the minimum daily temperature, in Celsius
 sph is specific humidity
 rh is relative humidity at 13:00
 Z is elevation
;/
function calc_vpd(tmax, tmin, sph, rh, Z)
local e1, Td, ew, fw, ew_tmin, ew_tmax, ew_tdew, vpd
begin

P=1013.25 * (1 - .0001 * Z)

sph = sph / .622
sph = sph * P
e1 = log( sph / 6.112)
Td = 243.5 * e1 / (17.67 - e1)

; solve for vapor pressure at minimum temp
ew = 10 ^ ((0.7859 + 0.03477 * tmin) / (1 + 0.00412 * tmin))
fw = 1 + 10^(-6) * P * (4.5 + 0.0006 * (tmin^2))
ew_tmin = fw * ew

; solve for vapor pressure at maximum temp
ew = 10 ^ ((0.7859 + 0.03477 * tmax) / (1 + 0.00412 * tmax))
fw = 1 + 10^(-6) * P * (4.5 + 0.0006 * (tmax^2))
ew_tmax = fw * ew

; solve for vapor pressure at dewtemp
ew = 10^((0.7859 + 0.03477 * Td) / (1 + 0.00412 * Td))
fw = 1 + 10^(-6) * P * (4.5 + 0.0006 * (Td^2))
ew_tdew = fw * ew

vpd = (ew_tmax / 2 + ew_tmin / 2) - ew_tdew             ; saturation vapor pressure in millibars
vpd = vpd / 10.               ; convert from mb to kPa

return(vpd)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 tmmn is minimum daily temperature
 lat is latitude
 vpd is vapor pressure deficit
 day_year is the day of year
 lonlen is the number of longitude coordinates in the area of calculation
 gsi is growing season index
;/
function calc_gsi(tmmn, lat, vpd, day_year, lonlen)
local vpd1, day_year, daylit, dayl, tmmn1, gsi, gsi_avg, gsi_adj
begin

vpd1 = 1 - (vpd - .9) / 3.2			;note that the variables vpd1, dayl, and tmmn1 are all normalized in some way, could be consolidated to a genearl normalizing function (not to be confused with function normalize below)
vpd1 = where(vpd .le. 0.9, 1., vpd1)
vpd1 = where(vpd .ge. 4.1, 0., vpd1)

daylit = calc_daylight_manual(day_year, lat, lonlen)

dayl = (daylit - 10.) / 11.
dayl = where(daylit .lt. 10, 0., dayl)
dayl = where(daylit .gt. 11, 1., dayl)

tmmn1 = (tmmn + 2) / 7.
tmmn1 = where(tmmn .ge. 5., 1, tmmn1)
tmmn1 = where(tmmn .le. -2., 0., tmmn1)

gsi = tmmn1 * vpd1 * dayl

timelen = dimsizes(gsi(:, 0,0))
latlen = dimsizes(gsi(0, :, 0))
gsi1 = conform_dims((/timelen + 20, latlen, lonlen/), flt2dble(0.), -1)
gsi1(10:(timelen+9), :, :) = gsi

gsi_avg = runave_n(gsi1, 21, 0, 0)        ; note that any reference to an element of this array must have 10 added in order to achieve the same output of MATLAB function
;the MATLAB code uses a running average of current element and previous 20 elements. There is no easy way to do this in NCL

gsi_adj = gsi_avg(10:timelen+9, :, :)	;discards the extra zeros on both ends of the array 

return(gsi_adj)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 gsi is growing season index
 this function is necessary to ensure that greenup can be initialized everywhere by normalizing GSI
;/
function normalize(gsi)	
local sort_gsi, min_gsi, max_gsi, min_index, max_index
begin

sort_gsi = dim_pqsort_n(gsi, 2, 0)
gsi_len = dimsizes(gsi(:, 0,0))
min_index = round(gsi_len * 0.005 - 1, 3) > 0
max_index = round(gsi_len * 0.995 - 1, 3)
min_gsi = sort_gsi(min_index, :, :)
max_gsi = sort_gsi(max_index, :, :)

latlen = dimsizes(gsi(0, :, 0))
lonlen = dimsizes(gsi(0, 0, :))

min_gsi1 = conform_dims((/gsi_len, latlen, lonlen/), min_gsi, (/1, 2/))
max_gsi1 = conform_dims((/gsi_len, latlen, lonlen/), max_gsi, (/1, 2/))

gsix = (gsi - min_gsi1) / (max_gsi1 - min_gsi1)

return(gsix)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 gsix is normalized GSI, or growing season index
 j_date is the day of year
 latlen is the number of latitude marks
 lonlen is the number of longitude marks
;/
function find_first(gsix, j_date, latlen, lonlen)               ;replaces the line < greenup(i)=find(gsix(:,i)>.5,1,'first') > in MATLAB
local ndays_year, nyears, jan1, cut_gsi, start_ind, end_ind, gsi_year, j_green
begin

ndays_yr = 365.2425
nyears = tointeger(ceil(dimsizes(j_date) / ndays_yr))
jan1 = dim_minind(j_date, 0)    ;the index of first occurence of January 1st

cut_gsi = where(gsix .ge. .5, .5, gsix) ;it does not matter if it goes higher than 0.5, so cut it off here to use a find maximum function

j_green = conform_dims((/nyears, latlen, lonlen/), 0, -1)

do i = 0, nyears-1
        start_ind = tointeger(jan1 + i*ndays_yr) < (dimsizes(cut_gsi(:, 0, 0))-1)
        end_ind = tointeger(jan1 + (i + 1) * ndays_yr) < (dimsizes(cut_gsi(:, 0, 0))-1)
        gsi_year = cut_gsi(start_ind:end_ind, :, :)             ;partition full run into year-long chunks
        j_green(i, :, :) = dim_maxind(gsi_year, 0)      ;find the first instance of 0.5 in the year. This should initialize greenup. assumes .5 is always reached, but if not will return whatever the highest gsi value is
	delete(gsi_year)
end do

return(j_green)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 sowc are State of Weather Codes
 T is temperature and H is humidity
;/
procedure adjust(T, H, sowc) 
begin

T = where( sowc .eq. 0, T + 25., T )
T = where( sowc .eq. 1, T + 19., T )
T = where( sowc .eq. 2, T + 12., T )
T = where( sowc .ge. 3, T + 5., T )

H = where( sowc .eq. 0, H * 0.75, H)
H = where( sowc .eq. 1, H * 0.83, H)
H = where( sowc .eq. 2, H * 0.92, H)
;no adjustment to humidity is made for sowc 3

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 rad is solar radiation
 ppt is hourly precipitation amount in inches/hr (sum of all precip over 24 hrs) / (24 hrs)
 maxrad is clear sky radiation
 sow are State of Weather Codes
;/

function calc_sow_daily(rad, ppt, maxrad)
local sow, percent_cloud
begin

;maxrad1 = conform(rad, maxrad, 0)
percent_cloud = rad / maxrad

sow = ppt
sow = -1

sow = where(percent_cloud .ge. 0.91, 0, sow)
sow = where(percent_cloud .lt. 0.91, 1, sow)
sow = where(percent_cloud .lt. 0.73, 2, sow)
sow = where(percent_cloud .lt. 0.5, 3, sow)
sow = where(ppt .ge. .01, 5, sow)       ; to indicate recent precipitation
sow = where(ppt .ge. .05, 6, sow)

return(sow)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/;
 z3 is a constant corresponding to latitude and longitude
 ppt is precipitation amount
 lat is latitude
 lon is longitude
;/

function calc_pduration(z3, ppt, lat, lon, mlat, mlon)	;this function uses the methods presented by MATLAB code
local pdur, flat, flon, flat1, flon1, b
begin

flat = ind(abs(mlat - lat) .lt. (1./24.))
flon = ind(abs(mlon - lon) .lt. (1./24.))
flat1 = flat(0)
flon1 = flon(0)

b = z3(flon1, flat1)	;!!may reorder variables later!!


pdur = 24. * (1. - exp(-b * ppt))
pdur = round(pdur, 0)
pdur = pdur < 8.
pdur = pdur > 0.
pdur = where(ppt .le. 0., 0, pdur)
return(pdur)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 ppt is amount of precipitation
 lat and lon are latitude and longitude
 climat is NFDRS climate class
;/
function calc_paper_pduration(ppt, lat, lon, climat)
local pdur, wetrat
begin

;note that this is different than the calculations in the MATLAB code. This is what is done in the paper

wetrat = where(climat .eq. 1 .or. climat .eq. 2, 0.25, 0.05)
pdur = (ppt / wetrat) + .49
pdur = pdur < 8.        ;not allowed to exceed 8 hours 

return(pdur)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 T is temperature
 H is humidity
 emc is equilibrium moisture content
;/
function calc_emc( T, H )
local emc
begin

emc = 2.22749 + 0.160107 * H - 0.014784 * T
emc = where(H .lt. 10., 0.03229 + .281073 * H - .000578 * T * H, emc)
emc = where(H .gt. 50., 21.0606 + 0.005565 * (H^2.0) - 0.00035 * H * T - 0.483199 * H, emc)

return(emc)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 sowc is State of Weather Codes
 emcprm is the equilibrium moisture content at the fuel atm interface and has had temp and humid adjustments
;/
function calc_fm1(emcprm, sowc)
local fm1
begin

fm1 = where(sowc .gt. 4, 35.0, 1.03 * emcprm)
return(fm1)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 sowc is State of Weather Code
 emcprm is the equilibrium moisture content at the fuel atm interface and has had temp and humid adjustments
;/
function calc_fm10(emcprm, sowc)
local fm10
begin

fm10 = where(sowc .gt. 4, 35., 1.28 * emcprm)
return(fm10)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 mc1000 is percent moisture content for 1000-hour timelag
 yx1000 is yesterday's x1000
 maxt is maximum daily temperature
 mint is minimum daily temperature
 hveg is the vegetation stage
;/
function calc_x1000(mc1000, ym1000, yx1000, maxt, mint, hveg)	;x1000 is a variable in the herbaceous fuel model
local diff, kwet, tempcheck, ktemp, x1000
begin

diff = mc1000 - ym1000
kwet = where((mc1000 .gt. 25.), 1., .0333 * mc1000 + .1675)
;kwet = where(mc1000 .lt. 10., 0.5, kwet)	this only appears in the paper
tempcheck = (maxt + mint) / 2.
ktemp = where(tempcheck .le. 50., 0.6, 1.0)
x1000 = yx1000 + (diff * kwet * ktemp)
x1000 = where(hveg .eq. "pregreen" .or. hveg .eq. "frozen" .or. hveg .eq. "cured", mc1000, x1000)

return(x1000)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
local mcherb, fherbf
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

mcherb = mc1	;pregreen stage

;mcherb = where(hveg .eq. "greenup", mchrbi + ((herbga + herbgb * x1000) - mchrbi) * gren , mcherb)	;mchrbp = herbga + herbgb * x1000; mcherbi taken from paper, max 30% or mcherb the day before greenup started
fherbf = herbga + herbgb * x1000 < 250
mcherb = where(hveg .eq. "greenup", (mc1 + (fherbf - mc1) * gren) < 250 , mcherb)		; this version from MATLAB code

mcherb = where(hveg .eq. "green", (herbga + herbgb * x1000) < 250, mcherb)

ymherb = where(hveg .eq. "green" .and. ymherb .lt. 0., mcherb, ymherb)

mcherb = where(hveg .eq. "green" .and. igrass .eq. "perennial", mcherb < ymherb, mcherb)	;only found in MATLAB code, not paper

ymherb = where(hveg .eq. "transition" .and. ymherb .lt. 0, annta + anntb * x1000, ymherb)

;mcherb = where(hveg .eq. "transition", where(igrass .eq. "perennial", (perta + pertb * x1000), (annta + anntb * x1000) < ymherb), mcherb)		where statements are used in the situation that igrass is not a scalar
if(igrass .eq. "perennial") then
	mcherb = where(hveg .eq. "transition", perta + pertb * x1000, mcherb)
else
	mcherb = where(hveg .eq. "transition", (annta + anntb * x1000) < ymherb, mcherb)
end if

;mcherb = where(igrass .eq. "perennial" .and. hveg .eq. "transition", mcherb > 30, mcherb)	;perennials are not allowed to go below 30%
if(igrass .eq. "perennial") then
	mcherb = where(hveg .eq. "transition", mcherb > 30., mcherb)
end if

;mcherb = where(hveg .eq. "cured", where(igrass .eq. "annual", perta + pertb * x1000, mc1), mcherb)
if(igrass .eq. "perennial")
	mcherb = where(hveg .eq. "cured", (perta + pertb * x1000) > 30, mcherb)
else
	mcherb = where(hveg .eq. "cured", mc1, mcherb)
end if

return(mcherb < 150)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 prgrn is a constant selected based on climat
 mc1000 is the 1000 hour fuel moisture
 hveg is the vegetation stage
 climat is the NFDRS climate class (1-4)
 ymwood is yesterday's mcwood
;/
function calc_mcwood(pregrn, mcwodi, mc1000, climat, hveg, gren, ymwood)
local mcwood, woodgas, pregrns, woodga, woodgb
begin

; shrubs over entire range of fmwood
woodgas = (/12.5,-5.0,-22.5,-45.0/)      ; wooda in MATLAB code
woodgbs = (/7.5,8.2,8.9,9.8/)            ; woodb in MATLAB code

; pre-season and post-freeze values for fmwood
pregrns = (/50.0,60.0,70.0,80.0/)

woodga = woodgas(climat - 1)
woodgb = woodgbs(climat - 1)
pregrn = pregrns(climat -1)
mcwodi = where(ymwood .gt. pregrn, ymwood, mcwodi)
mcwodp = woodga + woodgb * mc1000
mcwood = mcwodp < 200		; true during green stage. This corresponds to the hveg values green, transition, and cured
mcwood = mcwood > pregrn
mcwood = where(hveg .eq. "pregreen" .or. hveg .eq. "frozen", pregrn, mcwood)
mcwood = where(hveg .eq. "greenup", mcwodi + (mcwodp - mcwodi) * gren / 100., mcwood)	;mcwodi = pregrn

return(mcwood > pregrn)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 hveg is the vegetation stage
 warmdays is the number of consecutive days above freezing
 colddays is the number of days below freezing
 j_date is day of year
 j_green is the day to signal greenup
 gdd is growing degree days
;/
function calc_prelim_vegstage(hveg, warmdays, colddays, j_date, j_green, gdd)
local vegstage, vegstage1
begin

if(j_date .eq. 1) then
	vegstage1 = "pregreen"
else
	vegstage1 = hveg
end if

vegstage = where(vegstage1 .eq. "pregreen" .and. j_date .ge. 60. .and. j_date .le. 212 .and. warmdays .gt. 5 .and. gdd .gt. 300, "greenup", vegstage1)
vegstage = where(vegstage1 .eq. "curing" .and. colddays .ge. 3, "frozen", vegstage)

return(vegstage)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
warmdays is the number of (consecutive?) days where the maximum temperature is above freezing
colddays is the number of days where the minimum temperature below freezing
gdd is the growing degree days
maxt is the maximum temperature
mint is the minimum temperature
j_date is the day of year or julian day
j_green is the day of year on which greenup was initialized
gren is the fraction of the greenup period that has elapsed
mcherb is the calculated herbaceous percent moisture content
hveg is the vegetation stage
;/

function calc_vegstage(warmdays, colddays, gdd, maxt, mint, j_date, j_green, gren, mcherb, hveg)
local vegstage, prgrn_check
begin

vegstage = where(hveg .eq. "pregreen" .and. j_date .ge. j_green, "greenup", hveg)	
vegstage = where(hveg .eq. "greenup" .and. gren .ge. 100. .and. mcherb .ge. 120., "green", vegstage)
vegstage = where(hveg .eq. "greenup" .and. gren .ge. 100. .and. mcherb .lt. 120., "transition", vegstage)
vegstage = where(hveg .eq. "green" .and. mcherb .lt. 120, "transition", vegstage)
vegstage = where(hveg .eq. "transition" .and. mcherb .le. 30., "cured", vegstage)
vegstage = where(colddays .ge. 3 .and. hveg .eq. "cured", "frozen", vegstage)

return(vegstage)

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/;
 w1d,w10d,w100d,w1000d,wherb,wwood,depth,sig1d,sig10d,sg100d,s1000d,sgherb,sgwood,extmoi,hd are read in according to the fuel model
 fherbc is mcherb, herbaceous percent moisture content
 fm1, fm10, fm100, fm1000 are the same as mc1, mc10, mc100, mc1000, the percent moisture content of 1-, 10-, 100-, 1000-hour timelag
 erc is energy release component
;/
function calc_erc(w1d,w10d,w100d,w1000d,wherb,wwood,fherbc,depth,sig1d,sig10d,sg100d,s1000d,sgherb,sgwood,fm1,fm10,fm100,fm1000,fmwood,extmoi,hd)
local stdl, rhodl, sdl, etasdl, fctcur, wherbc, w1dp, wherbp, wtotd, wtotl, wtot, w1n, w10n, wherbn, wwoodn, wtotln, rhobed, rhobar, betbar, hnu1, hnu10, hnu100, hnherb, hnwood, wrat, fmff, extliv, sa1, sa10, sa100, sherbc, sawood, sadead, salive, fct1, fct10, fct100, fcherb, fcwood, fcded, fcliv, sgbrd, sgbrl, sgbrt, fct1e, fct10e, fct100e, f1000e, fwoode, fhrbce, fcdede, fclice, wdedne, wlivne, sgbrde, sgbrle, sgbrte, betope, gmamxe, ade, gmapme, wftmde, wtfmle, dedrte, livrte, etamde, etamle, ire, tau, erc
begin

stdl = 0.0555   ; used in place of std and stl, since both have the same value
rhodl = 32.     ; used in place of rhod and rhol, since both have the same value
sdl = 0.01      ; sd and sl
etasdl = 0.174 * sdl^(-.19)

fctcur = 1.33 - 0.0111 * fherbc
fctcur = fctcur > 0.
fctcur = fctcur < 1.
wherbc = fctcur * wherb		;wherbc is never initialized as this in the MATLAB code, but is a useful intermediary variable
w1dp = w1d + wherbc        
wherbp = wherb - wherbc		;wherbp here is wherbc in MATLAB code
wtotd = w1dp + w10d + w100d + w1000d
wtotl = wwood + wherbp
wtot = wtotd + wtotl

;compute net fuel loading
w1n = w1dp * (1. - stdl)
w10n = w10d * (1. - stdl)       
w100n = w100d - (1. - stdl)
wherbn = wherbp * (1. - stdl)	;wherbn is from paper. In MATLAB code this is the variable whernc
wwoodn = wwood * (1. - stdl)
wtotln = wtotl * (1. - stdl)

rhobed = (wtot - w1000d) / depth	;bulk density of fuel bed
rhobar = ((wtotl * rhodl) + (wtotd * rhodl)) / wtot	; particle density of weighted fuel
betbar = rhobed / rhobar	; packing ratio

;if wtotln .gt. 0
;heating numbers
hnu1 = w1n * exp(-138. / sig1d)	
hnu10 = w10n * exp( -138. / sig10d)
hnu100 = w100n * exp( -138. / sg100d)

;hnherb = where((-500. / sgherb) .lt. -180.218, 0., wherbn * exp(-500. / sgherb))
if((-500. / sgherb) .lt. -180.218) then
	hnherb = conform_dims(dimsizes(wherbn), 0., -1)
else
	hnherb = wherbn * exp(-500. / sgherb)
end if

hnwood = where((-500. / sgwood) .lt. -180.218, 0., wwoodn * exp(-500. / sgwood))
wrat = where((hnherb + hnwood) .eq. 0., 0., (hnu1 + hnu10 + hnu100) / (hnherb + hnwood))
fmff = ((fm1 * hnu1) + (fm10 * hnu10) + (fm100 * hnu100)) / (hnu1 + hnu10 + hnu100)	; fine dead fuel moisture content
extliv = where(wtotln .gt. 0, ((2.9 * wrat * (1 - fmff / extmoi) - 0.226) * 100) > extmoi, 0.)	; moisture of extinction of the dead fuels from the fuel model

;weighting factors for rate-of-spread by surface area
sa1 = (w1dp / rhodl) * sig1d
sa10 = (w10d / rhodl) * sig10d
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

fcherb = where(wtotl .gt. 0., sherbc / salive, 0.)
fcwood = where(wtotl .gt. 0., sawood / salive, 0.)

;weighting factors for dead, live fuel categories
fcded = sadead / (sadead + salive)
fcliv = salive / (sadead + salive)

; weighted surface area to volume ratios of dead and live fuel categories
sgbrd = fct1 * sig1d + fct10 * sig10d + fct100 *sg100d
sgbrl = fcwood * sgwood + fcherb * sgherb

;characteristic surface area to volume ratio
sgbrt = sgbrd * fcded + sgbrl * fcliv

;weighting factors for dead and live fuel classes by load
fct1e = w1dp / wtotd
fct10e = w10d / wtotd
fc100e = w100d / wtotd
f1000e = w1000d / wtotd

fwoode = where(wtotl .gt. 0, wwood / wtotl, 0)
fhrbce = where(wtotl .gt. 0, wherbp / wtotl, 0)

;weighting factors for dead and live fuel categories by load
fcdede = wtotd / wtot
fclive = wtotl / wtot
wdedne = wtotd * (1 - stdl)
wlivne = wtotl * (1 - stdl)

sgbrde = (fct1e * sig1d) + (fct10e * sig10d) + (fc100e * sg100d) + (f1000e * s1000d)
sgbrle = (fwoode * sgwood) + (fhrbce * sgherb)
sgbrte = sgbrde * fcdede + sgbrle * fclive
betope = 3.348 * (sgbrte^(-0.8189))

gmamxe = (sgbrte^1.5) / (495 + 0.0594 * (sgbrte^1.5))	; weighted max reaction velocity of loading
ade = 133 * (sgbrte^(-0.7913))
gmapme = gmamxe * ((betbar / betope)^ade) * exp(ade * (1 - (betbar/ betope))) ;weighted optimum reaction velocity of loading (gmaope)

;weighted moisture content of dead, live fuel categories
wtfmde = fct1e * fm1 + fct10e * fm10 + fc100e * fm100 + f1000e * fm1000
wtfmle = fwoode * fmwood + fhrbce * fherbc
dedrte = wtfmde / extmoi
livrte = wtfmle / extliv
etamde = 1 - 2 * dedrte + 1.5 * (dedrte^2) - 0.5 * (dedrte^3)
etamde = etamde < 1
etamde = etamde > 0
etamle = 1 - 2 * livrte + 1.5 * (livrte^2) - 0.5 * (livrte^3)
etamle = etamle < 1
etamle = etamle > 0

ire = fcdede * wdedne * hd * etasdl * etamde		;note in MATLAB code there is an hd and hl, but they are equal
ire = gmapme * (ire + (fclive * wlivne * hd * etasdl * etamle))
tau = 384. / sgbrt

erc = 0.04 * ire * tau

return(erc)


end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;MAIN BODY OF CODE
begin

r_pr = addfile(precip_in, "r")
r_rad = addfile(solrad_in, "r")
r_rhmax = addfile(rhmax_in, "r")
r_rhmin = addfile(rhmin_in, "r") 
r_tmax = addfile(tmpmax_in, "r")
r_tmin = addfile(tmpmin_in, "r")
r_fm1000 = addfile(fm1000_in, "r")
r_fm100 = addfile(fm100_in, "r")
r_huss = addfile(spchum_in, "r")
r_z3 = addfile(z3_in, "r")
r_const = addfile(const_in, "r")
;r_elev = addfile(elev_in, "r")

system("rm -f "+output)
w_erc = addfile(output, "c") ;create new file to store three month spi (current and previous lines)

;filedimdef(w_erc, "time", -1, True) ; make time dimension unlimited

;copy/set global attributes

att_names = getvaratts(r_pr)

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  w_erc@$att_names(i)$ = r_pr@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL script from source file "+precip_in+ ", "+solrad_in+ ", "+rhmax_in+ ", "+rhmin_in+ ", "+tmpmax_in+ ", "+tmpmin_in+ ", "+fm1000_in+ ", "+fm100_in
w_erc@history = history

; copy variables

var_names = getfilevarnames(r_pr)

do i = 0, dimsizes(var_names)-1
   if (var_names(i) .ne. "precipitation_amount") then
       w_erc->$var_names(i)$ = r_pr->$var_names(i)$
   end if
end do


; initialize the following
lat = r_pr->lat
lon = r_pr->lon
time = r_pr->day

maxt = r_tmax->air_temperature
maxtC = maxt - 273.15
maxt = maxtC * 1.8 + 32.
mint = r_tmin->air_temperature
mintC = mint - 273.15
mint = mintC * 1.8 + 32.		;Celsius to Fahrenheit
maxrh = r_rhmax->relative_humidity	
minrh = r_rhmin->relative_humidity
temp1 = maxt - 2.
rh1 = minrh + 2.
prec = r_pr->precipitation_amount
prec = prec / 24.5	;mm to inches
rad = r_rad->surface_downwelling_shortwave_flux_in_air
mc1000 = r_fm1000->fm1000	;calculated in a different file 
mc100 = r_fm100->fm100
huss = r_huss->specific_humidity
b = r_z3->Z3
;elev = r_elev->orog
elev = 500.

latlen = dimsizes(lat)
lonlen = dimsizes(lon)
timelen = dimsizes(time)
day_year = calc_julian_day(time)
tempsolar = calc_potential_solar(lat,day_year, elev) 
maxsolar = conform_dims((/timelen, latlen, lonlen/), tempsolar, (/0,1/))

sow = calc_sow_daily(rad, prec, maxsolar)

fuelmodel = 7		; corresponds to fuel model G
annperen = "annual"	; in MATLAB code, 1 == annual, 2 == perennial
climat = 3
;pptdur = calc_paper_pduration(prec, lat, lon, climat)
mlat = r_z3->lat
mlon= r_z3->lon
pptdur = calc_pduration(b, prec, lat, lon, mlat, mlon)

;READ IN ALL THE CONSTANTS. For right now, always use fuel model G
fuel_mod = 6    ;0=A, 1=B, 2=C, 3=D, 4=E, 5=F, 6=G, 7=H, 8=I, 9=J etc
w1d = r_const->w1(fuel_mod)
w10d = r_const->w10(fuel_mod)
w100d = r_const->w100(fuel_mod)
w1000d = r_const->w1000(fuel_mod)
wherb = r_const->whrb(fuel_mod)
wwood = r_const->wwd(fuel_mod)
depth = r_const->dp(fuel_mod)
sig1d = r_const->s1(fuel_mod)
sig10d = r_const->s10(fuel_mod)
sg100d = r_const->s100(fuel_mod)
s1000d = r_const->s1000(fuel_mod)
sgherb = r_const->shrb(fuel_mod)
sgwood = r_const->swd(fuel_mod)
extmoi = r_const->emo(fuel_mod)
hd = r_const->hd(fuel_mod)

c1 = 0.046

w1d = w1d * c1
w10d = w10d * c1
w100d = w100d * c1
w1000d = w1000d * c1
wherb = wherb * c1
wwood = wwood * c1              ; conversions from T/Ac to lbs/ft^2

hveg = conform_dims((/latlen, lonlen/), "pregreen", -1)                ; pregreen, greenup, green, transition, cured, frozen
greendays = prec(0, :, :)
greendays = 0.
colddays = prec(0, :, :)
colddays = 0.
warmdays = prec(0, :, :)
warmdays = 0.
gdd = prec(0, :, :)
gdd = 0.
ymherb = prec(0, :, :)
ymherb = 50.
ymwood = ymherb


vpd = calc_vpd(maxtC, mintC, huss, rh1, elev)		;the vpd function requires Celsius
gsi = calc_gsi(mint, lat, vpd, day_year, lonlen)
gsi_norm = normalize(gsi)

greenup = find_first(gsi_norm, day_year, latlen, lonlen)

yx1000 = mc1000(0, :, :)
ym1000 = mc1000(0, :, :)

pregrns = (/50.0,60.0,70.0,80.0/)
pregrn1 = pregrns(climat -1)

tmpprm = temp1
rhprm = rh1
adjust(tmpprm, rhprm, sow)             ;current MATLAB code does not adjust but it probably should
emcprm = calc_emc(tmpprm, rhprm)

mc1 = calc_fm1(emcprm, sow)             ; calculate fm1 and fm10
mc10 = calc_fm10(emcprm, sow)

mcwodi = ymherb
mcwodi = (/pregrn1/)
mcherbi = mc1

erc = prec
ndays = dimsizes(time) - 1

do i=0, ndays

	year = tointeger(floor(i / 365.2425))
	j_green = greenup(year, :, :)
	hveg = calc_prelim_vegstage(hveg, warmdays, colddays, day_year(i), j_green, gdd)
	j_green = where( greendays .eq. 0 .and. hveg .eq. "greenup", day_year(i), j_green)      ;any point to this line at this point????
	gdd = where(warmdays .gt. 5, gdd + (maxt(i, :, :) + mint(i, :, :)) / 2. - 32., 0)

	x1000 = calc_x1000(mc1000(i, :, :), ym1000, yx1000, maxt(i, :, :), mint(i, :, :), hveg)

	gren = where(hveg .eq. "greenup", 100. * greendays / (7 * climat), -1.0)

	mcherb  = calc_mcherb(mc1(i, :, :), mcherbi(i, :, :), mc1000(i, :, :), ym1000, greendays, climat, hveg, annperen, x1000, ymherb, gren)
	greendays = where(hveg .eq. "greenup", greendays + 1, greendays)
	mcwood = calc_mcwood(pregrn1, mcwodi, mc1000(i, :, :), climat, hveg, gren, ymwood)

	hveg = calc_vegstage(warmdays, colddays, gdd, maxt(i, :, :), mint(i, :, :), day_year(i), j_green, gren, mcherb, hveg)
	erc(i, :, :) = (/calc_erc(w1d, w10d, w100d, w1000d, wherb, wwood, mcherb, depth, sig1d, sig10d, sg100d, s1000d, sgherb, sgwood, mc1(i, :, :), mc10(i, :, :), mc100(i, :, :), mc1000(i, :, :), mcwood, extmoi, hd)/)

        colddays = where(hveg .eq. "cured" .and. mint(i, :, :) .lt. 32., colddays + 1, colddays)        
        colddays = where(hveg .eq. "greenup" .or. hveg .eq. "frozen", 0., colddays)
        warmdays = where(maxt(i, :, :) .gt. 32., warmdays + 1, 0.)

	yx1000 = (/x1000/)
	ymherb = (/mcherb/)
	ymwood = (/mcwood/)

end do

delete_VarAtts(erc, -1) ;get rid of superfluous attributes

erc@long_name = "Energy Release Component"   ; No convention for long names, just make it descriptive

varatts = (/"units", "missing_value", "_FillValue"/)

erc@$varatts(0)$ = "1"

do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
   erc@$varatts(i)$ = r_pr->precipitation_amount@$varatts(i)$
end do

w_erc->erc = erc

end
