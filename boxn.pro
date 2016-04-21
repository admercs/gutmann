FUNCTION getSoilNum, soildata
  s =soildata[0,*]
  si=soildata[1,*]
  c =soildata[2,*]

  Sand=where(s-c/5.0 GT 88)
  LoamySand=where(s LT 90 AND s-c GT 70)
  SandyLoam=where(s-c LT 70 AND c lt 20 AND (s GT 52 OR (c LT 7 AND si LT 50)))
  SiltLoam=where(c LT 28 AND si GT 50 AND (si LT 20 OR c GT 12))
  Loam=where(s LT 52 AND si LT 50 AND si GT 28 AND c GT 7 AND c LT 28)
  SandyClayLoam=where(s GT 45 AND c GT 20 AND c LT 35 AND si LT 18)
  SiltyClayLoam=where(s LT 20 AND c GT 28 AND c LT 40)
  ClayLoam=where(s LT 46 AND s GT 20 AND c LT 40 AND c GT 28)
  SandyClay=where(s GT 45 AND c GT 35)
  SiltyClay=where(c GT 40 AND si GT 40)
  Clay=where(s LT 45 AND c GT 40 AND si LT 40)

  output=intarr(n_elements(s))
  
  output[Sand]=0
  output[LoamySand]=1
  output[SandyLoam]=2
  output[SiltLoam]=3
  output[Loam]=4
  output[SandyClayLoam]=5
  output[SiltyClayLoam]=6
  output[ClayLoam]=7
  output[SandyClay]=8
  output[SiltyClay]=9
  output[Clay]=10

  return, output
END


PRO boxn, f1, charsize=charsize, _extra=e, varCol=varCol, $
          overplot=overplot, fc=fc, yr=yr, noprintn=noprintn, minmax=minmax, $
          logem=logem, histo=histo, inverse=inverse, ntom=ntom
  
  IF NOT keyword_set(varCol) THEN varCol=11
  IF n_elements(f1) EQ 0 THEN f1="newRosetta.txt"
  IF NOT keyword_set(noprintn) THEN printn=1
  IF NOT keyword_set(charsize) THEN charsize=1

;  maxLimit=600
;  top=600
  ;; colors for plotting
  red  =256l^0
  green=256l^1
  blue =256l^2
  print, load_cols(f1, data)
  index=where(data[varCol,*] NE -9.9)
  IF varCol EQ 7 THEN index=where(data[varCol,*] GT 0)
  IF index[0] EQ -1 THEN BEGIN 
     print, "error no valid data points!"
     return
  ENDIF
  data=data[*,index]
  
;; to make the y axis log scale :
;;   comment this line,
;;   uncomment ylog=logem,
;;   uncomment lines down by the xyouts xaxis labeling section,
;;   add logem=logem to the histo_flux_plot call...
;;   then fix histo_flux_plot to do logs...
  IF keyword_set(logem) THEN data[varcol,*] = alog10(data[varcol,*])
  IF keyword_set(inverse) THEN data[varcol,*] = 1.0/(data[varcol,*])
  IF keyword_set(ntom) THEN data[varcol,*] = 1-(1.0/(data[varcol,*]))

  maxLimit=max(data[varCol,*])
  minLimit=min(data[varCol,*])
  range=maxLimit-minLimit

  soilsdex=getSoilNum(data[3:5,*])
  data[1,*]=soilsdex

  nsoils=max(data[1,*])+1
  IF NOT keyword_set(yr) THEN yr=[1,5]
  IF keyword_set(minmax) THEN BEGIN 
     yr=[min(data[varcol,*]),max(data[varcol,*])]
     print, yr
  ENDIF

  maxLimit=min([yr[1], maxLimit])
  IF NOT keyword_set(overplot) THEN BEGIN 
     IF NOT keyword_set(yr) THEN yr=[minLimit-range/100.0,maxLimit+range/10.0]

     plot, [0],[0], xticks=1, xtickname=replicate(' ', 2), $
           /xs, xr=[-0.5,nsoils-0.5], yr=yr, $;, ylog=logem, $
           background=-1, color=0, /nodata, xminor=-1, _extra=e, /ys

     minLimit=yr[0]
     maxLimit=yr[1]
     IF !d.name EQ 'X' THEN ltgrey=200*red + 200*green+200*blue ELSE ltgrey=7
     IF !d.name EQ 'X' THEN black=0 ELSE black=0
     polyfill, [0.5, 0.5,1.5,1.5], $
               [minLimit,maxLimit,maxLimit,minLimit], color=ltgrey
     polyfill, [2.5, 2.5,3.5,3.5], $
               [minLimit,maxLimit,maxLimit,minLimit], color=ltgrey
     polyfill, [4.5, 4.5,5.5,5.5], $
               [minLimit,maxLimit,maxLimit,minLimit], color=ltgrey
     polyfill, [6.5, 6.5,7.5,7.5], $
               [minLimit,maxLimit,maxLimit,minLimit], color=ltgrey
     polyfill, [8.5, 8.5,9.5,9.5], $
               [minLimit,maxLimit,maxLimit,minLimit], color=ltgrey
  ;; draw and annotate x-axis over the polygons we just drew.  
