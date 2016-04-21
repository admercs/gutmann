; plots the Noah (cambell/cosby/other) k-theta curves for a range of b values
FUNCTION plotNoahSHPallB, color=color

;; numerical variables0
  start=1
  stop=15
  step=2
  n=(stop-start)/step+1
  nvals=100
  i=0
  newSize=0.3

;; physical variables
  psi=0.5
  theta_s=0.4
  theta_r=0.02

  results=fltarr(nvals,3,n)

  FOR b=start,stop,step DO BEGIN
     tmpresults=noahsucsat(b, psi, theta_s, theta_r, n=nvals)
     results[*,0:1,i]=tmpresults
     IF keyword_set(color) THEN color=((255./n)*i)+7
     IF i EQ 0 THEN BEGIN 
        plot, tmpresults[*,1], tmpresults[*,0], $
              title="Noah SHP Varying Beta", ytitle="Suction Head", $
              xtitle="Moisture Content", $
              xr=[0,0.5], yr=[0.1,10E20], /ylog, color=color
     ENDIF ELSE $
       oplot, tmpresults[*,1], tmpresults[*,0], color=color

     pos=where(tmpresults[*,1] LT 0.1)
     oldSize=!p.charsize
     !p.charsize=newSize
     xyouts, tmpresults[pos[0], 1], tmpresults[pos[0],0], $
             strcompress(b, /remove_all)
     !p.charsize=oldSize
     i++

  ENDFOR 

  i=0
  FOR b=start, stop, step DO BEGIN
     k=noahk(results[*,1,i], b, theta_s)
     results[*,2,i]=transpose(k)

     IF keyword_set(color) THEN color=((255./n)*i)+7
     IF i EQ 0 THEN BEGIN
        plot, results[*,1,i], k, $
              title="Noah SHP Varying Beta", ytitle="Conductivity", $
              xtitle="Moisture Content", $
              xr=[0,0.5], yr=[1E-20,1], /ylog, color=color

        pos=where(results[*,1,i] LT 0.15)
        oldSize=!p.charsize
        !p.charsize=newSize
        xyouts, results[pos[0],1,i], k[pos[0]], strcompress(b, /remove_all)
        !p.charsize=oldSize
     ENDIF ELSE $
       oplot, results[*,1,i], k, color=color
     i++
  ENDFOR
  i--
  pos=where(results[*,1,i] LT 0.15)
  oldSize=!p.charsize
  !p.charsize=newSize
  xyouts, results[pos[0],1,i], k[pos[0]], strcompress(b-2)
  !p.charsize=oldSize

  i=0
  FOR b=start, stop, step DO BEGIN 
     IF keyword_set(color) THEN color=((255./n)*i)+7
     
     IF i EQ 0 THEN BEGIN
        plot, results[*,0,i], results[*,2,i], $
              title="Noah SHP Varying Beta", ytitle="Conductivity", $
              xtitle="Suction Head", $
              yr=[1E-20,1], /ylog, xr=[0.1,1E15], /xs, /ys, /xlog, color=color
     ENDIF ELSE oplot, results[*,0,i], results[*,2,i], color=color
     i++
  ENDFOR
  oldSize=!p.charsize
  !p.charsize=newSize
  xyouts, 10E2,10E-7, strcompress(stop)
  xyouts, 1, 10E-7,strcompress(start)
  !p.charsize=oldSize
  return, results
END 
