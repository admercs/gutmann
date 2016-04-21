;; model time is assumed to be in the form YYYYMMDDTTTT

;; determines whether or not model and field days are the same
FUNCTION dayEqual, mtime, ftime
  day=fix((mtime MOD 1E6) /1E4)
  mon=fix((mtime MOD 1E8) /1E6)
  year=fix(mtime / 1E8)

  mday=getDOY(day,mon,year)
  return, mday EQ ftime
END

;; determines whether or not model and field times (hours) are the same
FUNCTION timeEqual, mtime, ftime
  modelTime=fix(mtime MOD 1E4)
  return, modelTime EQ ftime
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Returns indexes into field data that correspond to the first and last model times
;; 
;; Loops through all field data/times until it finds one that matches
;; the starting time from the model and one that matches the finishing
;; time from the model.
;;
;; Assumes that model time occurs within field time
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION GetTimes, mTime, fTime
  i=0
  sz=n_elements(mtime)

;; find the starting time
  WHILE NOT dayEqual(mtime[0], ftime[0,i]) DO i++
  WHILE NOT timeEqual(mtime[0], ftime[1,i]) DO i++
  
  starttime=i
  
;; find the ending time
  WHILE NOT dayEqual(mtime[sz-1], ftime[0,i]) DO  i++
  WHILE NOT timeEqual(mtime[sz-1], ftime[1,i]) DO i++

  endtime=i

  return, {start:starttime, stop:endtime}
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Compares field Ts data to model Ts data (or top layer)
;; returns an array of error values for each model output file
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION fieldVmodel, fieldFile, modelBase, Ts=Ts, T5=T5, hybrid
  IF keyword_set(Ts) THEN BEGIN
     fieldColumn=38
     modelColumn=2
  ENDIF ELSE IF keyword_set(T5) THEN BEGIN
     fieldColumn=66
     modelColumn=9
  ENDIF ELSE BEGIN
     fieldColumn=66  ;2.5cm
     modelColumn=2   ;Ts
  ENDELSE 

  IF n_elements(modelBase) EQ 0 THEN modelBase="out."
  filelist=file_search(modelBase+"*")

; read in the field data
  junk=load_cols(fieldfile, fieldData)
 ; bigloadcols uses doubles so we don't truncate the time YYYYMMDDTTTT
  junk=bigloadcols(filelist[0], modelData)

;; find the index into field Data that is at the same time as model data
  times=GetTimes(modelData[0,*], fieldData[0:1,*])

;; subset field data to Ts data for the correct time
  fTs=fieldData[fieldColumn,times.start:times.stop]

  IF keyword_set(Ts) THEN $
    fTs=(fTs/(0.95*5.6E-8))^0.25 $
  ELSE fTs+= 273.15           ; convert C to K

  index=where(fTs GT -10000 AND fTs LT 10000)
  IF n_elements(index) LT 10 THEN return, -1
  fTs=fTs[index]

  sz=n_elements(filelist)
  err=fltarr(sz,3)
;; loop through all files calculating error relative to field data
  FOR i=0, sz-1 DO BEGIN
     junk=load_cols(filelist[i], modelData)
     mTs=modelData[modelColumn,index]

     err[i,0]=max(mts-fts)
     
;; correlate mts and fts to remove (some) model structure error. 
     M2Fgain=regress(mTs, fts, const=M2Foffset, correlation=r)

;; regress returns a one element array so we need to ask for the first element
;;   otherwise a one element array times a n element array returns one element!
     newTs=mts*M2Fgain[0] + M2Foffset

     plot, newTs, fts, /xs, /ys, psym=1
     oplot, mts, fts, psym=2

     plot, newTs, l=1, /ys
     oplot, fts
     oplot, mts, l=2
     wait, 1

     err[i,1]=max(abs(newTs- fTs))
     err[i,2]=r

  ENDFOR
;  plot, err[*,0]
;  oplot, err[*,1], l=1
;  oplot, err[*,2], l=2

  return, err
END
