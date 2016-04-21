
FUNCTION calcVGhtCurve, params, theta=theta, h=h
  n=params[0]
  a=params[1]
  Ks=params[2]
  ts=params[3]
  tr=params[4]

  m=1.0-1.0/n


  IF keyword_set(theta) THEN BEGIN
     IF n_elements(theta) GT 1 THEN    $
       Sat=double((theta-tr)/(ts-tr))  $
     ELSE Sat=double(indgen(1000)/999.)
     
     return, Ks * (Sat^0.5) * (1.0-((1.0-(Sat^(1.0/m)))^m))^2.
  ENDIF 
  IF keyword_set(h) THEN BEGIN

     IF n_elements(h) LE 1 THEN    $
       h=indgen(700)
     h=double(h)
     Sat= ((1.0+(a*h)^n)^(-1.0*m))
     return, Sat*(Ts-Tr)+Tr
  ENDIF 
  
  return, -1
END
;; given van Genuchten parameters and the keyword theta or h
;; calculates and returns a conductivity curve.  
FUNCTION calcVGcurve, params, theta=theta, h=h, tnh=tnh
  IF keyword_set(tnh) THEN return, calcVGhtCurve(params, theta=theta, h=h)

  n=params[0]
  a=params[1]
  Ks=params[2]
  ts=params[3]
  tr=params[4]

  m=1.0-1.0/n


  IF keyword_set(theta) THEN BEGIN
     IF n_elements(theta) GT 1 THEN    $
       Sat=double((theta-tr)/(ts-tr))  $
     ELSE Sat=double(indgen(1000)/999.)
     
     return, Ks * (Sat^0.5) * (1.0-((1.0-(Sat^(1.0/m)))^m))^2.
  ENDIF 
  IF keyword_set(h) THEN BEGIN

     IF n_elements(h) LE 1 THEN    $
       h=indgen(700)
     h=double(h)
     Sat= ((1.0+(a*h)^n)^(-1.0*m))
     return, Ks * (Sat^0.5) * (1.0-((1.0-(Sat^(1.0/m)))^m))^2.
  ENDIF 
  
  return, -1
END
