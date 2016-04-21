;; plots error surfaces for vgN, alpha from UNSAT model runs

PRO plot3, sand, silt, loam,  col=col
  IF n_elements(sand) EQ 0 THEN print, load_cols('sand/vgn/logfile', sand)
  IF n_elements(silt) EQ 0 THEN print, load_cols('silt/vgn/logfile', silt)
  IF n_elements(loam) EQ 0 THEN print, load_cols('loam/vgn/logfile', loam)

;  tvlct, [0,255,0], [0,0,255], [0,0,0]

  IF NOT keyword_set(col) THEN col=8

  x = (indgen(49)/48.)*(3.35-1.1)+1.1
  x = sand[3,*]
  plot, x,abs(sand[col,*]), yr=[0,10], $
        xtitle='Van Genuchtan n', ytitle='RMS Error', $
        title='Sand, Silt, Loam : Inverse SHP Solutions'
  oplot, x,abs(sand[col,*]), color=3
  x = silt[3,*]
  oplot, x,abs(silt[col,*]), color=1
  x = loam[3,*]
  x=x-0.025
  oplot, x,abs(loam[col,*]), color=2

  real=[3.18, 1.68, 1.45]
  oplot, [real[0], real[0]], [0, 3], color=3
  oplot, [real[1], real[1]], [0, 2], color=1
  oplot, [real[2], real[2]], [0, 3.2], color=2
  xyouts, real[0], 3.1, strmid(strcompress(string(real[0])), 1, 4), $
                               color=3, alignment=0.5
  xyouts, real[1], 2.1, strmid(strcompress(string(real[1])), 1, 4), $
                               color=1, alignment=0.4
  xyouts, real[2], 3.3, strmid(strcompress(string(real[2])), 1, 4), $
                               color=2, alignment=0.4
  xyouts, real[0], 3.6, 'Real Value', color=3, alignment=0.6
  xyouts, real[1], 2.6, 'Real Value', color=1, alignment=0.35
  xyouts, real[2], 3.8, 'Real Value', color=2, alignment=0.35


  oplot, [1,3.5],[1,1], linestyle=1

end
PRO oldplot3, sand, silt, loam,  col=col, x=x
  IF n_elements(sand) EQ 0 THEN print, load_cols('sand/vgn/logfile', sand)
  IF n_elements(silt) EQ 0 THEN print, load_cols('silt/vgn/logfile', silt)
  IF n_elements(loam) EQ 0 THEN print, load_cols('loam/vgn/logfile', loam)

  IF NOT keyword_set(col) THEN col=0

;  IF NOT keyword_set(x) THEN x = (indgen(49)/48.)*(3.4-1.1)+1.1
;  x=x[0:48]
  plot, x,abs(sand[col,*]), yr=[0,10], $
        xtitle='Van Genuchtan n', ytitle='RMS Error', title='Sand, Silt, Loam'
  oplot, x,abs(silt[col,*]), color=1
  oplot, x,abs(loam[col,*]), color=2

  real=[3.18, 1.68, 1.45]
  oplot, [real[0], real[0]], [0, 1]
  oplot, [real[1], real[1]], [0, 1], color=1
  oplot, [real[2], real[2]], [0, 1], color=2
  

  oplot, [1,3.5],[1,1], linestyle=1

end

PRO plot4, col=col
  print, load_cols('sand/vgn/logfile', sand)
  print, load_cols('clay/vgn/logfile', clay)
  print, load_cols('silt/vgn/logfile', silt)
  print, load_cols('sloam/vgn/logfile', sloam)

  IF NOT keyword_set(col) THEN col=8
  x = (indgen(49)/48.)*(3.5-1)+1
  plot, x,abs(sand[col,*]), yr=[0,5], $
        xtitle='n', ytitle='RMS Error', title='Silt, Clay, Sa. Loam, and Sand'
  oplot, x,abs(silt[col,*]), linestyle=2
  oplot, x,abs(clay[col,*]), linestyle=0
  oplot, x,abs(sloam[col,*]), linestyle=2

  oplot, [1,3.5],[1,1], linestyle=1

end

PRO plot4alpha, col=col
  print, load_cols('sand/alpha/logfile', sand)
  print, load_cols('clay/alpha/logfile', clay)
  print, load_cols('silt/alpha/logfile', silt)
  print, load_cols('sloam/alpha/logfile', sloam)

  IF NOT keyword_set(col) THEN col=8
  x = (indgen(49)/48.)*(1.1-0.003)+0.003
  plot, x,abs(sand[col,*]), yr=[0,5], $
        xtitle='alpha', ytitle='RMS Error', title='Silt, Clay, Sa. Loam, and Sand'
  oplot, x,abs(silt[col,*]), linestyle=2
  oplot, x,abs(clay[col,*]), linestyle=0
  oplot, x,abs(sloam[col,*]), linestyle=2

  oplot, [0,3.5],[1,1], linestyle=1

end
PRO plot3alpha, col=col
  print, load_cols('sand/alpha/logfile', sand)
  print, load_cols('clay/alpha/logfile', clay)
  print, load_cols('loam/alpha/logfile', loam)

  IF NOT keyword_set(col) THEN col=8
  x = (indgen(49)/48.)*(1.1-0.003)+0.003
  plot, x,abs(sand[col,*]), yr=[0,5], $
        xtitle='alpha', ytitle='RMS Error', title='Sand, Clay, Loam'
  oplot, x,abs(clay[col,*]), linestyle=3
  oplot, x,abs(loam[col,*]), linestyle=2

  oplot, [0,3.5],[1,1], linestyle=1

end