;     axis,0,!y.window[0],/norm, color=0, $
     axis,xaxis=1, color=black, $
          xticks=1,xtickname=replicate(' ', 2), $
          xminor=-1, _extra=e
     axis,xaxis=0, color=black, $
          xticks=1,xtickname=replicate(' ', 2), $
          xminor=-1, _extra=e

  endif
  range=maxLimit-minLimit


;  boxplot, chnew[0:4,*], /is_percentile, group=1, background=-1, $
;           /quiet, count=fix(chnew[5,*]), $
;           boxwidth=0.2, boxpos=-0.25, /nAtMid, $
;           medianthick=3, charsize=charsize

  IF NOT keyword_set(fc) THEN BEGIN 
     IF !d.name EQ 'X' THEN fc=red*153 +green*102 +blue*51 ELSE fc=206 ;;206=grey
; black    0
; red      1
; green    2
; blue     3
; l. red   4
; l. green 5
; l. blue  6
; l. grey  7
;   8-> 70 = smooth red colors
;  71->133 = smooth green colors
; 134->196 = smooth blue colors
; 197->207 = 11 colors selected from the 16 LEVEL color table
;
;      197,    198,   199,  200,  201,   202,  203,    204, 205,  206,   207
;  ~ dk.gr, mid.gr, lt.gr, cyan, blue, purp., mag., dk.mag, red, grey, white
;
; 208-217 = black->white
  ENDIF


  IF NOT keyword_set(histo) THEN BEGIN 
     boxplot, data[varCol,*]<maxLimit, group=data[1,*], color=0, _extra=e, $
              /quiet, fillcolor=fc, printn=printn, $
              boxwidth=0.75, boxpos=0.0, /overplot, $
              medianthick=3, charsize=charsize ;, mediancolor=256l^3-256l^2
  ENDIF ELSE BEGIN 
     histo_flux_plot, (data[varCol,*]<maxLimit)>minlimit, data[1,*], /overplot, /nonames, $
                      _extra=e, nbins=20
  ENDELSE 

  IF file_test("SoilNames.txt") THEN BEGIN
     openr, un, /get, "SoilNames.txt" 
  ENDIF ELSE IF file_test("database/SoilNames.txt") THEN $
    openr, un, /get, "database/SoilNames.txt"
  
  line=""
;
; remnants from trying to get the yaxis to be on a log scale rather than loging the data
;  IF keyword_set(logem) THEN BEGIN 
;     minLimit=alog10(minLimit)
;     maxLimit=alog10(maxLimit)
;     range=maxLimit-minLimit
;  ENDIF

  off=range/20.0
  pos=minLimit-range/15.0-off
  IF NOT keyword_set(overplot) THEN BEGIN 
;     print, off, pos
     FOR i=0, nsoils-1 DO BEGIN 
        readf, un, line
;     IF !d.name EQ 'X' THEN cs=1.5 ELSE cs=0.5
;        IF keyword_set(logem) THEN $
;          xyouts, i, 10.0^(pos+(i MOD 2)*off), align=0.5, line, $
;                  charsize=(charsize/1.2), color=black $
;        ELSE $
        xyouts, i, pos+(i MOD 2)*off, align=0.5, line, $
                charsize=(charsize/1.2), color=black
;     xyouts, i, top-1, align=0.5, "n", charsize=charsize
        IF eof(un) THEN break
     ENDFOR  
  endIF

  close, un
  free_lun, un
END 
