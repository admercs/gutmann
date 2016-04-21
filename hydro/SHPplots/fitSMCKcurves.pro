;; findMinErr : return the distance between a given x,y point and a curve
;; This actually computes the distance squared between all points
;;  and returns the minimum.  
FUNCTION findMinErr, x, y, Xvals, Yvals, tr=tr
  tmp=sqrt((x-Xvals)^2+ (y-Yvals)^2)
  results=min(tmp)

  IF keyword_set(tr) THEN BEGIN
     tmpY=indgen(100)/(-10.0)+min(Yvals)
     res2=min(sqrt((x-Tr)^2+ (y-tmpY)^2))
     return, min([res2, results])
  ENDIF

  return,results
END

;; Finds the rms error between a set of data points and the van Genuchten
;;  curve specified by the given parameters
FUNCTION VGErr, alpha, n, Ks, Ts, Tr, SMC, condIN
  Sat=indgen(1000)/999.0
  curSMC =Sat* (Ts-Tr) + Tr
  sz=1000

  m=1-(1./n)
  IF m EQ 0 THEN m=1E-10

  curCond=alog10(Ks * (Sat^0.5) * (1.0-((1.0-(Sat^(1.0/m)))^m))^2.)/20.
  cond=alog10(condIN)/20.

  err=0
  FOR i=0, n_elements(cond)-1 DO $
    err+=findMinErr(smc[i], cond[i], curSMC, curCond)


;  plot, curSMC, curCond, title="VG"+string(n)+string(err)
;  oplot, SMC,cond, l=1
;  wait, 0.04

  return, sqrt(err/n_elements(cond))
END 

  
FUNCTION fit_vg2Data, inputData
  SMC =inputData[1,2:*]
  cond=inputData[2,2:*]

  output=fltarr(6)
  minErr=1.0E20

;; hacks to avoid too many loops 
  Tr=inputData[1,0]
  Ts=inputData[2,0]
  Ks=inputData[1,1]
  psi_s=inputData[2,1]

;; alpha doesn't actually matter so we assign it the mean value for now
  a = 0.06

;; loop over reasonable values for n
  FOR n=1.01,10, 0.01 DO BEGIN
     curErr=VGErr(a, n, Ks, Ts, Tr, SMC, cond)
     IF curErr LT minErr THEN BEGIN 
        minErr=curErr
        output=[n, a, Ks, Ts, Tr, minErr]
     ENDIF
  ENDFOR
  
  return, output  
END


;; Finds the rms error between a set of data points and the van Genuchten
;;  curve specified by the given parameters
FUNCTION CHErr, b, Ks, Ts, Tr, SMC, condIN
  Sat=indgen(1000)/999.0
  curSMC =Sat* (Ts-Tr) + Tr
  sz=1000

  curCond=alog10(Ks * (curSMC/Ts)^((2.0*b)+3))/20.
  cond=alog10(condIN)/20.
  err=0
  FOR i=0, n_elements(cond)-1 DO $
    err+=findMinErr(smc[i], cond[i], curSMC, curCond)

;  plot, curSMC, curCond, title="CH"+string(b)+string(err)
;  oplot, SMC,cond, l=1
;  wait, 0.04

  return, sqrt(err/n_elements(cond))
END 

  
FUNCTION fit_ch2Data, inputData
  SMC =inputData[1,2:*]
  cond=inputData[2,2:*]
  
  output=fltarr(6)
  minErr=1.0E20

;; hacks to avoid too many loops 
  Tr=inputData[1,0]
  Ts=inputData[2,0]
  Ks=inputData[1,1]
  psi_s=inputData[2,1]


;; loop over reasonable values for b
  FOR b=0.01,20, 0.01 DO BEGIN
     curErr=CHErr(b, Ks, Ts, Tr, SMC, cond)
     IF curErr LT minErr THEN BEGIN 
        minErr=curErr
        output=[b, psi_s, Ks, Ts, Tr, minErr]
     ENDIF
  ENDFOR
  
  return, output  
END

;; read the theta-conductivity relationship
function getRecord, un
  if eof(un) then return, -1

  line=""
  ;; read initial data line
  readf, un, line
  curData=float(strsplit(line, /extract))
  if n_elements(curData) eq 1 then return, -1  ;no data for this record
  recordNumber=curData[0] ;; this is the record number we want to look for
  Data=curData ;; initialize data

  ;; loop until we reach the next record
  while curData[0] eq recordNumber $
    and not eof(un) $
    and n_elements(curData) gt 1 do begin

     ;; store the current data
     Data=[[Data], [curData]]

     ;;store our current pointer into the file incase this is the next record
     point_lun, -1*un, pos
     readf, un, line
     curData=float(strsplit(line, /extract))
  ENDWHILE
  IF n_elements(data[0,*]) LT 4 THEN return, -1
  Data=Data[*,1:*]
  ;; point back to where we were before we hit the wrong record
  if not eof(un) then  point_lun, un, pos

  return, Data
end

;; duh, probably doesn't need it's own procedure
PRO writeData, unit, vg, ch
  printf, unit, vg, ch, format='(13F10.3)'
END



PRO fitSMCKcurves, infile, outfile
;  data=getData(infile)
  openr, un, /get, infile
  openw, oun, /get, outfile
  i=0

  window, 1, xs=1000, ys=1000

  WHILE NOT eof(un) DO BEGIN 
     data=getRecord(un)
     IF data[0] NE -1 THEN BEGIN 
;        wset, 1
;        plot, data[1,2:*], alog10(data[2,2:*])/20.
        vgFit = fit_VG2Data(data)
        chFit = fit_CH2Data(data)
        writeData, oun, vgfit, chfit
        print, ++i,  1.0/(vgFit[0]-1.0), chFit[0], vgFit[5], chFit[5]
        data=data[*,2:*]
;        wset, 1
;        IF data[1,0] GT 0 AND n_elements(data) GT 6 THEN BEGIN
;           plot, data[1,*], data[2,*], /ylog, psym=1
;           oplot, data[1,*], calcVGcurve(vgFit[0:4], theta=data[1,*])
;           oplot, data[1,*], calcCHcurve(chFit[0:4], theta=data[1,*]), l=2
;        endIF

;        wait, 1
     endIF ELSE print, "Error : ", ++i
  end

  close, un, oun
  free_lun, un, oun
END
