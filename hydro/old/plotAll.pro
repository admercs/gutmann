;; plots Ts error vs vgN, alpha for UNSAT runs, makes pretty error surfaces in NIP proposal?
PRO plotall
  cd, current=old
  texture=['sand', 'clay', 'silt', 'sloam', 'loam']
  textitle=['Sand', 'Clay', 'Silt', 'Sandy Loam', 'Loam']
  correctvals=[[3.18, 1.25, 1.68, 1.45, 1.47], $
               [0.035, 0.015, 0.0066, 0.0267, 0.011]]
  params=['vgn', 'alpha']
  paramtitle=['n', 'alpha']
  mins=[1.10, 0.003]
  maxs=[3.4, 0.040]
  outfile='allPlots.ps'

  save = !p.multi
  !p.multi=[0,2,4]
  savedev=!d.name
  set_plot, 'ps'
  
  device,file=outfile ,xsize=7.5, ysize=10, xoff=0.5, yoff=0.5, /inches, $
         set_font='Times', /tt_font, font_size=18
  
;  !x.thick=8
;  !y.thick=8
;  !p.thick=8
;  !p.font=1

  FOR i=0, n_elements(texture)-1 DO BEGIN
     cd, texture[i]
     FOR j=0, n_elements(params)-1 DO BEGIN
        cd, params[j]
        openr, un, /get, 'testOutput.huge'
        data=dblarr(50)
        readu, un, data
;        plot, data
        title=string(textitle[i], ' ', paramtitle[j])
        ytitle='RMS error'
        xtitle=paramtitle[j]
        x = indgen(50)* ((maxs[j]-mins[j])/49.) +mins[j]
        inverseEstimate=where(abs(data[0:48]) EQ min(abs(data[0:48])), count)
        IF count NE 0 THEN inverseEstimate = x[inverseEstimate]

        top=4
        plot, x[0:48], abs(data[0:48]), title=title, $
              xtitle=xtitle, ytitle=ytitle, yr=[0,5]
        oplot, [correctvals[i,j],correctvals[i,j]], [0,top-(top/4.)]
        oplot, [inverseEstimate, inverseEstimate], [0,top-(top/4.)], linestyle=2
        inverseEstimate=strmid(strcompress(inverseEstimate,/remove_all), 0, 6)

        xloc=correctvals[i,j]
        IF xloc LT x[5] THEN xloc = xloc+x[2]-x[0]
        yloc=top-(top/4.)+(top/20.)
;        IF xloc GT x[35] THEN xloc = xloc-x[10]+mins[j]
        thisVal=strmid(strcompress(correctvals[i,j],/remove_all), 0, 6)

        xyouts, xloc, yloc+(top/10.), 'Real',charsize=0.5, alignment=0.5
        xyouts, xloc, yloc, thisVal, charsize=0.5, alignment=0.5
        xyouts, xloc, yloc+3*(top/10.), 'Estimate',charsize=0.5, alignment=0.5
        xyouts, xloc, yloc+2*(top/10.), inverseEstimate,charsize=0.5, alignment=0.5

        top=max(abs(data))
        plot, x[0:48], abs(data[0:48]), title=title, $
              xtitle=xtitle, ytitle=ytitle, yr=[0,top+top/4.], /ystyle

        IF j EQ 0 THEN BEGIN
           IF i EQ 0 THEN sand=abs(data[0:48])
           IF i EQ 2 THEN silt=abs(data[0:48])
           IF i EQ 4 THEN loam=abs(data[0:48])
           nx=x
        ENDIF

        oplot, [correctvals[i,j],correctvals[i,j]], [0,top-(top/4.)]
        oplot, [float(inverseEstimate), float(inverseEstimate)], $
               [0,top-(top/4.)], linestyle=2

        xloc=correctvals[i,j]
        IF xloc LT x[5] THEN xloc = xloc+x[3]-x[0]
        yloc=top-(top/4.)+(top/20.)
        thisVal=strmid(strcompress(correctvals[i,j],/remove_all), 0, 6)
        xyouts, xloc, yloc+(top/10.), 'Real',charsize=0.5, alignment=0.5
        xyouts, xloc, yloc, thisVal, charsize=0.5, alignment=0.5
        xyouts, xloc, yloc+3*(top/10.), 'Estimate',charsize=0.5, alignment=0.5
        xyouts, xloc, yloc+2*(top/10.), inverseEstimate,charsize=0.5, alignment=0.5

        cd, '../'
        close, un
        free_lun, un
     ENDFOR
     cd, old
  ENDFOR
  col=7
  plot3, col=col
  plot4, col=col
  plot3alpha, col=col
  plot4alpha, col=col

  device, /close
  set_plot, 'x'
  !p.multi=save
  set_plot, 'ps'
  device, file='color3RMS.ps', /color
  oldplot3, transpose(sand), transpose(silt), transpose(loam), col=0, x=nx
  device, /close
  set_plot, 'x'
END
