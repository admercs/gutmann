;+
; NAME:             noah_plot_flux_texture
;
; PURPOSE:          Plot noah model flux (and state) output for all runs from a texture class.  
;
; CATEGORY:         plot noah output WRR 2006
;
; CALLING SEQUENCE: noah_plot_flux_texture, texture, var=var, outputfile=outputfile, skipn=skipn, 
;                        keyday=keyday, nops=nops, nocolor=nocolor,
;                        startday=startday, endday=endday, _extra=extra
;
; INPUTS:           texture = (string) name identifying the files to lookup as "out_<texture>_*"
;
; OPTIONAL INPUTS: <none other than keywords>
;
; KEYWORD PARAMETERS:
;                   var = (integer [7]) column in model output to plot, can be an array of columns
;                   outputfile = (string [<texture>_plot.ps]) name of the postscript file to
;                                create (if nops is not set)
;                   skipn = (integer or flag [0]) allows you to only plot every n files
;                           NOTE if skipn=1 it is assumed to be a flag and min(50,nfiles) will be loaded
;                   keyday = (integer [624]) day number from start of model output to look at
;                               plots 10 days after and 2 days before, for now assumes rain occurs
;                               the day before
;                   nops = (flag [0]) if set plot to the screen rather than a postscript file.
;                   nocolor = (flag [0]) if set plot in grey scale rather than color
;                   startday = (integer [keyday-2.5]) day number from start of model output to start
;                               output plot at
;                   endday = (integer [keyday+10.5]) day number from start of model output to stop
;                               output plot at
;                   _extra = extra keywords to be passed to the plot command
;
; OUTPUTS : <none required>
;
; OPTIONAL OUTPUTS: if nops flag is not set a postscript file is created named <outputfile> or
;                   if outputfile is not specified named <texture>_plot.ps
;
; COMMON BLOCKS:    <none>
;
; SIDE EFFECTS:     <none>
;
; RESTRICTIONS:     <none>
;
; PROCEDURE:       - Read desired columns from all/skipn data files
;                  - Determine time step of model data assuming the first column is the time
;                  - Plot all model outputs from 2 days before keyday to 10 days after
;
; EXAMPLE:          noah_plot_flux_texture, "sandy loam", outputfile="saloam.ps", /nocolor, skipn=10,
;                                  xtitle="Day", var=7, ytitle="Latent Heat Flux (W/m!E2!N)"
;
; MODIFICATION HISTORY:
;           08/23/2005 - edg - original (based heavily on plotAllofSoil.pro)
;
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


;; select the colors to be used depending on whether or not we are using color
;; and depending on whether or not we are 
PRO set_colors, rainColor, keydaycolor,rainDayColor, nocolor=nocolor
;; plot background color or linefill for rain day
  IF NOT keyword_set(nocolor) THEN BEGIN 
     IF !d.name EQ 'PS' then BEGIN 
        rainDayColor=6 
        rainColor=3
        keydaycolor=4
     ENDIF ELSE BEGIN 
        rainDayColor=(256.0^2)*250+200+200*256
        rainColor=(200.0^2)*250+100+100*256
        keydaycolor=(256.0^2)*200+250+200*256
     ENDELSE 
  ENDIF ELSE BEGIN 
     IF !d.name EQ 'PS' then BEGIN 
        rainDayColor=216
        rainColor=210
        keydaycolor=214
     ENDIF ELSE BEGIN
        rainDayColor=(256.0^2)*250+200+200*256
        rainColor=(200.0^2)*250+100+100*256
        keydaycolor=(256.0^2)*200+250+200*256
     ENDELSE 
  ENDELSE 
END

;; draw the color (or greyscale) box behind the main plot
PRO drawBackground, day, color, yrange

  xpositions=[day-0.5,day-0.5,day+0.5,day+0.5]

  yoffset=0.01*abs(yrange[0]-yrange[1])
  ypositions=[yrange[0]+yoffset, yrange[1]-yoffset, yrange[1]-yoffset, yrange[0]+yoffset]

  polyfill, xpositions, ypositions, color=color
END

