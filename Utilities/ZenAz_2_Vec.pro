;+
; NAME: ZenAz_2_Vec
;
; PURPOSE: Convert a Zenith angle and an azimuth into a three element, (x,y,z) vector
;   
; CATEGORY: Remote Sensing solar calculations
;
; CALLING SEQUENCE: vector = ZenAz_2_Vec(Zenith, Azimuth)
;
; INPUTS:
;   Zenith          Zenith angle for output vector (degrees)
;                      This is the angle between the vector and the zenith point
;
;   Azimuth         Azimuth for output vector (degrees)
;                      This is the angle between the vector (projected onto a flat surface),
;                      and true north, clockwise from the north
;
; OPTIONAL INPUTS: NONE
;
; KEYWORD PARAMETERS: NONE
;
; OUTPUTS: 
;   vector          3 element vector (x,y,z)
;              X        Longitude distance from starting point
;                        positive to the east
;              Y        Latitude  distance from starting point
;                        positive to the north
;              Z        Elevation distance from starting point
;                        positive upwards
;
;                 These are normalized such that the smallest (non-zero) magnitude = 1
;
;
; OPTIONAL OUTPUTS: NONE
;
; COMMON BLOCKS: NONE
;
; SIDE EFFECTS: NONE
;
; RESTRICTIONS: Zenith angle must be greater than 0 degrees
;
; PROCEDURE:  Determine which quadrant we are in (NE,SE,SW,NW)
;             Calculate inverse tangents
;             Fix Signs
;             check normalization and return
;
; EXAMPLE:  vector = ZenAz_2_Vec(29, 175) 
;
; MODIFICATION HISTORY:
;           03/03/2005 - edg - original
;
;-

FUNCTION ZenAz_2_Vec, zenith, azimuth
  
  IF n_params() EQ 0 THEN BEGIN
     doc_library, "ZenAz_2_Vec"
     return, -1
  ENDIF

  IF zenith GT 90 THEN return, [-1,-1,-1]

  IF azimuth GT 360 THEN BEGIN 
     print, "Azimuth angle must be between -360 and 360", azimuth
     return, [-1,-1,-1]
  ENDIF 
  IF azimuth LT 0 THEN azimuth+=360
  IF azimuth LT 0 THEN BEGIN 
     print, "Azimuth angle must be between -360 and 360 ()", azimuth
     return, [-1,-1,-1]
  ENDIF 


  IF azimuth EQ 0 OR azimuth EQ 360 THEN BEGIN
     x=0
     y=1
     z = tan(!dtor*(90-zenith))
;; we are in the northeast quadrant, x and y are both positive, xoy=pos
  ENDIF ELSE IF azimuth LT 90 THEN BEGIN

     xoy = tan(!dtor*azimuth)
     IF xoy GT 1 THEN BEGIN 
        y=1
        x=xoy
     ENDIF ELSE BEGIN
        x=1
        y=1/xoy
     ENDELSE 

     zoxy=tan(!dtor*(90-zenith))

     z = zoxy * sqrt(x^2 * y^2)
     
  endIF ELSE IF azimuth EQ 90 THEN BEGIN
     x=1
     y=0
     z = tan(!dtor*(90-zenith))
;; we are in the southeast quadrant, x is positive, and y is negative, xoy=neg
  ENDIF ELSE IF azimuth LT 180 THEN BEGIN

     xoy = tan(!dtor*azimuth)
     IF abs(xoy) GT 1 THEN BEGIN 
        y=-1
        x=-1*xoy
     ENDIF ELSE BEGIN
        x=1
        y=1/xoy
     ENDELSE 

     zoxy=tan(!dtor*(90-zenith))

     z = zoxy * sqrt(x^2 * y^2)

  endIF ELSE IF azimuth EQ 180 THEN BEGIN
     x=0
     y=-1
     z=tan(!dtor*(90-zenith))
;; we are in the southwest quadrant, x and y are both negative, xoy=pos
  endIF ELSE IF azimuth LT 270 THEN BEGIN

     xoy = tan(!dtor*azimuth)
     IF xoy GT 1 THEN BEGIN 
        y=-1
        x=-1*xoy
     ENDIF ELSE BEGIN
        x=-1
        y=x/xoy
     ENDELSE 

     zoxy=tan(!dtor*(90-zenith))

     z = zoxy * sqrt(x^2 * y^2)

  endIF ELSE IF azimuth EQ 270 THEN BEGIN
     x=-1
     y=0
     z=tan(!dtor*(90-zenith))
;; we are in the northwest quadrant, x is negative, y is positive, xoy=neg
  endIF ELSE BEGIN ;azimuth ge 270 lt 360

     xoy = tan(!dtor*azimuth)
     IF abs(xoy) GT 1 THEN BEGIN 
        y=1
        x=xoy
     ENDIF ELSE BEGIN
        x=-1
        y=x/xoy
     ENDELSE 

     zoxy=tan(!dtor*(90-zenith))

     z = zoxy * sqrt(x^2 * y^2)
  ENDELSE 


  IF z LT 1 THEN BEGIN
     x/=z
     y/=z
     z=1
  ENDIF

  IF zenith EQ 0 THEN return, [0,0,1]

  return, [x,y,z]
END
