PRO plot_tsvts, modisfile, fieldfile, noahfile, clmfile, best=best
  
  junk=load_cols(modisfile, modisdata)
  junk=load_cols(fieldfile, fielddata)
  junk=load_cols(noahfile, noahdata)


;; load the best comparison of modeled Ts to MODIS Ts
  plot_modis_v_model, modisdata, noahdata, data=model_modis_data, $
    modelTs=2, /noplot, best=best
  
;; constanats for computeing field Ts from LW up
  SB_const=5.67E-8
  emmissivity=0.98

;; calculate Field Ts from Longwave up
;; LW=sigma epsilon Ts^4... Ts=(LW/(sigma epsilon))^(1/4)
  fielddata[2,*]=(fielddata[37,*]/(SB_const*emmissivity))^0.25

;; load the best comparison of measured Ts to MODIS measured Ts
  plot_modis_v_model, modisdata, fielddata, data=meas_modis_data, $
    modelTs=2, /noplot, best=best

  
  range=[280,340]
  cs=0.7
  xy_x=285
  xy_y=332
  xy_yoff=5

;  !p.multi=[0,2,2]
;; modis - field
  x=meas_modis_data[0,*]
  y=meas_modis_data[1,*]
  goodvals=where(y GT 0 AND x GT 0)
  x=x[goodvals]
  y=y[goodvals]
  plot, x, y, $
    xtitle="MODIS Ts (K)", ytitle="Field Ts (K)", $
    /psym, /xs,/ys,xr=range, yr=range
  fit=linfit(x,y)
  xyouts, xy_x, xy_y, "R!U2!N= "+string(correlate(x,y)^2, format='(F4.2)'), charsize=cs
  xyouts, xy_x, xy_y-xy_yoff, "Slope= "+string(fit[1,*], format='(F4.2)'), charsize=cs
  oplot, range, range*fit[1]+fit[0], l=1
  oplot, range, range

;; model - field
  x=model_modis_data[1,*]
  y=meas_modis_data[1,*]
  goodvals=where(y GT 0 AND x GT 0)
  x=x[goodvals]
  y=y[goodvals]
  plot, x, y, $
    xtitle="Noah Ts (K)", ytitle="Field Ts (K)", $
    /psym, /xs,/ys,xr=range, yr=range
  fit=linfit(x,y)
  xyouts, xy_x, xy_y, "R!U2!N= "+string(correlate(x,y)^2, format='(F4.2)'), charsize=cs
  xyouts, xy_x, xy_y-xy_yoff, "Slope= "+string(fit[1,*], format='(F4.2)'), charsize=cs
  oplot, range, range*fit[1]+fit[0], l=1
  oplot, range, range

;; modis - model
  x=model_modis_data[0,*]
  y=model_modis_data[1,*]
  goodvals=where(y GT 0 AND x GT 0)
  x=x[goodvals]
  y=y[goodvals]
  plot, x, y, $
    xtitle="MODIS Ts (K)", ytitle="Noah Ts (K)", $
    /psym, /xs,/ys,xr=range, yr=range
  fit=linfit(x,y)
  xyouts, xy_x, xy_y, "R!U2!N= "+string(correlate(x,y)^2, format='(F4.2)'), charsize=cs
  xyouts, xy_x, xy_y-xy_yoff, "Slope= "+string(fit[1,*], format='(F4.2)'), charsize=cs
  oplot, range, range*fit[1]+fit[0], l=1
  oplot, range, range

  x=getnoons(noahdata[2,*])
  y=getnoons(fielddata[2,*])
  IF n_elements(x) LT n_elements(y) THEN y=y[0:n_elements(x)-1]
  goodvals=where(y GT 0 AND x GT 0)
  x=x[goodvals]
  y=y[goodvals]
  plot, x, y, $
    xtitle="Mid-Day Noah Ts (K)", ytitle="Mid-Day Field Ts (K)", $
    /psym, /xs,/ys,xr=range, yr=range
  fit=linfit(x,y)
  xyouts, xy_x, xy_y, "R!U2!N= "+string(correlate(x,y)^2, format='(F4.2)'), charsize=cs
  xyouts, xy_x, xy_y-xy_yoff, "Slope= "+string(fit[1,*], format='(F4.2)'), charsize=cs
  oplot, range, range*fit[1]+fit[0], l=1
  oplot, range, range

END
