;; plot soil textures in rosetta database on a soil texture triangle
PRO plotTextures, input, base=base, plottheta=plottheta, plotk=plotk
  IF n_elements(input) EQ 0 THEN input="newRosetta.txt"
  IF NOT keyword_set(base) THEN base =0
  print, load_cols(input, data)
  
  loamdex=where(data[3,*] lt 52 AND $
                data[4,*] gt 28 and data[4,*] lt 50 AND $
                data[5,*] lt 28 and data[5,*] gt 7)

  sldex=where(data[3,*] le 80 AND data[3,*] ge 50 AND $
                data[4,*] ge 0 and data[4,*] le 50 AND $
                data[5,*] le 20 and data[5,*] ge 0)

  cldex=where(data[3,*] le 45 AND data[3,*] ge 20 AND $
                data[5,*] le 40 and data[5,*] ge 27)

  sdex=where(data[3,*] GE 90)
  lsdex=where(data[3,*] LE 90 AND data[3,*] GE 80)

  window, base, xs=500, ys=500
  FOR i=0, n_elements(loamdex)-1 DO vgplot, data[7:11, loamdex[i]], $
    plottheta=plottheta, plotk=plotk

  window, base+1, xs=500, ys=500
  FOR i=0, n_elements(cldex)-1 DO vgplot, data[7:11, cldex[i]], $
    plottheta=plottheta, plotk=plotk

  window, base+2, xs=500, ys=500
  FOR i=0, n_elements(sldex)-1 DO vgplot, data[7:11, sldex[i]], $
    plottheta=plottheta, plotk=plotk

  window, base+3, xs=500, ys=500
  FOR i=0, n_elements(sdex)-1 DO vgplot, data[7:11, sdex[i]], $
    plottheta=plottheta, plotk=plotk

  window, base+4, xs=500, ys=500
  FOR i=0, n_elements(lsdex)-1 DO vgplot, data[7:11, lsdex[i]], $
    plottheta=plottheta, plotk=plotk
END

PRO plotIssues, input, base=base, plottheta=plottheta, plotk=plotk
  IF n_elements(input) EQ 0 THEN input="newRosetta.txt"
  IF NOT keyword_set(base) THEN base =0
  print, load_cols(input, data)

  loamdex=where(data[3,*] lt 52 AND $
                data[4,*] gt 28 and data[4,*] lt 50 AND $
                data[5,*] lt 28 and data[5,*] gt 7 AND $
                data[7,*] NE -9.9)

;  loamdex=where(data[3,*] le 80 AND data[3,*] ge 50 AND $
;                data[4,*] ge 0 and data[4,*] le 50 AND $
;                data[5,*] le 20 and data[5,*] ge 0 AND $
;                data[7,*] NE -9.9)


  
  old=setupPlot()
;  device, xsize=5, ysize=5
  !p.multi=[0,1,1]
 i=0 
  !p.thick=1

  FOR i=0, n_elements(loamdex)-1, 2 DO $
    vgplot, data[7:11, loamdex[i]], line=2, /plotk

  sand=[26.78, 0.053, 0.375, 0.0352, 3.18]
  silt=[1.595, 0.050, 0.489, 0.0066, 1.68]
  clay=[0.615, 0.098, 0.459, 0.015 , 1.25]

  !p.thick=4

  vgplot, sand, /plotk, color=1
  vgplot, silt, /plotk, color=2
  vgplot, clay, /plotk, color=3

;; paint over the graph edges in black again
  sand[0]=0
  vgplot, sand, /plotk


  resetplot, old
END
