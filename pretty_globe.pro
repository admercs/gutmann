;+
; NAME: pretty_globe
;
; PURPOSE: make a pretty postscript file of the globe for use in
;          publications as a map background
;
; CATEGORY: mapping, figures
;
; CALLING SEQUENCE: pretty_globe, filename
;
; INPUTS: filename = name of postscript file <default="pretty_globe.ps">
;
; OPTIONAL INPUTS: _extra=e passes extras to map_set
;
; KEYWORD PARAMETERS: <none>
;
; OUTPUTS: postsctipt file
;
; OPTIONAL OUTPUTS: <none>
;
; COMMON BLOCKS: <none>
;
; SIDE EFFECTS: <none>
;
; RESTRICTIONS: <none>
;
; PROCEDURE: set up the map projection (as seen from a satellite
;            100 earth radii above the earth) with filled continents
;            draw country and US State borders
;
; EXAMPLE: pretty_globe, "my_globe.ps"
;
; MODIFICATION HISTORY:
;          Original - edg - 1/16/05 for 1st wrr paper
;
;-

PRO pretty_globe, filename, nops=nops, box=box, _extra=e
  IF n_elements(filename) EQ 0 THEN filename="pretty_globe.ps"
  IF NOT keyword_set(nops) THEN BEGIN 
     old=setupplot(filename=filename, xs=5, ys=5)

;; colors defined in setupplot.pro
     white=207
     black=0
     boxcolor=1   ;red
  ENDIF ELSE BEGIN 
     white=256l^3-1
     black=0
     boxcolor=255 ;red
     !p.background=white
  ENDELSE 

;; setup a globe as seen from a satellite 100 earth radii above the earth
;;  centered at lat=30, lon=-90, fill the continents black,
;;  draw a grid thickness=2, linestyle=dashed
;;  and the horizon thickness=2
  map_set,  30, -90, /continents, /grid, $
            /horizon, /noborder, e_continents={fill:1}, $
            sat_p=[100.0,0.,00], /satellite, _extra=e, color=black, $
            e_horizon={thick:2}, glinethick=2, glinestyle=2
  
;; draw countries and US states in white (on top of black continents)
  map_continents, /countries, /usa, color=white

;; redraw continent borders in black because the state boundaries tend
;; to be too detailed and look bad around inlets.  
  map_continents, color=black

;; if given a box for a region of interest, draw it.  
  IF keyword_set(box) THEN $
    plots, box[0,*], box[1,*], color=boxcolor, thick=2

  IF NOT keyword_set(nops) THEN $
    resetplot, old
end
  
