;+
; NAME: noah2clm
;
; PURPOSE:  Convert a noah controlfiles directory into a set of clm netCDF files
;
; CATEGORY:             noah clm conversion
;
; CALLING SEQUENCE:     noah2clm, weatherfile
;
; INPUTS:               inputdir = directory containing noah input files
;                       outputdir= directory to place clm input files
;                                  ideally in subdirectories weather/,
;                                  initial/, srfdata/, and pftdata/
;                       if neither are included ./ is used for both
;
; OPTIONAL INPUTS:      <none>
;
; KEYWORD PARAMETERS:   <none>
;
; OUTPUTS:              clm netcdf files
;                            weather/yyyy-mm.nc
;                            srfdata/location_srf.nc
;                       clm text input file
;                            location.stdin
;
; OPTIONAL OUTPUTS:     <none>
;
; COMMON BLOCKS:        <none>
;
; SIDE EFFECTS:         <none>
;
; RESTRICTIONS:         Assumes the names of Noah Input files from the IHOP version of noah
;                         IHOPUDS1, IHOPluse, IHOPstyp, SOILPARM.TBL, VEGPARM.TBL,
;                         GENPARM.TBL, IHOPelev, IHOPposn, IHOPsoil
;
; WARNING :             Currently forces solar radiation to be greater than or equal to 0 
;
; PROCEDURE:    Read IHOP input files and parse them into structures.
;               Convert IHOPUDS1 weather file to a series of date.nc
;               clm weather files : read weather file, convert units, write netcdf file
;               write location_srf.nc and location.stdin files
;
;
; EXAMPLE: noah2clm, 'noah/ControlFiles/', 'clm/inputdata/sevilleta/', location="sevilleta"
;
; MODIFICATION HISTORY:
;           january 2005? - edg - original - only did weather file
;           11-04-2005    - edg - FINALLY added location.stdin and location_srf.nc files
;
;-

PRO make_inputfile, inputfilename, pos, basic, files, location, nsteps, test=test

  nsteps=strcompress(long(nsteps), /remove_all)
;  nsteps=strcompress(long(basic.ndays*(24.0*60.0*60.0)/basic.dt))
;  nmonths=fix(basic.ndays/30)

  month=strcompress(basic.start.month, /remove_all)
  IF basic.start.month LT 10 THEN month='0'+month
  day=strcompress(basic.start.day, /remove_all)
  IF basic.start.day LT 10 THEN day='0'+day
  start_ymd=strcompress(basic.start.year, /remove_all)+month+day

;; to simplify testing
  IF keyword_set(test) THEN $
    nsteps='200'

  openw, oun, /get, inputfilename
  printf, oun, ' &clmexp'
  printf, oun, ' caseid         = ''clm3run_'+location+''' '
  printf, oun, ' ctitle         = ''clm3run_'+location+''' '
  printf, oun, ' offline_atmdir = '''+files.weatherdir+'/'''
  printf, oun, ' finidat        = '''' '
  printf, oun, ' fsurdat        = '''+files.surfacefile+''''
  printf, oun, ' fpftcon        = '''+files.pftfile+''''
  printf, oun, ' frivinp_rtm    = '''+files.rtmfile+''''
  printf, oun, ' nsrest         =  0' ; 0 for initial run, 1 for restart run
  printf, oun, ' nelapse        =  '+nsteps ; + for time steps, - for days
  printf, oun, ' dtime          =  '+strcompress(long(float(basic.dt))) ; model time step (seconds)
  printf, oun, ' start_ymd      =  '+start_ymd
  printf, oun, ' start_tod      =  0'       ; start time of day
  printf, oun, ' irad           =  -1'      ; frequency of solar rad calcs (+ for time steps - for hours)
  printf, oun, ' wrtdia         = .false.'  ; write global average 2m air T to standard out
  printf, oun, ' mss_irt        =  0'       ; use ncar Mass Storage System (retention period in days if >0)
  printf, oun, ' hist_dov2xy    = .true.'   ; spatial averaging flag
  printf, oun, ' hist_nhtfrq    =  10'      ; interval between history outputs (+ for time steps, - for hours)
  printf, oun, ' hist_mfilt     =  '+nsteps ; number of time steps to output
  printf, oun, ' hist_crtinic   = ''NONE''' ;frequency of initial dataset output
  printf, oun, ' mksrf_offline_edges = '+strcompress(pos.lat-0.01, /remove_all)
  printf, oun, ' mksrf_offline_edgen = '+strcompress(pos.lat+0.01, /remove_all)
  printf, oun, ' mksrf_offline_edgee = '+strcompress(pos.lon+0.01, /remove_all)
  printf, oun, ' mksrf_offline_edgew = '+strcompress(pos.lon-0.01, /remove_all)
  printf, oun, ' mksrf_all_pfts = .false.'
  printf, oun, ' /'
  close, oun
  free_lun, oun

END

PRO makeNCDF_surface, srf_file, pos, basic, veg, SHPs
;; create the NetCDF file (this is noclobber by default)
  fid=ncdf_create(srf_File, /clobber)

  IF basic.nsoil NE 10 THEN BEGIN
     FOR i=0,10-basic.nsoil-1 DO BEGIN
;        basic.zsoil=[basic.zsoil[0]/2, basic.zsoil]
     ENDFOR
     basic.nsoil=10
  ENDIF

        

;; define the dimensions
  sdim=ncdf_dimdef(fid, 'scalar', 1)
  lonDim=ncdf_dimdef(fid, 'lsmlon', 1)
  latDim=ncdf_dimdef(fid, 'lsmlat', 1)
  pftDim=ncdf_dimdef(fid, 'lsmpft', 4)
  nlevsoi=ncdf_dimdef(fid, 'nlevsoi', basic.nsoil)
  timeDim=ncdf_dimdef(fid, 'time', /unlimited) ; ??
  
