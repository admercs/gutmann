;; plot key Noah variables (from original 2.5.2 write statement)
;;   uses two files (presumably a sand run and a clay run)
pro plot252, sandfname, clayfname
  j=load_cols(sandfname, sand)
  j=load_cols(clayfname, clay)

;
; 0=jday
; 1=time
; 2=NSOIL  (Number of Soil Layers???)
; 3=T1     (skin temp)
; 4=PRCP   (Precipitation)
; 5=AET    (Latent Heat Flux)
; 6=H      (Sensible Heat Flux)
; 7=S      (Ground Heat Flux)
; 8-7+NSOIL=         STC   (Soil Layer Temp)
; 8+NSOIL-7+2xNsoil= SMC   (Soil Moisture Content)
;

  xr=[202,215]
  day=lindgen(n_elements(sand[0,*]))/48.
  NSOIL= sand[2,1]
;;Skin Temp
  plot, day, sand[3,*], $
    xr=xr, yr=[270,330], /xs, /ys, $
    title='NOAH 2.5.2 Skin Temperature', $
    ytitle='Skin Temperature (K)', $
    xtitle='Day'
  oplot, day, clay[3,*], color=3
  oplot, day, sand[3,*], color=1

; Soil Layer Temp
  plot, day, sand[8,*], $
    xr=xr, yr=[270,330], /xs, /ys, $
    title='NOAH 2.5.2 top 5cm Temperature', $
    ytitle='Top 5cm Temperature (K)', $
    xtitle='Day'
  oplot, day, clay[8,*], color=3
  oplot, day, sand[8,*], color=1

; Soil Moisture Content
  plot, day, sand[8+NSOIL,*], $
    xr=xr, yr=[0.0,0.5], /xs, /ys, $
    title='NOAH 2.5.2 top 5cm Moisture Content', $
    ytitle='Top 5cm Moisture Content', $
    xtitle='Day'
  oplot, day, clay[8+NSOIL,*], color=3
  oplot, day, sand[8+NSOIL,*], color=1

; Precip
  oplot, day, sand[4,*]*100

;  plot, day, sand[4,*]*100, $
;    xr=xr, /xs, /ys, $
;    title='NOAH 2.5.2 Precipitation', $
;    ytitle='Precipitation (cm)', $
;    xtitle='Day'

;  oplot, day, clay[4,*], color=3

; Sensible Heat Flux
  plot, day, sand[6,*], $
    xr=xr, yr=[-100,500], /xs, /ys, $
    title='NOAH 2.5.2 Sensible Heat Flux', $
    ytitle='Sensible Heat Flux (W/m^2)', $
    xtitle='Day'
  oplot, day, clay[6,*], color=3
  oplot, day, sand[6,*], color=1

; Latent Heat Flux
  plot, day, sand[5,*], $
    xr=xr, yr=[-100,500], /xs, /ys, $
    title='NOAH 2.5.2 Latent Heat Flux', $
    ytitle='Latent Heat Flux (W/m^2)', $
    xtitle='Day'
  oplot, day, clay[5,*], color=3
  oplot, day, sand[5,*], color=1

; Ground Heat Flux
  plot, day, sand[7,*], $
    xr=xr, yr=[-100,500], /xs, /ys, $
    title='NOAH 2.5.2 Ground Heat Flux', $
    ytitle='Ground Heat Flux (W/m^2)', $
    xtitle='Day'
  oplot, day, clay[7,*], color=3
  oplot, day, sand[7,*], color=1

; Cum. Fluxes
;  plot, day, sand[5,*]+sand[6,*]+sand[7,*], $
;    xr=xr, /xs, /ys, $
;    title='NOAH 2.5.2 Cumulative Heat Fluxes', $
;    ytitle='Cumulative Heat Flux (W/m^2)', $
;    xtitle='Day'
;  oplot, day, clay[5,*]+clay[6,*]+clay[7,*], color=3
;  oplot, day, sand[5,*]+sand[6,*]+sand[7,*], color=1

end
