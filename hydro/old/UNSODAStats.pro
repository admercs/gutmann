;PRO UNSODAStats, dataFile, outputFile, generalFile

FUNCTION getSoilIndex, name, samples, indexFile
  openr, un, /get, indexFile

  index=lonarr(n_elements(samples))
  n=0
  line=""
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     tmp=strsplit(line, '~', /extract)
     tmpname=strmid(tmp[3], 1, strlen(tmp[3])-2)
     IF strmatch(tmpname, name) THEN BEGIN
        code=fix(tmp[0])
        curdex=where(samples EQ code)

        IF curdex NE -1 THEN BEGIN
           index[n]=curdex
           n++
        ENDIF
     ENDIF
  ENDWHILE

  close, un
  free_lun, un
  IF n GT 0 THEN return, index[0:--n] $
  ELSE return, -1
END


PRO UNSODAStats, dataFile, outputFile, generalFile
  IF n_elements(generalFile) EQ 0 THEN generalFile='general.txt'
  
;; read the input data
  junk=load_cols(dataFile, data)
  b=data[6,*]
  sample=data[12,*]

;; initialize useful variables
  SoilNames=["sand", "loamy sand", "sandy loam", "silt loam", $
             "loam", "sandy clay loam", "silty clay loam", $
             "clay loam", "sandy clay", "silty clay", "clay"]
  nsoils=n_elements(SoilNames)

  ; array of percentiles to be computed by the function Percentiles
  values=[0.05, 0.25, 0.5, 0.75, 0.95]

  openw, oun, outputFile, /get

;; loop through all soil types  
  FOR i=0, nsoils-1 DO BEGIN
     ;; find the soils that match the current soil name
     index=getSoilIndex(SoilNames[i], sample, generalFile)

     ;; if we found any matching soils compute statistics and output
     IF n_elements(index) EQ 1 THEN printf, oun, [0,0,0,0,0,0] $
     ELSE IF n_elements(index) LT 5 THEN BEGIN
        std=stdev(b[index])
        ave=mean(b[index])
        printf, oun, ave-3*std, ave-std, ave, ave+std, ave+3*std, n_elements(index)
     ENDIF ELSE $
       printf, oun, [Percentiles(value=values, b[index]), n_elements(index)]
  ENDFOR
  

;; close the output file
  close, oun
  free_lun, oun
END
