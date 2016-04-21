;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; takes the similar input style as boxplot.pro
;;
;; given a an array of integers identifying which group each row in the data array belongs to
;;  plot histograms of each group in their own column.  
;;
;; usually called from boxflux.pro when the histo keyword is set in the call to boxflux
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO histo_flux_plot, data, group, overplot=overplot, yr=yr, nonames=nonames, $
                     noskip=noskip, _extra=e, $
                     true=true, classAve=classAve, best=best, $
                     othercharsize=othercharsize, logem=logem, $
                     highlightCol=highlightCol, nbins=nbins


;  IF keyword_set(best) AND n_elements(best) LE 1 THEN best=getbestFit()
;  IF keyword_set(classAve) AND n_elements(classAve) LE 1 THEN classAve=getclassAve()
;  IF keyword_set(true) AND n_elements(true) LE 1 THEN true=gettruth()

  IF NOT keyword_set(othercharsize) THEN othercharsize=1.0
  IF NOT keyword_set(noskip) THEN noskip=0
  stop_group  = max(group)+noskip
  start_group = min(group)
  
;  print, start_group, stop_group

  datatop=max(data)
  maxLimit=500
  maxlimit=datatop
  databot=min(data)
  minlimit=0
;  IF !d.name NE 'PS' THEN BEGIN 
;     oldp=!p
;     !p.background=(256^3.0)-1
;     !p.color=0
;  ENDIF 
  red  =256l^0
  green=256l^1
  blue =256l^2

  
  xr=[start_group-0.6, stop_group-0.5]
  IF NOT keyword_set(yr) THEN $
    yr=[0,datatop+0.1*(datatop-databot)]
  maxlimit=yr[1]

  IF keyword_set(overplot) THEN BEGIN 
     yr=!y.crange
     xr=!x.crange
  ENDIF

  IF NOT keyword_set(overplot) THEN $
    plot, [0],[0], /xs, xticks=1, xtickname=replicate(' ',2), $
          xr=xr, yr=yr, /ys, _extra=e
  
  IF NOT keyword_set(fc) THEN BEGIN 
     IF !d.name EQ 'X' THEN fc=red*153 +green*102 +blue*51 ELSE fc=4
  ENDIF

  IF NOT keyword_set(overplot) THEN BEGIN 
;; draw the background grey rectangles
     IF !d.name EQ 'X' THEN ltgrey=200*red + 200*green+200*blue ELSE ltgrey=7
     offset=0.01*(yr[1]-yr[0])
     FOR i=xr[0]+1,xr[1]-1,2 DO $
       polyfill, [i, i,i+1,i+1], $
                 [minLimit+offset,maxLimit-offset,maxLimit-offset,minLimit+offset], color=ltgrey
     IF keyword_set(highlightCol) THEN BEGIN
        IF !d.name EQ 'X' THEN hc=red*103 +green*153 +blue*51 ELSE hc=5        ; yellow
        polyfill, [highlightCol-0.6,highlightCol-0.55,highlightCol+0.5,highlightCol+0.5], $
                  [minLimit+offset,maxLimit-offset,maxLimit-offset,minLimit+offset], color=hc
;        print, highlightCol
     ENDIF
     
  endIF

  xoff=0
  FOR curGroup=start_group, stop_group DO BEGIN 

     index=where(group EQ curGroup)
     IF index[0] NE -1 THEN BEGIN
        top=max(data[index])
        bot=min(data[index])
;        nbins=max([n_elements(index)/20, 10])  ; generall 10, 15 for one
        IF NOT keyword_set(nbins) THEN nbins=15
        hist=histogram(data[index], min=bot, max=top, nbins=nbins)
;        yvals=((indgen(nbins)+0.5) / $         ; + 0.5 centers the histogram bins 
;               float(nbins)) * (max(data[index])-min(data[index])) + min(data[index]) 
        yvals=((indgen(nbins)) / $         ; + 0.5 centers the histogram bins 
               float(nbins)) * (max(data[index])-min(data[index])) + min(data[index]) 
                                ;around the true values
                                ; normalize the histogram position and
                                ; put it into the correct range
        yvals=rebin(yvals, n_elements(yvals)*2, /sample)
        yvals=[yvals,top]
        hist=rebin(hist, n_elements(hist)*2, /sample)
        hist=[0,hist]

        maxhist=max(hist)
        xvals=hist/float(maxhist)*0.8 + curgroup

        xvals=[curgroup,xvals,curgroup]-0.45-xoff
        yvals=[bot, yvals, top]
        polyfill, xvals, yvals, color=fc
        oplot, [curgroup-0.45-xoff,curgroup-0.45-xoff], [bot,top]
        oplot, xvals, yvals
        midpt=median(data[index])
;        oplot, [curgroup-0.45-xoff,curgroup+0.4-xoff], [midpt,midpt], thick=2
        xyouts, curgroup-xoff, yr[1]*0.90, align=0.5, $
          strcompress(n_elements(index), /remove_all), charsize=0.8*othercharsize
;        midpt=mean(data[index])
;        oplot, [curgroup-0.5,curgroup+0.5], [midpt,midpt], thick=1
     ENDIF ELSE xoff++

  ENDFOR
  IF keyword_set(best) THEN oplot, best[0,*], best[1,*], l=1
  IF keyword_set(true) THEN oplot, true[0,*], true[1,*]
  IF keyword_set(classAve) THEN oplot, classAve[0,*]-0.3, classAve[1,*], psym=1, symsize=0.5


  if not keyword_set(nonames) then begin
      openr, un, /get, "SoilNames.txt"
      line=""
      range=yr[1]-yr[0]
      nsoils=13
      off=range/12.5
      pos=minLimit-range/10.0-off
      IF NOT keyword_set(overplot) THEN BEGIN 
;     print, off, pos
          FOR i=0, nsoils-1 DO BEGIN 
              readf, un, line
;     IF !d.name EQ 'X' THEN cs=1.5 ELSE cs=0.5
              xyouts, i, pos+(i MOD 2)*off, align=0.5, line, charsize=0.8/1.2*othercharsize, color=0
              IF eof(un) THEN break
          ENDFOR  
      endIF
      close, un
      free_lun, un
  endif

;  IF !d.name NE 'PS' THEN $
;    !p=oldp

END

