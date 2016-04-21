PRO plotFinalHisto, fname, mx=mx, title=title, legendx=legendx
  junk=load_cols(fname, data)

  ;; fname is generally bigFluxOutput or bigAllOutput

  n=100  ;this is the number of bins we will divide the histogram into

  IF NOT keyword_set(mx) THEN mx=5.0 ; this is the maximum value in the histogram
  IF NOT keyword_set(title) THEN title="Skin Temperature Error" ;plot title

  mx=float(mx) ; because I seem to keep passing it integers which really screws things up

  txt=indgen(n_elements(data[0,*])/3)*3
  modis=txt+1
  real=txt+2

  plot, indgen(n)/(n/mx), histogram(data[0,txt], nbins=n, max=mx, min=0), $
        title=title, xtitle="Error", ytitle="# of model runs"
  oplot, indgen(n)/(n/mx), histogram(data[0,modis], nbins=n, max=mx, min=0), l=1
  oplot, indgen(n)/(n/mx), histogram(data[0,real], nbins=n, max=mx, min=0), l=2

  ;; plot the legend

  means=[mean(data[0,txt]), $
         mean(data[0,modis]), $
         mean(data[0,real])]
  xstep=(mx)/100.0
  ystep=max(histogram(data[0,txt], nbins=n, max=mx, min=0))/100.0
  ystart=70
  yoff=1
  yinc=10
  IF keyword_set(legendx) THEN xstart=legendx ELSE xstart=65
  xwidth=10
  xoff=3
  legend=['Texture SHPs', 'Ts inverse SHPs', 'Real SHPs']
  FOR j=0,2 DO BEGIN 
     oplot, [xstep*(xstart),xstep*(xstart+xwidth)], $
            [ystep*(ystart+yinc*j+yoff),ystep*(ystart+yinc*j+yoff)], l=j
     xyouts, xstep*(xstart+xoff+xwidth), ystep*(ystart+yinc*j), legend[j]
     xyouts, xstep*(xstart-xwidth+(xoff/2)), ystep*(ystart+yinc*j), $
             string(means[j], format='(F6.3)')
  ENDFOR


END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; plots histograms of the error in the four main shps (n, Ks, alpha, SMC_Sat)
;;  then normalizes all shps, computes error in 4D space, and plots that histogram
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO plotSHPerror, fname, outfile
  print, load_cols(fname, data)

  n=100
  junk=''

  txt=indgen(n_elements(data[0,*])/3)*3
  modis=txt+1
  real=txt+2

  data[3,*]=alog10(data[3,*])

  xmaxes=fltarr(4)
  xmins=fltarr(4)
  maxes=fltarr(4)
  mins=fltarr(4)
  err=fltarr(2,n_elements(txt))
  fulltxtshperr=0
  fullmodisshperr=0

  Titles=['van Genuchten n', 'van Genuchten alpha', 'Saturated Conductivity', 'Saturated Moisture Content']

  FOR i=0, n_elements(maxes)-1 DO BEGIN
     ;; find the max and min to normalize the data too
     maxes[i]=max(data[i+1,*])
     mins[i]=min(data[i+1,*])

     ;; plot histograms of SHP error in 1D space before normalizing
     txtshperr=abs(data[i+1,txt]-data[i+1,real])
     modisshperr=abs(data[i+1,modis]-data[i+1,real])

     ;; use the 5th and 95th percentiles for plotting to eliminate outliers
     xmaxes[i]=percentiles([txtshperr, modisshperr], value=[0.95])
     xmins[i]=percentiles([txtshperr, modisshperr], value=[0.05])


     IF i EQ 2 THEN n/=2
     fullmax=max([modisshperr,txtshperr])
     fullmin=min([reform(modisshperr),reform(txtshperr),0])

     ymax=max(histogram(txtshperr, nbins=n, max=fullmax, min=fullmin))

     x = fullmin+indgen(n)/(n/(float(fullmax)-fullmin))
     plot, x, histogram(txtshperr, nbins=n, max=fullmax, min=fullmin), $
           /xs, xr=[xmins[i],xmaxes[i]], $
           title=Titles[i]+' Ratio='+strcompress(mean(txtshperr)/mean(modisshperr)), $
           ytitle="# model runs", xtitle="SHP error"
     oplot, x, histogram(modisshperr, nbins=n, max=fullmax, min=fullmin), l=1

     print, mean(txtshperr), mean(modisshperr), mean(txtshperr)/mean(modisshperr)
     means=[mean(txtshperr), mean(modisshperr)]
     ;; normalize the SHP distances
     data[i+1,*]-=mins[i]
     data[i+1,*]/=(maxes[i]-mins[i])

     fulltxtshperr+=(data[i+1,txt]-data[i+1,real])^2
     fullmodisshperr+=(data[i+1,modis]-data[i+1,real])^2
     
     ;; plot the legend
     xstep=(xmaxes[i]-xmins[i])/100.0
     ystep=ymax/100.0
     ystart=80
     yoff=1
     yinc=10
     xstart=65
     xwidth=10
     xoff=3
     legend=['Texture SHPs', 'Ts inverse SHPs']
     FOR j=0,1 DO BEGIN 
        oplot, [xstep*(xstart),xstep*(xstart+xwidth)], $
               [ystep*(ystart+yinc*j+yoff),ystep*(ystart+yinc*j+yoff)], l=j
        xyouts, xstep*(xstart+xoff+xwidth), ystep*(ystart+yinc*j), legend[j]
        xyouts, xstep*(xstart-xwidth+xoff), ystep*(ystart+yinc*j), $
                string(means[j], format='(F5.3)')
     ENDFOR
     
  ENDFOR

