FUNCTION getnoons, data, day, ndays=ndays, modis=modis, time=time
;; set up defaults
  IF n_elements(day) EQ 0 THEN day=0
  IF NOT keyword_set(ndays) THEN ndays=n_elements(data)/48-day
  IF NOT keyword_set(modis) THEN $
    times=[11,11.5,12,12.5,13,13.5]*2 $
  ELSE times=[11]*2

; could be used to allow a non-continuous time line to be input
;  IF NOT keyword_set(time) THEN time=lindgen(n_elements(data))/48.0

;; output array
  noons=fltarr(ndays)

;; loop through data retrieving midday values
  FOR i=day, day+ndays-1 DO $
    noons[i-day] = mean(data[times+(i*48l)])

  return, noons
END
