PRO makeBoxWhisker, f1, f2, f3, charsize=charsize, RosDo=RosDo, std=std, _extra=e
  
  IF n_elements(f1) EQ 0 THEN f1="CosbyStats.txt"
  IF n_elements(f2) EQ 0 THEN f2="ClappHornbergerStats.txt"
  IF n_elements(f3) EQ 0 THEN f3="RosettaStats.txt"
  IF n_elements(std) EQ 0 THEN std=[1,1,0]

  maxLimit=25
  top=25
  ;; colors for plotting
  red  =256l^0
  green=256l^1
  blue =256l^2
  print, load_cols(f1, ch)
  print, load_cols(f2, cos)

  IF not keyword_set(RosDo) THEN print, load_cols(f3, ros) ELSE BEGIN 
     print, load_cols(f3, ros)
     rosnew=[10.0^(ros[0,*]-ros[1,*]),10.0^(ros[0,*]-ros[1,*]), $
             10.0^(ros[0,*]), $
             10.0^(ros[0,*]+ros[1,*]),10.0^(ros[0,*]+2*ros[1,*]), ros[2,*]]
     n=rosnew[0:4,*]
     ;; convert via Morel-Seytoux et al relationship
     ;rosnew[0:4,*]=1.0/(n-1.0)<maxLimit
     ;; or via Lenhard et al
     rosnew[0:4,*]=1.0/(n-1.0) * 1.0/(1-0.5^(n/(n-1.0)))<maxLimit
     ;print, rosnew
  endELSE 

  chnew=ch
  cosnew=cos
  rosnew=ros
  IF std[0] THEN $
    chnew=([ch[0,*]-3*ch[1,*],ch[0,*]-ch[1,*],ch[0,*], $
            ch[0,*]+ch[1,*],ch[0,*]+3*ch[1,*], ch[2,*]]>0)
  IF std[1] THEN $
    cosnew=([cos[0,*]-3*cos[1,*],cos[0,*]-cos[1,*],cos[0,*], $
             cos[0,*]+cos[1,*],cos[0,*]+3*cos[1,*], cos[2,*]]>0)
  IF std[2] THEN $
    rosnew=([ros[0,*]-3*ros[1,*],ros[0,*]-ros[1,*],ros[0,*], $
             ros[0,*]+ros[1,*],ros[0,*]+3*ros[1,*], ros[2,*]]>0)

  rosnew[0:4,*]=rosnew[0:4,*]<maxLimit
  rosnew[0:4,*]=rosnew[0:4,*]>0

  chnew[0:4,*]=chnew[0:4,*]<maxLimit
  chnew[0:4,*]=chnew[0:4,*]>0

  cosnew[0:4,*]=cosnew[0:4,*]<maxLimit
  cosnew[0:4,*]=cosnew[0:4,*]>0

  badDex=where(rosnew[5,*] LT 5)
  IF badDex[0] NE -1 THEN rosnew[0:4,badDex]=0
  badDex=where(cosnew[5,*] LT 5)
  IF badDex[0] NE -1 THEN cosnew[0:4,badDex]=0
  badDex=where(chnew[5,*] LT 5)
  IF badDex[0] NE -1 THEN chnew[0:4,badDex]=0

  plot, [0],[0], xticks=1, xtickname=replicate(' ', 2), $
        /xs, xr=[-0.5,n_elements(ch[0,*])-0.5], yr=[0,maxlimit], $
        background=-1, color=0, /nodata, xminor=-1, _extra=e

  IF !d.name EQ 'X' THEN ltgrey=200*red + 200*green+200*blue ELSE ltgrey=7
  polyfill, [0.5, 0.5,1.5,1.5], [0,maxLimit,maxLimit,0], color=ltgrey
  polyfill, [2.5, 2.5,3.5,3.5], [0,maxLimit,maxLimit,0], color=ltgrey
  polyfill, [4.5, 4.5,5.5,5.5], [0,maxLimit,maxLimit,0], color=ltgrey
  polyfill, [6.5, 6.5,7.5,7.5], [0,maxLimit,maxLimit,0], color=ltgrey
  polyfill, [8.5, 8.5,9.5,9.5], [0,maxLimit,maxLimit,0], color=ltgrey
  
  ;; draw and annotate x-axis
  axis,0,!y.window[0],/norm, color=0, $
       xticks=1,xtickname=replicate(' ', 2), $
       xminor=-1, _extra=e

;  boxplot, chnew[0:4,*], /is_percentile, group=1, background=-1, $
;           /quiet, count=fix(chnew[5,*]), $
;           boxwidth=0.2, boxpos=-0.25, /nAtMid, $
;           medianthick=3, charsize=charsize

  IF !d.name EQ 'X' THEN fc=red*153 +green*102 +blue*51 ELSE fc=1
  boxplot, chnew[0:4,*], /is_percentile, group=1, color=0, _extra=e, $
           /quiet, count=fix(chnew[5,*]), fillcolor=fc, $
           boxwidth=0.2, boxpos=-0.25, /nAtMid, /overplot, $
           medianthick=3, charsize=charsize;, mediancolor=256l^3-256l^2

  IF !d.name EQ 'X' THEN fc=256l^2-255-(100l*256) ELSE fc=2
  boxplot, cosnew[0:4,*], /is_percentile, group=1, color=0, _extra=e, $
           /quiet, count=fix(cosnew[5,*]), fillcolor=fc, $;256l^2-25-(256l*25), $
           boxwidth=0.2, /overplot, /nAtMid, $
           medianthick=3, charsize=charsize;, mediancolor=256l^3-256l^2

  IF !d.name EQ 'X' THEN fc=red*128 +blue*128 ELSE fc=3
  boxplot, rosnew[0:4,*], /is_percentile, group=1, color=0, _extra=e, $
           /quiet, count=fix(rosnew[5,*]), fillcolor=fc , $;256l^2-255-(100l*256), $
           boxwidth=0.2, boxpos=0.25, /overplot, /nAtMid, $
           medianthick=3, charsize=charsize ;, mediancolor=256l^3-256l^2
  
;  oplot, [1.5,1.5,2.5,2.5,3.5,3.5,4.5,4.5,5.5,5.5, $
;          6.5,6.5,7.5,7.5,8.5,8.5,9.5,9.5,10.5,10.5]-1, $
;         [0,200,200,0,0,200,200,0,0,200,200,0,0,200,200,0,0,200,200,0], $
;         thick=2, l=1, color=100*red + 100*green +100*blue

  openr, un, /get, "SoilNames.txt"
  line=""
  FOR i=0, n_elements(rosnew[0,*])-1 DO BEGIN 
     readf, un, line
;     IF !d.name EQ 'X' THEN cs=1.5 ELSE cs=0.5
     xyouts, i, -1.5+(i MOD 2)/1.5, align=0.5, line, charsize=charsize/1.2, color=0
;     xyouts, i, top-1, align=0.5, "n", charsize=charsize
     IF eof(un) THEN break
  ENDFOR  
  close, un
  free_lun, un
END 