;; define the necessary positionn variables
  numlon=ncdf_vardef(fid, 'NUMLON', [latDim], /short)
  ncdf_attput, fid, numlon, 'long_name', 'number of longitudes for each latitude'
  ncdf_attput, fid, numlon, 'units', 'unitless'

  EW=ncdf_vardef(fid, 'EDGEW', [sDim], /float)
  ncdf_attput, fid, EW, 'long_name','western edge in atmospheric data' 
  ncdf_attput, fid, EW, 'units', 'degrees E'
  ncdf_attput, fid, EW, 'mode', 'time-invariant'

  EE=ncdf_vardef(fid, 'EDGEE', [sDim], /float)
  ncdf_attput, fid, EE, 'long_name','eastern edge in atmospheric data' 
  ncdf_attput, fid, EE, 'units', 'degrees E'
  ncdf_attput, fid, EE, 'mode', 'time-invariant'

  ES=ncdf_vardef(fid, 'EDGES', [sDim], /float)
  ncdf_attput, fid, ES, 'long_name','southern edge in atmospheric data' 
  ncdf_attput, fid, ES, 'units', 'degrees N'
  ncdf_attput, fid, ES, 'mode', 'time-invariant'

  EN=ncdf_vardef(fid, 'EDGEN', [sDim], /float)
  ncdf_attput, fid, EN, 'long_name','northern edge in atmospheric data' 
  ncdf_attput, fid, EN, 'units', 'degrees N'
  ncdf_attput, fid, EN, 'mode', 'time-invariant'

  LON=ncdf_vardef(fid, 'LONGXY', [lonDim, latDim], /float)
  ncdf_attput, fid, LON, 'long_name','longitude'
  ncdf_attput, fid, LON, 'units', 'degrees E'
  ncdf_attput, fid, LON, 'mode', 'time-invariant'

  LAT=ncdf_vardef(fid, 'LATIXY', [lonDim, latDim], /float)
  ncdf_attput, fid, LAT, 'long_name','latitude'
  ncdf_attput, fid, LAT, 'units', 'degrees N'
  ncdf_attput, fid, LAT, 'mode', 'time-invariant'

  LANDMASK=ncdf_vardef(fid, 'LANDMASK',[lonDim, latDim],/short)                   ;
  ncdf_attput, fid, LANDMASK, 'long_name', 'land/ocean mask'               ;
  ncdf_attput, fid, LANDMASK, 'units', '0=ocean and 1=land'                ;
  LANDFRAC=ncdf_vardef(fid, 'LANDFRAC',[lonDim, latDim],/double)                ;
  ncdf_attput, fid, LANDFRAC, 'long_name', 'land fraction'                 ;
  ncdf_attput, fid, LANDFRAC, 'units', 'unitless'                          ;
  LANDFRAC_PFT=ncdf_vardef(fid, 'LANDFRAC_PFT', [lonDim, latDim],/double)            ;
  ncdf_attput, fid, LANDFRAC_PFT, 'long_name', 'land fraction from pft dataset' ;
  ncdf_attput, fid, LANDFRAC_PFT, 'units', 'unitless'                           ;
  SOIL_COLOR=ncdf_vardef(fid, 'SOIL_COLOR', [lonDim, latDim],/short)                   ;
  ncdf_attput, fid, SOIL_COLOR, 'long_name', 'soil color'                       ;
  ncdf_attput, fid, SOIL_COLOR, 'units', 'unitless'                             ;
  PCT_SAND=ncdf_vardef(fid, 'PCT_SAND', [lonDim, latDim, nlevsoi],/float)            ;
  ncdf_attput, fid, PCT_SAND, 'long_name', 'percent sand'                       ;
  ncdf_attput, fid, PCT_SAND, 'units', 'unitless'                               ;
  PCT_CLAY=ncdf_vardef(fid, 'PCT_CLAY', [lonDim, latDim, nlevsoi],/float)            ;
  ncdf_attput, fid, PCT_CLAY, 'long_name', 'percent clay'                       ;
  ncdf_attput, fid, PCT_CLAY, 'units', 'unitless'                               ;
  SUC_SAT=ncdf_vardef(fid, 'SUC_SAT', [lonDim, latDim, nlevsoi],/float)              ;
  ncdf_attput, fid, SUC_SAT, 'long_name', 'saturated suction potential'         ;
  ncdf_attput, fid, SUC_SAT, 'units', 'mm'                                      ;
  HK_SAT=ncdf_vardef(fid, 'HK_SAT', [lonDim, latDim, nlevsoi],/float)                ;
  ncdf_attput, fid, HK_SAT, 'long_name', 'saturated hydraulic conductivity'     ;
  ncdf_attput, fid, HK_SAT, 'units', 'mm/s'                                     ;
  VG_N=ncdf_vardef(fid, 'VG_N', [lonDim, latDim, nlevsoi],/float)                    ;
  ncdf_attput, fid, VG_N, 'long_name', 'van Genuchten n parameter'              ;
  ncdf_attput, fid, VG_N, 'units', 'unitless'                                   ;
  VG_ALPHA=ncdf_vardef(fid, 'VG_ALPHA', [lonDim, latDim, nlevsoi],/float)            ;
  ncdf_attput, fid, VG_ALPHA, 'long_name', 'van Genuchten alpha parameter'      ;
  ncdf_attput, fid, VG_ALPHA, 'units', '1/mm'                                   ;
  WAT_DRY=ncdf_vardef(fid, 'WAT_DRY', [lonDim, latDim, nlevsoi],/float)              ;
  ncdf_attput, fid, WAT_DRY, 'long_name', 'residual water content'              ;
  ncdf_attput, fid, WAT_DRY, 'units', 'm^3/m^3 (porosity)'                      ;
  WAT_SAT=ncdf_vardef(fid, 'WAT_SAT', [lonDim, latDim, nlevsoi],/float)              ;
  ncdf_attput, fid, WAT_SAT, 'long_name', 'saturated water content'             ;
  ncdf_attput, fid, WAT_SAT, 'units', 'm^3/m^3 (porosity)'                      ;
  PCT_WETLAND=ncdf_vardef(fid, 'PCT_WETLAND', [lonDim, lonDim],/float)               ;
  ncdf_attput, fid, PCT_WETLAND, 'long_name', 'percent wetland'                 ;
  ncdf_attput, fid, PCT_WETLAND, 'units', 'unitless'                            ;
  PCT_LAKE=ncdf_vardef(fid, 'PCT_LAKE', [lonDim, lonDim],/float)                     ;
  ncdf_attput, fid, PCT_LAKE, 'long_name', 'percent lake'                       ;
  ncdf_attput, fid, PCT_LAKE, 'units', 'unitless'                               ;
  PCT_GLACIER=ncdf_vardef(fid, 'PCT_GLACIER', [lonDim, lonDim],/float)               ;
  ncdf_attput, fid, PCT_GLACIER, 'long_name', 'percent glacier'                 ;
  ncdf_attput, fid, PCT_GLACIER, 'units', 'unitless'                            ;
  PCT_URBAN=ncdf_vardef(fid, 'PCT_URBAN',[lonDim, lonDim],/float)                    ;
  ncdf_attput, fid, PCT_URBAN, 'long_name', 'percent urban'                     ;
  ncdf_attput, fid, PCT_URBAN, 'units', 'unitless'                              ;
  PFT=ncdf_vardef(fid, 'PFT', [lonDim, latDim, pftDim],/short)                         ;
  ncdf_attput, fid, PFT, 'long_name', 'plant functional type'                   ;
  ncdf_attput, fid, PFT, 'units', 'unitless'                                    ;
  PCT_PFT=ncdf_vardef(fid, 'PCT_PFT', [lonDim, latDim, pftDim],/float)               ;
  ncdf_attput, fid, PCT_PFT, 'long_name', 'percent plant functional type'       ;
  ncdf_attput, fid, PCT_PFT, 'units', 'unitless'                                ;
  MONTHLY_LAI=ncdf_vardef(fid, 'MONTHLY_LAI', [lonDim, latDim, pftDim, timeDim],/float) ;
  ncdf_attput, fid, MONTHLY_LAI, 'long_name', 'monthly leaf area index'         ;
  ncdf_attput, fid, MONTHLY_LAI, 'units', 'unitless'                            ;
  MONTHLY_SAI=ncdf_vardef(fid, 'MONTHLY_SAI', [lonDim, latDim, pftDim, timeDim],/float) ;
  ncdf_attput, fid, MONTHLY_SAI, 'long_name', 'monthly stem area index'         ;
  ncdf_attput, fid, MONTHLY_SAI, 'units', 'unitless'                            ;
  MONTHLY_HEIGHT_TOP=ncdf_vardef(fid, 'MONTHLY_HEIGHT_TOP', [lonDim, latDim, pftDim, timeDim],/float) ;
  ncdf_attput, fid, MONTHLY_HEIGHT_TOP, 'long_name', 'monthly height top'                     ;
  ncdf_attput, fid, MONTHLY_HEIGHT_TOP, 'units', 'meters'                                     ;
  MONTHLY_HEIGHT_BOT=ncdf_vardef(fid, 'MONTHLY_HEIGHT_BOT', [lonDim, latDim, pftDim, timeDim],/float) ;
  ncdf_attput, fid, MONTHLY_HEIGHT_BOT, 'long_name', 'monthly height bottom'                  ;
  ncdf_attput, fid, MONTHLY_HEIGHT_BOT, 'units', 'meters'                                     ;
  
  ;; put the file into 'data' mode
  NCDF_CONTROL, fid, /endef

  IF n_elements(pos) EQ 0 THEN pos={position, lat:34.3586, lon:-106.6911, elev:5000}
  ncdf_varput, fid, numlon, 1
  ncdf_varput, fid, EW, pos.lon-0.01
  ncdf_varput, fid, EE, pos.lon+0.01
  ncdf_varput, fid, ES, pos.lat-0.01
  ncdf_varput, fid, EN, pos.lat+0.01
  ncdf_varput, fid, LON, pos.lon
  ncdf_varput, fid, LAT, pos.lat

