FUNCTION getFiles, filelist
  openr, un, filelist
  line=''
  files=''
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     files=[files,line]
  ENDWHILE
  close, un
  free_lun, un
  files=files[1:n_elements(files)-1]
  return, files
END

PRO plotData, x, y, _extra=e

  plot, x, y[0,*], /ys, /xs, _extra=e

  offset=20
  gain=((196.0-20)/n_elements(y[*,0]))
  FOR i=1, n_elements(y[*,0])-1 DO BEGIN
     oplot, x,y[i,*], color=round(i*gain)+offset
  ENDFOR
end

PRO plotRunoff, filelist, psfile=psfile, dz=dz


  IF NOT keyword_set(psfile) THEN psfile='AllFigs.ps'
  IF NOT keyword_set(dz) THEN dz=1.5
  IF n_elements(filelist) EQ 0 THEN files=file_search('out. *') $
  ELSE files=getFiles(filelist)

  start=1
  FOR i=start, n_elements(files)-1 DO BEGIN
     j=load_cols(files[i], data)
     print, files[i]
     IF i EQ start THEN BEGIN
        runoff=data[26,*]
        drain=data[27,*]
        smc=data[18,*]
        smc2=data[19,*]
        rain=data[3,*]*3600.0 ; convert kg/s to mm/hr
        k = data[30,*]
     ENDIF ELSE BEGIN
        runoff=[runoff,data[26,*]]
        drain=[drain,data[27,*]]
        smc=[smc,data[18,*]]
        smc2=[smc2,data[19,*]]
        k = [k,data[30,*]]
     ENDELSE
  ENDFOR

  time=lindgen(n_elements(rain))/480.0
  runoff*=(3600l*1000)
  drain*=(3600l*1000)
  sz=size(runoff)
  infil=rebin(rain,sz[1],sz[2]) -runoff

;  stop
  old=setupplot(filename=psfile)
  !p.multi=[0,2,3]
  !p.thick=1.0
  !p.charsize=1.0
  xr=[1.2,3]
;  fluxmax=max([max(runoff),max(infil),max(drain)])
  fluxmax=max(rain)
  ksmax=max(k)
  IF ksmax GT 0.1 THEN ksmax=5e-6
  gradient= (smc-smc2)/dz
  maxgrad=max(gradient)
  maxsmc=max(smc)
  maxsmc=round((maxsmc+0.1)*10)/10.0
  plotData, time, runoff, xr=xr, yr=[0,fluxmax], $
            title="Runoff", xtitle="time (days)", ytitle="Runoff (mm/hr)"
  plotData, time, infil, xr=xr, yr=[0,fluxmax], $
            title="Infiltration", xtitle="time (days)", ytitle='Infiltration (mm/hr)'
  plotData, time, smc, xr=xr, yr=[0,maxsmc], $
            title="Soil Moisture", xtitle="time (days)", ytitle='Soil Moisture ()'
  plotData, time, drain, xr=xr, yr=[0,fluxmax], $
            title="Drainage", xtitle="time (days)", ytitle='Drainage (mm/hr)'
  plotData, time, (smc-smc2)/dz, xr=xr, yr=[1e-7,1.0], /ylog, $
            title="Moisture Gradient", xtitle="time (days)", ytitle='Moisture Gradient (1/m)'
  plotData, time, k, xr=xr, yr=[0,ksmax], $
            title="Conductivity", xtitle="time (days)", ytitle='Conductivity (m/s)'
  
  resetplot, old
END


    
