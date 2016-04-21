FUNCTION calcet, SMC
  return, 1.0-(1.0/(1+(2*SMC)^5)-0.03*SMC)
END

PRO scaleet, stdev
  old=!p
  !p.multi=[0,1,2]
  IF n_elements(stdev) EQ 0 THEN stdev=0.2
  nvals=10000
  nthetas=100

  theta=indgen(nthetas)/(nthetas-1.0)
  alltheta=rebin(indgen(nthetas)/(nthetas-1.0), nthetas,nvals)
  randvals= randomn(seed, [nthetas,nvals])*stdev

  alltheta+= randvals
  print, min(randvals), max(randvals)
  alltheta=alltheta>(-0.2)
  alltheta=alltheta<1.2


  allet=calcet(alltheta)
  plot, rebin(theta, nthetas,nthetas), allet[*,0:nthetas-1], $
    psym=3, yr=[-0.2, 1.2], /ys
  oplot, theta, total(allet, 2)/(nvals-1), thick=2, color=255
  oplot, theta, calcet(theta), l=2, thick=2

  plot, theta, total(allet, 2)/(nvals-1), yr=[-0.2, 1.2], /ys
  oplot, theta, total(allet, 2)/(nvals-1), thick=2, color=255
  oplot, theta, calcet(theta), l=2, thick=2

  !p=old
end
