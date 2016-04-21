;+
; NAME: noah_pickbest_multistorm
;
; PURPOSE: Find optimal SHPs from multiple storms in a time series.
;          Search through a time series of rain and measured and modelled ET.
;          For each rain storm find the model run ET that best fits the measured ET.
;
; CATEGORY: noah model post processing
;
; CALLING SEQUENCE:  noah_pickbest_multistorm, correlate=correlate,
;                                sday=sday, eday=eday, ndays=ndays, 
;                                measure_column=measure_column, model_column=model_column,
;                                meas_model_offset=meas_model_offset,
;                                outputfile=outputfile, rain_column=rain_column
;
; INPUTS: none required
;
; OPTIONAL INPUTS: keywords
;
; KEYWORD PARAMETERS:
;         correlate = if set, uses correlation rather than RMS error between ET time series
;                     to select optimal SHP
;                   <default = off>
;                     
;         sday, eday= if set, starting and ending days in MODEL time series to look at
;                   <default = entire period of record>
;                     
;         ndays     = if set number of days after a storm to use to define SHPs
;                   <default = 6>
;                     
;         measure_column= the column in the measured data to use for fitting SHPs
;                   <default = 26>
;                     
;         model_column  = the column in the modelled data to use for fitting SHPs
;                   <default = 7>
;                     
;         rain_column = the column in the measured data to read rainfall data from.  
;                   <default = 3>
;                     
;         meas_model_offset = offset (in days) between measured and modelled data,
;                             model starts after measured = positive offset
;                   <default = 365>
;                     
;         outputfile = output filename to write best SHP filename too.
;                     <default = "multistormSHPs">
;
;
; OUTPUTS: writes a file with one line for each storm it fit SHPs to.  Each line contains
;          the name of the model output file it thought was the best fit.  
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
;             Load model output files returning only the column of interest for each model run
;             Load measured flux and rain data from measurement file
;             Calculate mid-day values from model and measured data
;             Calculate daily rainfall amounts
;             Search throuhh daily rainfall for a day with >=6mm of rain
;             use the proceeding 6 days (or until another storm 2mm or larger) to fit SHPs
;                if only 2 days are available before another rainstorm don't use
;             write the best SHP model output file name to the output file
;
; EXAMPLE:  noah_pickbest_multistorm
;
;
;
; MODIFICATION HISTORY:
;           1/27/2006 - edg - original
;-


;; return dt (model output time step) in minutes
FUNCTION finddt, times, dt
  timechange=times[1]-times[0]

  IF timechange LT 60 THEN return, timechange ;; this is almost always what will happen

;; unless we happend to flip an hour
  IF timechange LT 2400 THEN BEGIN
     hours=ulong64(times[0:1]/100)
     minutes=fix(times[0:1] MOD 100)
     return, (hours[1] - hours[0])*60.0 + minutes[1] - minutes[0]
  ENDIF

;; if timechange is greater than 2400 than we must have flipped a day, look at the next time step
;; to see if it is any better
  timechange=times[2]-times[1]

  IF timechange LT 60 THEN return, timechange ;; this is almost always what will happen

  IF timechange LT 2400 THEN BEGIN
     hours=ulong64(times[0:1]/100)
     minutes=fix(times[0:1] MOD 100)
     return, (hours[1] - hours[0])*60.0 + minutes[1] - minutes[0]
  ENDIF

;; if timechange is still greater than 2400 than dt must be greater than one day! and this may not work
  ;; if it exactly one day, maybe we can use that??
  IF timechange EQ 10000 OR times[1]-times[0] EQ 10000 THEN return, 1440

  print, "ERROR : Model time step is greater than 1 day, we can't do anything with this!"
  print, "  Timestep 1 = ",strcompress(ulong64(times[0])), $
         "     Timestep 2 = ", strcompress(ulong64(times[1]))