;; MAKE NECESSARY UNIT CONVERSIONS
;;
;; this relies on the conversion in Morel-Seytoux (1995?) converting VG->BC
  p=3+2.0*(1.0/(shps.vgn-1.0))
  ;; convert alpha from 1/m to 1/mm?
  CLM_ALPHA=shps.alpha/1000
  SATPSI = (1.0/(CLM_ALPHA)) * (p+3)/(2*p*(p-1)) * (147.8+8.1*p + 0.092*(p^2))/(55.6+7.4*p + p^2)

  ;; convert ks m/s mm/s
  shps.ks*=1000

;; convert fg to LAI
  LAI=(-1.0)*alog(1.0-veg.fg + veg.fg*exp(-1*veg.LAI)) ; this sets clm direct beam transmission through the canopy
                                ; to be approximately 1-fg the transmision it would calculate if it made
                                ; separate calculations based on fg and LAI

; clm
; bare soil = 0, c3 grass = 13, c4 grass = 14, corn = 15, wheat = 16
; noah
; bare soil = 28, grass = 7, crop(dry) = 2, crop (irrigated)=3, crop/grass=5
;           1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28
  thisPFT=([0,15,15,15,16,16,14,10,14,14, 7, 3, 5, 1, 5, 0, 4, 4, 0,11, 2,11, 0, 0, 0, 0, 0, 0])[veg.vegtype-1] ;this is how we should be picking our PFT
  IF thisPFT EQ 0 THEN BEGIN 
     LAI=0
  ENDIF 

