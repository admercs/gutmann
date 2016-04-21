;; assumes that model time is in 30min increments and that it starts
;; on day 0 of the correct year.  
FUNCTION getmatchingdata, d1, d1time, d2, d2time
  data=fltarr(2,min([n_elements(d1time),n_elements(d2time)]))
  
  d2index=fix(d1time*48)-48
;  d2index=round(d1time*48)-48
  d2modifier=(d1time * 48) MOD 1
  
  data[0,*]=d1
  data[1,*]=(1-d2modifier)*d2[d2index] + d2modifier*d2[d2index+1]
;  data[1,*]=d2[d2index]

;  stop
  return, data
END


PRO plot_modis_v_model, modisdata, modeldata, modeltime, data=data, $
                        modelTs=modelTs, noplot=noplot, best=best
  IF n_elements(modeltime) EQ 0 THEN $
    modeltime=lindgen(n_elements(modeldata[0,*]))/48.0
  IF NOT keyword_set(modelTs) THEN modelTs=2 ; column in model data for Ts data

  modistime=modisdata[0,*]+modisdata[8,*]/24.0
;; subset out missing datapoints
  gooddata=where(modisdata[1,*] NE 0)
;; only look at really good data
  IF keyword_set(best) THEN gooddata=where((modisdata[5,*] AND (64+128)) NE (64+128))

;; various other MODIS flags that end up being the same as the above
;                 AND modisdata[3,*] LT 0.2 $
;                 AND ((modisdata[5,*] AND 3) EQ 0 $
;                      OR (modisdata[5,*] AND 12) EQ 0 $
;           OR $
;           ((modisdata[5,*] AND 32) EQ 0 $
;           AND $
;           (modisdata[5,*] AND (64+128)) NE (64+128));))


  data=getmatchingdata(modisdata[1,gooddata], modistime[gooddata], $
                       modeldata[modelTs,*], modeltime)

  range=[290,330]
  IF NOT keyword_set(noplot) THEN $
    plot, data[0,*], data[1,*], /psym,/xs,/ys, xr=range, yr=range
  
END
