;+
; NAME: compHT2HK
;
; PURPOSE:
;   Uses MOSCEM SHP parameters fit to head-theta data and evaluates
;   the fit to head-conductivity data.  
;
;
; CALLING SEQUENCE: compHT2HK, moscemPattern, H_Kdatafile, outfile
;
;
; INPUTS : 
;      moscemPattern = search string for the moscem output files
;      H_Kdatafile   = filename for h-k data
;      outfile       = base filename output files (data and postscript)
;
; KEYWORDS :
;      vg=vg   set this if you want to use the van Genuchten equations
;              this is also the default
;      cambell=cambell  set this if you want to use the Cambell equations
;
;
; OUTPUTS : data file and postscript plots
;   r^2 fit values for each soil are written to a data file
;   plots of h-k data points with the h-t fit line plotted through them
;
;
; PROCEDURE:
;
;
;
;
; NOTE : Cambell and CH (clapp-hornberger) names are used interchangeably for
;   legacy reasons, CH is INCORRECT.
;   
;
; MODIFICATION HISTORY:
;   Original 7/19/2004 EDG  Original
;            7/26/2004 EDG  Added vg and cambell keywords
;
;-
;


;; NOT CURRENTLY USED
;; 
;; findMinErr : return the distance between a given x,y point and a curve
;; This actually computes the distance squared between all points
;;  and returns the minimum.
;;
;; NOT CURRENTLY USED
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

;; The following is code that can be used to compute the root mean square
;;   of the ABSOLUTE distance between data points and the line instead of
;;   only the error in the y direction.  
;
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
FUNCTION VGErr, alpha, n, Ks, Ts, Tr, hIN, condIN, plot=plot

  m=(1-double(1.0)/n)>1E-20

  Sat=(1.0+double(alpha*hIN)^n)^(-1.0*m)


  curCond=(Ks * (Sat^0.5) * (1.0-((1.0-(Sat^(double(1.0)/m)))^m))^2.)

  IF keyword_set(plot) THEN BEGIN
     plot, hIN, condIN, psym=1, /ylog
     oplot, hIN, curCond
  ENDIF

  dex=where(curCond GT 0.000001)
  IF dex[0] EQ -1 THEN BEGIN
;     print, [hIN, condIN, curCond], format='(3F30.24)'
     return, [999.9,0.0]
  ENDIF

  curCond=alog10(curCond[dex])>(-1.0E10)
  err=sqrt(mean(((ALOG10(condIN[dex])>(-1.0E10))-curCond)^2))
  r=1.0-((err^2)/(mean((ALOG10(condIN[dex])-mean(ALOG10(condIN[dex])))^2)))

  return, [err,r]
END 

;; FOR THE CAMBELL SHP MODEL
;; estimate Ks based on the conductivity at some head value and the
;; SHP model parameters
FUNCTION getCambellKS, psis, b, Ts, Tr, h, cond
  IF h EQ 0 THEN return, cond
  IF b EQ 0 THEN b=0.00001

  ;; assume ks=1.0
  relCond=(psis/h)^(2+3.0/b)

  ;; cond is now a fraction of ks so we return, cond/relCond to get Ks
  return, float(cond/relCond)<1.0E10

END

;; estimate Ks based on the conductivity at some head value and the
;; SHP model parameters
FUNCTION getKS, alpha, n, Ts, Tr, h, cond, vg=vg
  IF h EQ 0 THEN return, cond

  IF NOT keyword_set(vg) THEN return, getCambellKS(alpha, n, Ts, Tr, h, cond)
  
  m=(1-double(1.0)/n)>1E-20

  Sat=(1.0+double(alpha*h)^n)^(-1.0*m)

  ;; assume ks=1.0
  relCond=(Sat^0.5) * (1.0-((1.0-(Sat^(double(1.0)/m)))^m))^2.

  ;; cond is now a fraction of ks so we return, cond/relCond to get Ks

  return, float(cond/relCond)<1.0E10

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
FUNCTION CHErr, psis, b, Ks, Ts, Tr, hIN, condIN, plot=plot

  IF b EQ 0 THEN b=0.00001

  curCond=(Ks * (psis/hIN)^(2.0+(3.0/b)))<Ks

  IF keyword_set(plot) THEN BEGIN
     plot, hIN, condIN, psym=1, /ylog
     oplot, hIN, curCond
  ENDIF

  dex=where(curCond GT 0.000001)
  IF dex[0] EQ -1 THEN BEGIN
;     print, [hIN, condIN, curCond], format='(3F30.24)'
     return, 999.9
  ENDIF
  
  curCond=alog10(curCond[dex])>(-1.0E10)
  err=sqrt(mean((ALOG10(condIN[dex])>(-1.0E10)-curCond)^2))
  r=1.0-((err^2)/(mean((ALOG10(condIN[dex])-mean(ALOG10(condIN[dex])))^2)))
  return, [err,r]
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

