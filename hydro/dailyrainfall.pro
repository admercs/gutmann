;+
; NAME: dailyrainfall
;
; PURPOSE:
;             Takes a time series of rainfall (or any variable really) and
;             computes the total rainfall for each day.
;
; CATEGORY: general
;
; CALLING SEQUENCE: dailyrainfall, rain, dt, offset=offset, binsize=binsize, average=average
;
; INPUTS: rain, dt
;             rain : variable to be summed
;             dt   : time step between rows in minutes
;             (e.g. 3 for 480 steps per day, 60 for 24 steps per day)
;
; OPTIONAL INPUTS: <none>
;
; KEYWORD PARAMETERS: binsize, average, offset
;             binsize : alternative to dt, specifies how many steps per day
;                       (or whatever), makes the routine more general
;                       essentially this is turning into a running average routine
;             average : return the average in each bin rather than the total
;             offset : if set, returns a subset of the daily totals started at offset
;
; OUTPUTS: returns array of totals (or averages) within each bin (day)
;
; OPTIONAL OUTPUTS: <none>
;
; COMMON BLOCKS: <none>
;
; SIDE EFFECTS: <none>
;
; RESTRICTIONS: <none>
;
; PROCEDURE:
;
; EXAMPLE: dailyprecip=dailyrainfall(precip, 30)
;
; MODIFICATION HISTORY:
;              2/20/2006 - edg - separated from noah_pickbest_multistorm
;-
FUNCTION dailyrainfall, rain, dt, offset=offset, average=average, binsize=binsize, midday=midday, $
  badval=badval

  IF NOT keyword_set(binsize) THEN stepsperday=24*60/dt ELSE stepsperday=binsize
  IF keyword_set(midday) THEN dailyoffset=fix(stepsperday/8) ELSE dailyoffset=0

  ndays=fix(n_elements(rain)/stepsperday)
  dailyrain=fltarr(ndays)
  averaging=intarr(ndays)+stepsperday-2*dailyoffset

  FOR i=0l, ndays-1 DO BEGIN 
     tmp=rain[i*stepsperday+dailyoffset:(i+1)*stepsperday-1-dailyoffset]
     IF keyword_set(badval) THEN BEGIN 
        gooddex=where(tmp NE badval)       
        averaging[i]=n_elements(gooddex)
        IF gooddex[0] EQ -1 THEN tmp = -999 ELSE tmp=tmp[gooddex]
     ENDIF
     
     dailyrain[i]=total(tmp)
  ENDFOR
  
  IF keyword_set(offset) THEN dailyrain=dailyrain[offset:*]
  IF keyword_set(average) THEN dailyrain/=averaging

  return, dailyrain
END
