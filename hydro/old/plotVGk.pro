PRO plotVGk

  a =0.035
  ks=20 

  allk=fltarr(500)
  window, 0
  FOR n=1.1,3.2,0.1 DO BEGIN
     m=1-(1/n)
;     FOR h=0.0001,50,0.01 DO BEGIN 
;        allk[(h*100)-1]=KS*((1-(a*h)^(n*m)*(1+((a*h)^n))^(-1*m))^2/ $
;                            (1+(a*h)^n)^m) 
;     ENDFOR
;     wait, 0.1
;     plot, allk
;     w_set, 1
     FOR a=0.006,0.04, 0.001 DO BEGIN
        m=1-(1/n)
        FOR h=0.0001,50,0.1 DO BEGIN 
           allk[(h*10)-1]=KS*((1-(a*h)^(n*m)*(1+((a*h)^n))^(-1*m))^2/ $
                              (1+(a*h)^n)^m) 
        ENDFOR
        wait, 0.1
        plot, allk
     ENDFOR
  ENDFOR
END

     
