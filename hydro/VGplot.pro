PRO vgplot, data, plotk=plotk, plottheta=plottheta, line=line, color=color

  hmin=0.000001
  hmax=400
  hstep=0.1
  hsz=4001

  ks=0
  tr=1
  ts=2
  a=3
  n=4

  x=indgen(hsz)*hstep

  IF keyword_set(plotK) THEN BEGIN 
     v=data
     m=(1-(1/v[n]))
     i=0
     k=fltarr(hsz)
     FOR h=hmin,hmax,hstep DO BEGIN
        K[i]=v[ks] * (( 1- ((v[a]*h)^(v[n]*m)) * ((1+(v[a]*h)^v[n])^(-1*m)))^2)/ $
             ((1+(v[a]*h)^v[n])^(0.5*m))
        i=i+1
     ENDFOR
     
     k=k/24.                    ; (convert cm/d -> cm/hr)
;; the real plotting functions
     plot, x, k, /ylog, yr=[0.00001,100], ytitle='Conductivity (cm/hr)', $
           title='Hydrologic Conductivity Curves', $
;for a range of sands, and a loam', $
           xtitle='Suction Head (cm)', /noerase, color=color, line=line
;  oplot, x,k
  ENDIF 

  IF keyword_set(plottheta) THEN BEGIN
     i=0
     v=data
     m=(1-(1/v[n]))
     theta=fltarr(hsz)
     FOR h=hmin, hmax, hstep DO BEGIN
        theta[i]=v[tr] + (v[ts]-v[tr])*(1+(v[a]*h)^v[n])^(m*(-1))
        i=i+1
     ENDFOR
     
;; the real plotting functions
     plot, x, theta, yr=[0,0.6], xtitle='Suction Head (cm)', $
           title='Suction Saturation Curves', linestyle=2, $
; for a sand and loam range and two field sites', $
           ytitle='Moisture Content (cm^3/cm^3)', /noerase
;  oplot, x, theta
  ENDIF

;     xyouts, 345,0.24, 'Loam'
;    xyouts, 320,0.06, 'Sand'

end

