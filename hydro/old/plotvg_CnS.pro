pro plotvg_CnS

  fact=1
  sz=30000/fact
  allk=fltarr(sz+1)
  theta=fltarr(sz+1)
; Clay parameters
  KS=0.615
  theta_s=0.459
  theta_r=0.098
  a=0.015
  n=1.25
  m=1-(1/n)

; Clay calculations
  FOR h=10.^(-50),30000,fact DO BEGIN
     allk[round(h/fact)]=KS*((1-(a*h)^(n*m)*(1+((a*h)^n))^(-1*m))^2/ $
                        (1+(a*h)^n)^m)
     theta[round(h/fact)]=theta_r+(theta_s-theta_r)*(1+(a*h)^n)^(-1*m)
  ENDFOR
  claytheta=theta
  clayk=allk
  clayKs=KS

; Sand parameters
  KS = 26.79
  theta_s=0.375
  theta_r=0.053
  a=0.035
  n=3.176
  m=1-(1/n)
; Sand calculations
  FOR h=10.^(-50),30000,fact DO BEGIN
     allk[(h/fact)]=KS*((1-(a*h)^(n*m)*(1+((a*h)^n))^(-1*m))^2/ $
                        (1+(a*h)^n)^m)
     theta[(h/fact)]=theta_r+(theta_s-theta_r)*(1+(a*h)^n)^(-1*m)
  ENDFOR

  head=indgen(sz)*fact

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   PLOTTING ROUTINES
;;

;plot clay theta vs k
  plot, claytheta, clayk, yr=[10.^(-10),50], /ylog, $
    xr=[0,0.5], /ys, /xs, line=1, $
    title='Van Genuchtan Sand(r),Clay(b)  :   Moisture Content vs K', $
    xtitle='Moisture Content', ytitle='Conductivity (cm/s)'
;plot sand theta vs k
  oplot, theta, allk, color=1
  oplot, claytheta, clayk, color=3


; plot clay theta vs relative K
  plot, claytheta, clayk/clayKs, line=1, $
    yr=[-0.1,1.1], /ys, xr=[0,0.5], $
    title='Van Genuchtan Sand(r),Clay(b)  :   Moisture Content vs K/Ks', $
    xtitle='Moisture Content', ytitle='Relative Conductivity (% Ksat)'
; plot sand theta vs relative K
  oplot, theta, allk/KS, color=1
  oplot, claytheta, clayk/clayKs, color=3


;plot clay head vs K
  plot, head, clayk, $
    line=1, xr=[-100,1000],/xs, /ylog, yr=[10.^(-15),50], /ys, $
    title='Van Genuchtan Sand(r),Clay(b)  :   Head vs K', $
    xtitle='Suction Head (cm)', ytitle='Conductivity (cm/s)'
;plot sand head vs K
  oplot, head, allk, color=1
  oplot, head, clayk, color=3

;plot clay head vs Diffusivity
  plot, head[0:sz-2], clayk[0:sz-2]/(claytheta[0:sz-2]-claytheta[1:sz-1]), $
    line=1, xr=[-100,1000], /xs, yr=[10.^(-8),100000], /ys, /ylog, $
    title='Van Genuchtan Sand(r),Clay(b)  :   Head vs Diffusivity', $
    xtitle='Suction Head (cm)', ytitle='Diffusivity (1/s)'
;plot sand head vs Diffusivity
  oplot, head[0:sz-1], allk[0:sz-2]/(theta[0:sz-2]-theta[1:sz-1]), color=1
  oplot, head[0:sz-2], clayk[0:sz-2]/(claytheta[0:sz-2]-claytheta[1:sz-1]), color=3

;plot clay theta vs Diffusivity
  plot, claytheta[0:sz-2], clayk[0:sz-2]/(claytheta[0:sz-2]-claytheta[1:sz-1]), $
    line=1, xr=[0,0.5], $
    title='Van Genuchtan Sand(r),Clay(b)  :   Theta vs Diffusivity', $
    xtitle='Moisture Content', ytitle='Diffusivity (1/s)'
;plot sand theta vs Diffusivity
  oplot, theta[0:sz-2], allk[0:sz-2]/(theta[0:sz-2]-theta[1:sz-1]), color=1
  oplot, claytheta[0:sz-2], clayk[0:sz-2]/(claytheta[0:sz-2]-claytheta[1:sz-1]), $
    color=3


;plot clay k vs Diffusivity
;  plot, clayk[0:sz-2], clayk[0:sz-2]/(claytheta[0:sz-2]-claytheta[1:sz-1]), $
;    line=1, xr=[0,0.5], $
;    title='Van Genuchtan Sand(r),Clay(b) : K vs Diffusivity', $
;    xtitle='Conductivity (cm/s)', ytitle='Diffusivity (1/s)'
;plot sand k vs Diffusivity
;  oplot, allk[0:sz-2], allk[0:sz-2]/(theta[0:sz-2]-theta[1:sz-1])

; plot clay h vs theta
  plot, head, claytheta, $
    line=1, yr=[0.0,0.5], /ys, /xlog, xr=[0.8,30000],/xs, $
   title='Van Genuchtan Sand(r),Clay(b)  :   Head vs Moisture Content',$
    xtitle='Suction Head (cm)', ytitle='Moisture Content'
; plot sand h vs theta
  oplot, head, theta, color=1
  oplot, head, claytheta, color=3
end
