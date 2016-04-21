;; Calculates Noah SHPs (suc-sat, K, D)
;;
;;  Also reads input suc-sat data and finds the best fit (several routines)
;;
;;  Also plots the results from best fit data

FUNCTION noahSucSat, b, PSIs, SMCs, SMCr, n=n

  IF NOT keyword_set(n) THEN n=100
  dSMC=(SMCs-SMCr)/n
  theta=indgen(n)*dSMC + SMCr

  b1=b+1
  theta=reverse(theta)
  h=fltarr(n)
  h[0]=PSIs
  FOR i=1, n-1 DO $
     h[i] = h[i-1] + dSMC* 1./((SMCs/(b*PSIs)) * (theta[i]/SMCs)^(b1))

;  oplot, theta, h;, /ys, yr=[min(h), 0.4]
  return, [[h],[theta]]

END

FUNCTION noahK, theta, b, ts, ks=ks
  IF NOT keyword_set(ks) THEN ks=1.
  return, ks *(theta/ts)^((2.)*b+3.)
END

FUNCTION noahD, theta, b, ts, ds=ds
  IF NOT keyword_set(ds) THEN ds=1.
  return, ds *(theta/ts)^(b+2.)
END

;; Computes diffusivity given an array of
;;    suctionhead(h)  MoistureContent(theta)  conductivity(k)
FUNCTION data2D, data
  sz=n_elements(data[0,*])
  ; Moisture capacity = dtheta/dh 
  centralDiff=(data[1,0:sz-3]-data[1,2:sz-1]) $
             /(-1*(data[0,0:sz-3]-data[0,2:sz-1]))

  ; Diffusivity = Conductivity / Moisture Capacity (dtheta/dh)
  D=data[2,1:sz-2]/centralDiff
  return, D
END


PRO plotResultSHP, params, data, ink=ink, ind=ind, title=title
 ;; find theta and h
  results=noahSucSat(params[0],params[1],params[2],params[3])
  h=reverse(results[*,0])
  theta=reverse(results[*,1])
 ;; find k
  k=noahK(data[1,*], params[0], params[2], ks=ink)
  d=noahD(data[1,*], params[0], params[2], ds=ind)

;; set up the curve for Noah's default SHPs  
  defaultp=[4.74, 0.141, 0.434, 0.047]  ;initialize default SHPs
;; Find theta and h
  defaultres=noahSucSat(defaultp[0],defaultp[1],defaultp[2],defaultp[3]) 
  dtheta=reverse(defaultres[*,1])
  dh=reverse(defaultres[*,0])
;; Find k
  defaultk=noahK(data[1,*], defaultp[0], defaultp[2], ks=ink)
  defaultd=noahD(data[1,*], defaultp[0], defaultp[2], ds=ind)

;; we want to plot theta-h and theta-k side by side
;  !p.multi=[0,3,1]
  sz=n_elements(theta)
;; plot theta-h solid = fitted, dotted=default, stars=data
  plot, theta, h, /ylog, yr=[0.05,1E6],/ys, $
;        title="Suction Head vs Moisture Content", $
        title=title, $
        ytitle="Suction Head (kPa)", $
        xtitle="Moisture Content"
  oplot, [theta[0],theta[0]], [h[0], 1E7]
  oplot, [theta[sz-1],theta[sz-1]], [h[sz-1], 1E-7]
  oplot, data[1,*], data[0,*], psym=1
  oplot, dtheta, dh, line=1
  oplot, [dtheta[0],dtheta[0]], [dh[0], 1E7], l=1
  oplot, [dtheta[sz-1],dtheta[sz-1]], [dh[sz-1], 1E-7], l=1

;; plot theta-k solid = fitted, dotted=default, stars=data
  plot, data[1,*], k, /ylog, yr=[1E-20,1], $
;        title="Conductivity vs Moisture Content", $
        title=title, $
        xtitle="Moisture Content", $
        ytitle="Conductivity / Ks"
  oplot, data[1,*], data[2,*], psym=1
  oplot, data[1,*], defaultk, line=1

;; plot theta-k solid = fitted, dotted=default, stars=data
  plot, data[1,*], d, /ylog, yr=[1E-11,1],/ys, $
;        title="Diffusivity vs Moisture Content", $
        title=title, $
        xtitle="Moisture Content", $
        ytitle="Diffusivity / Ds"
  oplot, data[1,1:n_elements(data[1,*])-2], data2d(data), psym=1
  oplot, data[1,*], defaultd, line=1


