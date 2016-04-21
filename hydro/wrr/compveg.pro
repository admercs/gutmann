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



PRO compveg, site=site, marksand=marksand, summary=summary, fit=fit, $
             pagetitle=pagetitle, cutoff=cutoff, ksonly=ksonly, nocolor=nocolor

  ks=5
  n=7
  step=n-ks
  IF keyword_set(ksonly) THEN step*=2
  LH=12
  STC=1
  rcol=16
  dcol=17

  IF NOT keyword_set(cutoff) THEN cutoff=0.9

  IF !d.name EQ 'X' THEN BEGIN 
     red=1
     green=256l
     blue=256l^2
  ENDIF ELSE BEGIN 
     red=1/255.0
     green=2/255.0
     blue=3/255.0
  ENDELSE


  IF NOT keyword_set(site) THEN site='8'
  IF NOT keyword_set(pagetitle) THEN pagetitle='';'All Soils'

  xt=strarr(10)
  xt[n]='m'
  xt[ks]='Ks (cm/day)'

  
  FOR col=ks,n,step DO BEGIN 

     IF keyword_set(summary) THEN BEGIN
        veglevs=[0,30,60,90] 
        !p.multi=[0,1,4]
     ENDIF ELSE BEGIN 
        veglevs=indgen(11)*10
        !p.multi=[0,3,4]
     ENDELSE 

  FOR i=0, n_elements(veglevs)-1 DO BEGIN
     veg=veglevs[i]
;  FOR veg=0,100, 10 DO BEGIN
     veglev=strcompress(veg,/remove_all)
     IF veg EQ 100 THEN veglev='_'+veglev

     junk=load_cols('ihop'+site+'_'+veglev+'/comb1', data)
     IF col EQ n THEN BEGIN 
        data[col,*]=1-(1/data[col,*])
        xr=[0,1]
     ENDIF ELSE xr=[10.^(-2),10.^4]

     cs=1.5
     IF col EQ ks THEN xticks=3 ELSE xticks=0
     plot, data[col,*],data[LH,*], psym=1, xtit=xt[col], ytit='LH (W/m!U2!N)', $
           title=' veg='+strcompress(veg)+'%', charsize=cs, $;+ $
           xlog=(col EQ ks), yr=[0,600], symsize=0.25,/xs, xticks=xticks,xr=xr
;; paste this line above the xlog line and remove comments to add cuttoff to title
;           ' cutoff='+strcompress(fix(cutoff*100),/remove_all)+'%', $

     IF keyword_set(fit) THEN BEGIN
        cs=0.8
        IF col EQ n THEN BEGIN
           x1=data[col,*] &     x2=x1^2 &     x3=x1^3 &     x4=x1^4
           params=regress([x1,x2,x3,x4],transpose(data[LH,*]),const=yint,mcorr=corr)
           corr=corr^2

           x=indgen(100)/99.0
           oplot, x, params[0]*x+params[1]*x^2+params[2]*x^3+params[3]*x^4+yint
           xyouts, 0.8,480, 'r!U2!N='+string(corr,format='(F4.2)'),charsize=cs, align=0.5

        ENDIF ELSE IF col EQ ks THEN BEGIN 
           x1=alog10(data[col,*]) &     x2=x1^2 &     x3=x1^3 &     x4=x1^4
           params=regress([x1,x2,x3,x4],transpose(data[LH,*]),const=yint,mcorr=corr)
           corr=corr^2
           
           x=(indgen(100)/99.0)*8-2
           oplot, 10.0^x, params[0]*x+params[1]*x^2+params[2]*x^3+params[3]*x^4+yint
           xyouts, 10^2.8,480, 'r!U2!N='+string(corr,format='(F4.2)'),charsize=cs, align=0.5
           
        ENDIF 

     ENDIF


     IF keyword_set(marksand) THEN $
       drain=where(data[dcol,*] GT cutoff AND data[stc,*] NE 0) $
     ELSE $
       drain=where(data[dcol,*] GT cutoff)
     IF drain[0] NE -1 AND NOT keyword_set(nocolor) THEN $
       oplot, data[col, drain], data[LH,drain], psym=3, symsize=0.25, color=255*red
     runoff=where(data[rcol,*] GT cutoff)
     IF runoff[0] NE -1 AND NOT keyword_set(nocolor)  THEN $
       oplot, data[col, runoff], data[LH,runoff], psym=3, symsize=0.25, color=255*green

     IF keyword_set(marksand) AND NOT keyword_set(nocolor) THEN BEGIN 
        sand=where(data[stc,*] EQ 0)
        
        IF sand[0] NE -1 THEN $
          oplot, data[col,sand],data[LH,sand], color=255*blue,psym=3;, /psym, symsize=0.15
     ENDIF

     
     

;     IF veg GT 30 AND keyword_set(nooutliers) THEN data=data[*,where(data[LH,*] GT 100)]
     IF NOT keyword_set(nocolor) THEN BEGIN 
        cs=0.5
        goodpoints=where((data[dcol,*]+data[rcol,*]) LT cutoff)
        xyouts, 10^(-1.5), 525, strcompress(100*n_elements(drain)/1221,/remove_all)+'%', $
                color=255*red, charsize=cs
        xyouts, 10^(-1.5), 475, strcompress(100*n_elements(runoff)/1221,/remove_all)+'%', $
                color=255*green, charsize=cs
        IF goodpoints[0] NE -1 THEN $
          xyouts, 10^2.8, 525, 'dev='+string(stdev(data[LH,goodpoints]), format='(F5.1)'), $
                  charsize=cs
     ENDIF

  ENDFOR
;  IF col EQ ks THEN xloc=10^2.5 ELSE xloc=0.5
;  xyouts, xloc,3500, align=0.5, pagetitle
;  IF NOT keyword_set(ksonly) THEN stop
  ENDFOR 
END
