PRO findingdays, measuredfname, modelfname, $
                 Tsd=Tsd, ETd=ETd, ETm=ETm, Tsm=Tsm, data=data
  IF n_elements(measuredfname) EQ 0 THEN $
    measuredfname=file_search("IHOPUDS*.txt")
  IF n_elements(modelfname) EQ 0 THEN $
    modelfname="LOAM"

  print, load_cols(measuredfname, measure)
  Tsd=measure[22,*]
  ETd=measure[23,*]
  
  print, load_cols(modelfname, model)
  Tsm=model[2,11l*48:*]
  ETm=model[7,11l*48:*]
  ETm=ETm[0,0:n_elements(ETd)-1]
  Tsm=Tsm[0,0:n_elements(Tsd)-1]



  data=[ETd,Tsd, ETm,Tsm]

END

PRO plotfounddays, data, _extra=e

  ETd=data[0,*]
  Tsd=data[1,*]
  ETm=data[2,*]
  Tsm=data[3,*]-273.15

  time=indgen(n_elements(Tsm))/48.0
  index=where(ETd LT 2000)

  !p.multi=[0,1,2]
  window, xs=1400, ys=1100

  plot, time[index], ETd[index], yr=[-200,600], /xs, /ys, _extra=e
  oplot, time, ETm, l=1
  oplot, time, (ETm-ETd)-100, l=2
  oplot, [0,3000],[-100,-100]

  plot, time, Tsd, yr=[-20,60],/xs,/ys, _extra=e
  oplot, time, Tsm,l=1
  oplot, time, Tsm-Tsd-10, l=2
  oplot, [0,3000],[-10,-10]
END

