;; given clap Hornberger parameters and the keyword theta or h
;; calculates and returns a conductivity curve.  
FUNCTION calcCHcurve, params, theta=theta, h=h
  b=params[0]
  psi_s=params[1]
  Ks=params[2]
  ts=params[3]
  tr=params[4]


  IF keyword_set(theta) THEN BEGIN
     IF n_elements(theta) GT 1 THEN    $
       Sat=double((theta)/(ts))  $
     ELSE Sat=double(indgen(1000)/999.)
     
     return, (Ks * Sat^(2.0*b+3)) < Ks
  ENDIF 
  IF keyword_set(h) THEN BEGIN
     IF n_elements(h) LE 1 THEN    $
       h=indgen(700)
     h=double(h)
     return, (Ks * (psi_s/h)^(2+3.0/b)) < Ks
  ENDIF 
  
  return, -1
END