;  n=50

  ;; plot the "total" SHP distance in 4D space
  fulltxtshperr=sqrt(fulltxtshperr/n_elements(maxes))
  fullmodisshperr=sqrt(fullmodisshperr/n_elements(maxes))
  print, '--------------------------------------'
  print, mean(fulltxtshperr), mean(fullmodisshperr), mean(fulltxtshperr)/mean(fullmodisshperr)

  x=indgen(n)/(n/max([fulltxtshperr, fullmodisshperr]))
  plot, x, histogram(fulltxtshperr, nbins=n, max=x[n_elements(x)-1], min=0), /xs, $
        title="All SHP parameters"+" ratio=" + $
        strcompress(mean(fulltxtshperr)/mean(fullmodisshperr)), $
        xtitle='4D SHP error', ytitle="# model runs"
  oplot, x, histogram(fullmodisshperr, nbins=n, max=x[n_elements(x)-1], min=0), l=1

  ;; plot the legend
  xstep=(max(x)-min(x))/100.0
  ystep=max(histogram(fulltxtshperr, nbins=n, max=x[n_elements(x)-1], min=0))/100.0
  means=[mean(fulltxtshperr), mean(fullmodisshperr)]
  ystart=80
  yinc=10
  xstart=65
  xwidth=10
  xoff=3
  legend=['Texture SHPs', 'Ts inverse SHPs']
  FOR j=0,1 DO BEGIN 
     oplot, [xstep*(xstart),xstep*(xstart+xwidth)], $
            [ystep*(ystart+yinc*j+yoff),ystep*(ystart+yinc*j+yoff)], l=j
     xyouts, xstep*(xstart+xoff+xwidth), ystep*(ystart+yinc*j), legend[j]
     xyouts, xstep*(xstart-xwidth+xoff), ystep*(ystart+yinc*j), string(means[j], format='(F5.3)')
  ENDFOR
  
END