;  thisPFT=14

;  LANDMASK=ncdf_vardef(fid, 'LANDMASK',[lonDim, latDim],/int)                   ;
  ncdf_varput, fid, LANDMASK, 1
;  LANDFRAC=ncdf_vardef(fid, 'LANDFRAC',[lonDim, latDim],/double)                ;
  ncdf_varput, fid, LANDFRAC, 1
;  LANDFRAC_PFT=ncdf_vardef(fid, 'LANDFRAC_PFT', [lonDim, latDim],/double)            ;
  ncdf_varput, fid, LANDFRAC_PFT, 1
;  SOIL_COLOR=ncdf_vardef(fid, 'SOIL_COLOR', [lonDim, latDim],/int)                   ;
  ncdf_varput, fid, SOIL_COLOR, 4
;  PCT_SAND=ncdf_vardef(fid, 'PCT_SAND', [nlevsoi, lonDim, latDim],/float)            ;
  ncdf_varput, fid, PCT_SAND, reform(replicate(65, basic.nsoil), 1, 1, basic.nsoil)
;  PCT_CLAY=ncdf_vardef(fid, 'PCT_CLAY', [nlevsoi, lonDim, latDim],/float)            ;
  ncdf_varput, fid, PCT_CLAY, reform(replicate(10, basic.nsoil), 1, 1, basic.nsoil)
;  SUC_SAT=ncdf_vardef(fid, 'SUC_SAT', [nlevsoi, lonDim, latDim],/float)              ;
  ncdf_varput, fid, SUC_SAT, reform(replicate(SATPSI, basic.nsoil), 1, 1, basic.nsoil)
;  HK_SAT=ncdf_vardef(fid, 'HK_SAT', [nlevsoi, lonDim, latDim],/float)                ;
  ncdf_varput, fid, HK_SAT, reform(replicate(shps.ks, basic.nsoil), 1, 1, basic.nsoil)
;  VG_N=ncdf_vardef(fid, 'VG_N', [nlevsoi, lonDim, latDim],/float)                    ;
  ncdf_varput, fid, VG_N, reform(replicate(shps.vgn, basic.nsoil), 1, 1, basic.nsoil)
;  VG_ALPHA=ncdf_vardef(fid, 'VG_ALPHA', [nlevsoi, lonDim, latDim],/float)            ;
  ncdf_varput, fid, VG_ALPHA, reform(replicate(CLM_ALPHA, basic.nsoil), 1, 1, basic.nsoil)
;  WAT_DRY=ncdf_vardef(fid, 'WAT_DRY', [nlevsoi, lonDim, latDim],/float)              ;
  ncdf_varput, fid, WAT_DRY, reform(replicate(shps.smcdry, basic.nsoil), 1, 1, basic.nsoil)
;  WAT_SAT=ncdf_vardef(fid, 'WAT_SAT', [nlevsoi, lonDim, latDim],/float)              ;
  ncdf_varput, fid, WAT_SAT, reform(replicate(shps.smcsat, basic.nsoil), 1, 1, basic.nsoil)
;  PCT_WETLAND=ncdf_vardef(fid, 'PCT_WETLAND', [lonDim, latDim],/float)               ;
  ncdf_varput, fid, PCT_WETLAND, 0
;  PCT_LAKE=ncdf_vardef(fid, 'PCT_LAKE', [lonDim, latDim],/float)                     ;
  ncdf_varput, fid, PCT_LAKE, 0
;  PCT_GLACIER=ncdf_vardef(fid, 'PCT_GLACIER', [lonDim, latDim],/float)               ;
  ncdf_varput, fid, PCT_GLACIER, 0
;  PCT_URBAN=ncdf_vardef(fid, 'PCT_URBAN',[lonDim, latDim],/float)                    ;
  ncdf_varput, fid, PCT_URBAN, 0
;  PFT=ncdf_vardef(fid, 'PFT', [pftDim, lonDim, latDim],/int)                         ;
  ncdf_varput, fid, PFT, reform([thisPFT, 0, 0, 0], 1, 1, 4)
;  PCT_PFT=ncdf_vardef(fid, 'PCT_PFT', [pftDim, lonDim, latDim],/float)               ;
  ncdf_varput, fid, PCT_PFT, reform([100, 0, 0,0], 1, 1, 4)
;  MONTHLY_LAI=ncdf_vardef(fid, 'MONTHLY_LAI', [timeDim, pftDim, lonDim, latDim],/float) ;
  ncdf_varput, fid, MONTHLY_LAI, reform(replicate(LAI, 12*4), 1, 1, 4, 12)
;  ncdf_varput, fid, MONTHLY_LAI, reform(replicate(LAI, 12*4), 1, 1, 4, 12)
;  MONTHLY_SAI=ncdf_vardef(fid, 'MONTHLY_SAI', [timeDim, pftDim, lonDim, latDim],/float) ;
  ncdf_varput, fid, MONTHLY_SAI, reform(replicate(0.0, 12*4), 1,1, 4, 12)
;  MONTHLY_HEIGHT_TOP=ncdf_vardef(fid, 'MONTHLY_HEIGHT_TOP', [timeDim, pftDim, lonDim, latDim],/float) ;
  ncdf_varput, fid, MONTHLY_HEIGHT_TOP, reform(replicate(0.5, 12*4), 1, 1, 4, 12) ;default grass top (meters)
