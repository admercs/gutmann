pro plotnoahSHP, pause=pause, title=title

; Clay parameters
  Ks=9.74*10.^(-7)
  Ds=0.112*10.^(-4)
  theta_s=0.468
  theta_r=0.138
  beta=11.55
  

  fact=0.0001
  sz=(theta_s-theta_r)/fact

; Clay calculations
  theta=lindgen(sz)*fact+theta_r
  h=fltarr(sz)
  k=Ks*(theta/theta_s)^((2.0*beta)+3.0)
  d=Ds*(theta/theta_s)^(beta+2.0)
  C=k/d
  h[0]=0
  for i=1, sz-1 do begin
     h[i]=h[i-1]+fact/(C[sz-i])
  endfor

;store the output in better variable names so we can reuse the above
;code for sand too.  
  claytheta=theta
  clayk=k
  clayKs=KS
  clayD=d
  clayh=reverse(h)

; Saloam parameters
  Ks=5.23*10.^(-6)
  Ds=0.805*10.^(-5)
  theta_s=0.434
  theta_r=0.047
  beta=4.74
  

  fact=0.0001
  sz=(theta_s-theta_r)/fact

; Saloam calculations
  theta=lindgen(sz)*fact+theta_r
  h=fltarr(sz)
  k=Ks*(theta/theta_s)^((2.0*beta)+3.0)
  d=Ds*(theta/theta_s)^(beta+2.0)
  C=k/d
;  h=theta/C
  h[0]=0
  for i=1, sz-1 do begin
     h[i]=h[i-1]+fact/(C[sz-i])
  endfor

;store the output in better variable names so we can reuse the above
;code for sand too.  
  saloamtheta=theta
  saloamk=k
  saloamKs=KS
  saloamD=d
  saloamh=reverse(h)

; Sand parameters
  Ks=1.07*10.^(-4)
  Ds=0.608*10.^(-6)
  theta_s=0.339
  theta_r=0.010
  beta=2.79
  

  fact=0.0001
  sz=(theta_s-theta_r)/fact

; sand calculations
  theta=lindgen(sz)*fact+theta_r
  h=fltarr(sz)
  k=Ks*(theta/theta_s)^((2.0*beta)+3.0)
  d=Ds*(theta/theta_s)^(beta+2.0)
  C=k/d
;  h=theta/C
  h[0]=0
  for i=1, sz-1 do begin
     h[i]=h[i-1]+fact/(C[sz-i])
  endfor

;store the output in better variable names so we can reuse the above
;code for sand too.  
  allk=k
  head=reverse(h)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   PLOTTING ROUTINES
;;

plotSHP, theta, claytheta, saloamtheta, $
             head, clayh, saloamh, $
             allk, clayk, saloamk, $
             ks, clayks, saloamks, $
             d, clayd, saloamd, $
             pause=pause, title=title
end
