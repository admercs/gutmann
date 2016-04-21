PRO boxplotMultiByDay, f1, var, nocolor=nocolor, nopattern=nopattern, _extra=e
  files=file_search(f1+"*")
  nfiles=n_elements(files)

  minday=(fix(strsplit(files[0], f1, /extract)))[0]
  
  daycol=0
  soilcol=1
 
  FOR i=0, nfiles-1 DO BEGIN 
     junk=load_cols(files[i], tmpdata)
     tmpdata[daycol,*] = i
     IF n_elements(data) EQ 0 THEN data=tmpdata ELSE data=[[data],[tmpdata]]
  ENDFOR 
  
  nsoils=max(data[soilcol,*])
  width=0.65/nsoils
  offset=0.25/nsoils+width
  coloroff=100.0
  colorgain=(255.0-coloroff)/nsoils

  IF !d.name EQ 'PS' THEN BEGIN 
     coloroff=196
     colorgain=1
  ENDIF 

  IF NOT keyword_set(nocolor) THEN BEGIN 
     colors=(10-indgen(nsoils))*colorgain+coloroff
     c1=4
     c2=6
     xoff=0.8
     yoff=25
     textoff=0.05
     textcolor=207
     o1=0
     o2=0
  endIF ELSE BEGIN 
     colors=(indgen(nsoils) MOD 4)*2+211
     xoff=0.4
     yoff=25
     textoff=0.45
     textcolor=0
     c1=214
     c2=216
;     o1=180
;     o2=90
     orient=intarr(nsoils)
     orient[4:7]=45
     orient[8:10]=135
     IF keyword_set(nopattern) THEN colors=218-indgen(nsoils)
  ENDELSE 

  yr=[0,450]
  plot, indgen(nfiles),intarr(nfiles), xr=[-0.5, nfiles-0.5], /xs, $
        yr=yr, /ys, /nodata, xminor=-1, _extra=e, xticks=1, xtickname=[' ',' '], $
        ytitle="Latent Heat (W/m!U2!N)"

  
  polyfill, [1.5,1.5,2.5,2.5], [1,449,449,1], color=c1, orientation=o1
  polyfill, [1.5,1.5,2.5,2.5]-1, [1,449,449,1], color=c2, orientation=o2

  soilNum=0
  
  xyouts, nfiles/2, -65, "Day of the Year", align=0.5
  FOR i=0, nfiles-1 DO $
     xyouts, i, -30, strcompress(i+625-365, /remove_all), align=0.5
  
  openr, un, /get, "SoilNames.txt"
  line=""
  FOR i=0, nsoils DO BEGIN
     index=where(data[soilcol,*] EQ i)
     IF index[0] NE -1 THEN BEGIN 
        boxplot, data[var,index], group=data[daycol,index], $
                 boxwidth=width, boxposition=offset*soilNum-0.4, $
                 /overplot, noprintn=noprintn, $
                 fillcolor=colors[soilNum], /quiet

        x=4+(1.1*fix(soilNum/(nsoils/2)))
        y=420-30*fix(soilNum MOD (nsoils/2))
        polyfill, [x,x,x+xoff,x+xoff], $
                  [y, y+yoff, y+yoff, y], $
                  color=colors[soilNum]
        plots, [x,x,x+xoff,x+xoff,x], $
               [y, y+yoff, y+yoff, y,y]
        readf, un, line
        xyouts, x+textoff, y+5, $
                line, charsize=0.5, color=textcolor
        

        IF soilNum GT 3 AND keyword_set(nocolor) AND NOT keyword_set(nopattern) THEN BEGIN
           polyfill, [x,x,x+xoff,x+xoff], $
                     [y, y+yoff, y+yoff, y], $
                     orientation=orient[soilNum]
           boxplot, data[var,index], group=data[daycol,index], $
                    boxwidth=width, boxposition=offset*soilNum-0.4, $
                    /overplot, noprintn=noprintn, $
                    /quiet, fillorient=orient[soilNum]
        endIF
        soilNum++
        
     ENDIF 
  ENDFOR
END



PRO boxplotMultiDay, f1, var=var, day=day, nocolor=nocolor, $
                     nopattern=nopattern, _extra=e

  IF n_elements(f1) EQ 0 THEN f1="combined"
  IF NOT keyword_set(var) THEN var=12
  IF keyword_set(day) THEN BEGIN 
     boxplotMultiByDay, f1, var, nocolor=nocolor, $
                        nopattern=nopattern, _extra=e
     return
  ENDIF


  files=file_search(f1+"*")
  nfiles=n_elements(files)
  
  width=0.60/nfiles
  offset=0.20/nfiles+width
  coloroff=100.0
  colorgain=255.0-coloroff

;  IF !d.name EQ 'PS' THEN BEGIN
;     colorgain=1
;     coloroff=1
;  ENDIF

  yr=[0,450]
  BoxFlux, files[0], boxwidth=width, boxposition=offset*0-0.4, $
           yr=yr, fc=0*colorgain/nfiles+coloroff, /noprintn, $
           title="Multi-day box plots", $
           ytitle="Latent Heat (W/m!U2!N)", $
           charsize=1.0, var=var
  
  FOR i=1,nfiles-1 DO BEGIN
     IF i EQ nfiles/2 THEN noprintn=0 ELSE noprintn=1
     BoxFlux, files[i], boxwidth=width, boxposition=offset*i-0.4, $
              /overplot, noprintn=noprintn, fc=i*colorgain/nfiles+coloroff
  ENDFOR
  FOR i=0, nfiles-1 DO BEGIN
     junk=load_cols(files[i], data)
     nsoils=max(data[1,*])
     med=fltarr(nsoils+1)
     med[*]=-9999
     FOR curSoil=0,nsoils DO BEGIN
        index=where(data[1,*] EQ curSoil)
        IF index[0] NE -1 THEN med[curSoil]=percentiles(data[var,index], value=0.5)
     ENDFOR
     x=indgen(nsoils)
     oplot, x+offset*i-0.4, med[where(med NE -9999)], color=i*colorgain/nfiles+coloroff
  ENDFOR

  yr=[0,350]
  coloroff=0.0
  colorgain=255.0
  FOR i=0, nfiles-1 DO BEGIN
     junk=load_cols(files[i], data)
     nsoils=max(data[1,*])
     med=fltarr(nsoils+1)
     med[*]=-9999
     FOR curSoil=0,nsoils DO BEGIN
        index=where(data[1,*] EQ curSoil)
        IF index[0] NE -1 THEN med[curSoil]=percentiles(data[var,index], value=0.5)
     ENDFOR
     IF i EQ 0 THEN BEGIN 
        plot, med[where(med NE -9999)], $
              xtitle="Soil Class", ytitle="Latent Heat Flux", yr=yr
     endIF
       oplot, med[where(med NE -9999)], color=i*colorgain/nfiles+coloroff
     
;     print,  x+offset*i-0.4
  ENDFOR


END
       