;  MONTHLY_HEIGHT_BOT=ncdf_vardef(fid, 'MONTHLY_HEIGHT_BOT', [timeDim, pftDim, lonDim, latDim],/float) ;
  ncdf_varput, fid, MONTHLY_HEIGHT_BOT, reform(replicate(0.01, 12*4), 1, 1, 4, 12) ;default grass bottom (meters)

  ncdf_close, fid
END

;; write a netCDF weather file YYYY-mm.nc
PRO makeNCDF_weather, clmFile, data, ntimeSteps, dt, pos=pos
;; create the NetCDF file (this is noclobber by default)
  fid=ncdf_create(clmFile, /clobber)

;; define the dimensions
  sdim=ncdf_dimdef(fid, 'scalar', 1)
  lonDim=ncdf_dimdef(fid, 'lon', 1)
  latDim=ncdf_dimdef(fid, 'lat', 1)
  timeDim=ncdf_dimdef(fid, 'time', ntimeSteps) ; /unlimited) ; ??
  
;; define the necessary positionn variables
  EW=ncdf_vardef(fid, 'EDGEW', [sDim], /float)
  ncdf_attput, fid, EW, 'long_name','western edge in atmospheric data' 
  ncdf_attput, fid, EW, 'units', 'degrees E'
  ncdf_attput, fid, EW, 'mode', 'time-invariant'

  EE=ncdf_vardef(fid, 'EDGEE', [sDim], /float)
  ncdf_attput, fid, EE, 'long_name','eastern edge in atmospheric data' 
  ncdf_attput, fid, EE, 'units', 'degrees E'
  ncdf_attput, fid, EE, 'mode', 'time-invariant'

  ES=ncdf_vardef(fid, 'EDGES', [sDim], /float)
  ncdf_attput, fid, ES, 'long_name','southern edge in atmospheric data' 
  ncdf_attput, fid, ES, 'units', 'degrees N'
  ncdf_attput, fid, ES, 'mode', 'time-invariant'

  EN=ncdf_vardef(fid, 'EDGEN', [sDim], /float)
  ncdf_attput, fid, EN, 'long_name','northern edge in atmospheric data' 
  ncdf_attput, fid, EN, 'units', 'degrees N'
  ncdf_attput, fid, EN, 'mode', 'time-invariant'

  LON=ncdf_vardef(fid, 'LONGXY', [latDim, lonDim], /float)
  ncdf_attput, fid, LON, 'long_name','longitude'
  ncdf_attput, fid, LON, 'units', 'degrees E'
  ncdf_attput, fid, LON, 'mode', 'time-invariant'

  LAT=ncdf_vardef(fid, 'LATIXY', [latDim, lonDim], /float)
  ncdf_attput, fid, LAT, 'long_name','latitude'
  ncdf_attput, fid, LAT, 'units', 'degrees N'
  ncdf_attput, fid, LAT, 'mode', 'time-invariant'


;; define the atmospheric forcing variables
  ;; Air Temperature
  T=ncdf_vardef(fid, 'TBOT', [latDim, lonDim, timeDim], /float)
  ncdf_attput, fid, T, 'long_name', 'temperature at the lowest atm level (TBOT)'
  ncdf_attput, fid, T, 'units', 'K'
  ncdf_attput, fid, T, 'mode', 'time-dependent'

  ;; Wind Speed
  wind=ncdf_vardef(fid, 'WIND', [latDim, lonDim, timeDim], /float)
  ncdf_attput, fid, wind, 'long_name', 'wind at the lowest atm level (WIND)'
  ncdf_attput, fid, wind, 'units', 'm/s'
  ncdf_attput, fid, wind, 'mode', 'time-dependent'

  ;; Specific Humidity
  q=ncdf_vardef(fid, 'QBOT', [latDim, lonDim, timeDim], /float)
  ncdf_attput, fid, q, 'long_name', 'specific humidity at the lowest atm level (QBOT)'
  ncdf_attput, fid, q, 'units', 'kg/kg'
  ncdf_attput, fid, q, 'mode', 'time-dependent'

  ;; Precipiation
  prec=ncdf_vardef(fid, 'PRECTmms', [latDim, lonDim, timeDim], /float)
  ncdf_attput, fid, prec, 'long_name','precipitation (PRECT)' 
  ncdf_attput, fid, prec, 'units', 'mm/s'
  ncdf_attput, fid, prec, 'mode', 'time-dependent'

  ;; Short wave radiation
  sun=ncdf_vardef(fid, 'FSDS', [latDim, lonDim, timeDim], /float)
  ncdf_attput, fid, sun, 'long_name', 'incident solar (FSDS)'
  ncdf_attput, fid, sun, 'units', 'W/m2'
  ncdf_attput, fid, sun, 'mode', 'time-dependent'

  ;; Air Pressure
  pres=ncdf_vardef(fid, 'PSRF', [latDim, lonDim, timeDim], /float)
  ncdf_attput, fid, pres, 'long_name','surface pressure at the lowest atm level (PSRF)' 
  ncdf_attput, fid, pres, 'units', 'Pa'
  ncdf_attput, fid, pres, 'mode', 'time-dependent'

