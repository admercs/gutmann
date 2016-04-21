FUNCTION compare_measure_model, inmodel, inmeasured, $
  corr=corr, normalize=normalize, midday=midday

  model=inmodel
  measured=inmeasured ;; temporary variables so we stop screwing up our data

;; incase we delete these values in the midday or 
  index=where(measured GT 20 AND measured LT 1500)
  norm_measure=(measured[index])[0]
  norm_model=(model[index])[0]
  IF keyword_set(midday) OR keyword_set(corr) THEN BEGIN
     time=(lindgen(min([n_elements(measured), n_elements(model)])) $
            MOD 48)/2.0
     index=where(time GE 12 AND time LT 16)
     IF index[0] NE -1 THEN BEGIN
        model=model[index]
        measured=measured[index]
     ENDIF
  ENDIF
  
  ;; only look at times when measured latent heat flux is greater than 20
  ;;   (and when it is realistic)  if midday is set probably all will
  index=where(measured GT 20 AND measured LT 1500)
  IF index[0] EQ -1 THEN index=lindgen(n_elements(measured))
  norm_model=(model[index])[0]
  norm_measure=(measured[index])[0]

  IF keyword_set(corr) THEN BEGIN
     ;; return the correlation coefficient between the measured and modeld values
;     stop
     return, 1-correlate(reform(measured[index]), reform(model[index]))
  ENDIF 
  IF NOT keyword_set(normalize) THEN BEGIN
     ;; normalize
     norm_measure=0
     norm_model=0
  ENDIF

; return the RMS error between the measured and modelled values
  return, sqrt(mean(((model[index]-norm_model)-(measured[index]-norm_measure))^2))
END

FUNCTION noah_pickbest_soil, real_file, model_files, _extra=e, $
  measure_column=measure_column, model_column=model_column, $
  sday=sday, eday=eday, nooffset=nooffset

  FILLVALUE=-999999

  IF n_elements(model_files) EQ 0 THEN model_files = file_search('out_*_*')
  IF n_elements(real_file) EQ 0 THEN real_file = file_search('IHOPUDS*.txt')

  junk=load_cols(real_file, measured)

  IF NOT keyword_set(model_column) THEN model_column=7
  IF NOT keyword_set(measure_column) THEN measure_column=23
  IF NOT keyword_set(sday) THEN sday=30l
  IF NOT keyword_set(eday) THEN eday=36l

  model_range = [sday*48l,eday*48l,1]
;  model_range = [48l*48,56l*48,1]
;  model_range = [36l*48,46l*48,1]

  IF NOT keyword_set(nooffset) then offset=round(11*48l) ELSE offset=0

  measure_range=model_range-offset
  model_range[2]=1
  tmp=measure_range[1]-(n_elements(measured[0,*])-1)
  IF tmp GT 0 THEN BEGIN
     measure_range[1]-=tmp
     model_range[1]-=tmp
  ENDIF

  measured=measured[measure_column, measure_range[0]:measure_range[1]]
  IF measure_column EQ 22 THEN measured+=273.15 ; convert Celcius to Kelvin
  print, measure_column
  plot, measured
  wait, 1

  best=FILLVALUE
  besti=0
  FOR i=0,n_elements(model_files)-1 DO BEGIN
     junk=load_cols(model_files[i], data)
     curdata=data[model_column, model_range[0]:model_range[1]]
     current=compare_measure_model(curdata, measured, _extra=e)

     IF best EQ FILLVALUE THEN BEGIN
        best=current
        besti=i
        plot, curdata, /xs, /ys
        oplot, measured, l=1
        wait, 0.01
     ENDIF ELSE BEGIN 
        IF current LT best THEN BEGIN 
           best=current
           besti=i
           plot, curdata, /xs, /ys
           oplot, measured, l=1
           print, i
           wait, 0.01
        ENDIF
     ENDELSE 
  ENDFOR
  return, model_files[besti]
END

  
