;+
; NAME:             clm_plot_flux_texture
;
; PURPOSE:          Plot clm model flux (and state) output for all runs from a texture class.  
;
; CATEGORY:         plot clm output WRR 2006
;
; CALLING SEQUENCE: clm_plot_flux_texture, texture, var=var, outputfile=outputfile, skipn=skipn, 
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
; EXAMPLE:          clm_plot_flux_texture, "sandy loam", outputfile="saloam.ps", /nocolor, skipn=10,
;                                  xtitle="Day", var=7, ytitle="Latent Heat Flux (W/m!E2!N)"
;
; MODIFICATION HISTORY:
;           08/23/2005 - edg - original (based heavily on plotAllofSoil.pro)
;
;-

;; return dt (model output time step) in minutes
FUNCTION clmfinddt, times, dt
  timechange=times[1]-times[0] ; this is very easy in clm, time is in decimal days since the start
  dt=timechange*24.0*60 ; convert days to minutes
  return, round(dt)
END


;; select the colors to be used depending on whether or not we are using color
;; and depending on whether or not we are 
PRO set_colors, rainColor, keydaycolor,rainDayColor, nocolor=nocolor
;; plot background color or linefill for rain day
  IF NOT keyword_set(nocolor) THEN BEGIN 
     IF !d.name EQ 'PS' then BEGIN 
        rainDayColor=6 
;        rainColor=
;        keydaycolor=
     ENDIF ELSE BEGIN 
        rainDayColor=(256.0^2)*250+200+200*256
;        rainColor=
;        keydaycolor=
     ENDELSE 
  ENDIF ELSE BEGIN 
     IF !d.name EQ 'PS' then BEGIN 
        rainDayColor=216
;        rainColor=
;        keydaycolor=
     ENDIF ELSE BEGIN
        rainDayColor=(256.0^2)*250+200+200*256
;        rainColor=
;        keydaycolor=
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
  junk=load_cols(file, data)
  data=data[variable, startPos:endPos]
  IF keyword_set(baseline) THEN data-=baseline
  oplot, time, data, thick=3, color=1
END
;; reads in the best SHP model run from "file".
;; oplots the given variable against the given timeline
;;   double line thickness, color=green
PRO plotbestSHP, file, variable, time, startPos, endPos, baseline=baseline
  junk=load_cols(file, data)
  data=data[variable, startPos:endPos]
  IF keyword_set(baseline) THEN data-=baseline
  oplot, time, data, thick=3, color=2
END

;; plots measured LE, or Ts over modeled 
PRO plotMeasured, file, variable, baseline=baseline
  offset=11    ;;-(1.0/48) ; days between the start of model output and the start of
               ;;weather forcing/measurements
  IF variable EQ 7 THEN variable=23 ELSE BEGIN 
     IF variable EQ 2 THEN variable=22 ELSE $
       return                 ; no soil moisture in IHOPUDS1 IHOP data
  ENDELSE

  junk=load_cols(file, data)
  time=indgen(n_elements(data[0,*]))/48.0 +offset + 119 -0.5
  index=where(data[variable,*] LT 1000)
  IF variable EQ 22 THEN data[variable,*]+=273.15
;  IF variable EQ 22 THEN stop  
  IF variable EQ 22 AND keyword_set(baseline) THEN BEGIN 
       xr=round(!x.crange*48)/48.0
       startpos=(where(time GE xr[0]))[0] ; not sure why we need the -1 but it does make things match
       endpos=(where(time GE xr[1]))[0]

       data[variable,startpos:endpos]-=baseline
    ENDIF

  oplot, time[index], data[variable, index], thick=3, color=201
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
                    bestSHP=bestSHP, legend=legend, remove_diurnal_ts=remove_diurnal_ts

  varindex=intarr(n_elements(var))
  FOR i=0, n_elements(var)-1 DO BEGIN
     CASE var[i] OF  
        'FGEV' : varindex[i]=1
        'FCEV' : varindex[i]=1
        'FCTR' : varindex[i]=1
        'TG'   : varindex[i]=0
        'H2OSOI':varindex[i]=2
        'SOILLIQ':varindex[i]=2
     ENDCASE
  ENDFOR

