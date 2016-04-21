;+
; NAME: clmPlotAllofSOil
;
; PURPOSE: Make postscript plots of relavent clm output variables with
;          one line for each soil listed in the current directory.
;          Finds soils with the name out_texture_number.
;          
;          Can also plot a subset of the total soils with the skipn keyword
;          Can make plots of just mid-day values with the noonOnly keyword
;          Can plot to screen with the nops keyword
;          
;
; CATEGORY: plot clm output
;
; CALLING SEQUENCE: plotAllofSoil, texture, T=T, TS=TS, SMC=SMC,
;                                           LHE=LHE, H=H, G=G,
;                                  outputfile=outputfile
;
; INPUTS: texture = a string identifying the filenames to look up as "out_texture_*"
;
; OPTIONAL INPUTS: all keywords are optional
;
; KEYWORD PARAMETERS: T = plot top soil temperature
;                     TS= plot skin temperature
;                     SMC=plot Soil Moisture Content (in top layer)
;                     LHE=plot Latent Heat Flux
;                     H = plot Sensible Heat Flux
;                     G = plot Ground Heat Flux
;
;                     By default all are plotted.
;                     If any keywords are set, only those keywords are plotted
;
; OUTPUTS: Postscript file named either outputfile, or if outputfile
;          is not specified, named <texture>.ps
;
; OPTIONAL OUTPUTS:
;
; COMMON BLOCKS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;         08/03/2004 - edg - original
;         09/??/2004 - edg - added noonsonly option,
;                           just plot LE,
;                           added skipn option
;                           added nops option
;         10/15/2004 - edg - added rainfall plotting
;         10/23/2004 - edg - added nocolor and nopattern keywords
;                           added title and position and nox keywords
;                           cleaned up rainfall axis and drawing
;         12/1/2004  - edg - modified plotAllofSoil to become clmPlotAllofSoil
;                           to plot clm output
;-

PRO plotData, data, smallPlot=smallPlot, nocolor=nocolor, nox=nox, $
              position=position, title=title, nopattern=nopattern, $
              yr=yr, ytitle=ytitle, xr=xr
  
  days=lindgen(n_elements(data[0,*,0]))/48.
  IF (n_elements(days) LT 5000) THEN days=days+624.5 ELSE days+=0.5
  IF NOT keyword_set(xr) THEN xr=[624.5,634.5]
  IF NOT keyword_set(yr) THEN yr=[0,500]
  IF NOT keyword_set(ytitle) THEN ytitle="Latent Heat (W/m!U2!N)"
;   plot, days, data[2,*,0], ytitle="Skin Temperature (K)", /ys, /xs, $
;         xr=xr, yr=[270,330]
;   FOR i=1, n_elements(data[0,0,*])-1 DO oplot, days, data[2,*,i]

;   plot, days, data[6,*,0], ytitle="Sensible Heat Flux", /ys, /xs, $
;         xr=xr, yr=[-100,700]
;   FOR i=1, n_elements(data[0,0,*])-1 DO oplot, days, data[6,*,i]

  IF keyword_set(smallPlot) THEN mul=20 ELSE mul=1
  plotpoints=lindgen(n_elements(data[0,*,0])/mul)*mul
  plotpointsindex=where(days[plotpoints] GE xr[0] AND days[plotpoints] LE xr[1])
  IF plotpointsindex[0] EQ -1 THEN return
  plotpoints=plotpoints[plotpointsindex]

;  days=days-365
;  xr=xr-365
  IF NOT keyword_set(nox) THEN BEGIN 
     xtitle="Day of the Year"
     xs=1
     ys=9
     plot, days[plotpoints], data[2,plotpoints,0], ytitle=ytitle, $
           xtitle=xtitle, ys=ys, xs=xs, $
           xr=xr, yr=yr, charsize=2, position=position, title=title
  endIF ELSE BEGIN
     xs=1
     ys=9
     plot, days[plotpoints], data[2,plotpoints,0], ytitle=ytitle, $
           xtitle=xtitle, ys=ys, xs=xs, xtickname=replicate(' ', 5),$
           xr=xr, yr=yr, charsize=2, position=position, title=title
     
  ENDELSE 

