PRO makeRosBoxPlot, f1, charsize=charsize, _extra=e
  
  IF n_elements(f1) EQ 0 THEN f1="RosVGStat"

  maxLimit=5
  top=5
  ;; colors for plotting
  red  =256l^0
  green=256l^1
  blue =256l^2
  print, load_cols(f1, ros)

  ros[0:4,*]=ros[0:4,*]<maxLimit
  ros[0:4,*]=ros[0:4,*]>0
  index=[4,3,2,1,0]
  
  plot, [0],[0], xticks=1, xtickname=replicate(' ', 2), $
        /xs, xr=[-0.5,n_elements(ros[0,*])-0.5], yr=[1,maxlimit], $
        background=-1, color=0, /nodata, xminor=-1, _extra=e

  IF !d.name EQ 'X' THEN ltgrey=200*red + 200*green+200*blue ELSE ltgrey=7
;   polyfill, [0.5, 0.5,1.5,1.5], [1,maxLimit,maxLimit,1], color=ltgrey
;   polyfill, [2.5, 2.5,3.5,3.5], [1,maxLimit,maxLimit,1], color=ltgrey
;   polyfill, [4.5, 4.5,5.5,5.5], [1,maxLimit,maxLimit,1], color=ltgrey
;   polyfill, [6.5, 6.5,7.5,7.5], [1,maxLimit,maxLimit,1], color=ltgrey
;   polyfill, [8.5, 8.5,9.5,9.5], [1,maxLimit,maxLimit,1], color=ltgrey
  
  ;; draw and annotate x-axis
  axis,0,!y.window[0],/norm, color=0, $
       xticks=1,xtickname=replicate(' ', 2), $
       xminor=-1, _extra=e


  IF !d.name EQ 'X' THEN fc=red*128 +blue*128 ELSE fc=3
  boxplot, ros[index,*], /is_percentile, group=1, color=0, _extra=e, $
           /quiet, count=fix(ros[5,*]), fillcolor=fc , $;256l^2-255-(100l*256), $
           boxwidth=0.75, boxpos=0.0, /overplot, $;/nAtMid, $
           medianthick=3, charsize=charsize ;, mediancolor=256l^3-256l^2
  
  openr, un, /get, "SoilNames.txt"
  line=""
  FOR i=0, n_elements(ros[0,*])-1 DO BEGIN 
     readf, un, line
;     IF !d.name EQ 'X' THEN cs=1.5 ELSE cs=0.5
     xyouts, i, 0.7+(i MOD 2)/7.0, align=0.5, line, charsize=charsize/1.5, color=0
;     xyouts, i, top-1, align=0.5, "n", charsize=charsize
     IF eof(un) THEN break
  ENDFOR  
  close, un
  free_lun, un
END 
