PRO wet2dry, wet, dry, fname=fname, pause=pause
  IF NOT keyword_set(pause) THEN pause=0
  j=load_cols(wet, d1)
  j=load_cols(dry, d2)

  day=lindgen(n_elements(d1[0,*]))/48.


  IF keyword_set(fname) THEN BEGIN 
     old=setupPlot(fileName=fname)
     !p.multi=[0,1,3]
  ENDIF 

  baseTitle=(strsplit(fname, '.', /extract))[0]

  xr=[220, 250]
;  window, 0
  plot, day, d2[2,*]-d1[2,*], $
    title="Ts_dry - Ts_wet "+baseTitle, xr=xr
  wait, pause

;  window, 1
  plot, day, d1[16,*], xr=xr, $
    title="Moisture Content "+baseTitle
  oplot, day, d1[16,*], color=3
  oplot, day, d2[16,*], color=1
  
  wait, pause

;  window, 2
  plot, day, d1[7,*], $
    yr=[-100,700], xr=xr, title="Latent Heat "+baseTitle
  oplot, day, d1[7,*], color=3
  oplot, day, d2[7,*], color=1

  IF keyword_set(fname) THEN resetPlot, old

END

