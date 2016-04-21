;+
; NAME: colortable
;
; PURPOSE: returns an array with values that can be passed to plot via the
;          color keyword.  
;
; CATEGORY: plotting
;
; CALLING SEQUENCE: ct=colortable()
;
; INPUTS: <none>
;
; OPTIONAL INPUTS: <none>
;
; KEYWORD PARAMETERS: <none>
;
; OUTPUTS: array of (currently 219) color values
;
; OPTIONAL OUTPUTS: <none>
;
; COMMON BLOCKS: <none>
;
; SIDE EFFECTS: <none>
;
; RESTRICTIONS: <none>
;
; PROCEDURE: create separate red, green, and blue component arrays
;            multiply red by 1, green by 256, and blue by 256^3
;            add red to green to blue and return the resulting array
;
;     black    0
;     red      1
;     green    2
;     blue     3
;     l. red   4
;     l. green 5
;     l. blue  6
;     l. grey  7
;       8-> 70 = smooth red colors
;      71->133 = smooth green colors
;     134->196 = smooth blue colors
;     197->207 = 11 colors selected from the 16 LEVEL color table
;
;      197,    198,   199,  200,  201,   202,  203,    204, 205,  206,   207
;     dk.gr, mid.gr, lt.gr, cyan, blue, purp., mag., dk.mag, red, grey, white
;
;     208-217 = black->white
;
; EXAMPLE:  ct=colortable()
;           for i=0, 218 do plot, indgen(10), color=ct[i]
;
; MODIFICATION HISTORY:
;           Original - edg - 11/01/2005 - color table is from setupplot.pro
;
;-



FUNCTION colortable
  return, [[0,180,  0,  0,   255,230,200, 220], $
            fix(indgen(63)*255.0/63.0), $ ;Red Component
            make_array(63, value=20), $
            make_array(63, value=20), $
            [0,0,0,       0,0,128,     255,255,255,  120,255], $ ; from 16 colors
            indgen(11)*255/10.0] +  $
           $
           [[0,  0,120,  0,   150,255,200, 220], $
            make_array(63, value=20), $ ;Green Component
            fix(indgen(63)*255.0/63.0), $
            make_array(63, value=20), $
            [100,168,250, 220,100,0,     0,0,0,        120,255], $ ; from 16 colors
            indgen(11)*255/10.0]*256l+ $
           $
           [[0,  0,  0,170,   150,230,255, 220], $
            make_array(63, value=20), $ ;Blue Component
            make_array(63, value=20), $
            fix(indgen(62)*255.0/62.0),[100], $
            [0,0,0,       220,255,255,  255,128,0,   120,255], $ ; from 16 colors
            indgen(11)*255/10.0] *256l^2
END
