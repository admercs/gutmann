;; findMinErr : return the distance between a given x,y point and a curve
;; This actually computes the distance squared between all points
;;  and returns the minimum.  
FUNCTION findMinErr, x, y, Xvals, Yvals, tr=tr
;; find the corresponding X value
  tmp=abs(x-Xvals)
  loc=where(tmp EQ min(tmp))

  IF loc[0] EQ -1 THEN BEGIN
     print, "ERROR!!!!!!!!!!!!!!!!!"
     retall
  ENDIF
;
;; return the squared distance to the corresponding Y value
;  results=mean((y-Yvals[loc])^2.0)
  
;   tmp=((x-Xvals)^2+ (y-Yvals)^2)
;   results=min(tmp)

;   IF keyword_set(tr) THEN BEGIN
;      tmpY=indgen(100)/(-10.0)+min(Yvals)
;      res2=min(((x-Tr)^2+ (y-tmpY)^2))
;      return, min([res2, results])
;   ENDIF

  return,results
END

;; Finds the rms error between a set of data points and the van Genuchten
;;  curve specified by the given parameters
FUNCTION VGErr, alpha, n, Ks, Ts, Tr, hIN, condIN

  m=(1-1.0/n)>1E-20

  Sat=(1.0+(alpha*hIN)^n)^(-1.0*m)


  curCond=alog10(Ks * (Sat^0.5) * (1.0-((1.0-(Sat^(1.0/m)))^m))^2.)
  err=total((ALOG10(condIN)-curCond)^2)

;  maxh=max(hIN)
;  sz=200
;  h=(maxh/(sz-1.0)) *indgen(sz)
;; change cond so that we have the same relative weighting
;   gain=(maxh/(max(alog10(condIN))-min(alog10(condIN))))
;   curCond=alog10(Ks * (Sat^0.5) * (1.0-((1.0-(Sat^(1.0/m)))^m))^2.)*gain
;   cond=alog10(condIN)*gain

;   curH=h
;   h=hIN

;   err=0
;   FOR i=0, n_elements(cond)-1 DO $
;     err+=findMinErr(h[i], cond[i], curH[i], curCond[i])
;
;  plot, hIN, condIN, /ylog, psym=1, title=err
;  oplot, hIN, 10.0^(curCond/gain)
;  wait, 0.1
;  plot, curSMC, curCond, title="VG"+string(n)+string(err)
;  oplot, SMC,cond, l=1
;  wait, 0.04

  return, sqrt(err/n_elements(condIN))
END 

  
FUNCTION fit_vg2Data, inputData
  h =inputData[1,*]
  cond=inputData[2,*]

  output=fltarr(6)
  minErr=1.0E38

;; hack to avoid too many loops 
  Ks=max(cond)
  Ts=0.4
  Tr=0.02


;; loop over reasonable values for n
  FOR a=0.001,0.3,0.0003 DO BEGIN
     FOR n=1.01,3, 0.003 DO BEGIN
        curErr=VGErr(a, n, Ks, Ts, Tr, h, cond)
        IF curErr LT minErr THEN BEGIN 
           minErr=curErr
           output=[n, a, Ks, Ts, Tr, minErr]
        ENDIF
     ENDFOR
     FOR n=3.01,10, 0.03 DO BEGIN
        curErr=VGErr(a, n, Ks, Ts, Tr, h, cond)
        IF curErr LT minErr THEN BEGIN 
           minErr=curErr
           output=[n, a, Ks, Ts, Tr, minErr]
        ENDIF
     ENDFOR
  ENDFOR 
  return, output  
END


;; Finds the rms error between a set of data points and the van Genuchten
;;  curve specified by the given parameters
FUNCTION CHErr, b, psis, Ks, Ts, Tr, hIN, condIN


  curCond=alog10((Ks * (psis/hIN)^(2.0+(3.0/b)))<Ks)
  err=total((ALOG10(condIN)-curCond)^2)


;  sz=200
;  maxh=max(hIN)
;  h=indgen(sz)*(maxh/(sz-1.0))
;; change cond so that we have the same relative weighting
;   gain=(maxh/(max(alog10(condIN))-min(alog10(condIN))))
;   curCond=alog10((Ks * (psis/h)^(2.0+(3.0/b)))<Ks)*gain
;   cond=alog10(condIN)*gain
;   curH=h
;   h=hIN
;
;   err=0
;   FOR i=0, n_elements(cond)-1 DO $
;     err+=findMinErr(h[i], cond[i], curH, curCond)
;
;  plot, curSMC, curCond, title="CH"+string(b)+string(err)
;  oplot, SMC,cond, l=1
;  wait, 0.04

  return, sqrt(err/n_elements(condIN))