;; reads in the class mean model run from "file".
;; oplots the given variable against the given timeline
;;   double line thickness, color=red
PRO plotclassmeans, file, variable, time, startPos, endPos, baseline=baseline

  IF !d.name EQ 'PS' THEN color=1 ELSE color=255

  junk=load_cols(file, data)
  data=data[variable, startPos:endPos]
  IF keyword_set(baseline) THEN data-=baseline
  oplot, time, data, thick=3, color=color
END
;; reads in the best SHP model run from "file".
;; oplots the given variable against the given timeline
;;   double line thickness, color=green
PRO plotbestSHP, file, variable, time, startPos, endPos, baseline=baseline

  IF !d.name EQ 'PS' THEN color=2 ELSE color=255l^2

  junk=load_cols(file, data)
  data=data[variable, startPos:endPos]
  IF keyword_set(baseline) THEN data-=baseline
  oplot, time, data, thick=3, color=color
END

;; plots measured LE, or Ts over modeled 
PRO plotMeasured, file, variable, baseline=baseline, sev=sev

  IF !d.name EQ 'PS' THEN color=201 ELSE color=256l^2*255+100+100l*255

  IF NOT keyword_set(sev) THEN offset=11 ELSE offset=0
    ;;-(1.0/48) ; days between the start of model output and the start of
               ;;weather forcing/measurements
  IF variable EQ 7 THEN variable=23 ELSE BEGIN 
     IF variable EQ 2 THEN variable=22 ELSE $
       return                 ; no soil moisture in IHOPUDS1 IHOP data
  ENDELSE
  IF keyword_set(sev) THEN variable=1

  junk=load_cols(file, data)
  time=indgen(n_elements(data[0,*]))/48.0 +offset + 119 -0.5
  IF keyword_set(sev) THEN time-=119
  index=where(data[variable,*] GT 600)
  IF index[0] NE -1 THEN data[variable,index]=0

  IF variable EQ 22 THEN data[variable,*]+=273.15
;  IF variable EQ 22 THEN stop  
  IF variable EQ 22 AND keyword_set(baseline) THEN BEGIN 
       xr=round(!x.crange*48)/48.0
       startpos=(where(time GE xr[0]))[0] ; not sure why we need the -1 but it does make things match
       endpos=(where(time GE xr[1]))[0]

       data[variable,startpos:endpos]-=baseline
    ENDIF

  oplot, time, data[variable,*], thick=3, color=color
end

PRO plotLegend, yr, xr, bestSHP=bestSHP, measuredLE=measuredLE, classMeans=classMeans

  ysize=yr[1]-yr[0]
  xsize=xr[1]-xr[0]
  ybase=0.93 * ysize+yr[0]
  xbase=0.6 * xsize+xr[0]
  xoff=0.06 * xsize
  yoff=0.07 * ysize

  colors=0
  legend="all soils"
  line=1
  IF keyword_set(bestSHP) THEN BEGIN
     colors=[colors, 2]
     legend=[legend, "Best SHP"]
     line=[line,0]
  ENDIF 
  IF keyword_set(measuredLE) THEN BEGIN
     colors=[colors, 201]
     legend=[legend, "Measured"]
     line=[line,0]
  ENDIF 
  IF keyword_set(classMeans) THEN BEGIN
     colors=[colors, 1]
     legend=[legend, "Class Average SHP"]
     line=[line,0]
  ENDIF 

  FOR i=0, n_elements(colors)-1 DO BEGIN 
     oplot, [xbase,xbase+xoff],[ybase-i*yoff,ybase-i*yoff], thick=3, color=colors[i], l=line[i]
     xyouts, xbase+1.2*xoff, ybase-i*yoff-yoff*0.2, legend[i], charsize=0.75
  ENDFOR

END