;; plot background color or linefill for measurement day
  IF NOT keyword_set(nocolor) THEN BEGIN 
     IF !d.name EQ 'PS' then color=4 ELSE color=(256.0^2)*200+250+200*256
  endIF ELSE BEGIN 
     IF !d.name EQ 'PS' then BEGIN 
        color=214
        IF NOT keyword_set(nopattern) THEN begin
           color=0 
           line_fill=1
           spacing=0.05
           orientation=180
        endIF
     ENDIF ELSE color=(256.0^2)*200+250+200*256
  endELSE 
  polyfill, [626,626,627,627]-364.5,[yr[0]+1,yr[1]-1,yr[1]-1,yr[0]+1], $
            color=color, line_fill=line_fill, orientation=orientation

;; plot background color or linefill for rain day
  IF NOT keyword_set(nocolor) THEN BEGIN 
     IF !d.name EQ 'PS' then color=6 ELSE color=(256.0^2)*250+200+200*256
  ENDIF ELSE BEGIN 
     IF !d.name EQ 'PS' then BEGIN 
        color=216
        IF NOT keyword_set(nopattern) THEN begin
           color=0 
           line_fill=1
           spacing=0.05
           orientation=90
        endIF
     ENDIF ELSE color=(256.0^2)*250+200+200*256
  endELSE 

  polyfill, [626,626,627,627]-365.5,[yr[0]+1,yr[1]-1,yr[1]-1,yr[0]+1], $
            color=color, line_fill=line_fill, orientation=orientation

;; plot rain fall
  index=where(days GE 261 AND days LT 262)
  IF NOT keyword_set(nocolor) THEN BEGIN 
     IF !d.name EQ 'PS' then color=3 ELSE color=(256.0^2)*170+00+00*256
  ENDIF ELSE BEGIN 
     IF !d.name EQ 'PS' then BEGIN 
        color=210 
     ENDIF ELSE color=(256.0^2)*250+200+200*256
  endELSE 

;; draw the right side y-axis
  axis, yaxis=1, yr=[yr[1]*0.006*10, 0], ytitle="Rainfall (mm/hr)", charsize=1.75
;; draw the rain

;  raingain=-1*(yr[1]-yr[0])*0.006*10
;  polyfill, [days[where(days LT xr[1] AND days GT xr[0])],xr[0]], $
;            [[(data[1,where(days LT xr[1] AND days GT xr[0]),0])/raingain+yr[1]], [[yr[1]]]], $
;            color=color

  FOR i=0, n_elements(data[0,0,*])-1 DO oplot, days[plotpoints], data[2,plotpoints,i]
;   plot, days, data[8,*,0], ytitle="Ground Heat Flux", /ys, /xs, $
;         xr=xr, yr=[-150,150]
;   FOR i=1, n_elements(data[0,0,*])-1 DO oplot, days, data[8,*,i]

;   plot, days, data[18,*,0], ytitle="Soil Moisture Content", /ys, /xs, $
;         xr=xr, yr=[0,0.8]
;   FOR i=1, n_elements(data[0,0,*])-1 DO oplot, days, data[18,*,i]

;   plot, days, data[19,*,0], ytitle="Soil Moisture Content", /ys, /xs, $
;         xr=xr, yr=[0,0.8]
;   FOR i=1, n_elements(data[0,0,*])-1 DO oplot, days, data[19,*,i]
;   plot, days, data[20,*,0], ytitle="Soil Moisture Content", /ys, /xs, $
;         xr=xr, yr=[0,0.8]
;   FOR i=1, n_elements(data[0,0,*])-1 DO oplot, days, data[20,*,i]
;   plot, days, data[10,*,0], ytitle="Soil Temperature", /ys, /xs, $
;         xr=xr, yr=[280,310]
;   FOR i=1, n_elements(data[0,0,*])-1 DO oplot, days, data[10,*,i]
;   plot, days, data[11,*,0], ytitle="Soil Temperature", /ys, /xs, $
;         xr=xr, yr=[280,310]
;   FOR i=1, n_elements(data[0,0,*])-1 DO oplot, days, data[11,*,i]

;  plot, days, data[10,*,0], ytitle="Soil 2.5cm Temperature (K)", /ys, /xs
;  FOR i=1, n_elements(data[0,0,*])-1 DO oplot, days, data[10,*,i]

END