END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Read the flux data and do a little formatting.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION read_flux_data, files, nfiles, vars, dt

  junk=load_cols(files[0], tmpData, /double)
  sz=size(tmpData)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; read the first file, find the time step and setup the output data array
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  data=fltarr(n_elements(tmpData[0,*]), n_elements(vars), nfiles)
  dt=finddt(tmpData[0,1:*]) ; skip the first time step as it is often different                       
  print, "| Time step =",fix(dt)," minutes                                  |", $
         format='(A,I6,A)'
  data[*,*,0]=transpose(float(tmpData[vars,*]))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  print, "| Loading files...                                           |"
;; read in input data (this can take a LONG time) the code from here to he loop sets up a "progress bar"
  print, "|", format='($,A)'
  nloops=nfiles
  IF nloops LT 15 THEN BEGIN
     step=nfiles/5.0
     update="............"
  ENDIF ELSE IF nloops LT 30 THEN BEGIN
     step=nfiles/15.0
     update="...."
  ENDIF ELSE IF nloops LT 60 THEN BEGIN
     step=nfiles/30.0
     update=".."
  ENDIF ELSE BEGIN
     step=nfiles/60.0
     update="."
  ENDELSE
  curstep=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; loop over the remaining files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  FOR i=0, nfiles-1 DO BEGIN
     junk=load_cols(files[i],tmpData)
     IF junk EQ -1 THEN print, "ERROR with file ", files[i] ELSE $
       DATA[*,*,i]=transpose(float(tmpData[vars,*]))

;; update the "progress bar"
     IF i GE curstep THEN BEGIN
        print, update, format='($,A)'
        curstep+=step
     ENDIF

  ENDFOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; close the progress bar
  print, '|'
  return, transpose(reform(data))
END

PRO readmeasurements, file, fcol, rcol, flux, rain, dt
  junk=load_cols(file, data)
  flux=data[fcol,*]
  rain=data[rcol,*]
  dt=30
;  dt=data[0,20]-data[0,19] ;;??
END

FUNCTION getmidday, data, dt, offset=offset
  starttime=round(9*60./dt)
  endtime=round(16*60./dt)
  dtperday=round(24*60./dt)

  ntimes=endtime-starttime
  middayindex=indgen(ntimes)+starttime

  ndays=n_elements(data[0,*])/dtperday
  output=fltarr(n_elements(data[*,0]), ndays)

  FOR i=0,ndays-1 DO $
    output[*,i]=total(data[*, middayindex+i*dtperday],2)/n_elements(middayindex)

  IF offset GT 0 THEN output=output[offset:*]

  return, output
END

FUNCTION dailyrainfall, rain, dt, offset=offset

  stepsperday=24*60/dt
  ndays=fix(n_elements(rain)/stepsperday)
  dailyrain=fltarr(ndays)
  FOR i=0l, ndays-1 DO $
    dailyrain[i]=total(rain[i*stepsperday:(i+1)*stepsperday-1])
  
  IF offset GT 0 THEN dailrain=dailyrain[offset:*]
  return, dailyrain
END


FUNCTION find_nextStorm, rain, startday

  ndays=n_elements(rain)-1
  curinterval=startday
  WHILE rain[curinterval] LT 5 AND curinterval LT ndays DO curinterval++

  IF curinterval EQ ndays THEN return, -1 $
  ELSE return, curinterval
  
END

FUNCTION rain_in_ndays, rain, curday, ndays, gooddays
  IF total(rain[curday:curday+ndays]) LT 2 THEN BEGIN 
     gooddays=ndays-1
     return, 0
  ENDIF ELSE BEGIN 
     FOR i=0, ndays-1 DO BEGIN 
        IF rain[curday+i] GE 3 THEN BEGIN 
           gooddays=i-1
           return, 1
        ENDIF 
     ENDFOR
     gooddays=ndays
     return, 0
  ENDELSE 
  
END

