PRO interferance
  n=5
  maxshift=100
  r=1 & g=256l & b=256l^2
  c1=200*r
  c2=200*g
  c3=200*b
  !p.background=(256l^3)-1
  !p.color=0
  FOR i=0, maxshift DO BEGIN
     x=float(indgen(360))*n
     y1=sin(x*!dtor)
     y2=sin((x+i*n)*!dtor)
     plot, x, y1, yr=[-2,2], xr=[0,360*n], /xs
     oplot, x, y1, color=c1
     oplot, x, y2, color=c2
     oplot, x, y1+y2, thick=2, color=c3
     wait, 0.1
  endFOR

end

PRO changeFrequency
  n=5
  maxshift=250
  r=1 & g=256l & b=256l^2
  c1=200*r
  c2=200*g
  c3=200*b
  !p.background=(256l^3)-1
  !p.color=0

  FOR i=0, maxshift DO BEGIN
     x=float(indgen(360))*n
     y1=sin(x*!dtor)
     y2=sin((x*i/(10*n))*!dtor)
     plot, x, y1, yr=[-2,2], xr=[0,360*n], /xs
     oplot, x, y1, col=c1
     oplot, x, y2, col=c2
     oplot, x, y1+y2, thick=2, col=c3
     wait, 0.1
  endFOR

end
  