PRO plotnoons, data, xr=xr
  days=lindgen(n_elements(data[0,*,0]))/480.
  IF (n_elements(days) LT 50000) THEN days=days+624
  IF NOT keyword_set(xr) THEN xr=[624,634]

;   plot, days, data[2,*,0], ytitle="Skin Temperature (K)", /ys, /xs, $
;         xr=xr, yr=[270,330]
;   FOR i=1, n_elements(data[0,0,*])-1 DO oplot, days, data[2,*,i]

;   plot, days, data[6,*,0], ytitle="Sensible Heat Flux", /ys, /xs, $
;         xr=xr, yr=[-100,700]
;   FOR i=1, n_elements(data[0,0,*])-1 DO oplot, days, data[6,*,i]

  days=days-365
  xr=xr-365
  ;; just get noon values
  index=where((days MOD 1)*24 GE 12.4 AND  (days MOD 1)*24 LT 12.6)
  plot, days[index], data[2,index,0], $
        ytitle="Latent Heat Flux (W/m!E2!N)", $
        xtitle="Day of the Year", $
        /ys, /xs, xr=xr, yr=[0,500]

  IF !d.name EQ 'PS' then color=4 ELSE color=(256.0^2)*200+250+200*256
  polyfill, [626,626,627,627]-365,[1,449,449,1], color=color
  IF !d.name EQ 'PS' then color=6 ELSE color=(256.0^2)*250+200+200*256
  polyfill, [626,626,627,627]-365-1,[1,449,449,1], color=color

  FOR i=0, n_elements(data[0,0,*])-1 DO oplot, days[index], data[2,index,i]

END


PRO clmplotAllofSoil, texture,  T=T, TS=TS, SMC=SMC, LHE=LHE, $
  H=H, G=G, outputfile=outputfile, smallPlot=smallPlot, $
  skipn=skipn, nops=nops, noonOnly=noonOnly, nocolor=nocolor, $
  nox=nox, position=position, title=title, nopattern=nopattern, $
  variable=variable, yr=yr, ytitle=ytitle, xr=xr

  texture=strcompress(texture, /remove_all)
  IF NOT keyword_set(outputfile) THEN outputfile=texture+'.ps'
  IF NOT keyword_set(variable) THEN variable='FGEV' ; default to latent heat

;; get the list of files to process
  files=file_search('out_'+texture+'_*')
  n_files=n_elements(files)

  IF n_files LE 1 THEN files=file_search(texture)
  n_files=n_elements(files)

;; read in the first file  
  print, "loading ",files[0]
  varnames=['time', 'RAIN', variable]

  done=0
  start=0
  WHILE NOT done DO BEGIN
     tmpData=readNCdata(files[start], varnames)
     tmpData=tmpData.data
     IF tmpData[0] EQ -1 THEN print, "ERROR with file ", files[0] ELSE $
       done=1
  ENDWHILE


  sz=size(tmpData)
  DATA=fltarr(sz[1], sz[2], n_elements(files))
  data[*,*,0]=tmpData

;; chose how much data to read in
  IF NOT keyword_set(skipn) THEN skipn =1 ELSE BEGIN 
     IF n_files GT 50 AND skipn EQ 1 THEN skipn=n_files/50
  ENDELSE 

;; read in input data (this can take a LONG time)
  FOR i=start, n_files-1,skipn DO BEGIN
     print, "loading ",files[i], 100.0*float(i)/(n_files-1), "% done", $
            format='(A8,A25,F7.1,A7)'
     tmpData=readNCdata(files[i], varnames)
     tmpData=tmpData.data
     IF tmpData[0] EQ -1 THEN print, "ERROR with file ", files[i] ELSE $
       DATA[*,*,i]=tmpData
  ENDFOR

;; if applicable setup postscript output
  IF NOT keyword_set(nops) THEN BEGIN 
     old=setupplot(filename=outputfile)
     !p.multi=[0,1,3]
  ENDIF 

;; all PLOTTING done here
  IF keyword_set(noonOnly) THEN plotNoons, Data ELSE $
    plotData, Data, smallPlot=smallPlot, nocolor=nocolor, nox=nox, $
              position=position, title=title, nopattern=nopattern, $
              yr=yr, ytitle=ytitle, xr=xr
              

;; if applicable close postscript file
  IF NOT keyword_set(nops) THEN BEGIN 
     resetplot, old
  ENDIF

END

