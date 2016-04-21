PRO batchChangeInp, newBase
;; folder names to move through "texture/param"
  texture=['sand', 'clay', 'silt', 'sloam', 'loam']
  params=['vgn', 'alpha', 'ks']

;; store a pointer to the starting directory
  cd, current=old

;; open the file we will use as a template  
  openr, un, /get, newBase

;; loop through all combinations of texture and parameter
  FOR i=0,n_elements(texture)-1 DO BEGIN
     FOR j=0,n_elements(params)-1 DO BEGIN

; move into the next directory
        cd, texture[i]+'/'+params[j]
        
;; note, we only need to create the file if we haven't done it already
;; for this texture
        IF j EQ 0 THEN BEGIN
;open the old input file for this texture
           openr, oldun, /get, 'mheatw.inp'
;open/create the new input file
           openw, newun, /get, 'mhotw.inp'
           
;; setup a few variables
           k=1                  ;keeps track of which line we are on
           line=''              ;holds the next line of template text
           oldline=''           ;holds the next line of old input text
           
           print, 'Making file ', texture[i]+'/'+params[j]+'mhotw.inp'
           
;loop through the entire newtemplate file (and old input file)
           WHILE NOT eof(un) DO BEGIN
; read a line from the template file
              readf, un, line
; read the same line from the old input file
              IF k LT 37 THEN $
                readf, oldun, oldline
; if we are at the soil hydraulic properties then use the line from
; the old input file, else use the line from the new template 
              IF k GT 28 AND k LT 36 THEN $
                line=oldline
; write the line to the new input file
              printf, newun, line
;keep track of which line we are on
              k=k+1
           ENDWHILE
           
;; reset file unit pointers
           close, oldun, newun
           free_lun, oldun, newun
           point_lun, un, 0
           
           print, 'Running...'
;; run unsat on the new input files
           spawn, './din <../../dinput; ./unsat <../../unsatput; dout <../../doutput;'

;; if this isn't the first time we've been in this texture then we
;; just need to copy the relevant files
        ENDIF ELSE $
          spawn, 'cp ../vgn/mhotw* ./'

;; move back to the starting directory
        cd, old

     ENDFOR
  ENDFOR
END

