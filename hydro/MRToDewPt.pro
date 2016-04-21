function MRToDewPt, mr, P

  newmr=mr/1000.                ;convert g/kg -> g/g
  e=(newmr*P)/(0.622+newmr)     ;calculate the vapor pressure (e)
;  e=e*1                         ;convert mbars -> hPa
  T= (alog10(e)-9.4041)/2354.

  return, T
end
