;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; used to look for the optimal storm in a weather record
;; plots noon (or 10-day running average noon)
;;      T, SWin, MR, PET
;;
;; read noah input and output files
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro PickDate, dataF, noahF

  IF n_elements(dataF) EQ 1 THEN $
    print, load_cols(dataF, data) ELSE data=dataF
  IF n_elements(noahF) EQ 1 THEN $
    print, load_cols(noahF, noah) ELSE noah=noahf


; Generate the Day-x variable
  day=lindgen(n_elements(data[0,*]))/48.
  
  noon=where((day mod 1) eq 0.5)
  sz=n_elements(noon)

  rs_aves=dblarr(sz-10)
  pe_aves=dblarr(sz-10)
  MR_aves=dblarr(sz-10)
  T_aves=dblarr(sz-10)

  for i=0, sz-11 do begin
     rs_aves[i]=mean(data[8,noon[i:i+10]])
     pe_aves[i]=mean(noah[29,noon[i:i+10]])
     MR_aves[i]=mean(data[7,noon[i:i+10]])
     T_aves[i]=mean(data[6,noon[i:i+10]])
  endFOR

  ;!p.charsize=2
  !p.multi=[0,1,4]
;  window, xs=1000, ys=1000
;  wset, 2
  xr=[530,540]
  xr=xr-365
  day=day-365
;  plot, day[noon], rs_aves, title="Solar Radiation 10-day", $
;        yr=[600,1000], /ys, xr=xr, /xs
;  plot, day[noon], pe_aves, title="Potential Evaporation 10-day", $
;        yr=[520,600], /ys, xr=xr, /xs
;  plot, day[noon], MR_aves, title="Mixing Ratio 10-day", $
;        yr=[0,15], /ys, xr=xr, /xs
;  plot, day[noon], T_aves, title="Air Temperature 10-day", $
;        yr=[15,40], /ys, xr=xr, /xs


;  wset, 2
  plot, day, data[8,*], xr=xr, title="Solar Radiation", $
        yr=[00,1100], /ys, /xs, ytitle="Solar Radiation (W/m^2)"
  plot, day, noah[29,*], xr=xr, title="Potential Evaporation", $
        yr=[0,700], /ys, /xs, ytitle="Potential Evaporation (W/m^2)"
  plot, day, data[7,*], xr=xr, title="Mixing Ratio", yr=[0,12], $
        /xs, ytitle="Mixing ratio (g/kg)"
  plot, day, data[6,*], xr=xr, title="Air Temperature", /xs, $
        xtitle="Day of the year 2002", ytitle="Temperature (Deg C)"

  oplot, day, noah[3,*]*10000, l=1
end
