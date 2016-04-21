PRO plotvg
  sand=[0.053, 0.375, 0.0352, 3.18, 26.78]
;  sandup=[0.029, 0.055, 0.0627, 4.808, 104.16]
;  sanddown=[0.029, 0.055, 0.0198, 2.099, 6.88]
  sandup=[0.029, 0.055, 0.0627, 4.808, 6.88]
  sanddown=[0.029, 0.055, 0.0198, 2.099, 104.16]
  silt=[0.050, 0.489, 0.0066, 1.68, 1.595]
  loam=[0.061, 0.399, 0.011, 1.47, 0.502]
  loamup=[0.073, 0.098, 0.0597, 1.77, 0.0604]
  loamdown=[0.073, 0.098, 0.00207, 1.091, 4.363]


  sandup[0:1]=sand[0:1]-sandup[0:1]
  sanddown[0:1]=sand[0:1]+sanddown[0:1]
  loamup[0:1]=loam[0:1]-loamup[0:1]
  loamdown[0:1]=loam[0:1]+loamdown[0:1]


  hmin=0.000001
  hmax=400
  hstep=0.1
  hsz=4001

  tr=0
  ts=1
  a=2
  n=3
  ks=4

  x=indgen(hsz)*hstep
  v=sand
  m=(1-(1/v[n]))
  i=0
  k=fltarr(hsz)
  FOR h=hmin,hmax,hstep DO BEGIN
     K[i]=v[ks] * (( 1- ((v[a]*h)^(v[n]*m)) * ((1+(v[a]*h)^v[n])^(-1*m)))^2)/ $
          ((1+(v[a]*h)^v[n])^(0.5*m))
     i=i+1
  ENDFOR
  sanddat=k

  v=sandup
  m=(1-(1/v[n]))
  i=0
  k=fltarr(hsz)
  FOR h=hmin,hmax,hstep DO BEGIN
     K[i]=v[ks] * (( 1- ((v[a]*h)^(v[n]*m)) * ((1+(v[a]*h)^v[n])^(-1*m)))^2)/ $
          ((1+(v[a]*h)^v[n])^(0.5*m))
     i=i+1
  ENDFOR
;  oplot, x, K
  sup=K

  v=sanddown
  m=(1-(1/v[n]))
  i=0
  k=fltarr(hsz)
  FOR h=hmin,hmax,hstep DO BEGIN
     K[i]=v[ks] * (( 1- ((v[a]*h)^(v[n]*m)) * ((1+(v[a]*h)^v[n])^(-1*m)))^2)/ $
          ((1+(v[a]*h)^v[n])^(0.5*m))
     i=i+1
  ENDFOR
;  oplot, x, K
  sdown=k

;  tvlct, [0,255,0], [0,0,255], [0,0,0]
;  index=where(sup LT 0.000001, count)
;  IF count NE 0 THEN sup(index) = 0.000001
;  polyfill, [x,reverse(x)], [sdown,reverse(sup)], color=1
;  plot, x, sup, /ylog, yr=[0.00001,100], /noerase
;  oplot, x, sdown, linestyle=2
;  oplot, x, save, thick=2

  v=silt
  m=(1-(1/v[n]))
  i=0
  k=fltarr(hsz)
  FOR h=hmin,hmax,hstep DO BEGIN
     K[i]=v[ks] * (( 1- ((v[a]*h)^(v[n]*m)) * ((1+(v[a]*h)^v[n])^(-1*m)))^2)/ $
          ((1+(v[a]*h)^v[n])^(0.5*m))
     i=i+1
  ENDFOR
;  oplot, x, K, linestyle=3

  v=loam
  m=(1-(1/v[n]))
  i=0
  k=fltarr(hsz)
  FOR h=hmin,hmax,hstep DO BEGIN
     K[i]=v[ks] * (( 1- ((v[a]*h)^(v[n]*m)) * ((1+(v[a]*h)^v[n])^(-1*m)))^2)/ $
          ((1+(v[a]*h)^v[n])^(0.5*m))
     i=i+1
  ENDFOR
;  oplot, x, K, color=2, thick=2
  loamdat=K

  v=loamdown
  m=(1-(1/v[n]))
  i=0
  k=fltarr(hsz)
  FOR h=hmin,hmax,hstep DO BEGIN
     K[i]=v[ks] * (( 1- ((v[a]*h)^(v[n]*m)) * ((1+(v[a]*h)^v[n])^(-1*m)))^2)/ $
          ((1+(v[a]*h)^v[n])^(0.5*m))
     i=i+1
  ENDFOR
;  oplot, x, K, linestyle=2, color=2;, thick=2
  ldown=K
  index=where(ldown LT 0.000001, count)
  IF count NE 0 THEN ldown(index) = 0.000001

  v=loamup
  m=(1-(1/v[n]))
  i=0
  k=fltarr(hsz)
  FOR h=hmin,hmax,hstep DO BEGIN
     K[i]=v[ks] * (( 1- ((v[a]*h)^(v[n]*m)) * ((1+(v[a]*h)^v[n])^(-1*m)))^2)/ $
          ((1+(v[a]*h)^v[n])^(0.5*m))
     i=i+1
  ENDFOR
