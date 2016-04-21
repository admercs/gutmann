pro scatterplotem, sday=sday, eday=eday, data=data, ndays=ndays, fromLE=fromLE, $
                   fromTsCorr=fromTsCorr, fromTsNorm=fromTsNorm

  bestSOIL=strarr(9)
  junk=''
  
  IF NOT keyword_set(sday) THEN sday=[30,30,30,32,32,31,32,32,32]
  IF NOT keyword_set(eday) THEN eday=36
  IF NOT keyword_set(fromTsCorr) AND NOT keyword_set(fromTsNorm) THEN fromLE=1
  if sday[0] eq 47 then begin 
     if keyword_set(fromLE) THEN BEGIN 
;; selected from LE
        bestSOIL[0] = 'out_sandyclayloam_842'
        bestSOIL[1] = 'out_sandyclayloam_883'
        bestSOIL[2] = 'out_sandyloam_1633'
        bestSOIL[3] = 'out_loam_1840'
        bestSOIL[4] = 'out_loam_1271'
        bestSOIL[5] = 'out_clayloam_1240'
        bestSOIL[6] = 'out_siltyclayloam_1421'
        bestSOIL[7] = 'out_siltyclayloam_1421'
        bestSOIL[8] = 'out_siltyclayloam_1970'
     ENDIF ELSE if keyword_set(fromTsNorm) THEN begin
        
        ;; selected from Ts normalized
        bestSOIL[0] = 'out_sandyclayloam_842'
        bestSOIL[1] = 'out_sandyclayloam_971'
        bestSOIL[2] = 'out_sandyloam_802'
        bestSOIL[3] = 'out_loam_1885'
        bestSOIL[4] = 'out_loam_1471'
        bestSOIL[5] = 'out_clayloam_1424'
        bestSOIL[6] = 'out_siltyclayloam_1910'
        bestSOIL[7] = 'out_siltyclayloam_1905'
        bestSOIL[8] = 'out_siltyclayloam_1412'
     endIF ELSE if keyword_set(fromTsCorr) THEN begin
        
        ;; selected from Ts Correlation
        bestSOIL[0] = 'out_sandyclayloam_842'
        bestSOIL[1] = 'out_sandyclayloam_956'
        bestSOIL[2] = 'out_sandyloam_839'
        bestSOIL[3] = 'out_loam_1853'
        bestSOIL[4] = 'out_loam_725'
        bestSOIL[5] = 'out_clayloam_1884'
        bestSOIL[6] = 'out_siltyclayloam_328'
        bestSOIL[7] = 'out_siltyclayloam_328'
        bestSOIL[8] = 'out_siltyclayloam_297'
     endIF 
  ENDIF ELSE IF sday[0] EQ 30 THEN BEGIN 
     if keyword_set(fromLE) THEN BEGIN
        bestSOIL[0] = 'out_sandyclayloam_929'
        bestSOIL[1] = 'out_sandyclayloam_841'
        bestSOIL[2] = 'out_sandyloam_1278'
        bestSOIL[3] = 'out_loam_1296'
        bestSOIL[4] = 'out_loam_1755'
        bestSOIL[5] = 'out_clayloam_1650'
        bestSOIL[6] = 'out_siltyclayloam_1688'
        bestSOIL[7] = 'out_siltyclayloam_1910'
        bestSOIL[8] = 'out_siltyclayloam_1454'

        bestSOIL[0] = 'out_sandyclayloam_860'
        bestSOIL[1] = 'out_sandyclayloam_759'
        bestSOIL[2] = 'out_sandyloam_1214'
        bestSOIL[3] = 'out_loam_1445'
        bestSOIL[4] = 'out_loam_1832'
        bestSOIL[5] = 'out_clayloam_1473'
        bestSOIL[6] = 'out_siltyclayloam_328'
        bestSOIL[7] = 'out_siltyclayloam_2122'
        bestSOIL[8] = 'out_siltyclayloam_1421'

     ENDIF ELSE if keyword_set(fromTsCorr) THEN BEGIN
        bestSOIL[0] = 'out_sandyclayloam_860'
        bestSOIL[1] = 'out_sandyclayloam_759'
        bestSOIL[2] = 'out_sandyloam_1214'
        bestSOIL[3] = 'out_loam_1445'
        bestSOIL[4] = 'out_loam_1832'
        bestSOIL[5] = 'out_clayloam_1473'
        bestSOIL[6] = 'out_siltyclayloam_328'
        bestSOIL[7] = 'out_siltyclayloam_2122'
        bestSOIL[8] = 'out_siltyclayloam_328'

        bestSOIL[0] = 'out_sandyclayloam_929'
        bestSOIL[1] = 'out_sandyclayloam_841'
        bestSOIL[2] = 'out_sandyloam_1278'
        bestSOIL[3] = 'out_loam_1296'
        bestSOIL[4] = 'out_loam_1755'
        bestSOIL[5] = 'out_clayloam_1650'
        bestSOIL[6] = 'out_siltyclayloam_1688'
        bestSOIL[7] = 'out_siltyclayloam_295'
        bestSOIL[8] = 'out_siltyclayloam_328'
     ENDIF ELSE print, "what form of fit do you want to work with?"
  ENDIF ELSE print, "what day do you want to work with?  29 or 47?"

  ;; define a circle as the 8th plot symbol
  angle=indgen(49)/48.0*2*!PI              
  usersym, sin(angle), cos(angle-!pi)      

  IF n_elements(sday) EQ 1 THEN sday=replicate(sday, 9)
  IF n_elements(eday) EQ 1 THEN eday=replicate(eday, 9)
  ct=colortable()
  ct=ct[[1,2,3,4,5,6,202,200,207]]
  ct[4]=255+256l*255
  ct[5]=110+110*256l+255*(256l^2)
  IF !d.name EQ 'PS' THEN ct=[1,2,3,4,5,6,202,200,0]
  !p.multi=[0,1,2]
