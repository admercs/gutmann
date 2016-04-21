pro sucsat

  n     = 1000.                 ;number of elements
  cmTOm = 100.                  ;convert cm to m
  maxr  = 1.0                   ;cm
  minr  = 0.1                   ;cm
  gamma = 7.24*10.^(-4)         ;N/m^2
  rho   = 1000                  ;kg/m^3
  g     = 9.8                   ;m/s^2


radius = ((maxr-minr)*(float(indgen(n))/(n-1)) + minr)/cmTOm
volume = 10*!pi*radius^2 + 5*!pi*(2*radius)^2
volume1 = 5*!pi*radius^2
volume2= volume1 + 5*!pi*(2*radius)^2

headentry1 = -1.*(2*gamma)/radius
headentry2 = -1.*gamma/radius
print, 'Radii =',radius(0)*100, radius(n-1)*cmTOm, ' (cm)'

maxhead=max(headentry2)
minhead=min(headentry1)
print, 'maxhead =', maxhead, '   minhead =', minhead
headvals=((maxhead-minhead)*(float(indgen(n))/(n-1)) + minhead)


totvol = fltarr(n)  ;integrated total volume
totvol1= fltarr(n)  ;integrated first fill volume 
totvol2= fltarr(n)  ;integrated second fill volume
totvol(0) = volume(0)
totvol1(0) = volume1(0)
totvol2(0) = volume2(0)

for i=1,n-1 do begin
  totvol(i) = totvol(i-1) + volume(i)
  totvol1(i)= totvol1(i-1)+ volume1(i)
  totvol2(i)= totvol2(i-1)+ volume2(i)
endfor


wvol=fltarr(n)
dvol=fltarr(n)
for i=0,n-1 do begin
  dex1=where(headentry1 le headvals(i))
  dex2=where(headentry2 le headvals(i))
  dex1=dex1(n_elements(dex1)-1)
  dex2=dex2(n_elements(dex2)-1)

  if dex1 ne -1 then $
    wvol(i) = totvol1(dex1) &$
    dvol(i) = totvol(dex1)
  if dex2 ne -1 then $
    wvol(i) = wvol(i)+totvol2(dex2)
endfor

print, totvol(n-1)

wsat=wvol/totvol(n-1)
dsat=dvol/totvol(n-1)

window, 0
plot, -1*headvals, dsat, yr=[0,1.2], /xlog
oplot, -1*headvals, wsat, line=1
oplot, [0.001,0.1],[1,1]
end
