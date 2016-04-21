PRO plotebalance
  !p.multi=[0,2,3]
  !p.charsize=0.5
  files=file_search("ihop*/IHOPUDS*.txt")
  xr=[-200,1000]
  yr=xr
  range=xr[1]-xr[0]
  offset=range/15

  FOR i=0, n_elements(files)-1 DO BEGIN
     j=load_cols(files[i], data)
     
     ; available energy=Rnet-Ground heat flux
     a=data[20,*]-data[25,*]

     ; h= latent + sensible heat
     h=data[23,*]+data[24,*]

     ; find the locations with good data and a minimum windspeed
     mid_wind=median(data[15,*])
     good=where(h LT 2000 AND data[15,*] GT mid_wind)
     
     IF good[0] EQ -1 THEN BEGIN 
        good=indgen(n_elements(a))
        print, "NO GOOD POINTS FOUND?"
        print, "IHOP Station = "+strcompress(i+1)
     ENDIF


     plot, a[good], h[good], xr=xr, yr=yr, psym=1, $
           xtitle="Available Energy (Rn-G W/m!E2!N)", $
           ytitle="Heat Flux (H + LE W/m!E2!N)", $
           title="IHOP station"+strcompress(i+1), $
           charsize=1, symsize=0.25
     
     oplot, xr, yr
     line=linfit(a[good], h[good])
     r=correlate(a[good], h[good])
     oplot, xr, xr*line[1]+line[0], l=2
     xyouts, xr[0]+offset, yr[1]-offset, $
             "slope    ="+string(line[1], format='(1F5.2)')
     xyouts, xr[0]+offset, yr[1]-offset*2, $
             "intercept="+string(line[0], format='(1F5.2)')
     xyouts, xr[0]+offset, yr[1]-offset*3, $
             "R!E2!N   ="+string(r^2, format='(1F5.2)')

     FOR j=xr[0],xr[1]-range/80, range/100.0 DO $
       polyfill, [j,j,j+range/80.0, j+range/80.0], $
                 [-170,-100,-100,-170], color=60*(((j/400.0)>0)<1)+8

     plot, [mid_wind, mid_wind], yr, $
           xr=[0,15], yr=[-0.25,1.25],/ys, charsize=1, $
           xtitle="Wind Speed z=10m (m/s)", $
           ytitle="Closure", title="IHOP station"+strcompress(i+1)
     FOR j=0l, n_elements(data[15,*])-1 DO $
       plots, data[15,j]<15, ((h[j]/a[j])>(-0.25))<1.25, $
             psym=1, color=60*(((a[j]/400)>0)<1)+8, symsize=0.5
     oplot, [mid_wind, mid_wind], yr, thick=3, color=1
  ENDFOR
END
