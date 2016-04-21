PRO boxplotLE, f1, charsize=charsize, _extra=e, histo=histo
  
  IF n_elements(f1) EQ 0 THEN f1="fullStats2" ; file from convOUTS2one?
  varcol=
;  maxLimit=600
;  top=600
  ;; colors for plotting
  red  =256l^0
  green=256l^1
  blue =256l^2
  print, load_cols(f1, stats)

  maxLimit=max(stats[6,*])
  minLimit=min(stats[0,*])
  range=maxLimit-minLimit

  index=[0,2,3,4,6]
  n=7

  plot, [0],[0], xticks=1, xtickname=replicate(' ', 2), $
        /xs, xr=[-0.5,n_elements(stats[0,*])-0.5], $
        yr=[minLimit-range/20.0,maxLimit+range/10.0], $
        background=-1, color=0, /nodata, xminor=-1, _extra=e, /ys

  IF !d.name EQ 'X' THEN ltgrey=200*red + 200*green+200*blue ELSE ltgrey=7
;   polyfill, [0.5, 0.5,1.5,1.5],
;             [minLimit+1,maxLimit-1,maxLimit-1,minLimit+], color=ltgrey
;   polyfill, [2.5, 2.5,3.5,3.5],
;             [minLimit+1,maxLimit-1,maxLimit-1,minLimit+1], color=ltgrey
;   polyfill, [4.5, 4.5,5.5,5.5],
;             [minLimit+1,maxLimit-1,maxLimit-1,minLimit+1], color=ltgrey
;   polyfill, [6.5, 6.5,7.5,7.5],
;             [minLimit+1,maxLimit-1,maxLimit-1,minLimit+1], color=ltgrey
;   polyfill, [8.5, 8.5,9.5,9.5],
;             [minLimit+1,maxLimit-1,maxLimit-1,minLimit+1], color=ltgrey
  
  ;; draw and annotate x-axis
  axis,0,!y.window[0],/norm, color=0, $
       xticks=1,xtickname=replicate(' ', 2), $
       xminor=-1, _extra=e

;  boxplot, chnew[0:4,*], /is_percentile, group=1, background=-1, $
;           /quiet, count=fix(chnew[5,*]), $
;           boxwidth=0.2, boxpos=-0.25, /nAtMid, $
;           medianthick=3, charsize=charsize

  IF !d.name EQ 'X' THEN fc=red*153 +green*102 +blue*51 ELSE fc=1
  IF NOT keyword_set(histo) THEN BEGIN 
     boxplot, stats[index,*], /is_percentile, group=1, color=0, _extra=e, $
              /quiet, count=fix(stats[n,*]), fillcolor=fc, $
              boxwidth=0.75, boxpos=0.0, /overplot, $
              medianthick=3, charsize=charsize ;, mediancolor=256l^3-256l^2
;     boxplot, data[varCol,*]<maxLimit, group=data[1,*], color=0, _extra=e, $
;              /quiet, fillcolor=fc, printn=printn, $
  ENDIF ELSE BEGIN 
     histo_flux_plot, stats[varCol,*]<maxLimit, stats[1,*], /overplot, /nonames, $
                      _extra=e
  ENDELSE 

  openr, un, /get, "SoilNames.txt"
  line=""
  pos=minLimit-range/15.0-range/20.0
  off=range/20.0
  FOR i=0, n_elements(stats[0,*])-1 DO BEGIN 
     readf, un, line
;     IF !d.name EQ 'X' THEN cs=1.5 ELSE cs=0.5
     xyouts, i, pos+(i MOD 2)*off, align=0.5, line, charsize=(charsize/1.5), color=0
;     xyouts, i, top-1, align=0.5, "n", charsize=charsize
     IF eof(un) THEN break
  ENDFOR  
  close, un
  free_lun, un
END 
