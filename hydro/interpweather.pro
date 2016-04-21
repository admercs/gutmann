; read the first 4 lines and return them as a vertical array
FUNCTION getHeader, infile
  openr, un, /get, infile
  line=""
  readf, un, line
  output=line
  readf, un, line
  output=[[output], [line]]
  readf, un, line
  output=[[output], [line]]
  readf, un, line
  output=[[output], [line]]

  close, un & free_lun, un
  return, output
END

FUNCTION matchMAP, rain, MAP, day
;  uses the median distance between day changes to determine dt
;  (AND thus how long a year is)
;  Forces the first Year of rain data to match MAP for spinup purposes
  index=where(day[1:*]-day[0:n_elements(day)-2] eq 1)
  IF index[0] EQ -1 THEN BEGIN 
     print, "MAP adjustment made assuming 480 time steps per day (dt=3min)"
     nsteps=480
  ENDIF ELSE $
    nsteps=fix(median(index[1:*]-index[0:n_elements(index)-2]))
  
  IF n_elements(rain) LT nsteps*365l THEN BEGIN 
     print, "Record too short to adjust, no MAP adjustment made : ", $
            nsteps, n_elements(rain)/nsteps
  ENDIF ELSE BEGIN 
     adjustment=MAP/total(rain[0:nsteps*365-1])
     rain[0:nsteps*365-1]*=adjustment
     print, "Rain for the first year adjusted by : " adjustment
  ENDELSE 

  return, rain
END


PRO interpWeather, infile, factor, outfile, MAP=MAP
  header=getHeader(infile)

  print, load_cols(infile, data)
  sz=size(data)
  newN=sz[2]*factor
  newoutput=dblarr(sz[1],newN)
;; use linear resampling then round down
;  newoutput[0:2,*]=fix(rebin(data[0:2,*], 3, newN))
  
;; time interpolation is a little tricky because we need to break
;; out seconds, minutes and hours, then interpolate, then put it
;; all back together again
   tmptime=(data[3,*]/100)
   tmptime2=long(tmptime)/100     ; hours
   tmptime3=long(tmptime) MOD 100 ; minutes
   tmptime4=(data[3,*] MOD 100)  ; seconds
;   newtime=tmptime2+(tmptime3/60.0) + (tmptime4/3600.0)

   julian=JULDAY(data[1,*], data[2,*], data[0,*], tmptime2, tmptime3, tmptime4)
   julian=rebin(julian, 1, newN)
   CALDAT,julian, month, day, year, hour, minute, second
   newoutput[0,*]=year
   newoutput[1,*]=month
   newoutput[2,*]=day
   newoutput[3,*]=((hour*100)+minute)*100+second
   
;   oldinterval=newtime[1]-newtime[0]
;   newinterval=float(oldinterval)/factor
;   tmp=(lindgen(newN) MOD factor)*newinterval

;   tmptime=rebin(newtime, 1, newN)
;   minutes=(tmptime MOD 1)*60.0
;   seconds=long((minutes MOD 1)*60.0)
;   minutes=long(minutes)
   ;; HACK
;     dex=where(seconds EQ 59)
;     IF dex[0] NE -1 THEN BEGIN
;        minutes[dex]++
;        seconds[dex]=0
;     ENDIF
;  hours=long(tmptime)

;  newoutput[3,*]=long(hours*100+minutes)*100 +seconds
  
;; now interpolate the next 6 columns
  newoutput[4:9,*]=rebin(data[4:9, *], 6, newN)

;; rain is a nearest neighbor sampling then divided by the
;;   number of intervals it is being split into.  
  newoutput[10,*]=rebin(data[10, *], 1, newN, /sample)/factor
  
  IF keyword_set(MAP) THEN newoutput[10,*]=matchMAP(newoutput[10,*], MAP, day)

;; again, just linearly interpolate the last 3 columns
  newoutput[11:13,*]=rebin(data[11:13, *], 3, newN)
  
;  print, newoutput[3,0:10]

  openw, oun, outfile, /get
  printf, oun, header
  FOR i=0l, newN-1 DO BEGIN
     printf, oun, newoutput[*,i], format='(4I7,10F10.4)'
  endFOR
  close, oun
  free_lun, oun

end
