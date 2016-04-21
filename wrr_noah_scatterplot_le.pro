;; finds midday time LE values during the period between sday and eday
;; scatter plots (or oplots) measured LE on X vs best fit or class average LE on Y
;;
;; this has been superceded by ~/idl/hydro/wrr/plotbest.pro
;;
PRO wrr_noah_scatterplot_LE, best, measured, class, $
  sday=sday, eday=eday, oplot=oplot, xr=xr, yr=yr, $
  bestonly=bestonly, classonly=classonly, data=data, color=color

  IF NOT keyword_set(eday) THEN eday=56
  IF NOT keyword_set(sday) THEN sday=47
  
  IF n_elements(measured) EQ 0 THEN measured=file_search('IHOPUDS*.txt')
  IF n_elements(class) EQ 0 THEN $
    class=file_search((strsplit(best, '_', /extract))[1],/fold_case)

  model_col=7
  measure_col=23
  offset=11*48l-1  ; offset between measured and modeled timelines


  junk=load_cols(best, bestLE)
  junk=load_cols(measured, measuredLE)
  junk=load_cols(class, classLE)
  
  time=lindgen(n_elements(classLE[0,*]))/48.0

  data=fltarr(3, eday-sday+1)
  noonstart=22
  noonend=28
  FOR i=sday,eday DO begin
     s=noonstart+i*48l
     e=noonend  +i*48l

     data[0,i-sday]=mean(classLE[model_col,s:e])
     data[1,i-sday]=mean(bestLE[model_col,s:e])
     tmp=measuredLE[measure_col, s-offset:e-offset]
     index=where(tmp LT 1500)
     IF index[0] NE -1 THEN begin
        data[2,i-sday]=mean(tmp[index])
     ENDIF ELSE data[2,i-sday]=-999
  ENDFOR

  IF keyword_set(oplot) THEN BEGIN 
     IF NOT keyword_set(bestonly) THEN oplot, data[0,*], data[2,*], psym=1, color=color
     IF NOT keyword_set(classonly) THEN oplot, data[1,*], data[2,*], psym=2, color=color
  ENDIF ELSE BEGIN
     IF NOT keyword_set(xr) THEN $
       xr=[min(measuredLE[measure_col, *]), max(measuredLE[measure_col, *])]
     IF NOT keyword_set(yr) THEN yr=xr
     IF keyword_set(classonly) THEN BEGIN 
        plot, data[0,*], data[2,*], psym=1, xr=xr, yr=yr,/xs,/ys, color=color
     ENDIF ELSE IF keyword_set(bestonly) THEN begin
        plot, data[1,*], data[2,*], psym=2, xr=xr, yr=yr,/xs,/ys, color=color
     ENDIF ELSE BEGIN
        plot, data[0,*], data[2,*], psym=1, xr=xr, yr=yr,/xs,/ys, color=color
        oplot, data[1,*], data[2,*], psym=2, color=color
     ENDELSE

  ENDELSE
END
