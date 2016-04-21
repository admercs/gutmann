PRO process_shp_effects, psfile=psfile
  files=file_search('*.out')
  
  junk=load_cols(files[0], curdata)
 ; time=(lindgen(n_elements(curdata[0,*]))/48.0)*24 MOD 24
 ; noon=where(time GE 11.8 AND time LE 12.2)
  noon=indgen(n_elements(curdata[0,*])/48)*48+24
 
  FOR i=0, n_elements(files)-1 DO BEGIN
     junk=load_cols(files[i], curdata)
     curinfo=strsplit(files[i], '_', /extract)
     curdex=fix(curinfo[0])
     curval=float(strmid(curinfo[1], 0, strlen(curinfo[1])-4))
     curTs=curdata[2,noon]
     curLE=curdata[7,noon]
     curSMC=curdata[18,noon]

     IF n_elements(allTs) EQ 0 THEN allTs=curTs ELSE allTs=[allTs,curTs]
     IF n_elements(allLE) EQ 0 THEN allLE=curLE ELSE allLE=[allLE,curLE]
     IF n_elements(allSMC) EQ 0 THEN allSMC=curSMC ELSE allSMC=[allSMC,curSMC]

     IF n_elements(allval) EQ 0 THEN allval=curval ELSE allval=[allval,curval]
     IF n_elements(alldex) EQ 0 THEN alldex=curdex ELSE alldex=[alldex,curdex]
     
  ENDFOR
  
  dexes=[1,6,7]
  titles=['n', 'alpha', 'Ks']
  ytitle1="Skin Temperature (K)"
  ytitle2="Latent Heat Flux (W/m!U2!N)"
  ytitle3="Soil Moisture (cm!U3!N/cm!U3!N)"
  xtitle="Time (days)"
  yr=[[305,330],[000,800],[0,0.4]]
  leg_ystep=(yr[1,1]-yr[0,1])/25.0
  leg_ystart=yr[1,1]-leg_ystep
  leg_x=[8, 9]
  xr=[4,12]

  runs=where(alldex EQ dexes[0])
  IF keyword_set(psfile) THEN BEGIN
     old=setupplot(filename=psfile)
     colortable=indgen(n_elements(runs))/float(n_elements(runs)-1) * (70-8) + 8
     !p.charsize=1.0
     !p.multi=[0,3,3]
  ENDIF ELSE $
    colortable=indgen(n_elements(runs))/float(n_elements(runs)-1) * 255
  

  FOR i=0, 2 DO BEGIN
     runs=where(alldex EQ dexes[i])

     plot, allTs[runs[0],*], yr=yr[*,0], /ys, title=titles[i], ytitle=ytitle1, xtitle=xtitle, /xs, xr=xr
     FOR j=0, n_elements(runs)-1 DO BEGIN
        oplot, allTs[runs[j],*], color=colortable[j] ; change color from black to red
     ENDFOR

     plot, allLE[runs[0],*], yr=yr[*,1], /ys, title=titles[i], ytitle=ytitle2, xtitle=xtitle, /xs, xr=xr
     FOR j=0, n_elements(runs)-1 DO BEGIN
        oplot, allLE[runs[j],*], color=colortable[j] ; change color from black to red
        oplot, leg_x, [leg_ystart-(leg_ystep*j), leg_ystart-(leg_ystep*j)], $
               color=colortable[j] 
        xyouts, leg_x[1], leg_ystart-(leg_ystep*(j+0.25)), $
                string(allval[runs[j]], format='(F6.2)'), charsize=!p.charsize/2.0
     ENDFOR

     plot, allSMC[runs[0],*], yr=yr[*,2], /ys, title=titles[i], ytitle=ytitle3, xtitle=xtitle, /xs, xr=xr
     FOR j=0, n_elements(runs)-1 DO BEGIN
        oplot, allSMC[runs[j],*], color=colortable[j] ; change color from black to red
     ENDFOR
  ENDFOR

  IF keyword_set(psfile) THEN resetplot, old
END

