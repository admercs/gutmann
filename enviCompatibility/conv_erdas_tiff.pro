;+
; NAME:             conv_erdas_tiff
;
; PURPOSE:          convert a directory full of erdas files into geotiff files
;
; CATEGORY:         ENVI/RS file conversion utility
;
; CALLING SEQUENCE: conv_erdas_tiff, [directory], [pattern=pattern]
;
; INPUTS:           none required
;
; OPTIONAL INPUTS:
;                   directory = optional directory name to search
;                       for erdas files (use pattern) default='./'
;
; KEYWORD PARAMETERS:
;                   pattern=pattern optional pattern to use when searching
;                            for files to convert (default='*.img')
;
; OUTPUTS:          files are converted to geotiff files
;                            (originals are left in place)
;
; OPTIONAL OUTPUTS: <none>
;
; COMMON BLOCKS:    <none>
;
; SIDE EFFECTS:     <none?>
;
; RESTRICTIONS:     envistart must be run before this will compile?
;
; PROCEDURE:        search directory for image files to conver
;                        loop over all files
;                            open in envi
;                            write to geotiff
;
; EXAMPLE:
;            conv_erdas_tiff, 'sevLandsatFiles/', pattern='*.img',
;                  outputdir='sevLandsatTiffs/'
;
; MODIFICATION HISTORY:
;           11/16/2005 - edg - original
;-
PRO conv_erdas_tiff, directory, outputdir=outputdir, pattern=pattern, $
                     setpos=setpos, setdims=setdims
 
  IF n_elements(directory) EQ 0 THEN cd, current=directory
  IF NOT keyword_set(outputdir) THEN outputdir=directory
  IF NOT keyword_set(pattern) THEN pattern="*.img"
  

;; sets up all the directories to fully qualified pathnames,
;; probably and easier way to do this...
  cd, directory, current=old
  cd, old, current=directory
  cd, outputdir
  cd, directory, current=outputdir

;; find the files that match the given pattern
  files=file_search(pattern, count=count)
  
  IF count EQ 0 THEN return
  FOR i=0, count-1 DO BEGIN 
     
     ENVI_OPEN_DATA_FILE, files[i], r_fid=fid, /erdas80
     IF fid NE -1 THEN BEGIN 
        ENVI_FILE_QUERY, fid, dims=dims, nb=nb
;        dims=[-1,0,ns-1, 0, nl-1]
        pos=indgen(nb)

;; if the user specified dimensions or band positions, then use those instead        
        IF keyword_set(setdims) THEN dims=setdims
        IF keyword_set(setpos) THEN pos=setpos

;; move into the output directory
        cd, outputdir

;; create the output file name by stripping the extension if one exists and adding .tif
        out_name=strsplit(files[i], '.', /extract)
        length=n_elements(out_name)
        IF length GT 1 THEN length-=2 ELSE length--
        out_name=strjoin(out_name[0:length], '.')+'.tif'

;; write the output files
        ENVI_OUTPUT_TO_EXTERNAL_FORMAT, fid=fid, dims=dims, out_name=out_name, $
          /tiff, pos=pos

;; return to the input directory
        cd, directory
        
;; close the input file
        ENVI_FILE_MNG, id=fid, /remove
     ENDIF 
  ENDFOR

END