;  oplot, x, K, linestyle=2, color=2;, thick=2
  lup=K
  index=where(lup LT 0.000001, count)
  IF count NE 0 THEN lup(index) = 0.000001


;; the real plotting functions
  plot, x, sanddat, /ylog, yr=[0.00001,100], ytitle='Conductivity (cm/hr)', $
        title='Hydrologic Conductivity Curves', $
;for a range of sands, and a loam', $
        xtitle='Suction Head (cm)'

  polyfill, [x,reverse(x)], [ldown,reverse(lup)], color=5
  plot, x, sanddat, /ylog, yr=[0.00001,100], /noerase, linestyle=2
;  oplot, x, sup, linestyle=2, color=3
;  oplot, x, sdown, linestyle=2, color=3
;  oplot, x, sanddat, color=3

  oplot, x, loamdat, color=2
  oplot, x, lup, color=2, linestyle=2
  oplot, x, ldown, color=2, linestyle=2

  xyouts, 320,2.*10.^(-4), 'Loam'
  xyouts, 200,10.^(-5), 'Sand'

  plot, x, sanddat, /ylog, yr=[0.00001, 100], /noerase
  oplot, x, sanddat, color=3

;wait, 5
;;;;;;;;;;;;;;;;;;;;;;;Finished with K vs H now plot suc-sat curve
  print, load_cols('wrc_data.txt', field)
  field[[1,3],*]=field[[1,3],*]*100. *100. ;(to convert to cm pressure)
  
  i=0
  v=sand
  m=(1-(1/v[n]))
  theta=fltarr(hsz)
  FOR h=hmin, hmax, hstep DO BEGIN
     theta[i]=v[tr] + (v[ts]-v[tr])*(1+(v[a]*h)^v[n])^(m*(-1))
     i=i+1
  ENDFOR
  sanddat=theta

  i=0
  v=sanddown
  m=(1-(1/v[n]))
  theta=fltarr(hsz)
  FOR h=hmin, hmax, hstep DO BEGIN
     theta[i]=v[tr] + (v[ts]-v[tr])*(1+(v[a]*h)^v[n])^(m*(-1))
     i=i+1
  ENDFOR
;  oplot, x, theta, linestyle=2
  sdown=theta

  i=0
  v=sandup
  m=(1-(1/v[n]))
  theta=fltarr(hsz)
  FOR h=hmin, hmax, hstep DO BEGIN
     theta[i]=v[tr] + (v[ts]-v[tr])*(1+(v[a]*h)^v[n])^(m*(-1))
     i=i+1
  ENDFOR
;  oplot, x, theta, linestyle=2
  sup=theta

  i=0
  v=loam
  m=(1-(1/v[n]))
  theta=fltarr(hsz)
  FOR h=hmin, hmax, hstep DO BEGIN
     theta[i]=v[tr] + (v[ts]-v[tr])*(1+(v[a]*h)^v[n])^(m*(-1))
     i=i+1
  ENDFOR
;  oplot, x, theta, color=2
  loamdat=theta
 
  i=0
  v=loamdown
  m=(1-(1/v[n]))
  theta=fltarr(hsz)
  FOR h=hmin, hmax, hstep DO BEGIN
     theta[i]=v[tr] + (v[ts]-v[tr])*(1+(v[a]*h)^v[n])^(m*(-1))
     i=i+1
  ENDFOR
;  oplot, x, theta, color=2, linestyle=2
  ldown=theta

  i=0
  v=loamup
  m=(1-(1/v[n]))
  theta=fltarr(hsz)
  FOR h=hmin, hmax, hstep DO BEGIN
     theta[i]=v[tr] + (v[ts]-v[tr])*(1+(v[a]*h)^v[n])^(m*(-1))
     i=i+1
  ENDFOR
  lup=theta

;; the real plotting functions

  plot, x, theta, yr=[0,0.6], xtitle='Suction Head (cm)', $
        title='Suction Saturation Curves', linestyle=2, $
; for a sand and loam range and two field sites', $
        ytitle='Moisture Content (cm^3/cm^3)'
  polyfill, [x,reverse(x)], [ldown,reverse(lup)], color=5
  plot, x, sanddat, yr=[0, 0.6], /noerase
;  oplot, x, sup, linestyle=2, color=3
;  oplot, x, sdown, linestyle=2, color=3
;  oplot, x, sanddat, color=3

  oplot, x, loamdat, color=2
  oplot, x, lup, color=2, linestyle=2
  oplot, x, ldown, color=2, linestyle=2

  oplot, field[1,*], field[0,*], linestyle=1
  oplot, field[3,*], field[2,*], linestyle=1

  xyouts, 345,0.24, 'Loam'
  xyouts, 320,0.06, 'Sand'
  xyouts, 285,0.19, 'Shrub'
  xyouts, 140,0.2, 'Grass'

  plot, x, sanddat, yr=[0, 0.6], /noerase
  oplot, x, sanddat, color=3
end

