FUNCTION read_data, files, col=col
  IF NOT keyword_set(col) THEN col=2
  ;; read in all input file Ts data
  junk=load_cols(files[0], curdata)

  n_files=n_elements(files)
  ;; read the first file to find out how many time steps there are
  data=fltarr(n_elements(curdata[0,*]), n_files)
  data[*,0]=curdata[col,*]

  ;; store soil database label in an array
  soils=intarr(n_files)
  soils[0]=(strsplit(files[0], '_', /extract))[2]

  FOR i=1, n_files-1 DO BEGIN
     junk=load_cols(files[i], curdata)
     data[*,i]=curdata[col,*]

     soils[i]=(strsplit(files[i], '_', /extract))[2]
     IF ((float(i)/(n_files-1))*100 MOD 10) lt 0.32 THEN $
       print, round(100*(float(i)/(n_files-1))), '%' ;, (float(i)/(n_files-1))*1000 MOD 100
;     plot, curdata[18,*], yr=[0,0.4]
;     wait, 0.1
  ENDFOR

  return, {data:data, soils:soils}
END


PRO agu2005_inverseexample, data=data, nops=nops
  files=file_search('out_*')

  junk=''
  IF NOT keyword_set(data) THEN BEGIN 
     info=read_data(files)
     data=info.data
  ENDIF 
  xr=[36, 42]
  yr=[285,320]
  pmulti=[0,1,3]

  n_variation=16
  dex=sort(data[(xr[0]+3.5)*48, *])
  nruns=n_elements(dex)
  mostvariation=dex[[indgen(n_variation)*nruns/n_variation, nruns-3, nruns-2, nruns-1]]
  n_variation+=2



  IF NOT keyword_set(nops) THEN $
    old=setupplot(filename='movie.ps')
  
  IF !d.name eq 'X' THEN BEGIN 
     red=255
     green=255l^2
  ENDIF ELSE BEGIN 
     red=1
     green=2
  ENDELSE 

  !p.multi=pmulti
  !p.charsize=1.5
  
  
  time=lindgen(n_elements(data[*,0]))/48.0
  time-=xr[0]-1.5
  xr-=xr[0]-1.5

;  plot, time, data[*,0], /ys, xr=xr, yr=yr, /xs, thick=3, $
;        xtitle="Time (days)", ytitle="Skin Temperature (K)"

  errors=randomn(seed, n_elements(time))
  
  IF !d.name EQ 'X' THEN $
    read, junk

  !p.multi=pmulti
;  !p.multi=[0,1,3] ; start a new page with every plot...
;  plot, time, data[*,0], /ys, xr=xr, yr=yr, /xs, thick=3, $
;        xtitle="Time (days)", ytitle="Skin Temperature (K)"
;  oplot, time, data[*,0], thick=3, color=green
;  oplot, time,data[*,0]+errors, thick=3, color=red
  
  IF !d.name EQ 'X' THEN $
    read, junk

;  FOR i=0, nruns-1 DO BEGIN
;     !p.multi=[0,1,3] ; start a new page with every plot...
  FOR i=0,n_variation/2-(n_variation/4) DO BEGIN
     !p.multi=pmulti
     plot, time, data[*,mostvariation[i]], /ys, xr=xr, yr=yr, /xs, l=2, thick=3, $
           xtitle="Time (days)", ytitle="Skin Temperature (K)"
     oplot, time, data[*,0]+errors, color=red, thick=3
     
     
     !p.multi=pmulti ; start a new page with every plot...
     plot, time, data[*,mostvariation[n_variation-i]], /ys, xr=xr, yr=yr, /xs, l=2, thick=3, $
           xtitle="Time (days)", ytitle="Skin Temperature (K)"
     oplot, time, data[*,0]+errors, color=red, thick=3
  ENDFOR

;; show bestfit soil in green and flash the green off and on
  FOR i=0, 10 DO BEGIN
     !p.multi=pmulti ; start a new page with every plot...
     plot, time, data[*,0], /ys, xr=xr, yr=yr, /xs, l=2, thick=3, $
           xtitle="Time (days)", ytitle="Skin Temperature (K)"
     oplot, time, data[*,0]+errors, color=red, thick=3
     oplot, time, data[*,0], color=green, thick=5

     !p.multi=pmulti ; start a new page with every plot...
     plot, time, data[*,0], /ys, xr=xr, yr=yr, /xs, l=2, thick=3, $
           xtitle="Time (days)", ytitle="Skin Temperature (K)"
     oplot, time, data[*,0]+errors, color=red, thick=3
  ENDFOR



  IF !d.name EQ 'PS' THEN BEGIN
     resetplot, old
     spawn, 'mv movie.ps ../../../../inversemovie/'
  ENDIF


END

