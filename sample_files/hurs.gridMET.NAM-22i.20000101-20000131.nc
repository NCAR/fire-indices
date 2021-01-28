CDF      
      time       lat       lon       bnds            author        =John Abatzoglou - University of Idaho, jabatzoglou@uidaho.edu      creation_date         09 March 2016      Conventions       CF-1.6     title         +gridMET gridded surface meteorological data    institution       University of Idaho    contact       'John Abatzoglou, jabatzoglou@uidaho.edu    URL       *http://www.climatologylab.org/gridmet.html     
references        �Abatzoglou, J.T., 2012, Development of gridded surface meteorological data for ecological applications and modeling, International Journal of Climatology, DOI: 10.1002/joc.3413   source       gridMET combines data from PRISM and NLDAS-2 according to the method of Abatzoglou 2012; PRISM v.LT71m: PRISM Climate Group, Oregon State University, http://prism.oregonstate.edu; NLDAS-2 v.s4pa: NASA ESD, Goddard Earth Sciences, http://ldas.gsfc.nasa.gov/nldas/     acknowledgements      1CF compliance by Seth McGinnis, mcginnis@ucar.edu      uuid      $5b9a93ba-35a6-46ad-9fa4-e9c2c7d8832d   history      �Sun Jan 24 14:48:57 2021: ncks -d time,0,30 -d lon,207,209 -d lat,103,104 hurs.gridMET.NAM-22i.2000-2001.nc hurs.gridMET.NAM-22i.20000101-20000130.nc
Thu Jan 21 16:15:11 2021: ncks -d time,2000-01-01 00:00:00,2001-12-31 23:59:59 /glade/scratch/kessenic/gridMET/hurs.gridMET.NAM-22i.nc /glade/scratch/kessenic/gridMET/hurs.gridMET.NAM-22i.2000-2001.nc
###################################
History of parent file /glade/p/cisl/risc/narccap/obs/gridMET/common/huss.gridMET.NAM-22i.nc:
Fri Aug 30 15:02:03 2019: ncrcat -n 38,4,1 huss.22i.1979.nc common/huss.gridMET.NAM-22i.nc
Fri Aug 30 14:21:51 MDT 2019: ncl coarsen.ncl datafile=huss.1979.nc gridfile=grid/grid.NAM-22i.nc outfile=regrid/huss.22i.1979.nc
Wed Aug 28 18:43:02 MDT 2019: updated for CF-compliance
-------------------------
History of parent file /glade/scratch/kessenic/gridMET/ps.gridMET.NAM-22i.nc:
ncl ~kessenic/scripts/calc_pressure.ncl tminfile=\"/glade/p/cisl/risc/narccap/obs/gridMET/common/tmin.gridMET.NAM-22i.nc\" tmaxfile=\"/glade/p/cisl/risc/narccap/obs/gridMET/common/tmax.gridMET.NAM-22i.nc\" orogfile=\"/glade/p/cisl/risc/narccap/obs/gridMET/orog/elevation.gridMET.NAM-22i.nc\" outfile=\"/glade/scratch/kessenic/gridMET/ps.gridMET.NAM-22i.nc\"
-------------------------
History of parent file /glade/scratch/kessenic/gridMET/tas.gridMET.NAM-22i.nc:
ncl ~kessenic/scripts/calc_tas.ncl tminfile=\"/glade/p/cisl/risc/narccap/obs/gridMET/common/tmin.gridMET.NAM-22i.nc\" tmaxfile=\"/glade/p/cisl/risc/narccap/obs/gridMET/common/tmax.gridMET.NAM-22i.nc\" tasfile=\"/glade/scratch/kessenic/gridMET/tas.gridMET.NAM-22i.nc\"
#########################
Created Thu Jan 21 14:34:14 MST 2021 by kessenic@casper07 using NCL script calc_humid.ncl from parent files listed above.
      tracking_id       $bb71cb45-15a1-423e-ba71-66b5daf56d18   NCO       `netCDF Operators version 4.9.5 (Homepage = http://nco.sf.net, Code = http://github.com/nco/nco)    nco_openmp_thread_number               	   crs              grid_mapping_name         latitude_longitude     longitude_of_prime_meridian                  semi_major_axis       AXT�@      inverse_flattening        @r��tm�   crs_wkt       GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]]   	long_name         WGS 84          �   data_status                 flag_meanings         permanent provisional early    flag_values                 �   hurs                      grid_mapping      crs    coordinates       �     missing_value         `�x�   standard_name         relative_humidity      	long_name         Relative Humidity      units         1      
_FillValue        `�x�        �   lat                units         degrees_north      	long_name         latitude   standard_name         latitude   bounds        lat_bnds        �   lat_bnds                         �   lon                units         degrees_east   	long_name         	longitude      standard_name         	longitude      bounds        lon_bnds        �   lon_bnds                         �   time                note      ?Days start/end at approximately midnight Mountain Standard Time    units         !days since 1900-01-01 00:00:00 -7      standard_name         time   	long_name         time   calendar      	gregorian      bounds        	time_bnds      axis      T              	time_bnds                                @B�     @C     B  B  B  B  �^     �]�     �]�     ��� ��  ��  �� �� ��     ?	�s?3�>�A�?�?�>�i�@�Ր    @�Հ    @�ՠ       ?�N?
&=>�F?�v? !{?�y@�հ    @�ՠ    @���       >��E>�:>ؿ
?��?��?�^@���    @���    @���       >���>Ȁ\>�">�Ĉ>�
;>Ծ_@���    @���    @��        >�,>�8�>s��>��/>���>�z#@��    @��     @��        >��>R�O><�>o̴>\f>K�@��0    @��     @��@       >��>{Z>�V>�8 >��:>���@��P    @��@    @��`       >���>�K>���>�$�>��>�'�@��p    @��`    @�ր       >�0�>�Fd>���>���>�Av>�]�@�֐    @�ր    @�֠       ?F*?E?d�?/�?)� ?s�@�ְ    @�֠    @���       ?DCm?=�?G?S�`?Hq�?5m�@���    @���    @���       ?)��?'(?�.??��?>b�?,i�@���    @���    @��        ?��?�h>�2?"_?�;?�@��    @��     @��        >�j>���>�W?A?�? c}@��0    @��     @��@       ?5�d?)��?`�?>��?7�1?+�@��P    @��@    @��`       ?7S3?83?[V?G��?@a?5ɯ@��p    @��`    @�׀       ?D��?E�?!�
?XJ�?U�?E5@�א    @�׀    @�נ       ?E� ?E��?% �?T'?L�(??O}@�װ    @�נ    @���       ?.�?,=�?C?:o_?/�a?!�@���    @���    @���       ?97�?3̔?�?F��?:`?)�C@���    @���    @��        ?.?-1,?K?B\?<-?-�@��    @��     @��        ?��?�|>���?*#�?"[_?�M@��0    @��     @��@       ?G#�?H=.?,
`?[�O?QĄ?C�T@��P    @��@    @��`       ?I��?E�C?$!i?U4�?H��?<��@��p    @��`    @�؀       ?J�
?J��?'=c?[S?R�?D2Z@�ؐ    @�؀    @�ؠ       ?&U�?Q�>�a?(�?l�? %@�ذ    @�ؠ    @���       ?F/>�|�>�P�>�k�>�/�>��;@���    @���    @���       >�q|>�uQ>x��>���>��>�F�@���    @���    @��        >��>�-�>�D>�l/>�x,>���@��    @��     @��        ?&�a?&��?Ra?9Nm?1?%�{@��0    @��     @��@       ?*�1?&Mn?��?;Q�?8xh?1��@��P    @��@    @��`    