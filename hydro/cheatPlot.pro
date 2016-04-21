;; plots a 2d surface for a plane with the equation given below
;; (currently z=x^2+y^2) and for another plane w/ 10 times the amplitude
PRO cheatPlot, output
  IF n_elements(output) EQ 0 THEN output='temp.ps'

  x=indgen(100)-50
  y=indgen(100)-50
  
  x=rebin(x,100,100)
  y=rebin(transpose(y),100,100)
  z=float(x)^2+float(y)^2

  set_plot, 'ps'
  device,file= output ,xsize=7.5, ysize=10, xoff=.5, yoff=.5, /inches, $
         set_font='Times', /tt_font, font_size=14
  
  save=!p.multi
  !p.multi=[0,1,2]

  surface, z*10, max_value=5000
  surface, z, max_value=5000

  !p.multi=save
  device, /close  

END

