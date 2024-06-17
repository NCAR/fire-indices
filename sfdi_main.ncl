/;

read in needed variables:
refbifile=\"abcd.nc\"
refercfile=\"abcd.nc\"
calcbifile=\"abcd.nc\"
calcercfile=\"abcd.nc\"
refstart=1980
refend=2010
evalstart=2005
evalend=2099
outfile=\"abcd.nc\"

;/

load "calc_sfdi.ncl"

begin

;read in files
;refbifile = "/glade/p/ral/risc/fire/mbcn-gridMET/NAM-22i/CanRCM4/CanESM2/hist/bi/bi.G.hist.CanESM2.CanRCM4.day.NAM-22i.mbcn-gridMET.nc"
;refercfile = "/glade/p/ral/risc/fire/mbcn-gridMET/NAM-22i/CanRCM4/CanESM2/hist/erc/erc.G.hist.CanESM2.CanRCM4.day.NAM-22i.mbcn-gridMET.nc"

;bifile = "/glade/p/ral/risc/fire/mbcn-gridMET/NAM-22i/CanRCM4/CanESM2/rcp85/bi/bi.G.rcp85.CanESM2.CanRCM4.day.NAM-22i.mbcn-gridMET.nc"
;ercfile = "/glade/p/ral/risc/fire/mbcn-gridMET/NAM-22i/CanRCM4/CanESM2/rcp85/erc/erc.G.rcp85.CanESM2.CanRCM4.day.NAM-22i.mbcn-gridMET.nc"

/;
rbi_ref = addfile(refbifile, "r")
rerc_ref = addfile(refercfile, "r")

rbi = addfile(calcbifile, "r")
rerc = addfile(calcercfile, "r")
;/
;NOTE THAT REF FILE AND ACTUAL REF PERIOD ARE SET SEPARATELY IN THIS VERSION
;and this version assumes reference and calc files are continuous in time (aka hist and rcp85)

rbi = addfiles((/refbifile, calcbifile/), "r")
rerc = addfiles((/refercfile, calcercfile/), "r")

rtimein = rbi[:]->time

timein_formatted = cd_calendar(rtimein, 0)

refpd_ind = ind(timein_formatted(:,0) .ge. refstart .and. timein_formatted(:, 0) .le. refend)

refbi = rbi[:]->bi(refpd_ind, :, :)
referc = rerc[:]->erc(refpd_ind, :, :)

evalpd_ind = ind(timein_formatted(:,0) .ge. evalstart .and. timein_formatted(:,0) .le. evalend)

bi_in = rbi[:]->bi(evalpd_ind, :, :)
erc_in = rerc[:]->erc(evalpd_ind, :, :)

print("refpd:")
print(get_unique_values(timein_formatted(refpd_ind,0)))
print("evalpd:")
print(get_unique_values(timein_formatted(evalpd_ind,0)))

printVarSummary(refbi)
printVarSummary(referc)
printVarSummary(bi_in)
printVarSummary(erc_in)


;refbi = rbi_ref->bi
;referc = rerc_ref->erc

;bi_in = rbi->bi
;erc_in = rerc->erc

;attach attributes
lat = rbi[0]->lat
lon = rbi[0]->lon

refbi@lat = lat
refbi@lon = lon
referc@lat = lat
referc@lon = lon

bi_in@lat = lat
bi_in@lon = lon
erc_in@lat = lat
erc_in@lon = lon

;send into function

;opts = True
opts = False
;opts@cutoff_file_bi = "/glade/scratch/kessenic/bi.cutoffs.G.hist.CanESM2.CanRCM4.day.NAM-22i.mbcn-gridMET.nc"
;opts@cutoff_file_erc = "/glade/scratch/kessenic/bi.cutoffs.G.hist.CanESM2.CanRCM4.day.NAM-22i.mbcn-gridMET.nc"	;well this probably screwed something up....

;opts@cutoff_file_bi = bicutofffile
;opts@cutoff_file_erc = erccutofffile
print("SKIPPING CUTOFF FILES")


sfdi = calc_sfdi(refbi, referc, bi_in, erc_in, opts)	;refbi, referc, bi, erc, opts

; set up output

system("rm -f "+outfile)
w_sfdi = addfile(outfile, "c") ;create new file to store erc

filedimdef(w_sfdi, "time", -1, True) ; make time dimension unlimited

print(w_sfdi)

;copy/set global attributes
att_names = getvaratts(rbi[0])

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  w_sfdi@$att_names(i)$ = rbi[0]@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL scripts sfdi_main.ncl, from source file "+refbifile+ " and "+refercfile+" and "+calcbifile+ " and "+calcercfile 
w_sfdi@history = history

print(w_sfdi)

; copy variables
var_names = getfilevarnames(rbi[1])

do i = 0, dimsizes(var_names)-1
   if (var_names(i) .ne. "bi" .and. var_names(i) .ne. "time" .and. var_names(i) .ne. "time_bnds") then
       w_sfdi->$var_names(i)$ = rbi[1]->$var_names(i)$
   end if
end do
print(w_sfdi)
printVarSummary(sfdi)

w_sfdi->time = rtimein(evalpd_ind)
w_sfdi->time_bnds = rbi[:]->time_bnds(evalpd_ind, :)

; write out

print(w_sfdi)
printVarSummary(sfdi)


w_sfdi->sfdi = sfdi

end
