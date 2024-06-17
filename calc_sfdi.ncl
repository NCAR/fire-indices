/;
this version loops over x and y so that 1D timeseries are handled instead of 3D arrays
;/

load "calc_percentile_cutoffs_1D.ncl"
load "identify_closest_bin_1D.ncl"
load "append_bins_1d.ncl"
load "assign_binning_1D.ncl"
load "add_jitter_uniform.ncl"

procedure print_minmax(var, varname)
begin

print(varname + str_get_tab() + "min = " + min(var) + str_get_tab() + "max = " + max(var))

end

function calc_sfdi(referc, refbi, futerc, futbi, opts)	;NOTE erc, bi must be the same in the x/y dimensions, but not in time
local referc_dims, p_prime, ny, nx, referc_1d, refbi_1d, futerc_1d, futbi_1d, referc_bins, refbi_bins, matchbins_bi, matchbins_erc 
begin
referc_dims = dimsizes(referc)

p_prime = futerc
p_prime = futerc@_FillValue

;if(debugopts) then

;print("nope")


;end if

ny = referc_dims(1)
nx = referc_dims(2)


do i=0,nx-1

	do j=0,ny-1

;		print(" ")
;		print("---------------------------------------------------------------")
;		print("(i, j) = " + i + ", " + j)
;		print("---------------------------------------------------------------")


		referc_1d = referc(:, j, i)
		refbi_1d = refbi(:, j, i)
		futerc_1d = futerc(:, j, i)
		futbi_1d = futbi(:, j, i)	

		miss_referc = all(ismissing(referc_1d))
		miss_refbi = all(ismissing(refbi_1d))
		miss_futerc = all(ismissing(futerc_1d))
		miss_futbi = all(ismissing(futbi_1d))

		if(miss_referc .and. miss_refbi .and. miss_futerc .and. miss_futbi) then
			print("skipping i,j = " + i + ", " + j + " because everything is missing")
		else


			;-------------------------------------
			; normalize erc, bi
			;-------------------------------------
			;make bins 0-100
			referc_bins = calc_percentile_cutoffs(referc_1d)
			refbi_bins = calc_percentile_cutoffs(refbi_1d)
			futerc_bins = calc_percentile_cutoffs(futerc_1d)
			futbi_bins = calc_percentile_cutoffs(futbi_1d)

			;print_minmax(referc_bins, "referc_bins")
			;print_minmax(refbi_bins, "refbi_bins")
			;print_minmax(futerc_bins, "futerc_bins")
			;print_minmax(futbi_bins, "futbi_bins")

			;find closest match bins
			matchbins_erc = identify_closest_bin(referc_bins, futerc_bins)
			matchbins_bi = identify_closest_bin(refbi_bins, futbi_bins)
			;combine ref and fut bins
			fullerc_bins = append_bins(referc_bins, futerc_bins, matchbins_erc)
			fullbi_bins = append_bins(refbi_bins, futbi_bins, matchbins_bi)

			;print_minmax(fullerc_bins, "fullerc_bins")
			;print_minmax(fullbi_bins, "fullbi_bins")

			;print("dims fullerc_bins = " + dimsizes(fullerc_bins))
			;print("dims fullbi_bins = " + dimsizes(fullbi_bins))

			;assign bins based on combination ref and future bins
			erc_prime = assign_binning(futerc_1d, fullerc_bins)
			bi_prime = assign_binning(futbi_1d, fullbi_bins)

			;print_minmax(erc_prime, "erc_prime")
			;print_minmax(bi_prime, "bi_prime")

			referc_prime = assign_binning(referc_1d, referc_bins)
			refbi_prime = assign_binning(refbi_1d, refbi_bins)

			;print_minmax(referc_prime, "referc_prime")
			;print_minmax(refbi_prime, "refbi_prime")
			;-------------------------------------
			; multiply erc, bi
			;-------------------------------------

			futp = erc_prime * bi_prime
			refp = referc_prime * refbi_prime

                        refp = add_jitter_uniform(refp) ;add some noise to the data to prevent large numbers of exactly the same value
                        futp = add_jitter_uniform(futp)

			;print_minmax(futp, "futp")
			;print_minmax(refp, "refp")
			
			;-------------------------------------
			;normalize product
			;-------------------------------------
			;make bins 0-100
			futp_bins = calc_percentile_cutoffs(futp)
			refp_bins = calc_percentile_cutoffs(refp)

			;print_minmax(futp_bins, "futp_bins")
			;print_minmax(refp_bins, "refp_bins")

			;find closest match bins at the top
			matchbins_p = identify_closest_bin(refp_bins, futp_bins)

			;combine reference and future bins
			fullp_bins = append_bins(refp_bins, futp_bins, matchbins_p)

			;print_minmax(fullp_bins, "fullp_bins")
			;print("dims fullp_bins = " + dimsizes(fullp_bins))

			;assign bins based on combination bins
			p_prime_1D = assign_binning(futp, fullp_bins)

			;print_minmax(p_prime_1D, "p_prime_1D")

			p_prime(:, j, i) = (/p_prime_1D/)

			/;
			if(i .eq. 1 .and. j .eq. 7) then
			if(i .eq. 48 .and. j .eq. 98) then
				ttime = 747
				print("*******************************************")
				print(" ")
				print("bi pctl " + fullbi_bins)
				print(" ")
				print("erc pctl " + fullerc_bins)
				print(" ")
				print("p pctl " + fullp_bins)
				print(" ")
				print("bi_value = " + futbi_1d(ttime))
				print("erc_value = " + futerc_1d(ttime))
				print("bi prime = " + bi_prime(ttime))
				print("erc prime = " + erc_prime(ttime))
				print("p value = " + futp(ttime))
				print("p prime 1D = " + p_prime_1D(ttime))
			end if
			;/	

			delete(fullerc_bins)
			delete(fullbi_bins)
			delete(fullp_bins)
		end if
	end do 
end do

delete_VarAtts(p_prime, -1) ;get rid of superfluous attributes

p_prime@long_name = "Severe Fire Danger Index"   ; No convention for long names, just make it descriptive
p_prime@standard_name = "nfdrs_severe_fire_danger_index"

varatts = (/"units", "missing_value", "_FillValue"/)

p_prime@$varatts(0)$ = "1"

do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from erc data
   p_prime@$varatts(i)$ = futerc@$varatts(i)$
end do

return(p_prime)

end