FUNCTION bestSHPs, data, measure, startday, endday
  gooddex=where(measure[0,startday:endday] GT 20)
  IF gooddex[0] EQ -1 THEN return, -1
  goodmeas=transpose((measure[0,startday:endday])[gooddex])
  gooddata=(data[*,startday:endday])[*,gooddex]
  testing=gooddata-rebin(goodmeas, n_elements(data[*,0]), n_elements(gooddex))
  testing=total(testing, 2)
  besterror=min(abs(testing))
  return, where(abs(testing) EQ besterror)
END


PRO noah_pickbest_multistorm, correlate=correlate, sday=sday, eday=eday, ndays=ndays, $
  measure_column=measure_column, model_column=model_column, meas_model_offset=meas_model_offset, $
  outputfile=outputfile, rain_column=rain_column, testonly=testonly

  IF NOT keyword_set(ndays) THEN ndays=6 ; number of days after a rainstorm to look at
;  IF NOT keyword_set(sday) THEN sday=0
;  IF NOT keyword_set(eday) THEN eday=720-365
  IF NOT keyword_set(measure_column) THEN measure_column=1
  IF NOT keyword_set(model_column) THEN model_column=7
  IF NOT keyword_set(meas_model_offset) THEN meas_model_offset=0
  IF NOT keyword_set(outputfile) THEN outputfile="multistormSHPs"
  IF NOT keyword_set(rain_column) THEN rain_column=0

  files=file_search('out_*', count=nfiles)
  file=file_search('IHOPUDS*.txt', count=measurefile)
  IF nfiles EQ 0 OR NOT measurefile THEN BEGIN
     print, "ERROR : no files found matching pattern : out_*"
     return
  ENDIF 
  IF NOT keyword_set(testonly) THEN BEGIN 
     data=read_flux_data(files, nfiles, model_column, dt)
  ENDIF ELSE data=read_flux_data(files[0:2], 3, model_column, dt)
  readmeasurements, file, measure_column, rain_column, flux, rain, measuredt
  
  data=getmidday(data, dt, offset=meas_model_offset*(-1))
  measured=getmidday(flux, measuredt, offset=meas_model_offset)
  rain=dailyrainfall(rain, measuredt, offset=meas_model_offset);*1000 ; convert m to mm

  IF NOT keyword_set(testonly) THEN $
    openw, oun, /get, outputfile

  lastStorm=0
  done=0
  curSHPs=-1
  WHILE lastStorm LT n_elements(data[0,*])-ndays-1 DO BEGIN 
     nextStorm=find_nextStorm(rain, lastStorm)+1
     curSHPs=-1

     IF nextStorm[0] NE -1 AND nextStorm[0] LT n_elements(data[0,*])-ndays-1 THEN BEGIN 
        IF rain_in_ndays(rain, nextStorm, ndays, gooddays) THEN BEGIN 
           IF gooddays GT 0 AND NOT keyword_set(testonly) THEN $
             curSHPs=bestSHPs(data, measured, nextStorm, nextStorm+gooddays)
        ENDIF ELSE IF NOT keyword_set(testonly) THEN $
          curSHPs=bestSHPs(data, measured, nextStorm, nextStorm+gooddays)
        
        IF curSHPs[0] NE -1 THEN BEGIN 
           printf, oun, files[curSHPs]
        ENDIF 
        curstorm=0
        FOR rainday=(nextStorm-2)>0,nextStorm DO curstorm+=rain[rainday]
        
        print, curSHPs, nextStorm, nextStorm+gooddays, gooddays, curstorm
        lastStorm=nextStorm
     endIF ELSE lastStorm=n_elements(rain)
  ENDWHILE

  IF NOT keyword_set(testonly) THEN BEGIN 
;; find the best SHPs for the entire perdiod of record
     curSHPs=bestSHPs(data, measured, 0, n_elements(data[0,*])-1)
     printf, oun, files[curSHPs]
     
     close, oun
     free_lun, oun
  ENDIF 
END
