; plots SHP curves given all the input values
pro plotSHP, theta, claytheta, saloamtheta, $
             head, clayh, saloamh, $
             allk, clayk, saloamk, $
             ks, clayks, saloamks, $
             d, clayd, saloamd, $
             pause=pause, title=title

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   PLOTTING ROUTINES
;;
; if we are plotting to the screen a delay between plots can be helpful
if not keyword_set(pause) then pause=0

;plot clay theta vs k
  plot, claytheta, clayk, $;yr=[0.00001,30], /ylog, $
    /ylog, xr=[0,0.5], /ys, /xs, yr=[10.^(-20),10.^(-4)], $
    title='NOAH Sand,Clay,Sa.Loam  :   Moisture Content vs K', $
    xtitle='Moisture Content', ytitle='Conductivity (cm/s)'
;plot sand theta vs k
  oplot, theta, allk, line=1
;plot sand loam theta vs k
  oplot, saloamtheta, saloamk, line=2
  oplot, claytheta, clayk, line=3

wait, pause

; plot clay theta vs relative K
  plot, claytheta, clayk/clayKs, $
    yr=[-0.1,1.1], /ys, xr=[0,0.5], $
    title='NOAH Sand(r),Clay(b),Sa.Loam(g)  :   Moisture Content vs K/Ks', $
    xtitle='Moisture Content', ytitle='Relative Conductivity (% Ksat)'
; plot sand theta vs relative K
  oplot, theta, allk/KS, line=1
; plot sand laom theta vs relative K
  oplot, saloamtheta, saloamk/saloamKS, line=2
  oplot, claytheta, clayk/clayKS, line=3

wait, pause
;plot clay head vs K
  plot, head, clayk, /ylog, yr=[10.^(-20), 0.1], /ys, $
;    xr=[-10,500],/xs, /ylog, yr=[0.000001,26], $
    xr=[-100,1000], /xs, $
    title='NOAH Sand,Clay,Sa.Loam  :   Head vs K', $
    xtitle='Suction Head (cm)', ytitle='Conductivity (cm/s)'
;plot sand head vs K
  oplot, head, allk, line=1
;plot sand loam head vs K
  oplot, saloamh, saloamk, line=2
  oplot, head, clayk, line=3

wait, pause
;plot clay head vs Diffusivity
  plot, head, clayd, /ylog, $
;    xr=[0,150], /xs, yr=[0.01,5000], /ylog, $
    xr=[-100,1000], /xs, $
    yr=[10.^(-15), 10.^(-4)], /ys, $
    title='NOAH Sand,Clay,Sa.Loam  :   Head vs Diffusivity', $
    xtitle='Suction Head (cm)', ytitle='Diffusivity (1/s)'
;plot sand head vs Diffusivity
  oplot, head, d, line=1
;plot sand loam head vs Diffusivity
  oplot, saloamh, saloamd, line=2
  oplot, head, clayd, line=3

wait, pause
;plot clay theta vs Diffusivity
  plot, claytheta, clayk, $
    xr=[0,0.5], $
    title='NOAH Sand,Clay,Sa.Loam  :   Theta vs Diffusivity', $
    xtitle='Moisture Content', ytitle='Diffusivity (1/s)'
;plot sand theta vs Diffusivity
  oplot, theta, d, line=1
;plot sand loam theta vs Diffusivity
  oplot, saloamtheta, saloamd, line=2
  oplot, claytheta, clayk, line=3


wait, pause
;plot clay k vs Diffusivity
;  plot, clayk, clayd, $
;    xr=[0,0.5], $
;    title='NOAH Sand,Clay,Sa.Loam  :   K vs Diffusivity', $
;    xtitle='Conductivity (cm/s)', ytitle='Diffusivity (1/s)'
;plot sand k vs Diffusivity
;  oplot, allk, d, line=1
;plot sand loam k vs Diffusivity
;  oplot, saloamk, saloamd, line=2
;  oplot, clayk, clayd, line=3

wait, pause
; plot clay h vs theta
  plot, head, claytheta, $
    yr=[0.0,0.5], /ys, /xlog, xr=[0.001,8000],/xs, $
    title='NOAH Sand,Clay,Sa.Loam  :   Head vs Moisture Content',$
    xtitle='Suction Head (cm)', ytitle='Moisture Content'
; plot sand h vs theta
  oplot, head, theta, line=1
; plot sand loam h vs theta
  oplot, saloamh, saloamtheta, line=2
  oplot, head, claytheta, line=3
end