END

FUNCTION estParam, data
  sz=20.
  sz2=1.

  bmax=15.   &  bmin=0.0001  & bstep=0.01 
  pmax=0.
  b=(indgen(sz+1)/sz) * 13. + 0.0001
  psi=(indgen(sz+1)/sz) *0.8 +0.00001
  theta_r = indgen(sz2+1)/sz2*0.03 + 0.01
  theta_s = indgen(sz2+1)/sz2*0.03 + 0.41
  theta_r[*]=0.02
  theta_s[*]=0.425
  ndata=n_elements(data[0,*])
  err1=fltarr(ndata)

  thet=data[1,*]
  h=data[0,*]
  indices=[0,0,0,0]
  maxErr=1000000.
  maxKErr=maxErr
  maxDErr=maxErr
  maxTErr=maxErr
  n=100

  FOR i=0, sz-1 DO BEGIN
     FOR k=0, sz2-1 DO BEGIN 
        kshp=noahK(thet, b[i], theta_s[k])
        kerr=total(abs(alog10(kshp)-alog10(data[2,*])))*(8./25.)

        IF kerr LT maxKErr THEN BEGIN
           maxKErr=kerr
           kindex=[i,k]
        ENDIF 
        dshp=noahD(thet, b[i], theta_s[k])
        derr=total(abs(alog10(dshp[1:ndata-2])-alog10(data2d(data))))*(16./25.)
;        print, derr
        IF derr LT maxDErr THEN BEGIN
           maxDErr=derr
           dindex=[i,k]
        ENDIF 
        FOR j=0, sz-1 DO BEGIN
           FOR l=0, sz2-1 DO BEGIN
              shp=noahSucSat(b[i], psi[j], theta_s[k], theta_r[l], n=n)
              tdex=99-round(n*(thet - theta_r[l])/(theta_s[k]-theta_r[l]))
              tmpdex=where(tdex LT 0)
              IF tmpdex[0] NE -1 THEN tdex[tmpdex]=0
              err1=abs(alog10(transpose((shp[tdex,0])))-(alog10(h)))
              err2= abs(thet-theta_r[l])*20  
;*20 normalizes the two differences because roughly 2 orders of
; magnitude change in h is equivilant to 0.1 change in SMC (first order)
;              err=total(min([err1, err2], dimension=1))
              err=total(err1)
              IF err LT maxErr THEN BEGIN
                 maxErr=err
                 indices=[i,j,k,l]
;                 print, indices, maxErr
              ENDIF 
              totErr = derr + kerr
              IF totErr LT maxTErr THEN BEGIN
                 tindices=[i,j,k,l]
                 maxTErr=totErr
                 print, b[tindices[0]], psi[tindices[1]], $
                        theta_s[tindices[2]], theta_r[tindices[3]], maxTErr
                 plotresultSHP, [ b[tindices[0]], psi[tindices[1]], $
                        theta_s[tindices[2]], theta_r[tindices[3]]], data
              ENDIF

           ENDFOR
        ENDFOR
     ENDFOR
  ENDFOR

  print, ""
  print, dindex
  print, "D-Beta=", strcompress(b[dindex[0]]), $
         "  D-Theta_s=",strcompress(theta_s[dindex[1]])
  print, "D-Error = ", maxDErr

  print, ""
  print, kindex
  print, "K-Beta=", strcompress(b[kindex[0]]), $
         "  K-Theta_s=",strcompress(theta_s[kindex[1]])
  print, "K-Error = ", maxKErr
  print, ""
  print, indices
  print, "b=", strcompress(b[indices[0]]), $
         "  psi=",strcompress(psi[indices[1]]), $
         "  Theta_s=", strcompress(theta_s[indices[2]]), $
         "  Theta_r=", strcompress(theta_r[indices[3]])
  print, "Error = ",maxErr

  print, ""
  print, "Best of Both Worlds"
  print, tindices
  print, "b=", strcompress(b[tindices[0]]), $
         "  psi=",strcompress(psi[tindices[1]]), $
         "  Theta_s=", strcompress(theta_s[tindices[2]]), $
         "  Theta_r=", strcompress(theta_r[tindices[3]])
  print, "Error = ",maxTErr

  return, $
         [[b[tindices[0]], psi[tindices[1]], theta_s[tindices[2]], theta_r[tindices[3]]],$
          [b[indices[0]], psi[indices[1]], theta_s[indices[2]], theta_r[indices[3]]], $
          [b[kindex[0]], psi[indices[1]], theta_s[kindex[1]], theta_r[tindices[3]]], $
          [b[dindex[0]], psi[indices[1]], theta_s[dindex[1]], theta_r[tindices[3]]]]