;; put the file into 'data' mode
  NCDF_CONTROL, fid, /endef

  IF NOT keyword_set(pos) THEN pos={position, lat:34.3586, lon:-106.6911, elev:5000}
  ncdf_varput, fid, EW, pos.lon-0.01
  ncdf_varput, fid, EE, pos.lon+0.01
  ncdf_varput, fid, ES, pos.lat-0.01
  ncdf_varput, fid, EN, pos.lat+0.01
  ncdf_varput, fid, LON, pos.lon
  ncdf_varput, fid, LAT, pos.lat

  ;; convert C to K
  ncdf_varput, fid, T, reform(data[6,0:ntimesteps-1]+273.15, 1,1,ntimesteps)
  ;; no conversion necessary
  ncdf_varput, fid, wind, reform(data[5,0:ntimesteps-1], 1, 1, ntimesteps)
  ;; convert MR(g/kg dry air) to q(kg/kg moist air)
  ncdf_varput, fid, q, reform(data[7,0:ntimesteps-1]/(1000+data[6,0:ntimesteps-1]), 1, 1, ntimesteps)
  ;; convert mm to mm/s
  ncdf_varput, fid, prec, reform(data[10,0:ntimesteps-1]/dt, 1, 1, ntimesteps)
  ;; no conversion necessary
  ncdf_varput, fid, sun, reform(data[8,0:ntimesteps-1], 1, 1, ntimesteps)>0
  ;; convert millibars to Pascals
  ncdf_varput, fid, pres, reform(data[4,0:ntimesteps-1]*100, 1, 1, ntimesteps)


  ncdf_close, fid
end



;; read the GENPARM.TBL file for slope and other data that we will probably ignore
FUNCTION read_GenData, genfile
  IF n_elements(genfile) EQ 0 THEN genfile='GENPARM.TBL'

  line=''
  openr, un, /get, genfile
  FOR i=0,2 DO readf, un, line
  slopedata=fltarr(fix(line))
  FOR i=0, n_elements(slopedata)-1 DO BEGIN
     readf, un, line
     slopedata[i]=float(line)
  endFOR
  readf, un, line & readf, un, line
  sbeta=float(line)
  readf, un, line & readf, un, line
  fxexp=float(line)
  readf, un, line & readf, un, line
  csoil=float(line)
  readf, un, line & readf, un, line
  salp=float(line)
  readf, un, line & readf, un, line
  refdk=float(line)
  readf, un, line & readf, un, line
  refdt=float(line)
  readf, un, line & readf, un, line
  frzk=float(line)
  readf, un, line & readf, un, line
  zbot=float(line)
  readf, un, line & readf, un, line
  czil=float(line)
  readf, un, line & readf, un, line
  smlow=float(line)
  readf, un, line & readf, un, line
  smhigh=float(line)

  close, un
  free_lun, un
  
  return, {gendata, slope:slopedata, sbeta:sbeta, fxexp:fxexp, csoil:csoil, salp:salp, $
           refdk:refdk,refdt:refdt,frzk:frzk,zbot:zbot,czil:czil,smlow:smlow,smhigh:smhigh}
END


;; read the SOILPARM.TBL file and extract SHPs to be used
FUNCTION read_SoilData, soilfile, typefile
  IF n_elements(typefile) EQ 0 THEN typefile='IHOPstyp'
  IF n_elements(soilfile) EQ 0 THEN soilfile='SOILPARM.TBL'
  
  line=''
  openr, un, /get, typefile
  FOR i=0, 2 DO readf, un, line
  index=fix(line)
  close, un
  free_lun, un

  openr, un, /get, soilfile
  FOR i=0,index+2 DO readf, un, line
  data=float(strsplit(line,/extract))
  print, 'Warning for type conversion is due to the soil name being at the end of the line'
  close, un
  free_lun, un

  return, {soildata, vgn:data[1], smcdry:data[2], smcsat:data[4], smcref:data[5], $
           f11:data[3], alpha:data[6], ks:data[7], ds:data[8], smcwlt:data[9], qtz:data[10]}
END



;; read the VEGPARM.TBL file and extract the vegetation type, roughness, albedo, and veg cover
FUNCTION read_VegData, vegfile, typefile
  IF n_elements(typefile) EQ 0 THEN typefile='IHOPluse'
  IF n_elements(vegfile) EQ 0 THEN vegfile='VEGPARM.TBL'
  
  line=''
  openr, un, /get, typefile
  FOR i=0, 2 DO readf, un, line
  index=fix(line)
  close, un
  free_lun, un

  openr, un, /get, vegfile
  FOR i=0,index+2 DO readf, un, line
  line=strsplit(line, /extract, ',')
  close, un
  free_lun, un

  return, {vegdata, vegtype:index, albedo:float(line[1]), zo:float(line[2]), Fg:float(line[3]), $
           Nroot:float(line[4]), RS:float(line[5]), RGL:float(line[6]), $
           HS:float(line[7]), SNUP:float(line[8]), LAI:float(line[9]), MAXALB:float(line[10])} 
END



;;
;; read the 'IHOPelev' file and return an elevation (in meters)
;; very simple, read three lines and return the third as a floating point number
;; 
FUNCTION read_elev, elev_fname
  openr, un, /get, elev_fname
  line=''
  FOR i=0, 2 DO readf, un, line
  close, un
  free_lun, un
  return, float(line)
END

;;
;; read latitude and longitude from the IHOPposn file, returns decimal degrees
;; read 6 lines, convert the 6th line from DDDmmss.s into decimal degrees
;;
;; also call read_elev, then return a structure with lat, lon, and elev
;;
FUNCTION read_posn, latlonname, elevname
  IF n_elements(latlonname) EQ 0 THEN latlonname='IHOPposn'
  IF n_elements(elevname) EQ 0 THEN elevname='IHOPelev'

;; first read the latitude and longitude
  openr, un, /get, latlonname

  line=''
;; the last (4th) line contains hemisphere information
  FOR i=0,4 DO readf, un, line
  hemisphere=strsplit(line, /extract)
  IF hemisphere[1] EQ 'W' THEN EW=(-1) ELSE EW=1
  IF hemisphere[3] EQ 'S' THEN NS=(-1) ELSE NS=1

;; and this line contains the coordinates
  readf, un, line
  data=strsplit(line, /extract)

  
