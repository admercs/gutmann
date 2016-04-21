PRO makeFigs, name1=name1, name2=name2
  if not keyword_set(name1) then name1='CLAY'
  if not keyword_set(name2) then name2='SAND'

; black    0
; red      1
; green    2
; blue     3
; l. red   4
; l. blue  5
; l. green 6
;          Primary        Light
  tvlct,[0,180,  0,  0,   255,230,230], $
        [0,  0,120,  0,   150,255,230], $
        [0,  0,  0,170,   150,230,255]
  
  olddev=!d.name
  set_plot, 'ps'
  device, file='AllFigs.ps', $
    set_font='Times', font_size=36, /tt_font, /color, $
    xs=7.5, xoff=0.5, ys=10, yoff=0.5, /inches
  
  p=!p
  x=!x
  y=!y

  !p.multi=[0,1,3]
  !p.font=1
  !p.thick=2
  !x.thick=3
  !y.thick=3

; Pick your plotting routine here
;  plot3
;  plotSvL
;  plotvg
;  plotnoahSHP, title='Extreme Sand and Clay :'
;  plotvg_cns

;  plot252, 'ihopsand', 'ihopclay'
;  noahplots, 'clay-ihop-1mm', 'sand-ihop-1mm', 10, title='NOAH-IHOP 1mm :'
;  noahplots, 'myclay', 'mysand', 8, title='NOAH-IHOP 5cm :'
;  UNSATplots, 'thinclay', 'thinsand', title='UNSAT 1mm :'
  noahplots, name1, name2, 8, title='NOAH :'
  device, /close
  !p=p &  !x=x &  !y=y 
  set_plot, olddev
;  set_plot, 'x'

end
