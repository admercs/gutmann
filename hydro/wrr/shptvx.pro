
PRO shptvx, cutoff=cutoff, value=value, nosand=nosand

;; this is the symbol we will use for the tvx diagram
;; it just draws a dash -
  usersym, [-0.5,0.5],[0,0]

;; default value for the runoff/drainage cutoff as a fraction of rainfall
  IF NOT keyword_set(cutoff) THEN cutoff=0.3

;; colors for plotting either to the screen or a postscript file
  IF !d.name EQ 'X' THEN BEGIN 
     red=255
     green=255*256l
     blue=255*256l^2
  ENDIF ELSE BEGIN 
     red=1
     green=2
     blue=3
  ENDELSE

  ;; we are only looking at IHOP 8 at the moment
  site='8'

;; plotting titles
  xtit='Vegetation Cover'
  ytit=['Skin T', 'Soil Moisture', 'LH']

  IF keyword_set(nosand) THEN nsoils=1002 ELSE nsoils=1221
;; array to store data in as we read it
  data=fltarr(5,11,nsoils)
  percs=fltarr(5,11,4)
  IF NOT keyword_set(value) THEN value=[0.10,0.90]             ; percentiles to get

;; key to the comb1 file
; 0     1     2    3   4    5  6   7   8  9 10 11 12 13  14     15      16     17
;soil,class,sand,silt,clay,ks,vga,vgn,ts,tr,Ts, H,LE, G,STC(1),SMC(1),runoff,drainage
  vars=[10,15,12,16,17] ; columns we will read from comb1
  
  !p.multi=[0,2,3]

  veglevs=indgen(11)*10
  ;; loop over the veg directories and read in the data
  FOR i=0, n_elements(veglevs)-1 DO BEGIN

;; set up the filename
     veg=veglevs[i]
     veglev=strcompress(veg,/remove_all)
     IF veg EQ 100 THEN veglev='_'+veglev

;; read the data
     junk=load_cols('ihop'+site+'_'+veglev+'/comb1', curdata)

     IF keyword_set(nosand) THEN curdata=curdata[*,where(curdata[1,*] NE 0)]
;; store the data
     FOR var=0,n_elements(vars)-1 DO BEGIN 
        data[var,veg/10,*]=curdata[vars[var],*]
        percs[var,veg/10,0:1]=percentiles(curdata[vars[var],*], value=value)
        percs[var,veg/10,2:3]=percentiles(curdata[vars[var], $
                                 where(curdata[vars[3],*]+ curdata[vars[4],*] $
                                       LT cutoff)], $
                                          value=value)
     ENDFOR

  ENDFOR

  data[0,*,*]-=273.15 ; convert K to deg C
  percs[0,*,*]-=273.15 ; convert K to deg C

  symbol=3
;; plot the data
  seed=123123
  xerr=randomu(seed, nsoils)*10-5
  FOR i=0,2 DO BEGIN 
     x=intarr(nsoils)
     yrs=[[28,40],[0.0,0.7],[0,550]]
     plot, x+xerr, data[i,0,*], psym=symbol, xtit=xtit, ytit=ytit[i], xr=[-9,109],/xs, $
           yr=[yrs[*,i]], /ys
     FOR veg=1,10 DO BEGIN 
        xerr=randomu(seed, nsoils)*10-5
        x[*]=veg*10
        oplot, x+xerr,data[i,veg,*], psym=symbol
     ENDFOR
     oplot, veglevs, percs[i,*,0], l=2, color=red, thick=2
     oplot, veglevs, percs[i,*,1], l=2, color=red, thick=2


;     yrs=[[28,37],[0.0,0.7],[100,600]]
     tmpdata=data[i,0,where(data[4,0,*] + data[3,0,*] LT cutoff)]
     x[*]=0
     plot, x+xerr, tmpdata[0,0,*], psym=symbol, xtit=xtit, ytit=ytit[i], xr=[-9,109], /xs, $
           yr=[yrs[*,i]], /ys
     FOR veg=1,10 DO BEGIN 
        x[*]=veg*10
        tmpdata=data[i,veg,where(data[4,veg,*] + data[3,veg,*] LT cutoff)]
        xerr=randomu(seed, nsoils)*10-5
        oplot, x+xerr,tmpdata[0,0,*], psym=symbol
     ENDFOR
     oplot, veglevs, percs[i,*,3], l=2, color=red, thick=2
     oplot, veglevs, percs[i,*,2], l=2, color=red, thick=2
        
  endfor

;     IF veg GT 30 AND keyword_set(nooutliers) THEN data=data[*,where(data[LH,*] GT 100)]
;  goodpoints=where((data[dcol,*]+data[rcol,*]) LT cutoff)
;     xyouts, 10^(-1.5), 500, strcompress(100*n_elements(drain)/nsoils,/remove_all)+'%', $
;             color=255*red, charsize=1.5
;     xyouts, 10^(-1.5), 400, strcompress(100*n_elements(runoff)/nsoils,/remove_all)+'%', $
;             color=255*green, charsize=1.5
;     xyouts, 10^4.0, 500, 'dev='+string(stdev(data[LH,goodpoints]), format='(F5.1)'), $
;             charsize=1.5
;     xyouts, 10^4.0, 400, ''+strcompress(fix(cutoff*100),/remove_all)+'%'

END
