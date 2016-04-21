pro plotTvX, inputfile, plotfile, day, curRes, subset

  old=setupplot(filename=plotfile)
  !p.multi=[0,1,2]

  data1=read_tiff(inputfile.ndvi)
  data2=read_tiff(inputfile.thermal)

;; convert NDVI from 0-20000 -> -1.0-1.0
  data1=(fix(data1)-10000)/10000.
;; convert thermal from DN to Kelvin
  data2=data2*0.02

  plot, data1, data2, psym=3, $
    xr=[-0.2,1], yr=[270,340], /xs, /ys, $
    xtitle="NDVI", $
    ytitle="Surface Temperature (K)", $
    title=string("Day :"+strcompress(day)+ $
                 "   Pixel :"+strcompress(curRes)+ $
                 "   subArea :"+strcompress(subset))
  
  resetplot, old
end