PRO usage
  print, "compHT2HK, moscemPattern, H_Kdatafile, outfile"
  print, " "
  print, "  type 0 to continue with the default parameters"
  print, "     moscemPattern=output/shpfit/par_shpfit_*.00.out"
  print, "     H_Kdatafile=lab_drying_h-k.txt"
  print, "     outfile=hthkFitFile"
  print, ""
  print, "  type 1 to quit"
  read, i
  IF i EQ 1 THEN retall
END

FUNCTION matchRecord, inputfile, un
;; find the current record number that we are searching for
  recnum=strsplit(inputfile, /extract, '_')
  recnum=(strsplit(recnum[2], /extract, '.'))[0]

;; save the current location so we can get back to it if
;; we didn't find any valid records
  point_lun, -1*un, location

;; get the next data record in the H_K file
  data=getRecord(un)

  WHILE data[0] LT recnum AND NOT eof(un) do data=getRecord(un)

  IF data[0] GT recnum OR eof(un) THEN point_lun, un, location ELSE $
    return, data

  return, -1
END

PRO compHT2HK, moscemPattern, H_Kdatafile, outfile, htfile, $
               vg=vg, cambell=cambell, plot=plot

  IF keyword_set(plot) THEN window, 1, xs=1000,ys=1000
  IF NOT keyword_set(cambell) THEN vg=1

  IF n_elements(moscemPattern) EQ 0 THEN BEGIN
     usage
     moscemPattern="output/shpfit/par_shpfit_*.00.out"
  ENDIF
  IF n_elements(H_Kdatafile) EQ 0 THEN $
    H_Kdatafile="lab_drying_h-k.txt"

  IF n_elements(outfile) EQ 0 THEN $
    outfile="hkhtFitFile"


  openr, un, /get, H_Kdatafile
  openw, oun, /get, outfile
  printf, oun, "Soil Sample         HT_err       HK_R^2              HT_err       HT_R^2             b                  psi_s                 K_s         ThetaS       ThetaR"
  IF n_elements(htfile) GT 0 THEN BEGIN 
     openr, htun, /get, htfile
     IF keyword_set(plot) THEN window, 2, xs=1000,ys=1000
     usinght=1
  ENDIF
  htdata=-1
  hterr=0
  inputfiles=file_search(moscemPattern)
  FOR i=0, n_elements(inputfiles)-1 DO BEGIN
     junk=load_cols(inputfiles[i], params)
     params=params[*,0]
     
     htdata[0]=-1
     IF usinght THEN WHILE htdata[0] EQ -1 DO htdata=getRecord(htun)

     data=matchRecord(inputfiles[i], un)
     IF data[0] NE -1 THEN BEGIN
        
        dex=where(data[2,*] EQ max(data[2,*]))
        IF n_elements(dex) GT 1 THEN dex=where(data[1,*] EQ min(data[1,dex]))
        ks=getKs(params[2],params[1], $
                  params[4],params[5], data[1,dex[0]], data[2,dex[0]], vg=vg)
        IF keyword_set(vg) THEN BEGIN
           err=VGerr(params[2],params[1],ks, $
                     params[4],params[5], data[1,*], data[2,*], plot=plot)
           IF usinght THEN BEGIN 
              IF keyword_set(plot) THEN BEGIN
                 wset, 2
                 plot, htdata[1,*], htdata[2,*], psym=1, /xlog, xr=[1,10000]
                 oplot, [indgen(10)/10.0, indgen(10),indgen(1000)*10], $
                        calcVGtheta(params[1:5], $
                                    [indgen(10)/10.0, indgen(10),indgen(1000)*10])
                 wset, 1
              ENDIF
              
              hterr=sqrt(mean((htdata[2,*]-calcVGtheta(params[1:5], htdata[1,*]))^2))
              htr=1.0-((hterr^2)/mean((htdata[2,*]-mean(htdata[2,*]))^2))
           endIF

        endIF ELSE begin
           err=CHerr(params[2],params[1],ks, $
                     params[4],params[5], data[1,*], data[2,*], plot=plot)
           IF usinght THEN begin
              IF keyword_set(plot) THEN BEGIN
                 wset, 2
                 plot, htdata[1,*], htdata[2,*], psym=1, /xlog, xr=[1,10000]
                 oplot, [indgen(10)/10.0, indgen(10),indgen(1000)*10], $
                        calcCHtheta(params[1:5], $
                                    [indgen(10)/10.0, indgen(10),indgen(1000)*10])
                 wset, 1
              ENDIF
              hterr=sqrt(mean((htdata[2,*]-calcCHtheta(params[1:5], htdata[1,*]))^2))
              htr=1.0-((hterr^2)/mean((htdata[2,*]-mean(htdata[2,*]))^2))
           endIF

        endelse


        params[3]=ks
        printf, oun, data[0], err, hterr, htr, params[1:5], $
                format='(I6,2(F20.4,F13.4),2F20.5, F20.4, 2F13.5)'
        print, data[0], err, hterr, htr, params[1:5], $
               format='(I6,2(F20.4,F13.4),2F20.5, F20.4, 2F13.5)'


        IF keyword_set(plot) THEN wait, 1
     endIF
  ENDFOR
  
  close, un, oun
  free_lun, oun, un
END

     
