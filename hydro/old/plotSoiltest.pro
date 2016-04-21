;; makes movie files in comps presentation
FUNCTION compFile, f1, d2, ps=ps
  j=load_cols(f1, d1)
  plotT, d1,d2
  plotdT, d1,d2
  IF NOT keyword_set(ps) THEN BEGIN 
     plotSMC, d1, d2
     plotdT2, d1, d2
  ENDIF 

  day=lindgen(n_elements(d2[0,*]))/48. + 220
  dex=where(day gt 222 and day lt 230)
  return, max(abs(d1[2,dex]-d2[2,dex]))
END

PRO plotSoiltest, infix, outfile, ps=ps
  IF n_elements(infix) EQ 0 THEN infix="out_"
  IF n_elements(outfile) EQ 0 THEN outfile="outputData"

  files=file_search(infix+'*')
  sz=n_elements(files)
  real=sz/4

  param=fltarr(sz)
  diff=fltarr(sz)
  SHPs=[0.028, 0.339, 10.^(-4.), 2.79]

  paramDex=3  &  label="Beta Exponent" ; these are passed to plotError
                                ; and should be all that need to be changed
                                ; in order to change which parameter we are
                                ; looking at.  
  paramDex=0  &  label="Residual Moisture Content (m^3/m^3)"
  paramDex=1  &  label="Saturated Moisture Content (m^3/m^3)"
;  paramDex=2  &  label="Saturated Conductivity"

  FOR i=0., sz-1 DO param[i]=float((strsplit(files[i], '_', /extract))[1])
  index=sort(param)
  param=param[index]
  files=files[index]
  j=load_cols(files[real], Reality)
  mn=min(param)
  mx=max(param)
  
  !p.multi=[0,3,2]
  FOR i=0, sz-1 DO BEGIN
;     param[i]=float((strsplit(files[i], '_', /extract))[1])
     IF keyword_set(ps) THEN BEGIN 
        psfile="plot"+strcompress(param[i], /remove_all)+".ps"
        old=setupplot(filename=psfile, xs=17,ys=17, fs=42)
        !p.multi=[0,2,2]
        !p.thick=4
     ENDIF
 
     diff[i]=compFile(files[i], Reality, ps=ps)

     plotSHP, SHPs,param[i], paramDex
     IF i GT 0 THEN plotError, param[0:i], diff[0:i], mn, mx, label $
     ELSE plot, [0,0], xr=[mn,mx], yr=[0,5], $
                title="Error Surface", $
                xtitle=label, $
                ytitle="Max Delta T (K)"
     IF i MOD 10 EQ 0 THEN print, 100.*i/sz, " %"
     IF keyword_set(ps) THEN BEGIN 
        resetPlot, old
        spawn, "pstopnm -portrait -xborder 0.0 -yborder 0.0 -xsize 700 -ysize 700 "+psfile
        spawn, "pnmtojpeg *.ppm >jpegs/plot" $
               +strcompress(fix(i), /remove_all)+".jpg"
        spawn, "rm *.ppm"
     ENDIF 
  ENDFOR 

;  index=sort(param)

;  plot, param, diff

  openw, oun, /get, outfile
  printf, oun, transpose([[param[index]],[diff[index]]])
  close, oun 
  free_lun, oun
END

;; plots noah SMC-K relationship given parameters
PRO plotSHP, params, variable, index
  IF n_elements(index) NE 0 THEN params[index]=variable
  theta_r = params[0]
  theta_s = params[1]
  Ks = params[2]
  Bexp = params[3]

  fact=10000.
  sz=(theta_s-theta_r)*fact
  theta=lindgen(sz)/fact+theta_r

  k=Ks*(theta/theta_s)^((2.0*Bexp)+3.0)
  plot, theta, k, title="Noah SHP", $
        xtitle="Moisture Content (m^3/m^3)", $
        ytitle="Conductity", $
        xr=[0.0,0.4], yr=[0,Ks], /ys, xtickinterval=xtickinterval

  IF index EQ 3 THEN col=1 ELSE col=0
  str=string("Bexp=",Bexp, format="(A,F6.3)")
  xyouts, 0.025, Ks*0.85, str, color=col

  IF index EQ 2 THEN col=1 ELSE col=0
  str=string("Ks=",Ks, format="(A,F9.6)")
  xyouts, 0.025, Ks*0.75, str, color=col

  IF index EQ 0 THEN col=1 ELSE col=0
  str=string("Theta_r=",theta_r, format="(A,F6.3)")
  xyouts, 0.025, Ks*0.65, str, color=col

  IF index EQ 1 THEN col=1 ELSE col=0
  str=string("Theta_s=",theta_s, format="(A,F6.3)")
  xyouts, 0.025, Ks*0.55, str, color=col
  
END

PRO plotDT, d1,d2
  day=indgen(n_elements(d1[2,*]))/48. + 220.
  dex=where(day gt 222 and day lt 230)
  data=abs(d1[2,dex] - d2[2,dex])
  plot, day[dex], data, $
        title="Change in Temperature", $
        xtitle="Day of the year", $
        ytitle="Ts-model - Ts-real (K)", $
        yr=[0,5], xr=[223,228], /xs
  maxVal=max(data)
  ndex=where(data EQ maxVal)
  oplot, (day[dex])[[ndex,ndex]], [0,20], line=2, color=1
END 
  
PRO plotT, d1,d2
  day=indgen(n_elements(d1[2,*]))/48. + 220.
  dex=where(day gt 222 and day lt 230)
  plot, day[dex], d2[2,dex], $
        title="Surface Temperature", $
        xtitle="Day of the year", $
        ytitle="Surface Temperature (K)", $
        yr=[302,318], /ys, xr=[223,226], /xs, xtickinterval=1
  oplot, day[dex], d1[2,dex], color=1
END 
PRO plotDT2, d1,d2
  day=indgen(n_elements(d1[2,*]))/48. + 220.
  dex=where(day gt 222 and day lt 230)
  data=abs(d1[8,dex] - d2[8,dex])
  plot, day[dex], data, $
        title="Change in Temperature", $
        xtitle="Day of the year", $
        ytitle="dT (K)", $
        yr=[0,10], xr=[223,226], /xs
  maxVal=max(data)
  ndex=where(data EQ maxVal)
  oplot, (day[dex])[[ndex,ndex]], [0,20], line=2, color=1
END 
  
PRO plotSMC, d1,d2
  day=indgen(n_elements(d1[2,*]))/48. + 220.
  dex=where(day gt 222 and day lt 230)
  plot, day[dex], d2[16,dex], $
        title="Soil Moisture", $
        xtitle="Day of the year", $
        ytitle="Soil Moisture", $
        yr=[0,0.3], /ys, xr=[222,226], /xs
  oplot, day[dex], d1[16,dex], line=2
  oplot, day[dex], d1[17,dex], line=1
  oplot, day[dex], d2[17,dex], line=1
END 

PRO plotError, paramVal, Error, min, max, param
  IF n_elements(min) EQ 0 THEN min = 2
  IF n_elements(max) EQ 0 THEN max = 10
  IF n_elements(param) EQ 0 THEN param="Beta Exponent"
  
  IF min LT 10.^(-4) THEN xtickinterval=4.*10.^(-5)
  sz=n_elements(paramVal)-1
  plot, paramVal, Error, $
        xr=[min,max], /xs, $
        yr=[0, 5], $
        title="Error Surface", $
        xtitle=param, xtickinterval=xtickinterval, $
        ytitle="Max Delta T (K)"
  oplot, paramVal[[0,sz]], Error[[0,sz]], psym=1, color=1
END