PRO plot_flux_data, data, dt, startday, endday, keyday=keyday, rainday=rainday, var=var, $
                    yr=yr, nocolor=nocolor, _extra=e, measuredLE=measuredLE, classmeans=classmeans, $
                    bestSHP=bestSHP, legend=legend, remove_diurnal_ts=remove_diurnal_ts, sev=sev, rainQ=rainQ

  ytitles=strarr(20)
  ytitles[2]="Surface Temperature (K)"
  ytitles[7]="LH (W/m!E2!N)"
  ytitles[18]="Soil Moisture (cm!E3!N/cm!E3!N)"
  stepsPerDay=1440/dt
  startPos=startDay * stepsPerDay
  endPos=endDay * stepsPerDay

  time=indgen(endPos-startPos)/float(stepsPerDay) + startDay + 119-0.5
  IF keyword_set(sev) THEN time-=119
  data=data[startPos:endPos, *,*]

  set_colors, rainColor, keydaycolor, rainDayColor, nocolor=nocolor
  FOR curvar=0,n_elements(data[0,*,0])-1 DO BEGIN 
     IF NOT keyword_set(yr) THEN thisyr=[min(data[*,curvar,*]), max(data[*,curvar,*])] $
     ELSE thisyr=yr[*,curvar]
     ymean=mean(data[*,curvar,*])
     ydev=stdev(data[*,curvar,*])
     IF ymean LT 330 AND ymean GT 270 AND ydev LT 60 THEN BEGIN ;;this is a skin temperature plot
        tmp=reform(data[*,curvar,*])
        thisyr[0]=min(reform(tmp[where(tmp GT 200)]))
        
        ;; subtract off the minimum Ts value from all data points to remove the diurnal signal
        ;;  the keyword baseline is passed to plot[measured,means,best]
        IF keyword_set(remove_diurnal_ts) THEN BEGIN
           tmp=min(tmp[*,where(tmp[0,*] GT 200)], dimension=2)
           data[*,curvar,*]-=rebin(tmp, n_elements(data[*,0,0]), n_elements(data[0,0,*]))
           thisyr[0]=-5
           thisyr[1]=15
;           thisyr[1]=max(data[*,curvar,*])
           baseline=tmp
        ENDIF

     END
     IF max(data[*,curvar,*]) GT 400 THEN yinterval=200 ELSE yinterval=100
     plot, time, data[*,curvar,0], yr=thisyr, /ys, /xs, l=1, $
       xtitle="Day of Year", ytitle=ytitles[var[curvar]], _extra=e, $
       ytickinterval=yinterval,yminor=2

     IF keyword_set(rainday) THEN drawBackground, rainday, raindayColor, thisyr
     IF keyword_set(rainQ) THEN BEGIN 
        rtime=rebin(time, n_elements(time)*2, /sample)
        rrain=rebin(reform(rainQ), n_elements(rainQ)*2,/sample)
;; this offsets rain and time by half a time step so we get bars of rainfall
        goodindex=where(rtime GE !x.crange[0] AND rtime LE !x.crange[1])
        rrain=rrain[goodindex]
        rtime=rtime[goodindex]
        rrain=[rrain,0]
        rtime=[!x.crange[0],rtime]
        
        polyfill, rtime, (thisyr[1]-rrain*10000), color=rainColor
     ENDIF 
     IF keyword_set(keyday) THEN drawBackground, keyday, keydayColor, thisyr

     FOR curfile=0,n_elements(data[0,0,*])-1 DO BEGIN
        oplot, time, data[*,curvar,curfile],l=1
     ENDFOR
     IF keyword_set(classmeans) THEN plotclassmeans, classmeans, var[curvar], $
       time, startPos, endPos, baseline=baseline
     IF keyword_set(measuredLE) THEN plotMeasured, measuredLE, var[curvar], $
       baseline=baseline, sev=sev
     IF keyword_set(bestSHP) THEN plotbestSHP, bestSHP, var[curvar], $
       time, startPos, endPos, baseline=baseline
     IF keyword_set(legend) THEN $
       plotLegend, thisyr, [time[0], time[n_elements(time)-1]], $
                   bestSHP=bestSHP, measuredLE=measuredLE, classmeans=classmeans

     baseline=0 ; make sure we don't carry over a Ts baseline to the next variable
  ENDFOR
