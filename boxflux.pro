PRO boxflux, f1, charsize=charsize, varCol=varCol, $
             overplot=overplot, fc=fc, yr=yr, noprintn=noprintn, nocolor=nocolor, $
             _extra=e, hist=hist
  
  IF NOT keyword_set(varCol) THEN varCol=12
  IF n_elements(f1) EQ 0 THEN f1="noonCombined"
  IF NOT keyword_set(noprintn) THEN printn=1
  IF keyword_set(nocolor) THEN fccolor=214 ELSE fccolor=4
;  maxLimit=600
;  top=600
  ;; colors for plotting
  red  =256l^0
  green=256l^1
  blue =256l^2
  junk= load_cols(f1, data)

  IF keyword_set(hist) THEN BEGIN 
     histo_flux_plot, data[varCol, *], data[1,*], yr=yr, _extra=e, othercharsize=charsize
     return
  ENDIF 


  maxLimit=max(data[varCol,*])
  minLimit=min(data[varCol,*])
  range=maxLimit-minLimit

  nsoils=max(data[1,*])+1

  IF NOT keyword_set(overplot) THEN BEGIN 
     IF NOT keyword_set(yr) THEN yr=[minLimit-range/100.0,maxLimit+range/10.0]
     plot, [0],[0], xticks=1, xtickname=replicate(' ', 2), $
           /xs, xr=[-0.5,nsoils-1.5], yr=yr, $
           background=-1, color=0, /nodata, xminor=-1, _extra=e, /ys
  ;; draw and annotate x-axis
     axis,0,!y.window[0],/norm, color=0, $
          xticks=1,xtickname=replicate(' ', 2), $
          xminor=-1, _extra=e
     minLimit=yr[0]
     maxLimit=yr[1]
  endif
  range=maxLimit-minLimit

  IF !d.name EQ 'X' THEN ltgrey=200*red + 200*green+200*blue ELSE ltgrey=7
    polyfill, [0.5, 0.5,1.5,1.5], $
              [minLimit+1,maxLimit-1,maxLimit-1,minLimit+1], color=ltgrey
    polyfill, [2.5, 2.5,3.5,3.5], $
              [minLimit+1,maxLimit-1,maxLimit-1,minLimit+1], color=ltgrey
    polyfill, [4.5, 4.5,5.5,5.5], $
              [minLimit+1,maxLimit-1,maxLimit-1,minLimit+1], color=ltgrey
    polyfill, [6.5, 6.5,7.5,7.5], $
              [minLimit+1,maxLimit-1,maxLimit-1,minLimit+1], color=ltgrey
    polyfill, [8.5, 8.5,9.5,9.5], $
              [minLimit+1,maxLimit-1,maxLimit-1,minLimit+1], color=ltgrey

;  boxplot, chnew[0:4,*], /is_percentile, group=1, background=-1, $
;           /quiet, count=fix(chnew[5,*]), $
;           boxwidth=0.2, boxpos=-0.25, /nAtMid, $
;           medianthick=3, charsize=charsize

  IF NOT keyword_set(fc) THEN BEGIN 
     IF !d.name EQ 'X' THEN fc=red*153 +green*102 +blue*51 ELSE fc=fccolor
  ENDIF

  boxplot, data[varCol,*], group=data[1,*], color=0, _extra=e, $
           /quiet, fillcolor=fc, printn=printn, $
           boxwidth=0.75, boxpos=0.0, /overplot, $
           medianthick=3, charsize=charsize;, mediancolor=256l^3-256l^2

  openr, un, /get, "SoilNames.txt"
  line=""
  off=range/25.0
  pos=minLimit-range/15.0-off
  IF NOT keyword_set(overplot) THEN BEGIN 
;     print, off, pos
     FOR i=0, nsoils-1 DO BEGIN 
        readf, un, line
;     IF !d.name EQ 'X' THEN cs=1.5 ELSE cs=0.5
        xyouts, i, pos+(i MOD 2)*off, align=0.5, line, charsize=(charsize/1.2), color=0
;     xyouts, i, top-1, align=0.5, "n", charsize=charsize
        IF eof(un) THEN break
     ENDFOR  
  endIF

  close, un
  free_lun, un

;  IF keyword_set(hist) THEN histo_flux_plot, data[varCol, *], data[1,*], _extra=e

END 
