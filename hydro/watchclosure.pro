PRO watchclosure, file, data=data, _extra=e, txt=txt
  maxLE=700
  LEyr=[0,maxLE]

  oldp=!p
  !p.charsize=2

  IF keyword_set(txt) THEN BEGIN 
    junk=load_cols(txt, class)
    class=class[*,11*48:*]
 ENDIF

  
  IF NOT keyword_set(data) THEN $ 
    junk= load_cols(file, data)
  time=lindgen(n_elements(data[0,*]))/48.0

  closure=1/((data[20,*]+data[25,*])/(data[23,*]+data[24,*]))
  
  !p.multi=[0,1,3]
  baddata=where(data[23,*] GT maxLE)
  IF baddata[0] NE -1 THEN $
    data[23,baddata]=0
  plot, time, data[23,*], _extra=e, yr=LEyr, /xs,/ys
  oplot, time, 700-(10*data[19,*])
  IF keyword_set(txt) THEN $
    oplot, time, class[7,*], l=2
  
  plot, time, data[20,*]+data[25,*], _extra=e, yr=LEyr, /xs,/ys
  baddata=where(data[24,*] GT maxLE)
  IF baddata[0] NE -1 THEN $
    data[24,baddata]=0
  oplot, time, data[24,*], l=2
  oplot, time, data[24,*]+data[23,*], l=1

  highsun=where(data[20,*] GT 300)
  IF highsun[0] NE -1 THEN BEGIN
     time=time[highsun]
     closure=closure[highsun]
  ENDIF

  baddata=where(closure GT 2.0)
  IF baddata[0] NE -1 THEN $
    closure[baddata]=0
  plot, time, closure, _extra=e, yr=[0.5,1.5], /psym, /xs,/ys
  oplot, [0,1000],[1,1],l=2

  !p=oldp
END