END



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; READ the data and do a little formatting
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION read_flux_data, files, nfiles, vars, skipn=skipn, dt, rainQ=rainQ
;; chose how much data to read in
  IF NOT keyword_set(skipn) THEN skipn =1 ELSE BEGIN 
     IF nfiles GT 50 AND skipn EQ 1 THEN skipn=nfiles/50
  ENDELSE 


  junk=load_cols(files[0], tmpData, /double)
  rainQ=tmpData[3,*]
  sz=size(tmpData)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; read the first file, find the time step and setup the output data array
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  data=fltarr(n_elements(tmpData[0,*]), n_elements(vars), nfiles/skipn+ (skipn NE 1))
  dt=finddt(tmpData[0,1:*]) ; skip the first time step as it is often different
  IF skipn GT 1 THEN print, "Skipping every"+strcompress(skipn)+" files"
  print, "| Time step =",fix(dt)," minutes                                  |", $
         format='(A,I6,A)'
  data[*,*,0]=transpose(float(tmpData[vars,*]))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  print, "| Loading files...                                           |"
;; read in input data (this can take a LONG time) the code from here to he loop sets up a "progress bar"
  print, "|", format='($,A)'
  nloops=nfiles/skipn
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
  FOR i=0, nfiles-1,skipn DO BEGIN
     junk=load_cols(files[i],tmpData)
     IF junk EQ -1 THEN print, "ERROR with file ", files[i] ELSE $
       DATA[*,*,i/skipn]=transpose(float(tmpData[vars,*]))

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
  return, data
END


PRO noah_plot_flux_texture, texture, var=var, outputfile=outputfile, skipn=skipn, $ 
  keyday=keyday, nops=nops, nocolor=nocolor, _extra=extra, $
  filepattern=filepattern, startday=startday, endday=endday, $
  yr=yr, rainday=rainday, classmeans=classmeans, measuredLE=measuredLE, $
  bestSHP=bestSHP, legend=legend, charsize=charsize, nosetup=nosetup, sev=sev

;; if improper input was entered show the user documentation and return
;  IF (n_elements(texture) EQ 0 AND NOT keyword_set(filepattern)) OR $
;    (NOT keyword_set(keyday) OR NOT (keyword_set(startday) AND keyword_set(endday))) THEN BEGIN
;     doc_library, 'noah_plot_flux_texture'
;     return
;  END

;; check for some keywords and set default values
  IF NOT keyword_set(var) THEN var=7
  IF NOT keyword_set(outputfile) THEN outputfile=texture+'_plot.ps'
  IF NOT keyword_set(filepattern) THEN filepattern='out_'+texture+'_*'
  IF NOT keyword_set(startday) THEN startday=keyday-2.5
  IF NOT keyword_set(endday) THEN endday=keyday+10.5
;  IF NOT keyword_set(keyday) AND keyword_set(startday) THEN keyday=startday+2.5 ELSE BEGIN 
;     doc_library, 'noah_plot_flux_texture'
;     return    
;  ENDELSE 

;; find the data files to read
  files=file_search(filepattern, count=nfiles)
  IF nfiles EQ 0 THEN BEGIN
     files=file_search(strcompress(filepattern, /remove_all), count=nfiles)
     IF nfiles EQ 0 THEN BEGIN 
        doc_library, 'noah_plot_flux_texture'
        return
     ENDIF 
  ENDIF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; READ the data and do a little formatting
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  data=read_flux_data(files, nfiles, var, skipn=skipn, dt);, rainQ=rainQ)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; if applicable setup postscript output
  IF NOT keyword_set(nops) AND NOT keyword_set(nosetup) THEN BEGIN 
     old=setupplot(filename=outputfile)
     !p.multi=[0,1,n_elements(var)]
     IF keyword_set(charsize) THEN !p.charsize=charsize
  ENDIF ELSE IF NOT keyword_set(nosetup) THEN BEGIN
; else setup the graphical environment for X window plots
     oldp=!p
     !p.background=255l+255l*256+255l*(256l^2)     ; white
     !p.color=0                                    ; black
  ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Plot the data
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  plot_flux_data, data, dt, startday, endday, keyday=keyday, rainday=rainday, $
                  nocolor=nocolor, yr=yr, _extra=extra, $
                  measuredLE=measuredLE, classmeans=classmeans, var=var, $
                  bestSHP=bestSHP, legend=legend, sev=sev, rainQ=rainQ

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; if applicable close postscript file
  IF NOT keyword_set(nops) AND NOT keyword_set(nosetup) THEN BEGIN 
     resetplot, old
  ENDIF ELSE IF NOT keyword_set(nosetup) THEN BEGIN
; else reset the graphical environment for X window plots
     !p=oldp
  ENDIF 
  
END
