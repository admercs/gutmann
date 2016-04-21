;; read through a file expected to have one string on each line
;;  the string will be in the format out_<texture>_shpindex
;;  collect the list of shpindices and return them as an array
FUNCTION readshpindex, shpfile

  line=''
  openr, un, /get, shpfile

;; read through the file until we reach the end
  WHILE NOT eof(un) DO BEGIN 
;; read a line from the file
     readf, un, line

     IF strlen(line) GT 5 THEN BEGIN ; watch out for a blank line

;; find the current index
        curindex=(strsplit(line, '_', /extract))[2]

;; add the current index to the list (or create the list if it doesn't exist yet)
        IF n_elements(fullindex) EQ 0 THEN fullindex=fix(curindex) $
        ELSE fullindex=[fullindex, fix(curindex)]
;; add the current filename to the list (or create the list if it doesn't exist yet)
        IF n_elements(filelist) EQ 0 THEN filelist=line $
        ELSE filelist=[filelist, line]
     ENDIF 
  ENDWHILE

;; clean up file IO and return the result
  close, un
  free_lun, un
  return, {index:fullindex, filelist:filelist}
END


FUNCTION readSHPs, rosettafile, shpfile, goodshps=goodshps
  junk=load_cols(rosettafile, data)
  shpfileinfo=readshpindex(shpfile)
  shpindex=shpfileinfo.index

  IF NOT keyword_set(goodshps) THEN goodshps=indgen(n_elements(shpindex))
  
;; column numbers in the Rosetta database
  vgncolumn=11
  alphacolumn=10
  kscolumn=7
  tscolumn=9
  trcolumn=8
  indexcolumn=0

;; create output arrays
  nshps=n_elements(goodshps)
  vgn=fltarr(nshps)
  alpha=fltarr(nshps)
  ks=fltarr(nshps)
  ts=fltarr(nshps)
  tr=fltarr(nshps)

;; loop through shp indices saving shp data for each in output arrays
  FOR i=0, nshps-1 DO BEGIN 
     j=goodshps[i]
     curshp=(where(data[indexcolumn,*] EQ shpindex[j]))[0]
     IF curshp NE -1 THEN BEGIN 
        vgn[i]=data[vgncolumn,curshp]
        alpha[i]=data[alphacolumn,curshp]
        ks[i]=data[kscolumn,curshp]
        ts[i]=data[tscolumn,curshp]
        tr[i]=data[trcolumn,curshp]
     ENDIF ELSE $
       print, "ERROR : couldn't find current SHP index in database : ", shpindex[i], i
     
  ENDFOR

;; find min and max ks and alpha values
  ksmax=max(data[kscolumn,*])
  ksmin=min(data[kscolumn,where(data[kscolumn,*] GT 0)]) ; remove -9.9 fill values
  alphamax=max(data[alphacolumn,*])
  alphamin=min(data[alphacolumn,*])

  return, {files:shpfileinfo.filelist[goodshps], index:shpindex[goodshps], $
           vgn:vgn, alpha:alpha, ks:ks, ts:ts, tr:tr, $
           ksmax:ksmax, ksmin:ksmin, alphamax:alphamax, alphamin:alphamin}
END


FUNCTION getModelLE, shps, events
  LEcol=7
  days=3
  startcol=1
  endcol=2

  maxdays=max(events[days,*])+3
  nevents=n_elements(events[0,*])

  nsteps=48 ;; assumes 48 model time steps per day
  LEdata=fltarr(nevents,maxdays*nsteps,n_elements(shps.files))

  FOR i=0, n_elements(shps.files)-1 DO BEGIN 
     junk=load_cols(shps.files[i], data)
     curLEflux=data[LEcol,*]

     FOR curevent=0, nevents-1 DO BEGIN 
        startpoint=nsteps*(events[startcol,curevent]-1)
        endpoint=nsteps*events[endcol,curevent]

        LEdata[curevent, 0:endpoint-startpoint, i] = transpose(curLEflux[startpoint:endpoint])
     ENDFOR

  ENDFOR

  return, LEdata
END

FUNCTION getMeasuredLE, events, measurementfile
  junk=load_cols(measurementfile, data)
  fluxdata=data[1,*]
  startcol=1
  endcol=2
  days=3
  nsteps=48 ; assumes 48 time steps per day

  maxdays=max(events[days,*])+2
  nevents=n_elements(events[0,*])

  LEdata=fltarr(nevents,maxdays*nsteps)

  FOR i=0,nevents-1 DO BEGIN 
     startpoint=(events[startcol,i]-1)*nsteps
     endpoint=   events[  endcol,i]   *nsteps
                  
     LEdata[i,0:endpoint-startpoint]=transpose(fluxdata[startpoint:endpoint])

  ENDFOR
     

  return, LEdata
END

PRO plotrainevent, i, modelledLE, measuredLE, rainevents, _extra=e, goodshps=goodshps
  time=lindgen(48*(rainevents[3,goodshps[i]]+1))/48.0 + rainevents[2,goodshps[i]] - 0.5
  plot, time, measuredLE[goodshps[i],*], /xs, yr=[-100,700], /ys, $
        title="Rain="+string(rainevents[4,goodshps[i]], format='(F5.1)')+"mm"
  FOR curshp=0, n_elements(modelledLE[0,0,*])-1 DO BEGIN
     oplot, time, modelledLE[goodshps[i],*,curSHP], l=1
  ENDFOR
  oplot, time, modelledLE[goodshps[i],*,i], color=1, thick=2
  oplot, time, measuredLE[goodshps[i],*], color=2, thick=2

END

FUNCTION load_soilparm, file
  openr, un, /get, file
  line=''
  FOR i=1,3 DO readf, un, line

  WHILE NOT eof(un) DO BEGIN 
     readf, un, line
     splitline=strsplit(line, ',', /extract)
     curdata=float(splitline[0:10])
     IF n_elements(data) EQ 0 THEN data=curdata $
     ELSE data=[[data],[curdata]]
  ENDWHILE 

  return, data
END


;; essentially identical to the plot procedure, but allows symbol size to vary on a
;; per point basis
PRO plotshps, x, y, symbolsize=symbolsize, good=good, psym=psym, $
              class=class, xave=xave, yave=yave, xvar=xvar, yvar=yvar, _extra=e

  plot, x, y, /nodata, _extra=e

  IF !d.name EQ 'X' THEN bgcol=255 ELSE bgcol=7

  IF keyword_set(xave) AND keyword_set(xvar) $
    AND keyword_set(yave) AND keyword_set(yvar) THEN BEGIN 
     polyfill, (1-1/(10.0^[xave-xvar,xave-xvar,xave+xvar,xave+xvar]))>0.00, $
               10.0^[yave-yvar, yave+yvar, yave+yvar, yave-yvar], color=bgcol
     plots, 1-1/(10.0^xave), 10.0^yave, psym=2;, color=1
     axis, yaxis=0, /ys
  ENDIF 

  FOR i=0, n_elements(good)-1 DO BEGIN 
     IF good[i] LT n_elements(symbolsize) THEN BEGIN 
        plots, x[i], y[i], psym=psym, symsize=symbolsize[good[i]]
     ENDIF ELSE $
       plots, x[i], y[i], psym=psym+1
  ENDFOR

  IF keyword_set(class) THEN BEGIN 
     oplot, class[0,*], class[1,*], psym=1, symsize=0.5
     plots, class[0,2],class[1,2], psym=2, symsize=0.5
  ENDIF
  

END


PRO analyze_multistorm, rainfile, shpfile, measuredfile, rosetta=rosetta, $
  goodshps=goodshps, soilparmfile=soilparmfile, _extra=e, $
  rainsize=rainsize, classes=classes, shpsonly=shpsonly, $
  measuredSHPs=measuredSHPs

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; use default input variables if not specified
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  IF NOT keyword_set(rosetta) THEN rosetta='newRosetta.txt'
  IF NOT keyword_set(soilparmfile) THEN soilparmfile='../database/SOILPARM.TBL'
  IF n_elements(rainfile) EQ 0 THEN BEGIN 
     rainfile=(file_search('*multirain'))[0]
     print, "rainfile not specified, using : ", rainfile
  ENDIF
  IF n_elements(shpfile) EQ 0 THEN BEGIN 
     shpfile=(file_search('*multistorm'))[0]
     print, "shpfile not specified, using : ", shpfile
  ENDIF
  IF n_elements(measuredfile) EQ 0 THEN BEGIN 
     measuredfile=(file_search('IHOPUDS*.txt'))[0]
     print, "measuredfile not specified, using : ", measuredfile
  ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Read in SHP, rain/drydown data, and Latent heat flux records 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; read best fit shps
  shps=readSHPs(rosetta, shpfile, goodshps=goodshps)
;; load the duration of drydowns and size of rain events
  junk=load_cols(rainfile, rainevents)

  IF NOT keyword_set(shpsonly) THEN BEGIN 
;; read the modelled Latent heat flux for all of the best fit shps
;; for all of the rainevent drydowns
     modelledLE=getModelLE(shps, rainevents)
;; read the measured Latent heat flux for all of the rainevent drydowns
     measuredLE=getMeasuredLE(rainevents, measuredfile)

  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Plot LE data
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     n_events=n_elements(rainevents[0,*])
     IF n_events GT 4 THEN cols=2 ELSE cols=1
     !p.multi=[0, cols, round(n_events/cols<4)]
     FOR i=0, n_elements(goodshps)-1 DO BEGIN 
        IF goodshps[i] LT n_events THEN $
          plotRainEvent, i, modelledLE, measuredLE, rainevents, _extra=e, goodshps=goodshps
     ENDFOR
     
     
     read, junk                 ; pause for the user to look at the data
  ENDIF 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Plot SHP data
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  !p.multi=[0,2,3]

;; load soil texture class average values from a SOILPARM.TBL file
  class=load_soilparm(soilparmfile)
;; change the units to match Rosetta units
  class[7,*]*=(24l*60*60*100.0)
  class[6,*]/=100
;; subset to the 12 USDA texture classes (removes bedrock, organic, land-ice, etc. classes)
  class=class[*,0:11]

  nave=0.161
  ksave=1.583
  nvar=0.11*2 ; two sigma
  ksvar=0.66*2 ; two sigma

  IF keyword_set(rainsize) THEN symbolsize=reform(rainevents[4,*])/15

  symbol=4 ; symbol to use when plotting shps
; m vs log(Ks)
  IF keyword_set(classes) THEN curclasses=[1-1/class[1,*], class[7,*]]
  plotshps, 1-1.0/shps.vgn, shps.ks, /ylog, psym=symbol, $
            xr=[0,1], yr=[shps.ksmin, shps.ksmax], /xs, /ys, $
            xtitle="van Genuchten m", ytitle="Ks [cm/day]", $
            symbolsize=symbolsize, good=goodshps, $
            class=curclasses, $
            xave=nave, yave=ksave, xvar=nvar, yvar=ksvar

  measuredm=  [  0.632, 0.597, 0.534, 0.648, 0.766]
  measuredks=  [11.491,33.955,20.736, 6.652,22.464]
  measuredalpha=[0.0622,0.0786,0.0680,0.0611,0.0766]
  txtm=[0.314,0.309,0.280,0.318,0.285,0.282,0.282,0.284]
  txtks=[54.20,51.71,27.01,56.35,29.71,30.43,31.24,35.59]
  txtavealpha=10^(1.574)
  IF keyword_set(measuredSHPs) THEN BEGIN
     oplot, measuredm, measuredks, /psym
     oplot, txtm, txtks, psym=4
  ENDIF


; 1/alpha vs log(Ks)
  IF keyword_set(classes) THEN curclasses=[1.0/class[6,*], class[7,*]]
  plotshps, 1.0/shps.alpha, shps.ks, /ylog, /xlog, psym=symbol, $
            xr=[1,10000], yr=[shps.ksmin, shps.ksmax], /xs, /ys, $
            xtitle='1/alpha = Water Potential mid-point [cm]', ytitle="Ks [cm/day]", $
            symbolsize=symbolsize, good=goodshps, class=curclasses
  IF keyword_set(measuredSHPs) THEN BEGIN
    oplot, 1/measuredalpha, measuredks, /psym
;    plots, 1/txtavealpha, ksave, psym=2
 ENDIF 
; m vs 1/alpha
  IF keyword_set(classes) THEN curclasses=[1-1/class[1,*], 1.0/class[6,*]]
  plotshps, 1-1.0/shps.vgn, 1/shps.alpha, psym=symbol, $
           xr=[0,1], yr=[1,10000], /xs, /ys, /ylog, $
            xtitle="van Genuchten m", $
            ytitle='1/alpha = Water Potential mid-point [1/cm]', $
            symbolsize=symbolsize, good=goodshps, class=curclasses
  IF keyword_set(measuredSHPs) THEN BEGIN
     oplot, measuredm, 1/measuredalpha, /psym
;     plots, 1-1/nave, 1/txtavealpha, psym=2
  ENDIF
  
; residual vs saturated moisture content
  IF keyword_set(classes) THEN curclasses=class[[2,4],*]
  plotshps, shps.tr, shps.ts, psym=symbol, $
            xr=[-0.05,0.3], yr=[0.2,0.85], /xs, /ys, $
            xtitle="Residual Moisture Content", ytitle="Saturated Moisture Content", $
            symbolsize=symbolsize, good=goodshps, class=curclasses
  
  IF keyword_set(rainsize) THEN BEGIN 
     plot, [0,1],[0,1], /nodata, psym=3, title=Legend
     xyouts, align=0.5, 0.5, 0.9, "Storm Size"
     FOR i=5, 30, 5 DO BEGIN 
        plots, 0.1, 0.0+((1./8)*i/5.0), psym=symbol, symsize=i/15.0
        xyouts,0.34, -0.02+(1/8.0)*i/5.0, strcompress(i)+"mm", align=0.5
     ENDFOR
     plots, 0.52, 0.62, psym=1, symsize=0.5
     xyouts, 0.5, 0.6, "    = class averages", charsize=0.5
     plots, 0.52, 0.52, psym=2, symsize=0.5
     xyouts, 0.5, 0.5, "    = sandy loam", charsize=0.5
  ENDIF 

  return ; don't bother with the other plots

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; same plots but let xr and yr vary with the data rather than with possible ranges
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  read, junk ; pause for the user to look at the data
  !p.multi=[0,2,3]
  
; m vs log(Ks)
  plot, 1-1.0/shps.vgn, shps.ks, /ylog, psym=symbol, $
        xtitle="van Genuchten m", ytitle="Ks [cm/day]"
; 1/alpha vs log(Ks)
  plot, 1.0/shps.alpha, shps.ks, /ylog, psym=symbol, $
        xtitle='1/alpha = Water Potential mid-point [cm]', ytitle="Ks [cm/day]"
; m vs 1/alpha
  plot, 1-1.0/shps.vgn, 1/shps.alpha, psym=symbol, $
        xtitle="van Genuchten m", ytitle='1/alpha = Water Potential mid-point [cm]'
  
; residual vs saturated moisture content
  plot, shps.tr, shps.ts, psym=symbol, $
        xtitle="Residual Moisture Content", ytitle="Saturated Moisture Content"
  
END

