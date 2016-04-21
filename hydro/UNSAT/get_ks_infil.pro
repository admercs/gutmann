;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Create a file with column formatted
;;     index, infiltration (cm/day), Ks (cm/day), sand %, silt %, clay %
;; 
;; read a batch of out_<textureclass>_<index> files from unsat
;;   infiltration tests, take the average infiltration rate over dt time
;;   (default = 10min) use unsat_soils_w_texture to generate the
;;   infiltration output files
;; 
;; read ks and texture data from newRosetta.txt file
;;
;; match up ks and texture data with infiltration experiments based on
;; the database indices embeded in the filenames.  
;;
;; default = get_ks_infil, "newRosetta.txt", "out_*", dt=10.0, outputfile="ks_infil.txt"
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; read through a file and return the nth line as an array split on
;;   spaces (any whitespace?)
FUNCTION nthline, file, n, stableonly=stableonly

  IF keyword_set(stableonly) THEN BEGIN
     junk=load_cols(file, data)
     tmp=data[1,2:n_elements(data[1,*])-1] - data[1,1:n_elements(data[1,*])-2]
     IF max(tmp) GT 0 THEN return, [-1,-1,-1,-1]
  ENDIF 


  openr, un, /get, file
  line=''
  FOR i=1, n DO readf, un, line
  
  close, un
  free_lun, un
  
  return, strsplit(line, /extract)

END


;; read the nth line from a batch of infiltration files and calculate
;; the average implied infiltration rate
FUNCTION readinfildata, files, steps, stableonly=stableonly

  dt=steps*0.0025/24.0 ; dt in days

  data=-1
  start=0
  WHILE data NE -1 DO BEGIN 
     data=(nthline(files[start], steps, stableonly=stableonly))[3]/dt
     index=fix((strsplit(files[start], '_', /extract))[2])
     start++
  ENDWHILE 

  FOR i=start, n_elements(files)-1 DO BEGIN
     tmp=float((nthline(files[i], steps, stableonly=stableonly))[3])/dt
     IF tmp NE -1/dt THEN BEGIN 
        index=[index, fix((strsplit(files[i], '_', /extract))[2])]
        data=[data, tmp]
     ENDIF 
  ENDFOR
  stop
  return, [transpose(index), transpose(data)]
END

FUNCTION readksdata, datafile
  junk= load_cols(datafile, data)
  index=data[0,*]
  ks=data[7,*]
  return, [index,ks]
END

FUNCTION  readtexturedata, datafile
  junk= load_cols(datafile, data)
  index=data[0,*]
  texture=data[3:5,*]
  return, [index,texture]
END 

FUNCTION matchindices, ks, texture, infil
  stop
  FOR i=0, n_elements(infil[0,*])-1 DO BEGIN 
     index=where(ks[0,*] EQ infil[0,i])
     IF index[0] NE -1 AND n_elements(index) EQ 1 THEN BEGIN
        IF n_elements(data) EQ 0 THEN $
          data= [infil[*,i], ks[1,index], texture[1:3,index]] $
        ELSE data=[[data],  [ [infil[*,i], ks[1,index], texture[1:3,index]] ]]
     ENDIF

  ENDFOR

  return, data
END


PRO get_ks_infil, ksdatafile, infil_pattern, dt=dt, $
                  outputfile=outputfile, stableonly=stableonly

  IF n_elements(infil_pattern) EQ 0 THEN infil_pattern="out_*"
  IF n_elements(ksdatafile) EQ 0 THEN ksdatafile="newRosetta.txt"
  IF NOT keyword_set(dt) THEN dt=10.0 ; minutes of data to average
  IF NOT keyword_set(outputfile) THEN outputfile="ks_infil.txt"

  nsteps=dt/60.0/0.0025 ; convert minutes to hours, then divide by the time step of the model in hours
 
  infilFiles=file_search(infil_pattern)
  IF n_elements(infilFiles) LT 2 THEN BEGIN 
     print, "not enough files found : "
     print, infilFiles
     return
  END

; Read infiltration, ks, and texture data
  infildata=readinfildata(infilFiles, nsteps, stableonly=stableonly)
  ksdata=readksdata(ksdatafile)
  texture=readtexturedata(ksdatafile)

  data=matchindices(ksdata, texture, infildata)

;; write the outputfile
  openw, oun, /get, outputfile
  FOR i=0, n_elements(data[0,*])-1 DO BEGIN
     printf, oun, data[*,i], format='(I10, 5F20.5)'
  ENDFOR
  close, oun
  free_lun, oun
END