END 

;; Just find the best B value to fit only the diffusivity term
FUNCTION bestD, data, smcS=smcS, smcR=smcR, psi=psi
  IF NOT keyword_set(smcS) THEN smcS = 0.43
  IF NOT keyword_set(smcR) THEN smcR = 0.02
  IF NOT keyword_set(psi) THEN psi  = 0.7

  D=data2D(data)
  theta=data[1,1:n_elements(D)]

  maxErr=10000.
  FOR B=1.,20,0.1 DO BEGIN 
     dshp=noahD(theta, B, smcS)
     err=total(abs(alog10(D) - alog10(dshp)))
     IF err LT maxErr THEN BEGIN 
        output=B
        maxErr=err
     ENDIF 
  ENDFOR 
  return, [output, psi, smcS, smcR]
END

;; Just find the best B value to fit only the conductivity term
FUNCTION bestK, data, smcS=smcS, smcR=smcR, psi=psi
  IF NOT keyword_set(smcS) THEN smcS = 0.43
  IF NOT keyword_set(smcR) THEN smcR = 0.02
  IF NOT keyword_set(psi) THEN psi  = 0.7

  k=data[2,*]
  theta=data[1,*]
  maxErr=10000.
  FOR B=1.,20,0.1 DO BEGIN 
     kshp=noahk(theta, B, smcS)
     err=total(abs(alog10(k) - alog10(kshp)))
     IF err LT maxErr THEN BEGIN 
        output=B
        maxErr=err
     ENDIF 
  ENDFOR 
  return, [output, psi, smcS, smcR]
END

;; Find the best B value to fit both the conductivity and diffusivity terms
FUNCTION bestB, data, smcS=smcS, smcR=smcR, psi=psi
  IF NOT keyword_set(smcS) THEN smcS = 0.43
  IF NOT keyword_set(smcR) THEN smcR = 0.02
  IF NOT keyword_set(psi)  THEN psi  = 0.1

  k=data[2,*]
  theta=data[1,*]
  D=data2D(data)
  Dtheta=data[1,1:n_elements(D)]

  maxErr=10000.
  FOR B=1.,15,0.01 DO BEGIN 
     dshp=noahD(theta, B, smcS)
     err1=total(abs(alog10(D) - alog10(dshp)))*2

     kshp=noahk(theta, B, smcS)
     err2=total(abs(alog10(k) - alog10(kshp)))

     IF (err1+err2) LT maxErr THEN BEGIN 
        output=B
        maxErr=err1+err2
     ENDIF 
  ENDFOR 
  return, [output, psi, smcS, smcR]
END

;; Just find the best B value to fit only the conductivity term
FUNCTION bestH, data, smcS=smcS, smcR=smcR, B=B
  IF NOT keyword_set(B) THEN B = 5
  IF NOT keyword_set(smcS) THEN smcS = 0.43
  IF NOT keyword_set(smcR) THEN smcR = 0.02


  h=data[0,*]
  theta=data[1,*]
  maxErr=10000.
  n=100
  FOR psi=0.0001,1,0.001 DO BEGIN 

     shp=noahSucSat(B, psi, smcS, smcR, n=n)

     tdex=(n-1)-round(n*(theta - smcR)/(smcS-smcR))
     tmpdex=where(tdex LT 0)
     IF tmpdex[0] NE -1 THEN tdex[tmpdex]=0

     t1=alog10((shp[transpose(tdex),0]))
     t2=alog10(h)
     err=total(abs(t1-t2))

     IF err LT maxErr THEN BEGIN 
        output=psi
        maxErr=err
     ENDIF 
  ENDFOR 
  return, [B, output, smcS, smcR]
END


PRO plotResults, data, params, ks=ks

  estimate = noahSucSat(params[0], params[1], params[2], params[3])
  plot, data[1,*], data[0,*], /ylog, psym=2
  oplot, [estimate[*,1],[params[3]]], [estimate[*,0],[1000000]]

  plot, data[1,*], data[2,*], /xlog, /ylog, psym=2
  oplot, data[1,*], noahk(data[1,*], params[0], params[2], ks=ks)
END
