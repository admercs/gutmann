PRO plotSvL
  print, load_cols('sandSvL.out', sand)
  print, load_cols('siltSvL.out', silt)
  print, load_cols('loamSvL.out', loam)

  print, load_cols('sand/vgn/mhotw.out', sandT)
  print, load_cols('silt/vgn/mhotw.out', siltT)
  print, load_cols('loam/vgn/mhotw.out', loamT)

;  tvlct, [0,0,150], [0,175,50], [0,0,0]

  col=2
  plot, sandT[0,*], sandT[col,*], Title='Surface Temperature and Latent Heat', $
    ytitle='Surface Temperature', $
    xtitle='Day of the Year', ystyle=9, $
    yr=[220,340]
  oplot, sandT[0,*], sandT[col,*], color=3
;  oplot, siltT[0,*], siltT[col,*], linestyle=3
  oplot, loamT[0,*], loamT[col,*],color=2;, linestyle=2
  oplot, [147.5, 147.1], [315,330]
  oplot, [146.6, 147], [312,330]
  xyouts, 147,331, 'Delta T = 20K', alignment=0.3


  col=3

; energy appears to be in joules per two hours, so divide by two, then
; convert hours to seconds
  j2watt=1/2. * 1/60. * 1/60.
  loam[col,*]=loam[col,*]*j2watt
  axis, yaxis=1, /noerase,  yr=[min(loam[col,*]), 1.8*max(loam[col,*])], $
        ytitle='Latent Heat Flux (W/m^2)'
;  oplot, silt[0,*], silt[col,*], linestyle=3, color=255
;        Title='Latent Heat Flux', $
;        ytitle='Latent Heat Flux (J/m^2)', $
;        xtitle='Day of the Year'
  plot, sand[0,*], j2watt*sand[col,*],  $
    yr=[min(loam[col,*]), 1.8*max(loam[col,*])], $
    /noerase, ystyle=13
  oplot, sand[0,*], j2watt*sand[col,*], color=3
  oplot, loam[0,*], loam[col,*], color=2
  
end