;; convert DDDmmss.s into DDD.dddddd
  lon=long(data[0])/10000 + $               ;;DDD + 
      (long(data[0])/100 MOD 100)/60.0 + $  ;; mm /60
      (float(data[0])*10 MOD 1000)/36000.0 ;; ss.s / 3600

  lat=long(data[1])/10000 + $               ;; degrees + 
      (long(data[1])/100 MOD 100)/60.0 + $  ;; minutes /60 + 
      (float(data[1])*10 MOD 1000)/36000.0 ;; seconds*10/36000

  lat*=NS
  lon*=EW

  close, un
  free_lun, un


;; then read the elevation
  elev=read_elev(elevname)

  return, {position, lat:lat, lon:lon, elev:elev}
END

;;
;; read initial soil moisture and soil temperature from IHOPsoil file
;;
FUNCTION read_Initial, initial_fname
  IF n_elements(initial_fname) EQ 0 THEN initial_fname='IHOPsoil'

  openr, un, /get, initial_fname
  line=''

  FOR i=0, 3 DO readf, un, line

  line=strsplit(line, /extract)
  
  nlayers=n_elements(line)/2
  soil_T=float(line[nlayers:nlayers*2-1])
  SMC=float(line[0:nlayers-1])

  close, un
  free_lun, un
  return, {initial, nlayers:nlayers, soil_T:soil_T, SMC:SMC}
END

;;
;; read through a namelist file looking for a line that contains the pattern *variable*=*
;; return the value that this variable is equal to.
;; 
FUNCTION readvar, un, variable
  line=''
  pattern='*'+variable+'*=*'

  readf, un, line
  WHILE NOT strmatch(line, pattern) AND NOT eof(un) DO readf, un, line
  IF NOT strmatch(line, pattern) THEN BEGIN
     ;; maybe it came before the point we were looking
     point_lun, un, 0
     WHILE NOT strmatch(line, pattern) AND NOT eof(un) DO readf, un, line
     IF NOT strmatch(line, pattern) THEN BEGIN
        print, 'ERROR : Could not find pattern : '+pattern
        return, -1
     ENDIF
  ENDIF
  
  ;; presumably if we got here we found the line we were looking for.
  ;; The typical case is to get here after reading only one or two lines.  
  return, (strsplit(line, '=', /extract))[1]
END


;; read the noah_offline.namelist file and parse the data.  
FUNCTION read_namelist, namelist_fname
  IF n_elements(namelist_fname) EQ 0 THEN namelist_fname='noah_offline.namelist'
  
  openr, un, /get, namelist_fname

  dir=readvar(un, 'DIR')
  NSOIL=readvar(un, 'NSOIL')

  zsoil=fltarr(nsoil)
  FOR i=0, nsoil-1 DO zsoil[i]=readvar(un, 'ZSOIL('+strcompress(i+1, /remove_all)+')')
  
  START_YEAR  = fix(readvar(un, 'START_YEAR'))
  START_MONTH = fix(readvar(un, 'START_MONTH'))
  START_DAY   = fix(readvar(un, 'START_DAY'))
  START_HOUR  = fix(readvar(un, 'START_HOUR'))
  START_MIN   = fix(readvar(un, 'START_MIN'))
  start={startTime, year:START_YEAR, month:START_MONTH, day:START_DAY, $
         hour:START_HOUR, min:START_MIN}

  ndays =readvar(un, 'KDAY')
  dt    = readvar(un, 'DT')
  tbot  = readvar(un, 'TBOT')
  met_z = readvar(un, 'ZLVL')
  Z = readvar(un, 'Z')


  close, un
  free_lun, un
  
  return, {namelist, dir:dir, nsoil:nsoil, zsoil:zsoil, start:start, ndays:ndays, $
          dt:dt, tbot:tbot, met_z:met_z, Z:Z}
END

;; return dt (model output time step) in minutes
FUNCTION finddt, times
  timechange=times[1]-times[0]

  IF timechange LT 60 THEN return, timechange ;; this is almost always what will happen

;; unless we happend to flip an hour
  IF timechange LT 2400 THEN BEGIN 
     hours=ulong64(times[0:1]/100)
     minutes=fix(times[0:1] MOD 100)
     return, (hours[1] - hours[0])*60.0 + minutes[1] - minutes[0]
  ENDIF 
  
;; if timechange is greater than 2400 than we must have flipped a day, look at the next time step
;; to see if it is any better
  timechange=times[2]-times[1]
  
  IF timechange LT 60 THEN return, timechange ;; this is almost always what will happen

  IF timechange LT 2400 THEN BEGIN 
     hours=ulong64(times[0:1]/100)
     minutes=fix(times[0:1] MOD 100)
     return, (hours[1] - hours[0])*60.0 + minutes[1] - minutes[0]
  ENDIF 
  
;; if timechange is still greater than 2400 than dt must be greater than one day! and this may not work
  ;; if it exactly one day, maybe we can use that??
  IF timechange EQ 10000 OR times[1]-times[0] EQ 10000 THEN return, 1440

  print, 'ERROR : Model time step is greater than 1 day, we can''t do anything with this!'
  print, '  Timestep 1 = ',strcompress(ulong64(times[0])), $
         '     Timestep 2 = ', strcompress(ulong64(times[1]))

END

;;
;; add one timestep to the current time (mon, day, year)
;; only updated every month because that is how often we write a new clm weather file
;; 
;; esp. for use with the IHOP input files in which I have looped the time series to allow
;;  the model to spin up
;;
PRO updateTiming, mon, yr, month=month, day=day, year=year, data, curoffset
  IF keyword_set(month) THEN BEGIN
     month++
     month = month MOD 12
     IF month EQ 0 THEN month=12
     mon=month
  ENDIF ELSE mon=fix(data[1,curoffset])
  IF keyword_set(year) THEN BEGIN
     IF month EQ 1 THEN year++
     yr=year
  ENDIF ELSE yr=fix(data[0,curOffset])
