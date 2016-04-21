;+
; NAME: make_wrr_map
;
; PURPOSE: draw a map of the field area for wrr paper number 1
;
; CATEGORY: mapping, figures, general
;
; CALLING SEQUENCE: make_wrr_map, sitefile, psfile
;
; INPUTS:  sitefile=text file containing lat,lon pairs for sites
;          psfile = postscript file <default="sitemap.ps">
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS: postscript file
;
; OPTIONAL OUTPUTS:
;
; COMMON BLOCKS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE: read site locations from a file,
;            plot state boundaries and sites
;
; EXAMPLE: make_wrr_map, "sites.txt", "sitemap.ps"
;
; MODIFICATION HISTORY:
;          original - edg - 1/16/2006
;
;-
PRO make_wrr_map, sitefile, psfile, nops=nops

  IF n_elements(sitefile) EQ 0 THEN sitefile="site.txt"
  IF n_elements(psfile) EQ 0 THEN psfile="sitemap.ps"

  IF NOT file_test(sitefile) THEN BEGIN
     print, "error : could not find site file : "+sitefile
     return
  ENDIF

  IF NOT keyword_set(nops) THEN BEGIN 
     old=setupplot(filename=psfile, xs=15/3.0, ys=9/2.0)

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

  boundingbox=transpose([[-110,-110,-95,-95,-110], [30,40,40,30,30]])
  
  junk=load_cols(sitefile, data)

  map_set, /mercator, /continents, limit=[31, -110,40,-95], /usa, /grid, $
           color=black, mlinethick=2, $
           e_grid={label:0, latdel:2, londel:2, box_axes:1}
;           e_grid={label:1, latdel:2, londel:2, lonlab:31, latlab:-109}
  oplot, data[1,*], data[0,*], psym=4, color=black, symsize=0.5

  IF NOT keyword_set(nops) THEN $
    resetplot, old
  
END

