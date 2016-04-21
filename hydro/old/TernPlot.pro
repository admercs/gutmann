;; simple function computes wheather or not a point falls within
;; an equilateral triangle that has sides of length 1 and starts at (0,0)
function isinTriangle, x, y
  if y eq 0 then return, 1
  if x le 0.5 then return, (y lt (x*tan(!dtor*60.)))
  return, (y lt ((1-x)*tan(!dtor*60.)))
end

;; Converts a grid of data points into column format
;; col 1 = x location, col2 = y location, col3 = data value
;;
;; also removes any points that are outside of an
;;    equilateral triangle with side length =1
FUNCTION grid2points, data, xtop, ytop, xbot, ybot
  sz=size(data)
  xmax=sz[1]
  ymax=sz[2]

  output=[0,0,0]
  npoints=0
  xgain=(xtop-xbot)/(xmax-1)
  ygain=(ytop-ybot)/(ymax-1)

  for x=0.,xmax-1 do begin
     for y=0., ymax-1 do begin
        if isinTriangle(x*xgain+xbot, y*ygain+ybot) then begin
           output=[[output], [x*xgain+xbot, y*ygain+ybot, data[x,y]]]
           npoints=npoints+1
        endif
     endfor
  endfor

  output=output[*,1:npoints]
  return, output
end


pro contourTernPlot, x, y, z
;; sets the axis to be exact and to prevent drawing the axis
  !x.style=5  &  !y.style=5

;set up the X and Y axis ranges
;  axis, xr=[0,1], yr=[0,1]

; convert x and y coordinates (really sand and clay %) into cartesian x,y
  pos=Ternary_Coords(x,y)
  sparse_x=pos[0,*]
  sparse_y=pos[1,*]

;; fill in the ends of the triangle with the extreme values
  z=[[z[0]], [z[0,0:3]], [z[4]], [z[0,4:11]], [z[11]] ]
  pos=[[[0,0]], [pos[*,0:3]], [[1,0]], $
       [pos[*,4:11]], [[0.5,sin(!dtor*60.)]] ]
;  print, z, pos
;; smooths the data points
  gridded=min_curve_surf(z,pos[0,*],pos[1,*], nx=101, ny=101)

;; removes data points that fall outside the triangle
  newdata=grid2points(gridded, max(pos[0,*]), max(pos[1,*]), $
                      min(pos[0,*]), min(pos[1,*]))
  x=newdata[0,*]
  y=newdata[1,*]
  z=newdata[2,*]

;print, x, y, z

;; set up the number of contour levels and labels
  levmax=round(max(z)*10)
  levmax=10
  levs=indgen(levmax*2)/2.
  labs=intarr(levmax*2)
  labs[where(levs mod 1 eq 0)]=1
;; make a REAL pretty plot

  loadct, 0
  contour, z, x, y, /irregular, $
    nlevels=1, $
;    title="Soil Texture dT Contour Plot", $
    xs=5, ys=5, xr=[-0.2,1.2], yr=[0,1]

  loadct, 33
  contour, z, x, y, /irregular, /fill, /overplot, $
    levels=levs, C_colors=indgen(levmax*2)*127./levmax

  loadct, 0
  contour, z, x, y, /irregular, /overplot, $
    c_labels=labs, levels=levs;, $
;    title="Soil Texture dT Contour Plot"
 

  xyouts, -0.20, 0, 'Sand'
  xyouts, cos(!dtor*60.)-0.08, sin(!dtor*60.)+0.05, 'Clay'
  xyouts, 1.05, 0, 'Silt'

; plot a triangle around the edge 
  oplot, [0,cos(!dtor*60.),1,0], [0,sin(!dtor*60.),0,0]
  oplot, sparse_x,sparse_y, psym=2
end

pro terndriver, dataf, posf

  if n_elements(posf) eq 0 then posf = 'texture'
  if n_elements(dataf) eq 0 then dataf = 'compsoils.txt'
  
  !error=0
  j=load_cols(dataf, data)
  pos=readSoilText(posf)

  old=setupPlot(filename="TernPlot.ps")
  !p.multi=[0,1,1]

;; all color table loading is performed within TernPlot now
;     levmax=1+round(max(data[i,*])*10)*2
;     offset=20
;     gain=(255.-offset)/levmax
;     tvlct,indgen(levmax)*gain+offset, $ ;Red Component
;       make_array(255, value=offset/2), $ ;Green Component
;       make_array(255, value=offset/2)    ;Blue Component
;     loadct, 33
  contourTernPlot, pos[0,*], pos[2,*], data[1,*]
  for i=0, n_elements(data[*,0])-1 do begin
     print, max(data[i,*])
;     TernPlot, pos[0,*], pos[2,*], data[i,*]
  end

  resetPlot, old
END

PRO TernPlot, filename, sandCol=sandCol, clayCol=clayCol
  print, load_cols(filename, data)
  IF NOT keyword_set(sandCol) THEN sandCol=3
  IF NOT keyword_set(clayCol) THEN clayCol=3
  sand=data[sandCol,*]
  clay=data[clayCol,*]

  ;; sets the axis to be exact and to prevent drawing the axis
  !x.style=5  &  !y.style=5
  
; convert x and y coordinates (really sand and clay %) into cartesian x,y
  pos=Ternary_Coords(sand,clay)

  plot, pos[0,*], pos[1,*], psym=1, xr=[-0.3,1.3], yr=[0,1]

;; Label the resulting plot
  xyouts, -0.20, 0, 'Sand'
  xyouts, cos(!dtor*60.)-0.08, sin(!dtor*60.)+0.05, 'Clay'
  xyouts, 1.05, 0, 'Silt'

; Plot a triangle around the edge 
  oplot, [0,cos(!dtor*60.),1,0], [0,sin(!dtor*60.),0,0]
END

