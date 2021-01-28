CDF      
      time       lat       lon       bnds            author        =John Abatzoglou - University of Idaho, jabatzoglou@uidaho.edu      creation_date         02 December 2017   Conventions       CF-1.6     title         +gridMET gridded surface meteorological data    institution       University of Idaho    contact       'John Abatzoglou, jabatzoglou@uidaho.edu    URL       *http://www.climatologylab.org/gridmet.html     
references        �Abatzoglou, J.T., 2012, Development of gridded surface meteorological data for ecological applications and modeling, International Journal of Climatology, DOI: 10.1002/joc.3413   source       gridMET combines data from PRISM and NLDAS-2 according to the method of Abatzoglou 2012; PRISM v.LT71m: PRISM Climate Group, Oregon State University, http://prism.oregonstate.edu; NLDAS-2 v.s4pa: NASA ESD, Goddard Earth Sciences, http://ldas.gsfc.nasa.gov/nldas/     acknowledgements      1CF compliance by Seth McGinnis, mcginnis@ucar.edu      uuid      $06c71e71-1556-4cd1-9cda-cf75854dbcef   history      Wed Jan 27 17:52:37 2021: ncks -d time,0,30 -d lon,207,209 -d lat,103,104 fm100.gridMET.NAM-22i.2000-2001.nc fm100.gridMET.NAM-22i.20000101-20000131.nc
Mon Jan 25 15:50:58 2021: ncks -d time,2000-01-01 00:00:00,2001-12-31 23:59:59 /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.nc /glade/scratch/kessenic/gridMET/inputs/fm100.gridMET.NAM-22i.2000-2001.nc
Mon Jan 25 15:31:57 2021: ncrcat /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1979.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1980.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1981.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1982.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1983.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1984.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1985.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1986.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1987.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1988.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1989.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1990.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1991.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1992.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1993.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1994.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1995.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1996.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1997.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1998.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1999.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2000.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2001.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2002.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2003.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2004.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2005.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2006.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2007.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2008.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2009.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2010.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2011.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2012.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2013.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2014.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2015.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.2016.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.nc
Mon Jan 25 15:27:11 2021: ncks -d time,1979-01-01 00:00:00,1979-12-31 23:59:59 /glade/scratch/kessenic/gridMET/spinup/fm100.gridMET.NAM-22i.1979-1980.spinup.nc /glade/scratch/kessenic/gridMET/fire/fm100.gridMET.NAM-22i.1979.nc
Created Fri Jan 22 11:28:31 MST 2021 by kessenic@casper10 using NCL scripts calc_emc.ncl, calc_julian_day.ncl, calc_daylight_builtin.ncl, calc_daylight_manual.ncl, calc_pduration.ncl, calc_fm100.ncl, and fm100_main.ncl, from source files /glade/scratch/kessenic/gridMET/inputs/prec.gridMET.NAM-22i.1979-1980.nc, /glade/scratch/kessenic/gridMET/inputs/tmax.gridMET.NAM-22i.1979-1980.nc, /glade/scratch/kessenic/gridMET/inputs/tmin.gridMET.NAM-22i.1979-1980.nc, /glade/scratch/kessenic/gridMET/inputs/rhmin.gridMET.NAM-22i.1979-1980.nc, /glade/scratch/kessenic/gridMET/inputs/rhmax.gridMET.NAM-22i.1979-1980.nc    tracking_id       $0c75931b-9985-4200-ab4a-bb26b666b238   NCO       `netCDF Operators version 4.9.5 (Homepage = http://nco.sf.net, Code = http://github.com/nco/nco)    nco_openmp_thread_number               	   crs              grid_mapping_name         latitude_longitude     longitude_of_prime_meridian                  semi_major_axis       AXT�@      inverse_flattening        @r��tm�   crs_wkt       GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]]   	long_name         WGS 84             data_status                 flag_meanings         permanent provisional early    flag_values            cell_methods      
time: mean          p   fm100                         	long_name         +Percent Moisture Content for 100-hr timelag    units         %      missing_value         �<    
_FillValue        �<    cell_methods      
time: mean          t   lat                units         degrees_north      	long_name         latitude   standard_name         latitude   bounds        lat_bnds            lat_bnds                         0   lon                units         degrees_east   	long_name         	longitude      standard_name         	longitude      bounds        lon_bnds        @   lon_bnds                         X   time                note      ?Days start/end at approximately midnight Mountain Standard Time    units         !days since 1900-01-01 00:00:00 -7      standard_name         time   	long_name         time   calendar      	gregorian      bounds        	time_bnds      axis      T      cell_methods      
time: mean          �   	time_bnds                      cell_methods      
time: mean          �   @B�     @C     B  B  B  B  �^     �]�     �]�     ��� ��  ��  �� �� ��      A<Q�A,W�A��A9��A4�A(R@�Ր    @�Հ    @�ՠ        AM>AAbA'OvAV�Aa�A^,�@�հ    @�ՠ    @���        AF��A?��A*	CA^��Az�AuE4@���    @���    @���        A6PtA0�{A/�cAO��Ae��A]Rc@���    @���    @��         A+�AEfA� A4��AA+UA;�O@��    @��     @��         A�A�qA��A��A"�{A��@��0    @��     @��@        A
��@�[DA/0AF�A�uAտ@��P    @��@    @��`        A�A@���@�9A˘A��A6X@��p    @��`    @�ր        A^@�ZA %iA�]AjA(p@�֐    @�ր    @�֠        A3�hA"l�A�rA?ĂAC~�A9��@�ְ    @�֠    @���        A�"�Ax��AdA�H*A�6A���@���    @���    @���        A�QAA�&�An�A��MA� HA��^@���    @���    @��         A}�cAq�gA\��A�ѝA��A�[�@��    @��     @��         Aa�zA\�0AJUbA��1A��A�l6@��0    @��     @��@        A�vA�n�A���A���A��A�b\@��P    @��@    @��`        A��A��%A�'vA�e�A�pA���@��p    @��`    @�׀        A���A���A���A���A�PA���@�א    @�׀    @�נ        A�?BA���A��BA�,}A�B-A�0@�װ    @�נ    @���        A��EA�0A��NAȰ�A��A�f@���    @���    @���        A��nA��A�[�AяA�P�AĻ@���    @���    @��         A�-�A���A�H�A���AȌ�A��i@��    @��     @��         A�}
A�w3A��mA�j�A�*�A��,@��0    @��     @��@        A��A�9pA�QA�иA���A��@��P    @��@    @��`        A���A��A���AѬ�A��A�H@��p    @��`    @�؀        A��A�qA���A٘A�G�A�@�ؐ    @�؀    @�ؠ        A��A�6jA��Aȿ(A�I�A�9�@�ذ    @�ؠ    @���        A���A��3A�!�A�&�A�aHA���@���    @���    @���        A�lAs��Au6�A��xA�@.AE�@���    @���    @��         Ac��AMVmAPl"Aj~RA`¶AYDn@��    @��     @��         A���A�vVA�NGA�7�A� �A��e@��0    @��     @��@        A���A���A�g�A���A��A��@��P    @��@    @��`    