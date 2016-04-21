FUNCTION calcrunoff, data
  z=[0,0.05,0.1,0.2,0.35,0.55,0.8,1.25,2]
  dz=z[1:*]-z[0:7]
  
  smc=data[18:*,*]
  swat=total(smc*rebin(dz, 8,n_elements(smc[0,*])),1)

  LH=data[7,*] ; J/s(/m^2)
  rho=1000 ; kg/m^3
  lambda=2.5E6 ; J/kg
  dt=1800 ; s
  E = dt*LH/(rho*lambda) ; m^3(/m^2)


  dsw=swat[1:*]-swat[0:n_elements(swat)-2]
  rain=data[3,*]

  runoff=(rain[1:*]*1.79)-E[1:*]-dsw>0

  runoff[where(rain EQ 0)]=0

  drain=dsw+E[1:*]-(rain[1:*]*1.79)<0

;  stop
  return, {runoff:runoff, drain:drain}
end