END


PRO weather_noah2clm, noahFile, outdir=outdir, month=month, day=day, year=year, $
                      ihop=ihop, pos=pos, start=start, realTimeSteps=realTimeSteps
;  print, ''
;  print, ' WARNING : Currently forces solar radiation to be greater than or equal to 0'
;  print, ''

  IF NOT keyword_set(outdir) THEN outdir=''
  IF keyword_set(month) OR keyword_set(day) OR keyword_set(year) OR keyword_set(ihop) THEN begin
     IF NOT keyword_set(month) THEN month=1
     IF NOT keyword_set(day) THEN day=1
     IF NOT keyword_set(year) THEN year=2001
  ENDIF
  IF keyword_set(start) THEN BEGIN 
     year=start.year
     month=start.month
     day=start.day
  ENDIF

  IF n_elements(noahFile) EQ 0 THEN noahFile='IHOPUDS1'
  junk=load_cols(noahFile, data)
  
  dt=180.0
  IF n_elements(data[0,*]) LT 4*2l*365*24 THEN dt*=10
  daysPerMonth=[31,28,31,30,31,30,31,31,30,31,30,31]

  curOffset=0
  IF keyword_set(month) THEN curmonth=month-1 ELSE curMonth=data[1,0]-1

  updateTiming, mon, yr, month=month, year=year, day=day, data, curoffset
;  IF yr MOD 4 EQ 0 THEN daysPerMonth[1]=29    ; leap years
  IF yr MOD 4 EQ 0 THEN daysPerMonth[1]=28    ; leap years... CLM doesn't actually handle leap years from what I can tell
  IF yr MOD 4 NE 0 THEN daysPerMonth[1]=28    ; all others are not
  IF keyword_set(month) THEN BEGIN
     mon--
     month--
  ENDIF 
  ntimeSteps=daysPerMonth[curMonth]*24*(3600.0/dt)
  ;; (days per month) *24(hours per day)*3600(seconds per hour)/dt(seconds per time step)
  ;; = timesteps/month
  
  WHILE curOffset+ntimeSteps LT n_elements(data[0,*]) DO BEGIN 
     
     IF mon LT 10 THEN monthSTR='0'+strcompress(fix(mon), /remove_all) $
     ELSE monthSTR=strcompress(fix(mon), /remove_all)
     clmFile=outdir+strcompress(fix(yr), /remove_all)+'-'+ monthSTR+'.nc'

;     print, clmFile, ntimesteps, dt, curMonth, yr, mon, year, month
     makeNCDF_weather, clmFile, data[*,curOffset:curOffset+ntimeSteps], ntimeSteps, dt, pos=pos

     updateTiming, mon, yr, month=month, year=year, day=day, data, curoffset
;     IF yr MOD 4 EQ 0 THEN daysPerMonth[1]=29 ; leap years
     IF yr MOD 4 EQ 0 THEN daysPerMonth[1]=28 ; leap years... CLM doesn't actually handle leap years from what I can tell
     IF yr MOD 4 NE 0 THEN daysPerMonth[1]=28 ; all others are not

     curOffset+=ntimeSteps
     curMonth++
     ntimeSteps=daysPerMonth[curMonth MOD 12]*24*(3600.0/dt)
     ;; (days per month) *24(hours per day)*3600(seconds per hour)/dt(seconds per time step)
     ;; = timesteps/month
  ENDWHILE
  realTimeSteps=curOffset       ; this is the number of model time steps that have actually
                                ; been written to weather files we can't run the model longer
                                ; than this because it will run out of weather data.  
END



PRO noah2clm, inputdir, outputdir, ihop=ihop, location=location, test=test
  IF NOT keyword_set(location) THEN location='sevilleta'
  IF n_elements(inputdir) EQ 0 THEN inputdir='./'
  IF n_elements(outputdir) EQ 0 THEN outputdir='./'

  cd, current=fullpath
  IF strmid(outputdir, 0,1) NE '/' THEN outputdir= fullpath+'/'+outputdir
  print, "Creating CLM files in : "+outputdir

  position= read_posn(inputdir+'IHOPposn', inputdir+'IHOPelev')
  initial = read_Initial(inputdir+'IHOPsoil')
  SHPs    = read_SoilData(inputdir+'SOILPARM.TBL', inputdir+'IHOPstyp')
  veg     = read_VegData(inputdir+'VEGPARM.TBL', inputdir+'IHOPluse')

  basic=read_namelist(inputdir+'noah_offline.namelist')
  
;; convert weather files this is probably the hardest part
  weatherFile=file_search(inputdir+'/IHOPUDS1')
  IF file_test(outputdir+'weather/', /directory) THEN $
    weatherdir=outputdir+'weather/' $
  ELSE weatherdir=outputdir
  weather_noah2clm, weatherFile, ihop=ihop, outdir=weatherdir, pos=position, $
                    start=basic.start, realTimeSteps=realTimeSteps

;; we might be able to write this from a clm run, or by just editing an existing initial.txt
;  makeNCDF_initial, initial, position, basic

  
  IF file_test(outputdir+'srfdata/', /directory) THEN $
    srfdir=outputdir+'srfdata/' $
  ELSE srfdir=outputdir
  srffile= srfdir+location+'_srf.nc'
  makeNCDF_surface, srffile, position, basic, veg, SHPs

  pftfile=outputdir+'pftdata/pft-physiology'
  rtmfile=outputdir+'rtmdata/rdirc.05'

  files={files, weatherdir:weatherdir, surfacefile:srffile, pftfile:pftfile, rtmfile:rtmfile}
  make_inputfile, outputdir+location+'.stdin', position, basic, files, location, realTimeSteps, test=test
END
