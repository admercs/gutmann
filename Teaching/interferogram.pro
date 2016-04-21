FUNCTION generate_Topography
  x=indgen(360*2)
  y=sin(float(x)*!dtor)
  y2=sin(3.3*float(x)*!dtor)
  y3=sin(6.2*float(x)*!dtor)
  newy= y/5.0+ $     ; fundamental topography
        y2/10.0+ $   ; rolling hills
        y3/20.0+ $   ; smaller hills        
        indgen(720)/720.0  ;gentle linear slope
;        congrid(randomn(10,7200)/10.0, 720, /interp)/5.0+ $ ; random component
  return,(newy-min(newy))*50
END
FUNCTION simple_topography
  x=indgen(360*2)
  y=sin(float(x)*!dtor)
  return, (y-min(y))*50
END
FUNCTION flat_topography
  return, intarr(720)+30
END


FUNCTION load_topography, filename
  junk=load_cols(filename, data)
  return, data>0
END

FUNCTION plot_Sine, offset, shiftMod
  x=indgen(360*2)
  plot, sin(x*!dtor), /xs, yr=[-2,2]
  oplot, sin(x*!dtor+offset/shiftMod*2*!pi)
  oplot, sin(x*!dtor+offset/shiftMod*2*!pi)+ sin(x*!dtor), l=1
  return, sin(offset/shiftMod*2*!pi)
END


PRO plot_geometry, ground, pos, s1, s2
  yr=[0, max(ground)*10]
  n=n_elements(ground)
  xr=[0,n]

;; draw the ground
  plot, ground, yr=yr, xr=xr, /xs, /ys
  polyfill, [indgen(n),n,0], [ground,0,0]

;; calculate the sattellite positions
  xdist=xr[1]-xr[0]
  ydist=yr[1]-yr[0]
  sat1=[s1[0]*xdist,s1[1]*ydist]
  sat2=[s2[0]*xdist,s2[1]*ydist]

;; draw the satellites
  oplot, [sat1[0],sat2[0]], [sat1[1],sat2[1]], psym=2

;; draw lines from the sattelites to the ground position
  oplot, [sat1[0],pos], [sat1[1],ground[pos]], l=1
  oplot, [sat2[0],pos], [sat2[1],ground[pos]], l=2
END

FUNCTION distance, p1, p2
  p1=double(p1)
  p2=double(p2)

;; return the euclidian distance between two points
  return, sqrt((p1[0]-p2[0])^2 + (p1[1]-p2[1])^2)
END
  
FUNCTION calc_shift, ground, pos, s1, s2
  yr=[0, max(ground)*10]
  n=n_elements(ground)
  xr=[0,n]

;; calculate the sattellite positions
  xdist=xr[1]-xr[0]
  ydist=yr[1]-yr[0]
  sat1=[s1[0]*xdist,s1[1]*ydist]
  sat2=[s2[0]*xdist,s2[1]*ydist]

  d1=distance([pos, ground[pos]], s1)
  d2=distance([pos, ground[pos]], s2)
;  print, d1, d2
  phase_shift=(d1-d2)
  return, phase_shift
END

PRO plot_interferance, data, a, b, yr=yr, xr=xr
  IF NOT keyword_set(xr) THEN xr=[0,n_elements(data)]
  n=b-a
  x=indgen(n)+a
  plot, x, data[a:b], /ys, xr=xr, /xs, yr=yr
END

;;
;; MAIN PROGRAM
;; 
;; read or generate terrain
;; move over terrain generateing interferogram (data) 
;; for each point on the terrain,
;;     plot sattelite geometry
;;     calculate phase shift
;;     plot interferogram so far
;;

PRO plotsetup, flat=flat, simple=simple
  terrain=generate_Topography()
  IF keyword_set(flat) THEN terrain=flat_topography()
  IF keyword_set(simple) THEN terrain=simple_topography()
  sat1=[0.05,0.85]
  sat2=[0.1,0.9]
  pos=300
  plot_geometry, terrain, pos, sat1, sat2
end  

