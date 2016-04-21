;; plots surface temperatures for 4 different files
PRO plotTs4, f1, f2, f3, f4

  print, load_cols(f1, d1)
  print, load_cols(f2, d2)
  print, load_cols(f3, d3)
  print, load_cols(f4, d4)
  day=indgen(n_elements(d1[2,*]))/48. + 220

  old=setupPlot()
  !p.multi=[0,1,1]

  !p.thick=5
  plot, day, d4[2,*], yr=[285,320], xr=[38+220,42+220], /ys, $
        ytitle="Surface Temperature (K)", $
        xtitle="Day of the Year", $
        title="Surface Temperature for 4 different SHPs"
  !p.thick=3
  oplot, day, d2[2,*], color=2
  oplot, day, d3[2,*], color=1
  oplot, day, d1[2,*], color=1

  oplot, day, d1[3,*]*10000 + 285.5, color=3

  resetplot, old
end
