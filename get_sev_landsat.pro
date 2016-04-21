;+
; NAME:              get_sev_landsat
;
; PURPOSE:           read sevilleta geotiff landsat files and get
;                    thermal (and albedo?) data from specified locations
;
; CATEGORY:          SHP processing RS data
;
; CALLING SEQUENCE:  get_sev_landsat, [landsatdir], [locationfile=locationfile]
;                            [outputfile=outputfile], [albedofile=albedofile]
;
; INPUTS:
;
; OPTIONAL INPUTS:   landsatdir = directory containing landsat geotiff files
;                           (default='./')
;
; KEYWORD PARAMETERS:
;                    locationfile = file containing sevilleta locations we
;                                   want to get data from.  
;                                   (default="sevLandsatLocs.txt")
;
; OUTPUTS:           outputfile = column formated text file
;                           one column for each location
;                           rows are temperature data
;                    albedofile = column formated text file
;                           one column for each location
;                           rows are albedo data
;
; OPTIONAL OUTPUTS:  albedo file see above
;
; COMMON BLOCKS:     <none>
;
; SIDE EFFECTS:      <none>
;
; RESTRICTIONS:      <none>
;
; PROCEDURE:
;             Find landsat input files.
;             read locations from location file
;             grab data from landsat files
;             write data to output file
;
; EXAMPLE: get_sev_landsat, 'sevLandsatTiffs/', locationfile='locations.txt',
;                           outputfile="thermaldata", albedofile="albedodata"
;
; MODIFICATION HISTORY:
;           11/16/2005 - edg - original
;
;-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; read a very strict file format,
;;   one header line, three column data,
;;   return the last two columns as integer data.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION read_locs, locationfile
  openr, un, /get, locationfile
  line=''
  readf, un, line
  readf, un, line
  data=(strsplit(line, /extract))[1:2]
  WHILE NOT eof(un) DO begin
     readf, un, line
     data=[[data],[(strsplit(line, /extract))[1:2]]]
  ENDWHILE
  close, un & free_lun, un
  return, fix(data)
END 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main program
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO get_sev_landsat, landsatdir, locationfile=locationfile, $
                     outputfile=outputfile, albedofile=albedofile

  cd, current=olddir
  IF n_elements(landsatdir) NE 0 THEN cd, landsatdir
  IF NOT keyword_set(locationfile) THEN locationfile="sevLandsatLocs.txt"
  IF NOT keyword_set(outputfile) THEN outputfile="thermaldata.txt"
  IF NOT keyword_set(albedofile) THEN albedofile="albedodata.txt"

  locs=read_locs(olddir+'/'+locationfile)
  albedo=intarr(n_elements(locs[0,*]))
  thermal=intarr(n_elements(locs[0,*]))

  files=file_search('*.tif', count=count)
  FOR i=0,count-1 DO BEGIN
     curalbedo=intarr(n_elements(locs[0,*]))
     curthermal=intarr(n_elements(locs[0,*]))
     data=read_tiff(files[i])
     sz=size(data)
     FOR curloc=0, n_elements(locs[0,*])-1 DO BEGIN
        IF sz[0] GT 2 THEN BEGIN 
           ;; we have albedo data too
           curalbedo[curloc]=data[2,locs[0,curloc], locs[1,curloc]]

           curthermal[curloc]=data[5,locs[0,curloc], locs[1,curloc]]
        ENDIF ELSE $ ; we only have thermal, so leave off the first index
          curthermal[curloc]=data[locs[0,curloc], locs[1,curloc]]
        
     ENDFOR
     albedo=[[albedo],[curalbedo]]
     thermal=[[thermal],[curthermal]]
  ENDFOR 
  cd, olddir
  albedo=albedo[*,1:n_elements(albedo[0,*])-1]
  thermal=thermal[*,1:n_elements(thermal[0,*])-1]
  
  IF max(albedo) GT 0 THEN BEGIN 
     openw, oun, /get, albedofile
     printf, oun, albedo
     close, oun
     free_lun, oun
  ENDIF 
  openw, oun, /get, outputfile
  printf, oun, thermal
  close, oun
  free_lun, oun
  
END
