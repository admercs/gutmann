FUNCTION getrunoffdata, filename, n, data
  openr, un, /get, filename
  soils=fltarr(n)
  runoff=fltarr(n)
  drain1=fltarr(n-6)
  drain=fltarr(n)

  readf, un, soils
  readf, un, runoff
  readf, un, drain1
  drain[0:n-7]=drain1
  data=[transpose(soils), transpose(runoff), transpose(drain)]

  return, 0
END



PRO whatveg, norunoff=norunoff, site=site, marksand=marksand, $
             nooutliers=nooutliers, pagetitle=pagetitle

  n=7
  ks=5
  LH=12
  STC=1

  IF NOT keyword_set(site) THEN site='8'
  IF NOT keyword_set(pagetitle) THEN pagetitle='';'All Soils'

  x=strarr(10)
  x[n]='m'
  x[ks]='K_sat'

  
  FOR col=ks,n,n-ks DO BEGIN 
     !p.multi=[0,2,2]
  veglevs=[0,30,60,100]
  FOR i=0, 3 DO BEGIN
     veg=veglevs[i]
     veglev=strcompress(veg,/remove_all)
     IF veg EQ 100 THEN veglev='_'+veglev

     junk=load_cols('ihop'+site+'_'+veglev+'/comb1', data)
     IF col EQ n THEN data[col,*]=1-(1/data[col,*])
     IF keyword_set(norunoff) THEN BEGIN 
        IF n_elements(norunoff) EQ 1 THEN BEGIN 
;           junk=getrunoffdata('ihop'+site+'_'+veglev+'/runoff', $
;                              n_elements(data[0,*]), runoffdata)
;           runoffdata=runoffdata[*,sort(runoffdata[0,*])]
;           data=data[*,sort(data[0,*])
;           runoff=where(runoffdata[1,*] GT 0.20)
;           drain=where(runoffdata[2,*] GT 0.20)
;           data=data[*,where(data[ks,*] GT 1.25)]
           
        ENDIF ELSE $
          data=data[*,norunoff]
     ENDIF 
     runoff=where(data[ks,*] LT 1.25)
     drain=where(data[stc,*] NE 0)
     IF keyword_set(nodrain) THEN BEGIN 
        IF n_elements(nodrain) EQ 1 THEN BEGIN 
           data=data[*,where(data[ks,*] LT 10^2.5)]
        ENDIF ELSE $
          data=data[*,norunoff]
     ENDIF 

     plot, data[col,*],data[LH,*], psym=1, xtit=x[col], ytit='Latent Heat Flux (W/m!U2!N)', $
       title='IHOP'+site+' veg='+strcompress(veg), xlog=(col EQ ks), yr=[0,600], symsize=0.25

;     oplot, data[col, drain], data[LH,drain], psym=1, symsize=0.25, color=255
;     oplot, data[col, runoff], data[LH,runoff], psym=1, symsize=0.25, color=255
     
     IF keyword_set(marksand) THEN BEGIN 
        sand=where(data[stc,*] NE 0)
        
        IF sand[0] NE -1 THEN $
          data=data[*,sand]
        oplot, data[col,*],data[LH,*], /psym, symsize=0.5
     ENDIF
     

     IF veg GT 30 AND keyword_set(nooutliers) THEN data=data[*,where(data[LH,*] GT 100)]
;     xyouts, 10^3.5, 500, string(stdev(data[LH,*]), format='(F6.2)'), charsize=0.5

  ENDFOR
  IF col EQ ks THEN xloc=10^2.5 ELSE xloc=0.5
;  xyouts, xloc,3500, align=0.5, pagetitle
  stop
  ENDFOR 
END
