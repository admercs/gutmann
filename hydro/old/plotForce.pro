;; plot weather forcings from a Noah model run
PRO plotForce, datafile
  print, load_cols(datafile, data)
  
  day=lindgen(n_elements(data[0,*]))/48.+221


  raindex=indgen(n_elements(data[0,*]))
  rain=(data[3,raindex]+data[3,raindex+1])/2.
  
  xr=[224,230]

  plot, day[raindex], rain, $
        title='Weather Forcing', ytitle='Rainfall rate (mm/hr)', $
        xtitle="Day", ystyle=8, xr=xr
  oplot, day[raindex], rain, color=3

  axis, yaxis=1, yr=[-100,1200], /ys, ytitle="Solar Radiation (W/m^2)"
  plot, day, data[5,*], $
        /noerase, yr=[-100,1200], xs=4, ys=5, xr=xr

  oplot, day, data[5,*], color=1

end