function interferogram, terrainFile=terrainFile, $
  flat=flat, simple=simple, fast=fast, resize=resize
  readjunk=""
  oldp=!p.multi
  IF NOT keyword_set(resize) THEN resize=1
  IF NOT keyword_set(fast) THEN begin
     window, xs=1000/resize, ys=1000/resize
     plotsetup, flat=flat, simple=simple
     read, readjunk
     !p.multi=[0,2,2]
  ENDIF

  IF NOT keyword_set(terrainFile) THEN BEGIN
     terrain=generate_Topography()
     IF keyword_set(flat) THEN terrain=flat_topography()
     IF keyword_set(simple) THEN terrain=simple_topography()
  endIF ELSE terrain=load_topography(terrainFile)
  
  ;sattelite positions
  myyr=[[-0.0005,0.0015], [0.04, 0.07]]
  sat1=[0.05,0.85]
  sat2=[0.1,0.9]
  shiftMod=0.001
  IF keyword_set(flat) THEN BEGIN
     shiftMod=0.0004
     myyr=[[-0.0001,0.0005], [0.04,0.07]]
  ENDIF
  IF keyword_set(simple) THEN BEGIN
     shiftMod=0.001
     myyr=[[-0.0005,0.0015], [0.04,0.07]]
  ENDIF

  data=fltarr(n_elements(terrain))
  inter=fltarr(n_elements(terrain))
  start=300
  img=fltarr(n_elements(terrain), 10)
  pausedYet=0
  FOR i=start, n_elements(terrain)-1 DO BEGIN
     data[i]=calc_shift(terrain, i, sat1, sat2)
     img[i,*]=data[i] MOD shiftMod

     If NOT keyword_set(fast) THEN BEGIN 
        IF i GT start AND i MOD 2 EQ 0 THEN BEGIN 
           plot_geometry, terrain, i, sat1, sat2
           
           plot_interferance, data MOD shiftMod, start, i, yr=myyr[*,0], xr=[300,710]
           plot, [0,0],[0,0], xs=4, ys=4
           tvscl, congrid(img, 420/resize,420/resize), 60/resize,60/resize
;           plot_interferance, data, start, i, yr=myyr[*,1]
           inter[i]=plot_Sine(data[i], shiftMod)
           
           wait, 0.1
           IF i-start GE 33 AND NOT pausedYet THEN BEGIN 
              read, readjunk
              pausedYet=1
           ENDIF

        endIF
     ENDIF 

  ENDFOR
  i=i-1
  IF NOT keyword_set(fast) THEN begin
;; correct for the flat earth 
     flat=interferogram(/flat, /fast)
     tmp=data-flat
     tmp[where(tmp EQ 0)]=min(tmp)
     tmp=tmp-min(tmp)

;; let the lecturer catch up, wait for input
     read, readjunk

     plot_geometry, terrain, i, sat1, sat2
     
     plot_interferance, data MOD shiftMod, start, i, yr=myyr[*,0]
     plot, [0,0],[0,0], xs=4, ys=4
     tvscl, congrid(img, 420/resize,420/resize),60/resize,60/resize 
     plot_interferance, (data-min(data[start:i]))*13000, $
                        start, i, yr=[0,200];yr=(myyr[*,1]+0.02)

;; again pause for commentary
     read, readjunk

     plot_geometry, terrain, i, sat1, sat2
     
     plot_interferance, data MOD shiftMod, start, i, yr=myyr[*,0]
     plot, [0,0],[0,0], xs=4, ys=4
     tvscl, congrid(img, 420/resize,420/resize),60/resize,60/resize 

;; plot the real topography, the raw data, and the corrected data
     plot_interferance, (data-min(data[start:i]))*13000, $
                        start, i, yr=[0,200];yr=(myyr[*,1]+0.02)
     oplot, terrain, thick=2
     oplot, tmp*10000+min(terrain), l=2, color=255 
     
     oplot, [300,400], [160,160], l=2, color=255
     xyouts, 440, 158, "Corrected Topography"
     oplot, [300,400], [170,170]
     xyouts, 440, 168, "Uncorrected Topography"
     oplot, [300,400], [180,180], thick=2
     xyouts, 440, 178, "Original/True Topography"

  ENDIF
    
  !p.multi=oldp
  return, data
END
