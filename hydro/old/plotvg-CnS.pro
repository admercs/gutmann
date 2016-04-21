pro plotvg_CnS

;clay
  theta_s=0.459
  theta_r=0.098
  a=0.015
  n=1.25
  m=1-(1/n)
  FOR h=0.0001,50,0.1 DO BEGIN
     allk[(h*10)-1]=KS*((1-(a*h)^(n*m)*(1+((a*h)^n))^(-1*m))^2/ $
                        (1+(a*h)^n)^m)
     theta[(h*10)-1]=theta_r+(theta_s-theta_r)*(1+(a*h)^n)^(-1*m)
  ENDFOR
  plot, theta, allk, line=1


;sand
  theta_s=0.459
  theta_r=0.098
  a=0.015
  n=1.25
  m=1-(1/n)
  FOR h=0.0001,50,0.1 DO BEGIN
     allk[(h*10)-1]=KS*((1-(a*h)^(n*m)*(1+((a*h)^n))^(-1*m))^2/ $
                        (1+(a*h)^n)^m)
     theta[(h*10)-1]=theta_r+(theta_s-theta_r)*(1+(a*h)^n)^(-1*m)
  ENDFOR
  oplot, theta, allk


end
