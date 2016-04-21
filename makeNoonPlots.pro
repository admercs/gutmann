PRO makeNoonPlots, bfg, bsg, outfile, startDay=startDay, endDay=endDay
  IF NOT keyword_set(startDay) THEN startDay=209
  IF NOT keyword_set(endDay) THEN endDay=251

  starthour=1000
  endhour=1400

  

  ;; setup output arrays
  tOut=fltarr(2,endDay+1-startDay)
  smcOut=fltarr(2,endDay+1-startDay)
  luOut=fltarr(endDay+1-startDay)

  ;; read the data
  IF n_elements(bfg) GT 100 THEN d1=bfg ELSE BEGIN
     print, "Loading ", bfg, "..."
     junk= load_cols(bfg, d1)
  END
  IF n_elements(bsg) GT 100 THEN d2=bsg ELSE BEGIN
     print, "Loading ", bsg, "..."
     junk= load_cols(bsg, d2)
  END

  i=0
  
  d1i=d1
  d2i=d2
  FOR startDay=210,210,10 DO BEGIN
  ; these are indexes into the files and probably should not be changed
  ; column numbers in raw*.txt files
  rain=[28,58]
  day=[1,2]
  hour=[2,3]
  smc=[29,86]
  t=[6,33]
  lu=85
  ; indices into the above arrays
  bf=0
  bs=1

 ;    wset, 1
     endDay=startDay+20
     d1=d1i
     d2=d2i
     start=startDay
     xr=[start,start+20.0]
     dayss=indgen(20*96)/96. +start
     plot, dayss, d1[rain[bf],start*96l:(start+20)*96l], xr=xr, yr=[0,25], /xs, $
           xtitle="Day of the year", ytitle="Rain and dT @2.5cm (C)"
      oplot, dayss, (d2[rain[bs],start*96l:(start+20)*96l]+10)>10, l=1
;      oplot, dayss, d1[t[bf],start*96l:(start+20)*96l]/10
;      oplot, dayss, d2[t[bs],start*96l:(start+20)*96l]/10+10, l=1
      oplot, dayss, d1[t[bf],start*96l:(start+20)*96l]- $
             d2[t[bs],start*96l:(start+20)*96l]+20>15
      oplot, xr, [20,20]




  ;; move data around to put it in easy to use arrays
  print, "Moving data"
  d1=d1[*,where(d1[day[bf],*] GE startDay AND d1[day[bf],*] LE endDay)]
  d2=d2[*,where(d2[day[bs],*] GE startDay AND d2[day[bs],*] LE endDay)]

  print, "Moving data"
  d1=d1[[day[bf],hour[bf],rain[bf],smc[bf],t[bf]],*]
  d2=d2[[day[bs],hour[bs],rain[bs],smc[bs],t[bs], lu],*]
  
  day=0 & hour=1 & rain=2 & smc=3 & t=4 & lu=5

  
  print, "Collecting Noon data"
  ;; loop through all days gathering data as we go
  FOR curDay=startDay, endDay DO BEGIN

     dex=where(d1[day,*] EQ curDay AND $
               d1[hour,*] GE startHour AND $
               d1[hour,*] LE endHour AND $
               d1[t,*] GT 0 AND d1[t,*] LT 100)
          
     IF dex[0] NE -1 THEN $
       tOut[bf,curDay-startDay]=mean(d1[t,dex])
     
     dex=where(d2[day,*] EQ curDay AND $
               d2[hour,*] GE startHour AND $
               d2[hour,*] LE endHour AND $
               d2[t,*] GT 0 AND d2[t,*] LT 100)
     IF dex[0] NE -1 THEN tOut[bs,curDay-startDay]=mean(d2[t,dex])


     dex=where(d1[day,*] EQ curDay AND $
               d1[hour,*] GE startHour AND $
               d1[hour,*] LE endHour AND $
               d1[smc,*] GT 0 AND d1[smc,*] LT 1)
     IF dex[0] NE -1 THEN smcOut[bf,curDay-startDay]=mean(d1[smc,dex])
     dex=where(d2[day,*] EQ curDay AND $
               d2[hour,*] GE startHour AND $
               d2[hour,*] LE endHour AND $
               d2[smc,*] GT 0 AND d2[smc,*] LT 1)
     IF dex[0] NE -1 THEN smcOut[bs,curDay-startDay]=mean(d2[smc,dex])


     dex=where(d2[day,*] EQ curDay AND $
               d2[hour,*] GE startHour AND $
               d2[hour,*] LE endHour AND $
               d2[lu,*] GT 300 AND d2[lu,*] LT 1000)
     
     IF n_elements(dex) GT 3 THEN BEGIN 
        luOut[curDay-startDay]=mean(d2[lu,dex])
     END

  endFOR

;  window, 3, xs=1000, ys=1000
  oldpm=!p.multi
  !p.multi=[0,1,2]
  x=indgen(endDay-startDay+1)+startDay
  xr=[startDay,endday]
;  xr=[210,220]
  dex=where(tOut[0,*] NE 0)
  plot, x[dex]+0.5, tOut[0,dex], yr=[20,40], xr=xr, $
        xtitle="Day of the year", ytitle="Soil Temperature @2.5cm (C)"
  dex=where(tOut[1,*] NE 0)
  oplot, x[dex]+0.5, tOut[1,dex], l=1
  oplot, x[dex]+0.5, (tOut[0,dex]-tOut[1,dex])+23, l=2
  oplot, xr, [0,0]+23, l=3
  dex=where(smcOut[0,*] NE 0)
  plot, x[dex]+0.5, smcOut[0,dex], yr=[0,0.4], xr=xr, $
        xtitle="Day of the year", ytitle="Soil Moisture @2.5cm"
  dex=where(smcOut[1,*] NE 0)
  oplot, x[dex]+0.5, smcOut[1,dex], l=1
  days=indgen((endDay-startDay+1)*96.)/96. +startDay
;  plot, days, d2[smc,*], l=1, xr=xr, yr=[0,0.4]
;  oplot, days, d1[smc,*]

  dex=where(luOut NE 0)
  plot, x[dex]+0.5, (luOut[dex]/(0.95 * 5.67051e-8))^0.25-273.15, $
        yr=[40,60], xr=xr, xtitle="Day of the year", ytitle="Skin Temperature(C)"

  plot, days, d2[rain,*]+10, l=1, yr=[0,20], xr=xr, $
        xtitle="Day of the year", ytitle="Rain (mm/15min)"
  oplot, days, d1[rain,*]
  !p.multi=oldpm
;  read, i
endfor
END
