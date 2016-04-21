FUNCTION getNoon, data, day, column

  times=[11,11.5,12,12.5,13,13.5]*2
  
  midday=data[column,day*48+times]

  return, mean(midday)
END

FUNCTION plotbest, basedir=basedir, ef=ef
  
  IF keyword_set(basedir) THEN cd, current=old, basedir
  bestSOIL=strarr(11)
  bestSOIL[0] = 'out_sandyclayloam_835'
  bestSOIL[1] = 'out_clay_1713'
  bestSOIL[2] = 'out_sandyloam_1093'
  bestSOIL[3] = 'out_sandyloam_1018'
  bestSOIL[4] = 'out_loamysand_1720'
  bestSOIL[5] = 'out_clay_736'
  bestSOIL[6] = 'out_loam_2126'
  bestSOIL[7] = 'out_sandyloam_1278'
  bestSOIL[8] = 'out_sandyloam_1214'
  bestSOIL[9] = 'out_loam_1691'
  bestSOIL[10] = 'out_clayloam_1474'

;; after updating LH for closure...
  bestSOIL[0] = 'out_siltloam_1677'
  bestSOIL[1] = 'out_sandyclayloam_882'
  bestSOIL[2] = 'out_clay_1508'
  bestSOIL[3] = 'out_loam_1866'
  bestSOIL[4] = 'out_loamysand_1586'
  bestSOIL[5] = 'out_clay_1869'
  bestSOIL[6] = 'out_siltloam_1187'
  bestSOIL[7] = 'out_clayloam_279'
  bestSOIL[8] = 'out_sandyloam_1214'

;; after updating albedos  
  bestSOIL[0] = 'out_siltloam_1846'
  bestSOIL[1] = 'out_loam_1840'
  bestSOIL[2] = 'out_sandyloam_1392'
  bestSOIL[3] = 'out_siltyclayloam_1444'
  bestSOIL[4] = 'out_loamysand_2025'
  bestSOIL[5] = 'out_clay_1869'
  bestSOIL[6] = 'out_siltloam_1187'
  bestSOIL[7] = 'out_clayloam_1305'
  bestSOIL[8] = 'out_sandyloam_1214'
  
;; after updating storm for BSG
  bestSOIL[10]='out_sandyloam_1721'

  day=[29,29,37,38,38,14,14,46,46, 261,192]
  albedo=[0.25, 0.21, 0.18, 0.21, 0.19, 0.20, 0.23, 0.25, 0.19, 0.15, 0.14]
  class=['sandyclayloam', 'sandyclayloam', 'sandyloam', 'loam', $
         'loam', 'clayloam', 'siltyclayloam','siltyclayloam', $
         'siltyclayloam', 'sandyloam', 'loamysand']
  class=strupcase(class)

  dirs=file_search('ihop*')
  dirsort=sort(fix(strmid(dirs, 4,2)))
  dirs=dirs[dirsort]

  fulldata=fltarr(3,n_elements(dirs))

  FOR i=0,n_elements(dirs)-1 DO BEGIN 

     cd, current=lastdir, dirs[i]
     measurement=file_search('IHOPUDS*.txt')

     junk=load_cols(bestSOIL[i], curbest)
     junk=load_cols(measurement[0], measured)
     junk=load_cols(class[i], classdata)
     
     cur=getNoon(curbest, day[i], 7)

     IF i LT 9 THEN $
       meas=getNoon(measured, day[i]-11, 23) $
     ELSE $
       meas=getNoon(measured, day[i], 1)

     cls=getNoon(classdata, day[i], 7)

     IF keyword_set(ef) THEN BEGIN 
        ;; net radiation = albedo * sw + longwave down - longwave up
        Rn=(1-albedo[i])*getNoon(curbest, day[i], 5)+ $
           getNoon(curbest[6,*]*0.05 - 0.95*(5.67E-8) * (curbest[2,*]^4.0),day[i],0)
        IF i LT 9 THEN Rn=getNoon(measured, day[i]-11, 20) ELSE Rn=getNoon(measured, day[i], 2)

        G = getNoon(curbest, day[i],8)
        ;; available energy=Rn-G (if G positive down)
        Q=Rn+G ; model G is positive up
        
;        Q=getNoon(Q, day[i], 0)

        ;; compute evaporative fraction
        meas/=Q
        cls/=Q
        cur/=Q
        xt1='Modeled EF (class average SHP)'
        xt2='Modeled EF (Best Fit SHP)'
        yt='Measured EF'
     ENDIF ELSE BEGIN 
        xt1='Modeled LH (class average SHP)'
        xt2='Modeled LH (best fit SHP)'
        yt='Measured LH (W/m!U2!N)'
     ENDELSE

     fulldata[*,i]=[cur,meas,cls]

     cd, lastdir
  ENDFOR

  !p.multi=[0,1,2]
  charsize=0.75
;; are we plotting evaporative fraction of latent heat flux?
;; set the x and y ranges as appropriate
  IF keyword_set(ef) THEN plotrange=[0.2,1.0] ELSE plotrange=[100,700]


;; plot texture class LH vs measured
  plot, fulldata[2,*], fulldata[1,*], xtitle=xt1, /xs,/ys, $
        ytitle=yt, psym=1, yr=plotrange, xr=plotrange, $
        title='r!U2!N = '+$
        string(correlate(fulldata[2,*], fulldata[1,*])^2, format='(F4.2)')+ $
        '      slope='+ $
        string((linfit(fulldata[2,*], fulldata[1,*]))[1], format='(F4.2)'), $
        xtickinterval=0.2, ytickinterval=0.2, xminor=2, yminor=2, charsize=charsize
;  print, linfit(fulldata[2,*], fulldata[1,*])
;  print, linfit(fulldata[0,*], fulldata[1,*])
;; one to one line
  oplot, plotrange,plotrange

;; plot best fit vs measured
  plot, fulldata[0,*], fulldata[1,*], xtitle=xt2, /xs,/ys, $
        ytitle=yt, psym=1, yr=plotrange, xr=plotrange, $
        title='r!U2!N = '+$
        string(correlate(fulldata[0,*], fulldata[1,*])^2, format='(F4.2)')+ $
        '      slope='+ $
        string((linfit(fulldata[0,*], fulldata[1,*]))[1], format='(F4.2)'), $
        xtickinterval=0.2, ytickinterval=0.2, xminor=2, yminor=2, charsize=charsize

;; one to one line
  oplot, plotrange,plotrange

  IF keyword_set(basedir) THEN cd, old

  return, fulldata
END

