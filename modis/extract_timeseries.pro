;+
; NAME: extract_timeseries
;
; PURPOSE:  retrieve a time series of data for a single location from
;           a set of geotiff files.  Ideally geotiff files should be
;           output from resample_ts.pro.  If not, file names must be
;           as they would be from resample_ts.pro
;
; CATEGORY: Processing MODIS data
;
; CALLING SEQUENCE: extract_timeseries, lat, lon, dir=dir, outfile=outfile, raw=raw
;
; INPUTS: 
;          lat - latitude (in either UTM or decimal degrees)
;          lon - longitude (in either UTM or decimal degrees)
;                (both lat and lon must be in the same format (UTM or DD)
;                default location is the sevilleta Shrub site
;
; OPTIONAL INPUTS: (lat and lon default to sevilleta shrub site)
;
; KEYWORD PARAMETERS:
;          dir - directory to search for geotiff files (default = '.')
;          outfile - name of output file to be created (default = 'timeseries.txt')
;          raw - if this keyword is set (non-zero) MOD11A1v004 gains will
;                not be appliet to the output data (if you are not
;                using MOD11A1v004 data you should probably set this flag)
;
; OUTPUTS: outfile - a column formated output file that will contain a
;                    header describing each column, followed by data
;                    with one row for each original input geotiff file
;
; OPTIONAL OUTPUTS: <none>
;
; COMMON BLOCKS: <none>
;
; SIDE EFFECTS: <none>
;
; RESTRICTIONS: all geotiff files must cover the same area, and file
;               names must follow a specific file format
;
; REQUIRED IDL FILES : 
;               text_progressbar.pro
;
; PROCEDURE: 
;
; EXAMPLE: extract_timeseries, 33.3434, -105.2343, dir='/data/modis/raw/', outfile='BSS_MODIS_LST.txt', /raw
;
; MODIFICATION HISTORY:
;        5-12-2006 - edg - original
;-


;; find the pixel location of the requested lat and lon
FUNCTION findxy, file, lat, lon
;; takes lat lon in decimal degrees and converts it to utm if necessary
  IF abs(lat) LT 90 AND abs(lon) LT 180 THEN BEGIN 
     utm=ll_to_utm(lon, lat)
     lat=utm[1]
     lon=utm[0]
  ENDIF

;; read header info from the geotiff file
  junk=read_tiff(file, geotiff=geotiff)
  
; find the pixel size in geotiff file
  sx=geotiff.modelpixelscaletag[0]
  sy=geotiff.modelpixelscaletag[1]
; find the upper left coordinate in the geotiff file
  left=geotiff.MODELTIEPOINTTAG[3,0]
  top=geotiff.MODELTIEPOINTTAG[4,0]

; calculate the desired pixel location
  x=floor((lon-left)/sx)
  y=floor((top-lat)/sy)

  return, [x,y]
END


;; Read the MODIS field names from the file names and return an array of strings
;; filenames must be in the format "MOD11A1.A2002060.h09v05.004.2003197112234_Fieldname.tif"
;;  = MODXXXX.AYYYDDD.hHHvVV.ver.YYYYDDDHHMMSS_Fieldname.tif
;;
;;  The number of characters in the input filename is all that is really important, 
;;  there must be 42 characters before the field name and there must be 4
;;  characters after the field name
FUNCTION getfieldnames, files
  fieldnames=strarr(n_elements(files)+1)
  fieldnames[0]='Julian_Day'
;; loop through all files extracting the field names
  FOR i=1, n_elements(files) DO BEGIN
     tmp=file_basename(files[i-1])
     fieldnames[i]=strmid(tmp, 42, strlen(tmp)-42-4)
  ENDFOR
  return, fieldnames
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; this applies the appropriate gains and offsets for the MOD11A1 product,
;; assuming all fields were extracted.
;;
;; If you wish to modify this for other data products, the order of
;; the files is determined alphabetically by the filenames
;;
;; NOTE : on some systems this may put all upper case letters before
;; lower case
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION applyGains, data
;; Data             Gain     Offset
; Clear_day_cov     0.0001     0
; Clear_night_cov   0.0001     0
; Day_view_angl     1.0      -65
; Day_view_time     0.1        0
; Emis_31           0.002      0.49
; Emis_32           0.002      0.49
; LST_Day_1km       0.02       0
; LST_Night_1km     0.02       0
; Night_view_angl   1.0      -65
; Night_view_time   0.1        0
; QC_Day            1          0
; QC_Night          1          0

  gains=[1, 0.0001,0.0001,1.0,0.1,0.002,0.002,0.02,0.02,1.0,0.1,1.0,1.0]
  offsets=[0, 0,0,-65,0,0.49,0.49,0,0,-65,0,0,0]
  
;; apply gains and offsets
  return, data $
          * rebin(gains,n_elements(gains),n_elements(data[0,*])) $
          + rebin(offsets,n_elements(offsets),n_elements(data[0,*]))
END



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; read a time series of data from a collection of MODIS geotiff files
;; output a column formated text file
;; 
;; input filenames must follow a certain format
;; input files must be geotiffs as output by the MRTool resample program
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO extract_timeseries, lat, lon, dir=dir, outfile=outfile, raw=raw
;; default values for all input variables
  IF NOT keyword_set(dir) THEN $
    dir='.'
  IF NOT keyword_set(outfile) THEN outfile='timeseries.txt'
  IF n_elements(lat) EQ 0 THEN BEGIN 
     ;; sevilleta bowen station shrub site
     lat=34.335
     lon=-106.729
  ENDIF          
  
;; set up the files
  files=file_search(dir+'/*.tif')

;; find just one days worth of files
  tmp=file_search(dir+'/'+(strsplit(file_basename(files[0]),'_',/extract))[0]+'*.tif')
;; read the field names to be processed from the file names.
  fieldnames=getfieldnames(tmp)

  nfiles=n_elements(files)
  nfields=n_elements(tmp)
  ndates=nfiles/nfields
  
;; simple error checking
  IF float(nfiles)/nfields MOD 1 NE 0 THEN BEGIN 
     print, nfiles, nfields, ndates
     print, 'ERROR : All combinations of dates/fields are not present'
     return
  ENDIF 

  output=lonarr(nfields+1,ndates) ; add a field for the day of the year from the file name

;; find the pixel of interest
  xy=findxy(files[0], lat, lon)
  
;; initialize a progress bar
  text_progressbar, /init
  curfield=0
  curday=0
;; loop over all files retreiving data and sticking it in the output array
  FOR i=0, nfiles-1 DO BEGIN 

     IF curfield EQ 0 THEN $ ; read the julian day from the filename
       output[curfield++, curday]=fix(strmid(file_basename(files[i]), 13,3))
     
     output[curfield++, curday]=(read_tiff(files[i]))[xy[0],xy[1]]

     IF curfield GT nfields THEN BEGIN 
        ;; we should be moving on to the next day and the first field again
        curday++
        curfield=0
     ENDIF

;; update the progress bar
     text_progressbar, nfiles, progress=i, last=last
  ENDFOR
;; finish the progress bar
  text_progressbar, /done, last=last

  columns=indgen(n_elements(output[*,0]))
;; process data with gains and offsets
  IF NOT keyword_set(raw) THEN BEGIN 
     output=applyGains(output)

;; rearrange output columns
;;      Julian_Day     LST_Day_1km   LST_Night_1km   Clear_day_cov Clear_night_cov
;;      QC_Day        QC_Night   Day_view_angl   Day_view_time         Emis_31
;;      Emis_32 Night_view_angl Night_view_time
     columns=[0,7,8,1,2,11,12,3,4,5,6,9,10]
  ENDIF 

;; write the output files
  openw, oun, /get, outfile
  printf, oun, fieldnames[columns], format='('+strcompress(nfields+1)+'A16)'
  IF keyword_set(raw) THEN $
    printf, oun, output[columns,*], format='('+strcompress(nfields+1)+'I16)' $
  ELSE $
    printf, oun, output[columns,*], format='('+strcompress(nfields+1)+'F20.10)'
  close, oun
  free_lun, oun
END

