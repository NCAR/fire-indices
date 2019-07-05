/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 This procedure adjusts the observed temperature and humidity at weather stations to reflect the conditions at the fuel-atmosphere interface
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

