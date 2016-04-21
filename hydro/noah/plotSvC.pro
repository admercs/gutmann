PRO plotSvC, sand, clay

  tempCol=8

  wset, 0
  print, load_cols('sand', sand)
  print, load_cols('clay', clay)
  plot, sand[tempCol,*], xr=[10000, 11000], yr=[270,320]
  oplot, clay[tempCol,*], linestyle=1

  wset, 1
  plot, sand[tempCol,*]-clay[tempCol,*], xr=[10000,11000], yr=[-5,20]
  print, max(sand[tempCol,10300:10700]-clay[tempCol,10300:10700])

END

PRO plotSvCveg, sand, clay

  tempCol=8
  
  wset, 0
  print, load_cols('sandveg', sand)
  print, load_cols('clayveg', clay)
  plot, sand[tempCol,*], xr=[10000, 11000], yr=[270,320]
  oplot, clay[tempCol,*], linestyle=1

  wset, 1
  plot, sand[tempCol,*]-clay[tempCol,*], xr=[10000,11000], yr=[-5,20]
  print, max(sand[tempCol,10300:10700]-clay[tempCol,10300:10700])

end
