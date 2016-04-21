PRO AGUnoahplots, basename1, basename2, nsoil, title=title

  IF n_elements(nsoil) EQ 0 THEN nsoil=8

  IF n_elements(basename1) gt 100 then begin
     data1=basename1
  endif else $
    j=load_cols(basename1, data1)
  
  IF n_elements(basename2) gt 100 then begin
     data2=basename2
  endif else $
    j=load_cols(basename2, data2)

  IF NOT keyword_set(title) THEN title=''

  xr=[224,230]
  yr=[285,325]

  day=lindgen(n_elements(data1[0,*]))/48.

  if n_elements(day) lt 10000 then day=day+221

;  i=8
;  plot, day, data1[i,*], xr=xr, yr=yr, /xs, /ys, $
;    line=2, title=title+' Temperature', $
;    ytitle='Temperature (K)', xtitle='Day'
;  oplot, day, data2[i,*], color=1
;  oplot, day, data1[i,*], color=3

  i=8+nsoil
  plot, day, data1[i,*], xr=xr, yr=[0,0.5], /xs, /ys, $
    line=2, title=title+' Soil Moisture', $
    ytitle='Moisture Content (cm^3/cm^3)', xtitle='Day'
  oplot, day, data2[i,*], color=1
  oplot, day, data1[i,*], color=3
;  oplot, day, data2[i+1,*], color=1, line=2
;  oplot, day, data1[i+1,*], color=3, line=2
;  oplot, day, data2[i+2,*], color=1, line=1
;  oplot, day, data1[i+2,*], color=3, line=1
;  oplot, day, data2[i+3,*], color=1, line=1
;  oplot, day, data1[i+3,*], color=3, line=1
;  oplot, day, data2[i+4,*], color=1, line=1
;  oplot, day, data1[i+4,*], color=3, line=1
;  oplot, day, data2[i+5,*], color=1, line=1
;  oplot, day, data1[i+5,*], color=3, line=1
;  oplot, day, data2[i+6,*], color=1, line=1
;  oplot, day, data1[i+6,*], color=3, line=1
;precip
;  oplot, day, data1[3,*]*100

;   i=6
;   plot, day, data1[i,*], xr=xr, /xs, yr=[-100,500], /ys, $
;     line=2, title=title+' Sensible Heat Flux', $
;     ytitle='Sensible Heat (W/m^2)', xtitle='Day'
;   oplot, day, data2[i,*], color=1
;   oplot, day, data1[i,*], color=3
  
  i=7
  plot, day, data1[i,*], xr=xr, /xs, yr=[-100,500], /ys, $
    line=2, title=title+' Latent Heat Flux', $
    ytitle='Latent Heat (W/m^2)', xtitle='Day'
  oplot, day, data2[i,*], color=1
  oplot, day, data1[i,*], color=3

  i=2
  plot, day, data1[i,*], xr=xr, /xs, yr=yr, /ys, $
    line=2, title=title+' Skin Temperature', $
    ytitle='Skin Temperature (K)', xtitle='Day'
  oplot, day, data2[i,*], color=1
  oplot, day, data1[i,*], color=3
  
;   i=11+2*nsoil
;   plot, day, data1[i,*], xr=xr, /xs, yr=[-100,500], /ys, $
;     line=2, title=title+' Ground Heat Flux', $
;     ytitle='Ground Heat Flux (W/m^2)', xtitle='Day'
;   oplot, day, data2[i,*], color=1
;   oplot, day, data1[i,*], color=3
  
  
;  device, /close

;  !p.multi=oldp
;  set_plot, olddevice

end