;  .run wrr_noah_scatterplot_le
  xr=[0,500]
  yr=xr
  IF NOT keyword_set(data) OR  NOT keyword_set(ndays) THEN BEGIN 
     cd, 'ihop1'
     wrr_noah_scatterplot_le, bestSOIL[0], xr=xr, /bestonly, data=data, sday=sday[0], eday=eday[0]
     ndays=n_elements(data[0,*])
     for i=1,8 do BEGIN
        IF i EQ 7 THEN i++
        cd, '../ihop'+strcompress(i+1, /remove_all)
        wrr_noah_scatterplot_le, bestSOIL[i], /oplot, /bestonly, data=tmp, sday=sday[i], eday=eday[i], color=ct[i]
        data=[[data],[tmp]]
        ndays=[ndays, n_elements(tmp[0,*])]
     endfor
     oplot, xr, xr
     cd, '../'
     xr=[0,600]
     plot, data[0,*], data[2,*], psym=1, xr=xr, yr=xr
     oplot, xr, xr
  endIF

  ClassRMS= sqrt(total((data[0,*]-data[2,*,*])^2)/(n_elements(data[0,*])-1))
  BestRMS = sqrt(total((data[1,*]-data[2,*,*])^2)/(n_elements(data[0,*])-1))
  print, ClassRMS, BestRMS
  
  xr=[0,600]
  yr=xr
  yt="Measured Latent Heat Flux (W/m!U2!N)"
  ti1="Best Fit SHPs"
  xt1="Best Fit Latent Heat Flux (W/m!U2!N)"
  ti2="Class Average SHPs"
  xt2="Class Ave. Latent Heat Flux (W/m!U2!N)"   

  
  plot, data[1,*], data[2,*], psym=3, xr=xr,yr=yr, $
    /xs,/ys, title=ti1, xtitle=xt1, ytitle=yt
  last=0
  longest_i=(where(ndays EQ max(ndays)))[0]
  xyouts, 30, 500, "Symbol Sequence = ", charsize=0.5
  FOR i=0, n_elements(ndays)-1 DO BEGIN
     FOR j=last, last+ndays[i]-1 DO BEGIN
        IF (j-last) MOD 6 LT 2 then psym=((j-last) MOD 6)+1 ELSE psym=((j-last) MOD 6)+2
        plots, data[1,j], data[2,j], color=ct[i], psym=psym, thick=2, symsize=0.6
        IF i EQ longest_i THEN plots, 160+(j-last)*17, 510, psym=psym, color=ct[8], thick=2, symsize=0.6
     ENDFOR
     oplot, data[1,last:last+ndays[i]-1], data[2,last:last+ndays[i]-1], color=ct[i]
     last+=ndays[i]
     xyouts, 30, 470-i*25, "IHOP Station"+strcompress(i+1), color=ct[i], charsize=0.5
  endFOR

  oplot, xr,xr
;xyouts,30,400,"R!U2!N="+string(correlate(data[1,*], data[2,*])^2,
;format='(F4.2)')
  xyouts,30,540,"RMS error="+strcompress(fix(BestRMS))+" W/m!U2!N"


  xr=[0,600]
  yr=xr
  plot, data[0,*,*], data[2,*,*], psym=3, xr=xr,yr=yr, $
    /xs,/ys, title=ti2, xtitle=xt2, ytitle=yt
  last=0
  xyouts, 30, 500, "Symbol Sequence = ", charsize=0.5
  FOR i=0, n_elements(ndays)-1 DO BEGIN
     FOR j=last, last+ndays[i]-1 DO BEGIN
        IF (j-last) MOD 6 LT 2 then psym=((j-last) MOD 6)+1 ELSE psym=((j-last) MOD 6)+2
        plots, data[0,j], data[2,j], color=ct[i], psym=psym, thick=2, symsize=0.6
        IF i EQ longest_i THEN plots, 160+(j-last)*17, 510, psym=psym, color=ct[8], symsize=0.6, thick=2
     ENDFOR
     oplot, data[0,last:last+ndays[i]-1], data[2,last:last+ndays[i]-1], color=ct[i]
     last+=ndays[i]
     xyouts, 30, 470-i*25, "IHOP Station"+strcompress(i+1), color=ct[i], charsize=0.6
  endFOR
;  FOR i=0, n_elements(ndays)-1 DO BEGIN
;     FOR j=last, last+ndays[i]-1 DO BEGIN 
;        IF j LT 3 then psym=(j MOD 6)+1 ELSE psym=((j+1) MOD 6)+1
;        plots, data[0,j], data[2,j], color=ct[i], psym=psym
;     ENDFOR
;     oplot, data[0,last:last+ndays[i]-1], data[2,last:last+ndays[i]-1], color=ct[i], psym=1
;     last+=ndays[i]
;  endFOR
  oplot, xr, xr         
;xyouts,30,480,"R!U2!N="+string(correlate(data[0,*], data[2,*])^2,
;format='(F4.2)')                               
  xyouts,30,540,"RMS error="+strcompress(fix(ClassRMS))+" W/m!U2!N"
  
;cd, 'ihop1'
;wrr_noah_scatterplot_le, bestSOIL[0], xr=xr, /classonly
;for i=1,8 do begin
;  cd, '../ihop'+strcompress(i+1, /remove_all)
;  wrr_noah_scatterplot_le, bestSOIL[i], /oplot, /classonly, data=tmp
;endfor
;cd, "../"

END
