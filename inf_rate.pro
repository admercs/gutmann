function calcErr, volRates, tensions, alpha, logKs, R_disc
  Ks=10.0^logKs

  Q= Ks*2.71828^(alpha*(-1)*tensions) * (1.0+(4.0/(!pi*R_disc*alpha)))
  
  return, sqrt(mean((volRates-Q)^2.0))
end

pro inf_rate, dataFname, infoFname, col=col
  if not keyword_set(col) then col=5

  j=load_cols(dataFname, data)
  j=load_cols(infoFname, info)

  R_resevoir=2.25  ; resevoir tube radius
  R_disc=20.0      ; infiltration disc radius

  infVolume=fltarr(n_elements(info[0,*]))
  infRates=fltarr(n_elements(info[0,*]))
  tension=fltarr(n_elements(info[0,*]))

  ;; info file contains column formated data,
  ;;   one line for each tension measured
  ;;   column 0 = column in data file
  ;;   column 1 = site number
  ;;   column 2 = tension index (0-n) used so we can combine multiple intervals
  ;;   column 3 = start position for current interval
  ;;   column 4 = stop position for current interval
  ;;   column 5 = top of water in bubbling tube
  ;;   column 6 = bottom of air entry tube
  time =fix(data[3,*]/100)+fix(data[3,*] mod 100)/60.0 + data[4,*]/3600.0
  tmp=''
  !p.multi=[0,1,2]
  for i=0, n_elements(info[0,*])-1 do begin
      col=info[0,i]
 ;     startX=(where(data[3,*] eq info[0,i]))[0]
 ;     endX=(where(data[3,*] eq info[1,i]))[0]
      startX=info[3,i]
      endX=info[4,i]
      tension[i]=info[6,i]-info[5,i];;-3.2  ; minus the offset for the given infiltrometer

      line=linfit(time[startX:endX], data[col, startX:endX], sigma=deviation)
      r=correlate(time[startX:endX], data[col, startX:endX])
      infVolume[i] = abs(line[0]*!pi * R_resevoir^2.0)

      infRates[i] = infVolume[i]/(!pi*R_disc^2.0)
      print, tension[i], info[1,i], line[1], deviation[1], r^2, infRates[i], format='(7F10.3)'
      plot, time[startX:endX], data[col,startX:endX], psym=2, /xs, /ys
      oplot, time[startX:endX], time[startX:endX]*line[1]+line[0], l=2

      plot,  data[col,startX:endX] - (time[startX:endX]*line[1]+line[0]), psym=2
;      read, tmp
  endfor


  minErr=100000.0
  trueA=-9999.9
  trueK=-9999.9
  ;; loop through reasonable values of Ks and alpha (I don't really
  ;; know the range of values to search so I may need to expand
  ;; this).  
  nsites=max(info[1,*])
  window, 1, xs=1000, ys=1000
  !p.multi=[0,2,2]
  FOR curSite=1,nsites DO begin
     sitedex=where(info[1,*] EQ curSite)

     plot, tension[sitedex], infVolume[sitedex], psym=2, xr=[0,25]
     wait, 0.1
     for alpha=0.0001,0.4, 0.0001 do begin
        for logKs=3.0,3.5, 0.0001 do begin
           err=calcErr(infVolume[sitedex], tension[sitedex], alpha, logKs, R_disc)
           if err lt minErr then begin
              minErr=err
              trueA=alpha
              trueK=logKs
           endif
        ENDFOR
;        IF alpha MOD 10 LT 0.1 THEN print, round(alpha)
     ENDFOR
     tmptensions=indgen(26)
     oplot, indgen(26), (10.0^trueK)*2.71828^(trueA*(-1)*tmptensions) * (1.0+(4.0/(!pi*R_disc*trueA)))
     print, curSite, trueA, trueK
  ENDFOR
  wset, 0
end
