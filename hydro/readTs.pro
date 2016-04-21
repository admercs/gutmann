;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Designed to read all Surface Temperature data from a series of files
;;   (probably tens of thousands).
;;
;; Files must be in the current directory.
;;   filenames must be out.TS.TR.KS.BB  where
;;      TS = the index into the Theta_sat range
;;      TR = the index into the Theta_resid range
;;      KS = the index into the K_sat range
;;      BB = the index into the beta exponent range
;;   Files must be column formated with Surface Temperature in the third column
;;
;; Returns a 600xnxnxnxn array of surface temperatures where n=NFILES^0.25
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readTs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; find all files
  filelist=file_search('out.*')
;; find the number of iterations in each parameter (breaks if all parameters don't
;;   have the same number of iterations.  )
  DataSZ=round(n_elements(filelist)^0.25)
;  print, DataSZ
;; setup our output array
  Data=fltarr(600, DataSZ, DataSZ, DataSZ, DataSZ)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FOR ALL FILES
  FOR i=0, n_elements(filelist)-1 DO BEGIN
;; read the current input file
     junk=load_cols(filelist[i], tmpDat)

     IF i MOD (n_elements(filelist)/1000.) EQ 0 THEN print, 100.*i/n_elements(filelist)
;; find the proper indices from the input filename
     file=strsplit(filelist[i], '.', /extract)
     ts=fix(file[1])
     tr=fix(file[2])
     ks=fix(file[3])
     bb=fix(file[4])
     
;; store the data
     Data[*, ts,tr,ks,bb]=transpose(tmpDat[2,0:599])

  ENDFOR

  return, Data
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION read1Var, srch=srch, varCol=varCol, ErrRef=ErrRef, nthVar=nthVar
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  if not keyword_set(srch) then srch="fort.*"
  if not keyword_set(varCol) then varCol=2
  if not keyword_set(ErrRef) then ErrRef=0
  if not keyword_set(nthVar) then nthVar=1
;; find all files
  filelist=file_search(srch)
;; find the number of iterations in each parameter (breaks if all parameters don't
;;   have the same number of iterations.  )
  DataSZ=n_elements(filelist)
;  print, DataSZ
;; setup our output array
  Data=fltarr(600, DataSZ)
	err=fltarr(DataSZ)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FOR ALL FILES
	junk=load_cols(filelist[ErrRef], tmpDat)
	Data[*,ErrRef]=transpose(tmpDat[varCol,0:599])
	start=fix((strsplit(filelist[0], '.', /extract))[nthVar])

  FOR i=0, n_elements(filelist)-1 DO BEGIN
;; read the current input file
     junk=load_cols(filelist[i], tmpDat)

;     IF i MOD (n_elements(filelist)/10.) EQ 0 THEN print, 100.*i/n_elements(filelist)
;; find the proper indices from the input filename
     file=strsplit(filelist[i], '.', /extract)
     index=fix(file[nthVar]);-start
     err[index]= max(abs(Data[*,ErrRef]-tmpDat[varCol,0:599]))
;; store the data
     Data[*, index]=transpose(tmpDat[varCol,0:599])

  ENDFOR

  return, {Data:Data, Err:Err}
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Returns a 2xN array.
;; The first column is the lowest index into the data array
;;   that yields a temperature difference greater than maxErr,
;; the second column is the highest,  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION SHP_accuracy, data, maxErr, midday=midday, satellite=satellite
  IF n_elements(maxErr) EQ 0 THEN maxErr=1  ;default to 1degree error
  IF keyword_set(midday) THEN BEGIN
     time=(indgen(n_elements(data[*,0])) MOD 48)/2.0
     index=where(time GE 10 AND time LT 14)
  endIF ELSE IF keyword_set(satellite) THEN BEGIN
     time=(indgen(n_elements(data[*,0])) MOD 48)/2.0
     index=where(time EQ 11)
  endIF ELSE index=indgen(n_elements(data[*,0]))

  sz=size(data)

  acc=fltarr(2,sz[2])
  err=fltarr(sz[2])
  FOR i=0, sz[2]-1 DO BEGIN 
     FOR j=0,sz[2]-1 DO BEGIN
        err[j]=max(abs(data[index,i]-data[index,j]))
     ENDFOR 
     dex=where(err LE 1, count)
     IF count EQ 0 THEN acc[*,i]=[0,sz[2]]
     acc[0,i]=dex[0]
     acc[1,i]=dex[count-1]

  ENDFOR

  return, acc

END

PRO plotSHP_acc, acc, bb=bb, ts=ts, tr=tr, ks=ks, shpdex=shpdex
  IF keyword_set(ts) OR shpdex EQ 0 THEN BEGIN
     shpmax=0.5
     shpmin=0.3
     axisTitle="Saturated Moisture Content"
  ENDIF 
  IF keyword_set(tr) OR shpdex EQ 1  THEN BEGIN
     shpmax=0.16
     shpmin=0.01
     axisTitle="Residual Moisture Content"
  ENDIF 
  IF keyword_set(bb)  OR shpdex EQ 2 THEN BEGIN
     shpmax=15.
     shpmin=1
     axisTitle="Beta exponent"
  ENDIF 
  IF keyword_set(ks)  OR shpdex EQ 3 THEN BEGIN
     shpmax=1.0E-3
     shpmin=1.0E-7
     ylog=1
     axisTitle="Saturated Conductivity"
  ENDIF 

  title="Accuracy range for SHP determiniation"
  shprange=shpmax-shpmin
  nshp=float(n_elements(acc[0,*]))

  accplot=(acc/nshp)*shprange +shpmin
  shp=(indgen(nshp)/nshp) *shprange +shpmin
  
  plot, shp, accplot[0,*], $
        yr=[shpmin,shpmax], ylog=ylog, xlog=ylog, $
        title=title, xtitle=axisTitle, ytitle=axisTitle
  oplot, shp, accplot[1,*]
END 

PRO plotall
  dirs=["TSruns", "TRruns", "BBruns", "KSruns"]
  FOR i=0, 3 DO BEGIN
     data=read1Var(srch=dirs[i]+"/fort.*")
     acc=shp_accuracy(data.data)
     plotSHP_acc, acc, shp=i
  ENDFOR

END 
