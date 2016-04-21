PRO plotem, aves, vars, perc
  !p.multi=[0,1,2]

  veg=indgen(n_elements(aves[*,0,0]))*10

  plot, veg, aves[*,2,0], yr=[0,700], /ys, title='Mean Latent Heat Flux', $
    xtitle="Vegetation cover", ytitle="Mean Latent Heat Flux (W/m!U2!N)"
  FOR i=0, 11 DO oplot, veg, aves[*,i,0]
  FOR i=0, 11 DO oplot, veg, aves[*,i,1], l=1

  plot, veg, vars[*,2,0], yr=[0,200], /ys, title='Std.Dev. Latent Heat Flux', $
    xtitle="Vegetation cover", ytitle="Std.Dev Latent Heat Flux (W/m!U2!N)"
  FOR i=0, 11 DO oplot, veg, vars[*,i,0]
  FOR i=0, 11 DO oplot, veg, vars[*,i,1], l=1

  plot, veg, vars[*,2,0]/aves[*,2,0], yr=[0,1],/ys, title='Std.Err Latent Heat Flux', $
    xtitle="Vegetation cover", ytitle="Std.Err Latent Heat Flux"
  FOR i=0, 11 DO oplot, veg, vars[*,i,0]/aves[*,i,0]
  FOR i=0, 11 DO oplot, veg, vars[*,i,1]/aves[*,i,1], l=1

  plot, veg, perc[*,2,0], yr=[0,200], /ys, title='75%-25% LH Range', $
    xtitle="Vegetation cover", ytitle='75%-25% LH Range (W/m!U2!N)'
  FOR i=0, 11 DO oplot, veg, perc[*,i,0]
  FOR i=0, 11 DO oplot, veg, perc[*,i,1], l=1
  
END

PRO plotfullvals, data, t1, t2, xt, yt, no3=no3, title=title
  IF NOT keyword_set(title) THEN title=''
  xt="Vegetation Cover (%)"
  yt="Latent Heat Flux (W/m!U2!N)"
  t1="IHOP3 "+title
;  t2="IHOP8 "+title

  veg=indgen(11)*10

  IF NOT keyword_set(no3) THEN BEGIN 
     plot, veg, data.fullave[*,0], title=t1, xtit=xt, ytit=yt
     oplot, veg, data.fullvars[*,0], l=1
     oplot, veg, data.fullptop[*,0]- data.fullpbot[*,0], l=2
     oplot, veg, data.fullptop[*,0], l=3                    
     oplot, veg, data.fullpbot[*,0], l=3
  ENDIF 
  
  plot, veg, data.fullave[*,1], title=t2, xtit=xt, ytit=yt, yr=[0,600]
;  oplot, veg, data.fullvars[*,1], l=1
  oplot, veg, data.fullptop[*,1]- data.fullpbot[*,1], l=2
  oplot, veg, data.fullptop[*,1], l=1
  oplot, veg, data.fullpbot[*,1], l=1

  p1=strcompress(fix(data.percs[0]*100),/remove_all)
  p2=strcompress(fix(data.percs[1]*100),/remove_all)
  oplot, [5,15],[450,450]+100
  xyouts, 17,440+100, "Mean LH"
;  oplot, [5,15],[400,400]+100, l=1
;  xyouts, 17,390+100, "Std.Dev. LH"
  oplot, [5,15],[350,350]+150, l=2
  xyouts, 17,340+150, p2+'%-'+p1+'% LH'
  oplot, [5,15],[300,300]+150, l=1
  xyouts, 17,290+150, p1+'% & '+p2+'% LH'

;  plot, veg, data.allsoils[*,0,0], title='40 random soils', xtit=xt, ytit=yt
;  FOR i=1,n_elements(data.allsoils[0,*,0])-1,30 DO oplot, veg, data.allsoils[*,i,0]
;  plot, veg, data.allsoils[*,0,0], title="ALL 1221 soils", xtit=xt, ytit=yt
;  FOR i=1,n_elements(data.allsoils[0,*,0])-1 DO oplot, veg, data.allsoils[*,i,0]   

END


PRO plotallhistos, site, _extra=e
  dirs=file_search(site+'*', /test_directory)
  FOR i=0, n_elements(dirs)-1 DO BEGIN
     cd, current=old, dirs[i]
     
     boxflux, (file_search('comb*'))[0], /hist, yr=[0,650], $
       title=site+' Veg='+strcompress((strsplit(dirs[i],'_',/extract))[1]), $
       nonames=(i LT n_elements(dirs)-1), _extra=e
     
     cd,old
  ENDFOR

END
