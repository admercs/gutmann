PRO unsatplots, basename1, basename2, title=title, outfile=outfile
  if not keyword_set(outfile) then outfile=basename1+basename2+'.ps'
  
;  oldp=!p.multi
;  !p.multi=[0,1,3]
;  olddevice=!D.name
;  set_plot, 'ps'
;  device, filename=outfile, $
;          xs=7.5, ys=10, xoff=0.5, yoff=0.5, $
;          /inches, /tt_font, set_font=times, font_size=36


  xr=[225,230]
  yr=[280,330]
  
  j=load_cols(basename1+'temp.out', temp1)
  j=load_cols(basename1+'theta.out', theta1)
  j=load_cols(basename1+'heatflux.out', flux1)
  j=load_cols(basename2+'temp.out', temp2)
  j=load_cols(basename2+'theta.out', theta2)
  j=load_cols(basename2+'heatflux.out', flux2)

  fluxUnits=3600.

  plot, temp1[0,*], temp1[2,*], xr=xr, yr=yr, /xs, /ys, $
    line=2, title=title+'Skin Temperature', $
    ytitle='Skin Temperature (K)', xtitle='Day'
  oplot, temp2[0,*], temp2[2,*], color=1
  oplot, temp1[0,*], temp1[2,*], color=3

  plot, temp1[0,*], temp1[3,*], xr=xr, yr=yr, /xs, /ys, $
    line=2, title=title+' Temperature', $
    ytitle='Temperature (K)', xtitle='Day'
  oplot, temp2[0,*], temp2[3,*], color=1
  oplot, temp1[0,*], temp1[3,*], color=3
  
  plot, theta1[0,*], theta1[1,*], xr=xr, yr=[0,0.4], /xs, $
    line=2, title=title+' Moisture Content', $
    ytitle='Moisture Content (cm^3/cm^3)', xtitle='Day'
  oplot, theta2[0,*], theta2[1,*], color=1
  oplot, theta1[0,*], theta1[1,*], color=3

  plot, flux1[0,*], flux1[2,*]/fluxUnits, $
    xr=xr, /xs, yr=[-100,600], /ys, $
    line=2, title=title+' Sensible Heat Flux', $
    ytitle='Latent Heat (W/m^2)', xtitle='Day'
  oplot, flux2[0,*], flux2[2,*]/fluxUnits, color=1
  oplot, flux1[0,*], flux1[2,*]/fluxUnits, color=3

  plot, flux1[0,*], flux1[3,*]/fluxUnits, $
    xr=xr, /xs, yr=[-100,600], /ys, $
    line=2, title=title+' Latent Heat Flux', $
    ytitle='Latent Heat (W/m^2)', xtitle='Day'
  oplot, flux2[0,*], flux2[3,*]/fluxUnits, color=1
  oplot, flux1[0,*], flux1[3,*]/fluxUnits, color=3

  plot, flux1[0,*], flux1[4,*]/fluxUnits, $
    xr=xr, /xs, yr=[-100,600], /ys, $
    line=2, title=title+' Ground Heat Flux', $
    ytitle='Latent Heat (W/m^2)', xtitle='Day'
  oplot, flux2[0,*], flux2[4,*]/fluxUnits, color=1
  oplot, flux1[0,*], flux1[4,*]/fluxUnits, color=3

;  device, /close

;  !p.multi=oldp
;  set_plot, olddevice

end