END 

  
FUNCTION fit_ch2Data, inputData
  h =inputData[1,*]
  cond=inputData[2,*]
  
  output=fltarr(6)
  minErr=1.0E38

;; hack to avoid too many loops 
  Ks=max(cond)
  Ts=0.4
  Tr=0.02

;; loop over reasonable values for b
  FOR psi_s=1.0,100,0.3 DO BEGIN
     FOR b=0.01,3, 0.003 DO BEGIN
        curErr=CHErr(b, psi_s, Ks, Ts, Tr, h, cond)
        IF curErr LT minErr THEN BEGIN 
           minErr=curErr
           output=[b, psi_s, Ks, Ts, Tr, minErr]
        ENDIF
     ENDFOR
     FOR b=3.01,100, 0.03 DO BEGIN
        curErr=CHErr(b, psi_s, Ks, Ts, Tr, h, cond)
        IF curErr LT minErr THEN BEGIN 
           minErr=curErr
           output=[b, psi_s, Ks, Ts, Tr, minErr]
        ENDIF
     ENDFOR
  ENDFOR
  return, output  
END

;; read the h-conductivity relationship
function getRecord, un
  if eof(un) then return, -1

  line=""
  ;; read initial data line
  readf, un, line
  curData=float(strsplit(line, ',', /extract))
  IF n_elements(curData) EQ 1 THEN curData=float(strsplit(line, /extract))

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
     curData=float(strsplit(line,',',/extract))
     IF n_elements(curData) EQ 1 THEN curData=float(strsplit(line, /extract))
  ENDWHILE

  IF n_elements(data[0,*]) LT 4 THEN return, -1
  Data=Data[*,1:*]
  ;; point back to where we were before we hit the wrong record
  if not eof(un) then  point_lun, un, pos

  return, Data
end

;; duh, probably doesn't need it's own procedure
PRO writeData, unit, vg, ch, index, testValue=testValue
  IF keyword_set(testValue) THEN BEGIN
    printf, unit, vg, ch, index, testValue, format='(13F10.3,I6, I4)'
 ENDIF ELSE printf, unit, vg, ch, index, format='(13F10.3,I6)'
END



PRO fitHKcurves, infile, outfile, test=test
;  data=getData(infile)
  openr, un, /get, infile
  openw, oun, /get, outfile
  i=0
  IF keyword_set(test) THEN TestValue=0

  window, 1, xs=1000, ys=500
  !p.multi=[0,2,1]
  WHILE NOT eof(un) DO BEGIN 
     data=getRecord(un)
     IF data[0] NE -1 THEN BEGIN 
        
        vgFit = fit_VG2Data(data)
        chFit = fit_CH2Data(data)
        print, ""
        print, ""
        print, data[0,0], ++i,  1.0/(vgFit[0]-1.0), chFit[0], $
               vgfit[1], chfit[1], vgFit[5], chFit[5]
        print, ""

        IF data[1,0] GT 0 AND n_elements(data) GT 6 THEN BEGIN
           plot, data[1,*], data[2,*], /ylog, psym=1, $
                 title=string(vgFit[5])+string(chFit[5]), /xs, /ys
;           oplot, data[1,*], calcVGcurve(vgFit[0:4], h=data[1,*])
;           oplot, data[1,*], calcCHcurve(chFit[0:4], h=data[1,*]), l=2
           oplot, indgen(700), calcVGcurve(vgFit[0:4], /h)
           oplot, indgen(700), calcCHcurve(chFit[0:4], /h), l=2
           plot, data[1,*], data[2,*], psym=1, $
                 title=string(vgFit[5])+string(chFit[5]), /xs, /ys
           oplot, indgen(700), calcVGcurve(vgFit[0:4], /h)
           oplot, indgen(700), calcCHcurve(chFit[0:4], /h), l=2
        endIF
        IF keyword_set(test) THEN $
          read, "Enter Quality (1-5) : ", TestValue

        writeData, oun, vgfit, chfit, data[0,0], testValue=testValue
;        wait, 1
     endIF ;ELSE print, "Error : ", ++i
  end

  close, un, oun
  free_lun, un, oun
END
