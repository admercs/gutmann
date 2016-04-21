FUNCTION setupPlot, fileName=fileName, xs=xs, ys=ys, fs=fs, ct=ct, eps=eps
  IF NOT keyword_set(ct) THEN ct=-1
  IF NOT keyword_set(fileName) THEN fileName = 'AllFigs.ps'
  IF NOT keyword_set(xs) THEN xs=8
  IF NOT keyword_set(ys) THEN ys=10
  IF NOT keyword_set(fs) THEN fs=24
 
; IDL's Default color tables 
; 0-        B-W LINEAR   14-             STEPS   28-         Hardcandy
; 1-        BLUE/WHITE   15-     STERN SPECIAL   29-            Nature
; 2-   GRN-RED-BLU-WHT   16-              Haze   30-             Ocean
; 3-   RED TEMPERATURE   17- Blue - Pastel - R   31-        Peppermint
; 4- BLUE/GREEN/RED/YE   18-           Pastels   32-            Plasma
; 5-      STD GAMMA-II   19- Hue Sat Lightness   33-          Blue-Red
; 6-             PRISM   20- Hue Sat Lightness   34-           Rainbow
; 7-        RED-PURPLE   21-   Hue Sat Value 1   35-        Blue Waves
; 8- GREEN/WHITE LINEA   22-   Hue Sat Value 2   36-           Volcano
; 9- GRN/WHT EXPONENTI   23- Purple-Red + Stri   37-             Waves
;10-        GREEN-PINK   24-             Beach   38-         Rainbow18
;11-          BLUE-RED   25-         Mac Style   39-   Rainbow + white
;12-          16 LEVEL   26-             Eos A   40-   Rainbow + black
;13-           RAINBOW   27-             Eos B

; black    0
; red      1
; green    2
; blue     3
; l. red   4
; yellow   5
; l. blue  6
; l. grey  7
;   8-> 70 = smooth red colors
;  71->133 = smooth green colors
; 134->196 = smooth blue colors
; 197->207 = 11 colors selected from the 16 LEVEL color table
;
;      197,    198,   199,  200,  201,   202,  203,    204, 205,  206,   207
;  ~ dk.gr, mid.gr, lt.gr, cyan, blue, purp., mag., dk.mag, red, grey, white
;
; 208-217 = black->white
;
;
;          Primary        Light         lt grey
  tvlct,[[0,180,  0,  0,   255,205,150, 220], $
         fix(indgen(63)*255.0/63.0), $   ;Red Component
         make_array(63, value=20), $
         make_array(63, value=20), $
         [0,0,0,       0,0,128,     255,255,255,  120,255], $  ; from 16 colors
         indgen(11)*255/10.0], $
        $
        [[0,  0,120,  0,   150,205,150, 220], $
         make_array(63, value=20), $         ;Green Component
         fix(indgen(63)*255.0/63.0), $
         make_array(63, value=20), $
         [100,168,250, 220,100,0,     0,0,0,        120,255], $ ; from 16 colors
         indgen(11)*255/10.0], $
        $
        [[0,  0,  0,170,   150,00,255, 220], $
         make_array(63, value=20), $         ;Blue Component
         make_array(63, value=20), $
         fix(indgen(62)*255.0/62.0),[100], $
         [0,0,0,       220,255,255,  255,128,0,   120,255], $ ; from 16 colors
         indgen(11)*255/10.0]
  
  IF ct GE 0 THEN loadct, ct

  olddev=!d.name
  set_plot, 'ps'
  device, file=fileName, $
    set_font='Helvetica', font_size=fs, /tt_font, /color, $
    xs=xs, xoff=0, ys=ys, yoff=0, /inches, encapsulated=eps

  p=!p
  x=!x
  y=!y

  !p.multi=[0,1,1]
  !p.font=1
  !p.thick=1
  !x.thick=4
  !y.thick=4

  return, {plotInfo, p:p, x:x, y:y, olddev:olddev}
END

PRO resetPlot, old
  device, /close
  !p=old.p &  !x=old.x &  !y=old.y
  set_plot, old.olddev
END

