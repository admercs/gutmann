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
FUNCTION calcVGtheta, params, curH
  n=params[0]
  alpha=params[1]
  Ts=params[3]
  Tr=params[4]
  hIN=curH>0.0001

  m=(1-1.0/n)>1E-20
  curTheta=(1.0+(alpha*hIN)^n)^(-1.0*m)*(Ts-Tr)+Tr
  return, curTheta
END

;; Finds the rms error between a set of data points and the van Genuchten
;;  curve specified by the given parameters
FUNCTION VGErr, alpha, n, Ks, Ts, Tr, hIN, thetaIN

  m=(1-1.0/n)>1E-20

  curTheta=(1.0+(alpha*hIN)^n)^(-1.0*m)*(Ts-Tr)+Tr

  err=total((thetaIN-curTheta)^2)

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

  return, sqrt(err/n_elements(thetaIN))
END 

  
FUNCTION fit_vg2Data, inputData
  h =inputData[1,*]
  theta=inputData[2,*]

  output=fltarr(6)
  minErr=1.0E38

;; hack to avoid too many loops 
;  Ks=max(cond)
  Ks=1.0
  Ts=max(theta)
  Tr=min(theta)


;; loop over reasonable values for n
  FOR a=0.001,0.3,0.0003 DO BEGIN
     FOR n=1.01,3, 0.003 DO BEGIN
        curErr=VGErr(a, n, Ks, Ts, Tr, h, theta)
        IF curErr LT minErr THEN BEGIN 
           minErr=curErr
           output=[n, a, Ks, Ts, Tr, minErr]
        ENDIF
     ENDFOR
     FOR n=3.0,15, 0.03 DO BEGIN
        curErr=VGErr(a, n, Ks, Ts, Tr, h, theta)
        IF curErr LT minErr THEN BEGIN 
           minErr=curErr
           output=[n, a, Ks, Ts, Tr, minErr]
        ENDIF
     ENDFOR
  ENDFOR 
  return, output  
END

FUNCTION calcCHtheta, params, curH
  b=params[0]
  psis=params[1]
  Ts=params[3]
  hIN=curH>0.0001
  curTheta=(Ts*(psis/hIN)^(1.0/b))<Ts
  return, curTheta
END

;; Finds the rms error between a set of data points and the van Genuchten
;;  curve specified by the given parameters
FUNCTION CHErr, b, psis, Ks, Ts, Tr, hIN, thetaIN


  dex=where(hIN EQ 0)
  IF dex[0] NE -1 THEN hIN[0] = 1E-10
  curTheta=(Ts*(psis/hIN)^(1.0/b))<Ts
  err=total((thetaIN-curTheta)^2)


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
;  plot, hIN, curTheta
;  oplot, hIN, thetaIN, psym=1
;  wait, 0.1
  return, sqrt(err/n_elements(thetaIN))
END 

  
FUNCTION fit_ch2Data, inputData
  h =inputData[1,*]
  theta=inputData[2,*]
  
  output=fltarr(6)
  minErr=1.0E38

;; hack to avoid too many loops 
  ks=1.0
;  Ks=max(cond)
  Ts=max(theta)
  Tr=min(theta)

;; loop over reasonable values for b
  FOR psi_s=1.0,100,0.3 DO BEGIN
     FOR b=0.01,3, 0.003 DO BEGIN
        curErr=CHErr(b, psi_s, Ks, Ts, Tr, h, theta)
        IF curErr LT minErr THEN BEGIN 
           minErr=curErr
           output=[b, psi_s, Ks, Ts, Tr, minErr]
        ENDIF
     ENDFOR
     FOR b=3.0,50, 0.03 DO BEGIN
        curErr=CHErr(b, psi_s, Ks, Ts, Tr, h, theta)
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
PRO writeData, unit, vg, ch, index, TestValue=TestValue
  IF keyword_set(TestValue) THEN BEGIN
     printf, unit, vg, ch, TestValue, index, format='(13F12.5,I4,I6)'
  ENDIF ELSE $
    printf, unit, vg, ch, index, format='(13F12.5,I6)'
END



PRO fitHTcurves, infile, outfile, test=test
;  data=getData(infile)
  openr, un, /get, infile
  openw, oun, /get, outfile
  i=0
  IF keyword_set(test) THEN TestValue=0

  window, 1, xs=1000, ys=500
  !p.multi=[0,2,1]
  tempHead=[long(indgen(100)),100+indgen(100)*10, $
            1000+indgen(10)*1000, 10000+indgen(10)*10000l]

  WHILE NOT eof(un) DO BEGIN 
     data=getRecord(un)
     IF data[0] NE -1 THEN BEGIN 
;        wset, 1
;        plot, data[1,2:*], alog10(data[2,2:*])/20.
        
        vgFit = fit_VG2Data(data)
        chFit = fit_CH2Data(data)
        print, ""
        print, ""
        print, data[0,0], ++i,  1.0/(vgFit[0]-1.0), chFit[0], $
               vgfit[1], chfit[1], vgFit[5], chFit[5]

        print, vgFit
        print, chFit
        print, ""
;        data=data[*,2:*]
;        wset, 1
        data[1,*]=data[1,*]>0.001
        print, n_elements(data[1,*])
        IF n_elements(data) GT 9 THEN BEGIN
           plot, data[1,*], data[2,*], psym=2, symsize=3, $
                 title=string(vgFit[5])+string(chFit[5]), /xs, /ys
;           oplot, data[1,*], calcVGcurve(vgFit[0:4], h=data[1,*])
;           oplot, data[1,*], calcCHcurve(chFit[0:4], h=data[1,*]), l=2
;           dex=sort(data[1,*])
;           oplot, data[1,dex], calcVGtheta(vgFit[0:4], data[1,dex])
;           oplot, data[1,dex], calcCHtheta(chFit[0:4], data[1,dex]), l=2
           oplot, tempHead, calcVGtheta(vgFit[0:4], tempHead)
           oplot, tempHead, calcCHtheta(chFit[0:4], tempHead), l=2
           plot, data[1,*], data[2,*], /xlog, psym=2, symsize=3, $
                 title=string(vgFit[5])+string(chFit[5]), /xs, /ys
           oplot, tempHead, calcVGtheta(vgFit[0:4], tempHead)
           oplot, tempHead, calcCHtheta(chFit[0:4], tempHead), l=2
           wait, 0.01
           IF keyword_set(test) THEN BEGIN 
              read, "Enter Quality (1-5) : ", TestValue
           ENDIF
        endIF
        writeData, oun, vgfit, chfit, data[0,0], TestValue=TestValue
     endIF ;ELSE print, "Error : ", ++i
  end

  close, un, oun
  free_lun, un, oun
END