;; designed to read the main output files, not the fulloutput file from comptstxt.pro
PRO plothisto, fname, mx=mx, title=title, outfile=outfile, noplot=noplot

  junk=load_cols(fname, data)

  n=100  ;this is the number of bins we will divide the histogram into

  IF NOT keyword_set(mx) THEN mx=5.0 ; this is the maximum value in the histogram
  IF NOT keyword_set(title) THEN title="Skin Temperature Error" ;plot title

  mx=float(mx) ; because I seem to keep passing it integers which really screws things up

  IF NOT keyword_set(noplot) THEN BEGIN 
     plot, indgen(n)/(n/mx), histogram(data[0,*], nbins=n, max=mx, min=0), $
           xtitle="Error", ytitle="n points", title=title
;  bar_plot, histogram(data[0,*], nbins=n, max=mx, min=0), $
;        xtitle="Ts Error", ytitle="n points"
     
     histmax=max(histogram(data[0,*], nbins=n, max=mx, min=0))
     
     xstep=mx/10.0
     ystep=histmax/10.0
     titles=["Texture Class", "MODIS Best Fit", "Real Value"]
     
     FOR i=0,2 DO begin
        oplot, [data[0,i], data[0,i]], [0,2*histmax], l=i
        
        oplot, [5.5*xstep,6.5*xstep], [ystep*(i+7), ystep*(i+7)], l=i
        xyouts, 6.7*xstep, (i+6.8)*ystep, titles[i]
     END
  ENDIF

;; this is the output file to use for plotSHPerror and plotfinalhisto??
  IF keyword_set(outfile) THEN BEGIN
     openw, oun, /get, /append, outfile
     printf, oun, data[*,0:2], format='(6F20.5)'
     close, oun
     free_lun, oun
  ENDIF

END
 
PRO plotfullhisto, fname, mx=mx, offset=offset, title=title, n=n, mn=mn, _extra=e

  junk=load_cols(fname, data)
  

  IF NOT keyword_set(n) THEN n=100  ;this is the number of bins we will divide the histogram into
  IF NOT keyword_set(offset) THEN offset=0 ; 0=modis, 1=all,2=flux(modis)
  IF NOT keyword_set(mx) THEN mx=5.0 ; this is the maximum value in the histogram
  IF NOT keyword_set(mn) THEN mn=0.0 ; this is the minimum value in the histogram
  IF NOT keyword_set(title) THEN title="Skin Temperature Error" ;plot title

  mx=float(mx) ; because I seem to keep passing it integers which really screws things up
  
  plot, [indgen(n)/(n/(mx-mn))+mn,mx], [histogram(data[0+offset,*], nbins=n, max=mx, min=mn),0], $
        xtitle="Error", ytitle="n points", title=title, psym=10, _extra=e

  ncols=n_elements(data[*,0])
  oplot, [indgen(n)/(n/(mx-mn))+mn,mx], [histogram(data[ncols-3+offset,*], nbins=n, max=mx, min=mn),0], $
         l=2, psym=10

  histmax=max(histogram(data[0+offset,*], nbins=n, max=mx, min=mn))
  
  xstep=(mx-mn)/10.0
  ystep=histmax/10.0

  titles=["Best Fit", "Texture Class"]
  
  lineoffset=0
  FOR i=0,1 DO begin
;     oplot, [data[0,i], data[0,i]], [0,2*histmax], l=i
;     
     oplot, [5.5*xstep+mn,6.5*xstep+mn], [ystep*(i+7), ystep*(i+7)], l=i+lineoffset
     xyouts, 6.7*xstep+mn, (i+6.8)*ystep, titles[i]
     lineoffset=1
  END
END

PRO batchplotfullhisto
  old=setupplot()
  !p.multi=[0,2,3]
  dirs=file_search('mod*')
  FOR i=0, n_elements(dirs)-1 DO BEGIN
     cd, current=old, dirs[i]
     ihopdirs=file_search('ihop*')
     FOR j=0, n_elements(ihopdirs)-1 DO BEGIN
        cd, current=last, ihopdirs[j]
        plotfullhisto, 'fulloutfile', title=dirs[i]+ihopdirs[j]
        plotfullhisto, 'fullmodisoutput', title='modis'+dirs[i]+ihopdirs[j]
        cd, last
     ENDFOR
     cd, old
  ENDFOR
END