;; add entries for the 9 other soil levels
  index=where(varindex EQ 2)
  FOR i=0, n_elements(index)-1 DO BEGIN
     IF index[i] LT n_elements(varindex)-1 THEN $
       varindex=[varindex[0:index[i]], (intarr(9)+2), varindex[index[i]+1:n_elements(varindex)-1]] $
     ELSE varindex=[varindex[0:index[i]], (intarr(9)+2)]
     IF i LT n_elements(index)-1 THEN index+=9 ; we just added 9 new entries to varindex
  ENDFOR

  title=strarr(n_elements(varindex))
  evapdex=where(varindex EQ 1)
  IF evapdex[0] NE -1 THEN BEGIN 
     evapdex++ ; because we are adding on a new row here
     sz=size(data)
     data=[[fltarr(sz[1],1,sz[3])], [data]]
     FOR i=0, n_elements(evapdex)-1 DO BEGIN
        data[*,0,*]+=data[*,evapdex[i],*]
     ENDFOR
     varindex=[1,varindex]
     var=['Total LE', var]
  ENDIF


  ytitles=strarr(3)
  ytitles[0]="Surface Temperature (K)"
  ytitles[1]="Latent Heat Flux (W/m!E2!N)"
  ytitles[2]="Soil Moisture (cm!E3!N/cm!E3!N)"
  stepsPerDay=1440/dt
  startPos=startDay * stepsPerDay
  endPos=endDay * stepsPerDay

  time=indgen(endPos-startPos)/float(stepsPerDay) + startDay + 119-0.5
  data=data[startPos:endPos, *,*]

  set_colors, rainColor, keydaycolor, rainDayColor, nocolor=nocolor
  FOR curvar=0,n_elements(data[0,*,0])-1 DO BEGIN 
     IF var[curvar] EQ 'FCEV' THEN curvar++
     IF NOT keyword_set(yr) THEN thisyr=[max([-10,min(data[*,curvar,*])]), max(data[*,curvar,*])] $
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
     plot, time, data[*,curvar,0], yr=thisyr, /ys, /xs, l=1, $
           xtitle="Time (days)", ytitle=ytitles[varindex[curvar]], _extra=e, $
           title=var[curvar]

     IF keyword_set(rainday) THEN drawBackground, rainday, raindayColor, thisyr
     IF keyword_set(keyday) THEN drawBackground, keyday, keydayColor, thisyr

     FOR curfile=0,n_elements(data[0,0,*])-1 DO BEGIN
        oplot, time, data[*,curvar,curfile],l=1
     ENDFOR
     IF keyword_set(classmeans) THEN plotclassmeans, classmeans, var[curvar], $
       time, startPos, endPos, baseline=baseline
     IF keyword_set(measuredLE) THEN plotMeasured, measuredLE, var[curvar], baseline=baseline
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
FUNCTION read_flux_data, files, nfiles, vars, skipn=skipn, dt
;; chose how much data to read in
  IF NOT keyword_set(skipn) THEN skipn =1 ELSE BEGIN 
     IF nfiles GT 50 AND skipn EQ 1 THEN skipn=nfiles/50
  ENDELSE 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; read the first file, find the time step and setup the output data array
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  junk=load_cols(files[0], tmpData, /double)
  tmpData=readncdata(files[0], ['time',vars], /dataonly)
  sz=size(tmpData)

  dt=clmfinddt(tmpData[0,1:10]) ; skip the first time step as it is often different (for noah)

  data=fltarr(n_elements(tmpData[0,*]), n_elements(vars), nfiles/skipn+ (skipn NE 1))

  IF skipn GT 1 THEN print, "Skipping every"+strcompress(skipn)+" files"
  print, "| Time step =",fix(dt)," minutes                                  |", $
         format='(A,I6,A)'
  data[*,*,0]=transpose(float(tmpData[1:n_elements(vars),*]))

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
     tmpData=readncdata(files[i],vars, /dataonly)
     IF tmpData[0] EQ -1 THEN print, "ERROR with file ", files[i] ELSE $
       DATA[*,*,i/skipn]=transpose(float(tmpData[0:n_elements(vars)-1,*]))

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


PRO clm_plot_flux_texture, texture, var=var, outputfile=outputfile, skipn=skipn, $ 
  keyday=keyday, nops=nops, nocolor=nocolor, _extra=extra, $
  filepattern=filepattern, startday=sday, endday=eday, $
  yr=yr, rainday=rainday, classmeans=classmeans, measuredLE=measuredLE, $
  bestSHP=bestSHP, legend=legend, charsize=charsize, nosetup=nosetup

;; if improper input was entered show the user documentation and return
;  IF (n_elements(texture) EQ 0 AND NOT keyword_set(filepattern)) OR $
;    (NOT keyword_set(keyday) OR NOT (keyword_set(startday) AND keyword_set(endday))) THEN BEGIN
;     doc_library, 'clm_plot_flux_texture'
;     return
;  END

;; check for some keywords and set default values
  IF NOT keyword_set(var) THEN var=['FGEV', 'FCTR', 'FCEV', 'TG', 'H2OSOI']
  IF NOT keyword_set(outputfile) THEN outputfile=texture+'_plot.ps'
  IF NOT keyword_set(filepattern) THEN filepattern='out_'+texture+'_*'
  IF NOT keyword_set(sday) THEN startday=keyday-2.5
  IF NOT keyword_set(eday) THEN endday=keyday+10.5
  startday=sday+366
  endday=eday+366

;; find the data files to read
  files=file_search(filepattern, count=nfiles)
  IF nfiles EQ 0 THEN BEGIN
     files=file_search(strcompress(filepattern, /remove_all), count=nfiles)
     IF nfiles EQ 0 THEN BEGIN 
        doc_library, 'clm_plot_flux_texture'
        return
     ENDIF 
  ENDIF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; READ the data and do a little formatting
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  data=read_flux_data(files, nfiles, var, skipn=skipn, dt)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; if applicable setup postscript output
  IF NOT keyword_set(nops) AND NOT keyword_set(nosetup) THEN BEGIN 
     old=setupplot(filename=outputfile)
     !p.multi=[0,1,n_elements(var)]
     IF n_elements(var) EQ 1 THEN !p.multi=[0,1,2]
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
                  measuredLE=measuredLE, classmeans=classmeans, var=var, bestSHP=bestSHP, legend=legend

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; if applicable close postscript file
  IF NOT keyword_set(nops) AND NOT keyword_set(nosetup) THEN BEGIN 
     resetplot, old
  ENDIF ELSE IF NOT keyword_set(nosetup) THEN BEGIN
; else reset the graphical environment for X window plots
     !p=oldp
  ENDIF 
  
END
